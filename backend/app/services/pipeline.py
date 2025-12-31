"""
Two-Stage Grammar Correction Pipeline.

This is the core orchestration component that:
1. Stage 1: Uses LanguageTool for rule-based grammar detection
2. Stage 2: Uses LLM for semantic correction and rewrites
3. Validates LLM output to prevent hallucinations
4. Falls back to rule-based correction if validation fails
"""

import logging
from typing import Optional, List
from dataclasses import dataclass

from .languagetool import LanguageToolService, LanguageToolError
from .llm import LLMService, LLMError
from .validator import ValidationService, ValidationResult
from ..models.request import CheckRequest, CheckMode, Tone
from ..models.response import (
    CheckResponse,
    GrammarIssue,
    RewriteSuggestion,
    Explanation
)
from ..utils.chunker import TextChunker

logger = logging.getLogger(__name__)


class GrammarPipeline:
    """
    Orchestrates the two-stage grammar correction pipeline.

    Flow:
    1. LanguageTool analysis (ground truth for errors)
    2. LLM correction (semantic understanding + rewrites)
    3. Validation (re-check LLM output)
    4. Fallback to rule-based if validation fails
    """

    def __init__(self):
        self.languagetool = LanguageToolService()
        self.llm = LLMService()
        self.validator = ValidationService(self.languagetool)
        self.chunker = TextChunker()

    async def process(self, request: CheckRequest) -> CheckResponse:
        """
        Process a grammar check request through the full pipeline.

        Args:
            request: The check request with text, language, mode, etc.

        Returns:
            CheckResponse with corrections, issues, rewrites, and explanations
        """
        text = request.text
        language = request.language
        mode = request.mode
        tone = request.tone
        include_explanations = request.include_explanations

        logger.info(f"Processing grammar check: {len(text)} chars, lang={language}")

        # ===== STAGE 1: LanguageTool Analysis =====
        try:
            issues = await self.languagetool.check_text(text, language)
            logger.info(f"LanguageTool found {len(issues)} issues")
        except LanguageToolError as e:
            logger.error(f"LanguageTool failed: {e}")
            # Return original text with error indication
            return CheckResponse(
                original_text=text,
                corrected_text=text,
                issues=[],
                rewrites=[],
                explanations=[],
                validation_passed=False,
                fallback_used=True,
                language=language
            )

        # If no issues found, still call LLM to check for issues LanguageTool might have missed
        if not issues:
            logger.info("No grammar issues from LanguageTool, calling LLM for additional checking")
            include_rewrites = mode == CheckMode.STYLE
            try:
                llm_response = await self.llm.generate_rewrites_only(
                    text=text,
                    language=language,
                    tone=tone
                )
                if llm_response:
                    # Check if LLM found issues that LanguageTool missed
                    llm_found_issues = llm_response.corrected_text != text
                    corrected = llm_response.corrected_text if llm_found_issues else text

                    # If LLM made corrections, validate them
                    if llm_found_issues:
                        logger.info("LLM found issues that LanguageTool missed")
                        validation = await self.validator.validate_correction(
                            corrected,
                            [],  # No original issues to compare
                            language
                        )
                        if not validation.is_valid:
                            logger.warning("LLM corrections failed validation, keeping original")
                            corrected = text

                    # Convert LLM explanations to structured issues
                    llm_issues = self._explanations_to_issues(text, llm_response.explanations)

                    return CheckResponse(
                        original_text=text,
                        corrected_text=corrected,
                        issues=llm_issues if llm_found_issues else [],
                        rewrites=llm_response.rewrites if include_rewrites else [],
                        explanations=llm_response.explanations if include_explanations else [],
                        validation_passed=True,
                        fallback_used=False,
                        language=language
                    )
            except Exception as e:
                logger.warning(f"LLM generation failed: {e}")

            return CheckResponse(
                original_text=text,
                corrected_text=text,
                issues=[],
                rewrites=[],
                explanations=[],
                validation_passed=True,
                fallback_used=False,
                language=language
            )

        # Generate rule-based fallback correction
        fallback_text = self._apply_rule_based_fixes(text, issues)

        # ===== STAGE 2: LLM Semantic Correction =====
        include_rewrites = mode == CheckMode.STYLE
        llm_response = None
        validation_passed = False
        used_fallback = False
        final_text = fallback_text
        rewrites: List[RewriteSuggestion] = []
        explanations: List[Explanation] = []

        try:
            llm_response = await self.llm.generate_correction(
                text=text,
                issues=issues,
                language=language,
                tone=tone,
                include_rewrites=include_rewrites
            )

            if llm_response:
                # ===== VALIDATION LOOP =====
                final_text, used_fallback, validation = await self.validator.validate_and_choose(
                    llm_text=llm_response.corrected_text,
                    fallback_text=fallback_text,
                    original_issues=issues,
                    language=language
                )

                validation_passed = validation.is_valid

                if not used_fallback:
                    rewrites = llm_response.rewrites
                    explanations = llm_response.explanations
                else:
                    logger.warning(
                        f"Validation failed: {validation.message}. "
                        f"New issues: {len(validation.new_issues)}"
                    )
                    # Generate basic explanations for rule-based fixes
                    explanations = self._generate_basic_explanations(issues)
            else:
                # LLM failed, use fallback
                used_fallback = True
                explanations = self._generate_basic_explanations(issues)

        except LLMError as e:
            logger.error(f"LLM failed: {e}. Using fallback.")
            used_fallback = True
            explanations = self._generate_basic_explanations(issues)

        return CheckResponse(
            original_text=text,
            corrected_text=final_text,
            issues=issues,
            rewrites=rewrites,
            explanations=explanations if include_explanations else [],
            validation_passed=validation_passed,
            fallback_used=used_fallback,
            language=language
        )

    def _apply_rule_based_fixes(
        self,
        text: str,
        issues: List[GrammarIssue]
    ) -> str:
        """
        Apply rule-based fixes using LanguageTool suggestions.

        This is the fallback method when LLM fails or produces invalid output.
        We apply suggestions in reverse order to maintain correct offsets.
        """
        # Sort issues by offset in descending order to apply from end to start
        sorted_issues = sorted(issues, key=lambda x: x.offset, reverse=True)

        result = text
        for issue in sorted_issues:
            if issue.suggestions:
                # Use the first suggestion
                suggestion = issue.suggestions[0]
                start = issue.offset
                end = issue.offset + issue.length
                result = result[:start] + suggestion + result[end:]

        return result

    def _generate_basic_explanations(
        self,
        issues: List[GrammarIssue]
    ) -> List[Explanation]:
        """Generate basic explanations from LanguageTool issues."""
        explanations = []
        for issue in issues:
            if issue.suggestions:
                explanations.append(Explanation(
                    span=issue.original_text,
                    original=issue.original_text,
                    corrected=issue.suggestions[0],
                    reason=issue.message
                ))
        return explanations

    def _explanations_to_issues(
        self,
        text: str,
        explanations: List[Explanation]
    ) -> List[GrammarIssue]:
        """
        Convert LLM explanations to GrammarIssue objects.

        Used when LLM finds issues that LanguageTool missed.
        """
        issues = []
        for exp in explanations:
            if exp.original and exp.corrected and exp.original != exp.corrected:
                # Find the offset of the original text
                offset = text.find(exp.original)
                if offset == -1:
                    offset = 0  # Fallback if not found

                issues.append(GrammarIssue(
                    offset=offset,
                    length=len(exp.original),
                    message=exp.reason or "LLM detected issue",
                    rule_id="LLM_DETECTED",
                    category="grammar",
                    severity="warning",
                    original_text=exp.original,
                    suggestions=[exp.corrected],
                    context=text[max(0, offset-20):offset+len(exp.original)+20]
                ))
        return issues

    async def check_services(self) -> dict:
        """Check availability of all services."""
        lt_available = await self.languagetool.is_available()
        llm_available = await self.llm.is_available()

        return {
            "languagetool": lt_available,
            "llm": llm_available,
            "pipeline_ready": lt_available  # LLM is optional (has fallback)
        }
