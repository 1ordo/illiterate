"""
Validation Service for LLM Output.

This is a CRITICAL component that prevents LLM hallucinations from reaching
the user. After the LLM generates a correction, we re-run LanguageTool on
the corrected text to verify no new errors were introduced.
"""

import logging
from typing import Tuple, List, Optional
from dataclasses import dataclass

from .languagetool import LanguageToolService, LanguageToolError
from ..models.response import GrammarIssue

logger = logging.getLogger(__name__)


@dataclass
class ValidationResult:
    """Result of validating LLM output."""
    is_valid: bool
    new_issues: List[GrammarIssue]
    message: str


class ValidationService:
    """
    Validates LLM corrections by re-checking with LanguageTool.

    The validation loop ensures that:
    1. LLM corrections don't introduce new errors
    2. LLM doesn't hallucinate issues that didn't exist
    3. The final output is cleaner than the input
    """

    def __init__(self, languagetool: LanguageToolService):
        self.languagetool = languagetool
        # Allow some tolerance for new issues (style vs grammar)
        self.max_new_issues = 0  # Strict: no new errors allowed
        self.ignore_categories = {"STYLE", "TYPOGRAPHY"}  # Can ignore minor style issues

    async def validate_correction(
        self,
        corrected_text: str,
        original_issues: List[GrammarIssue],
        language: str = "nl",
        strict: bool = True
    ) -> ValidationResult:
        """
        Validate that LLM correction doesn't introduce new errors.

        Args:
            corrected_text: The LLM-corrected text
            original_issues: Issues found in the original text
            language: Language code
            strict: If True, reject any new issues; if False, allow style issues

        Returns:
            ValidationResult with validity status and any new issues
        """
        try:
            # Re-check the corrected text with LanguageTool
            new_issues = await self.languagetool.check_text(
                corrected_text,
                language
            )
        except LanguageToolError as e:
            logger.error(f"Validation failed - LanguageTool error: {e}")
            # If we can't validate, reject the LLM output to be safe
            return ValidationResult(
                is_valid=False,
                new_issues=[],
                message=f"Validation failed: {str(e)}"
            )

        # Filter out issues that were in the original text (same position/rule)
        original_rules = {(i.offset, i.rule_id) for i in original_issues}

        # Identify truly new issues
        truly_new_issues = []
        for issue in new_issues:
            key = (issue.offset, issue.rule_id)

            # Skip if this was an original issue (might be at different offset)
            if self._is_similar_issue(issue, original_issues):
                continue

            # In non-strict mode, skip style/typography issues
            if not strict and issue.category.value.upper() in self.ignore_categories:
                continue

            truly_new_issues.append(issue)

        # Determine validity
        if len(truly_new_issues) > self.max_new_issues:
            return ValidationResult(
                is_valid=False,
                new_issues=truly_new_issues,
                message=f"LLM introduced {len(truly_new_issues)} new issues"
            )

        # Check if we actually reduced errors
        if len(new_issues) > len(original_issues):
            logger.warning(
                f"Correction has more issues ({len(new_issues)}) "
                f"than original ({len(original_issues)})"
            )
            return ValidationResult(
                is_valid=False,
                new_issues=new_issues,
                message="Correction did not reduce error count"
            )

        return ValidationResult(
            is_valid=True,
            new_issues=truly_new_issues,
            message="Validation passed"
        )

    def _is_similar_issue(
        self,
        issue: GrammarIssue,
        original_issues: List[GrammarIssue]
    ) -> bool:
        """
        Check if an issue is similar to any original issue.

        This accounts for offset shifts due to corrections.
        """
        for orig in original_issues:
            # Same rule ID and similar text
            if issue.rule_id == orig.rule_id:
                if issue.original_text.lower() == orig.original_text.lower():
                    return True

            # Same error text (might have shifted position)
            if issue.original_text == orig.original_text:
                return True

        return False

    async def validate_and_choose(
        self,
        llm_text: str,
        fallback_text: str,
        original_issues: List[GrammarIssue],
        language: str = "nl"
    ) -> Tuple[str, bool, ValidationResult]:
        """
        Validate LLM output and choose between LLM and fallback.

        Args:
            llm_text: Text corrected by LLM
            fallback_text: Text corrected by rule-based method
            original_issues: Original issues from LanguageTool
            language: Language code

        Returns:
            Tuple of (chosen_text, used_fallback, validation_result)
        """
        # Validate LLM output
        validation = await self.validate_correction(
            llm_text,
            original_issues,
            language
        )

        if validation.is_valid:
            return llm_text, False, validation
        else:
            logger.warning(
                f"LLM validation failed: {validation.message}. "
                "Falling back to rule-based correction."
            )
            return fallback_text, True, validation
