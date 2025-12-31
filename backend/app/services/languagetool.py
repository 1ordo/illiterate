"""
LanguageTool Service Client.

Handles communication with the local LanguageTool HTTP API for rule-based
grammar detection. This is Stage 1 of the two-stage pipeline.
"""

import httpx
from typing import List, Optional
import logging

from ..config import get_settings, SUPPORTED_LANGUAGES
from ..models.response import GrammarIssue, IssueSeverity, IssueCategory

logger = logging.getLogger(__name__)


class LanguageToolError(Exception):
    """Exception raised when LanguageTool API fails."""
    pass


class LanguageToolService:
    """
    Client for the LanguageTool grammar checking API.

    This service handles:
    - Text analysis for grammar, spelling, and style issues
    - Language code mapping to LanguageTool-specific codes
    - Response normalization to internal models
    """

    def __init__(self):
        self.settings = get_settings()
        self.base_url = self.settings.languagetool_url
        self.timeout = self.settings.languagetool_timeout

    def _get_languagetool_code(self, language: str) -> str:
        """Map internal language code to LanguageTool code."""
        lang_config = SUPPORTED_LANGUAGES.get(language, {})
        return lang_config.get("languagetool_code", language)

    def _map_category(self, lt_category: str) -> IssueCategory:
        """Map LanguageTool category to internal category."""
        category_map = {
            "GRAMMAR": IssueCategory.GRAMMAR,
            "TYPOS": IssueCategory.SPELLING,
            "SPELLING": IssueCategory.SPELLING,
            "PUNCTUATION": IssueCategory.PUNCTUATION,
            "STYLE": IssueCategory.STYLE,
            "TYPOGRAPHY": IssueCategory.TYPOGRAPHY,
            "CASING": IssueCategory.TYPOGRAPHY,
            "CONFUSED_WORDS": IssueCategory.GRAMMAR,
            "REDUNDANCY": IssueCategory.STYLE,
            "MISC": IssueCategory.OTHER,
        }
        return category_map.get(lt_category.upper(), IssueCategory.OTHER)

    def _map_severity(self, lt_type: str) -> IssueSeverity:
        """Map LanguageTool issue type to severity."""
        severity_map = {
            "misspelling": IssueSeverity.ERROR,
            "grammar": IssueSeverity.ERROR,
            "style": IssueSeverity.STYLE,
            "typographical": IssueSeverity.WARNING,
            "hint": IssueSeverity.HINT,
        }
        return severity_map.get(lt_type.lower(), IssueSeverity.WARNING)

    async def check_text(
        self,
        text: str,
        language: str = "nl"
    ) -> List[GrammarIssue]:
        """
        Analyze text for grammar issues using LanguageTool.

        Args:
            text: The text to analyze
            language: ISO language code

        Returns:
            List of detected grammar issues

        Raises:
            LanguageToolError: If the API call fails
        """
        lt_language = self._get_languagetool_code(language)

        payload = {
            "text": text,
            "language": lt_language,
            "enabledOnly": "false",
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/check",
                    data=payload
                )
                response.raise_for_status()
                data = response.json()

        except httpx.TimeoutException:
            logger.error(f"LanguageTool timeout for language {language}")
            raise LanguageToolError("LanguageTool service timeout")
        except httpx.HTTPStatusError as e:
            logger.error(f"LanguageTool HTTP error: {e.response.status_code}")
            raise LanguageToolError(f"LanguageTool HTTP error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"LanguageTool error: {str(e)}")
            raise LanguageToolError(f"LanguageTool error: {str(e)}")

        return self._parse_matches(data.get("matches", []), text)

    def _parse_matches(
        self,
        matches: List[dict],
        original_text: str
    ) -> List[GrammarIssue]:
        """Parse LanguageTool matches into GrammarIssue models."""
        issues = []

        for match in matches:
            offset = match.get("offset", 0)
            length = match.get("length", 0)

            # Extract the original text span
            original_span = original_text[offset:offset + length] if length > 0 else ""

            # Extract suggestions
            replacements = match.get("replacements", [])
            suggestions = [r.get("value", "") for r in replacements[:5]]  # Limit to 5

            # Get context
            context_data = match.get("context", {})
            context = context_data.get("text", "")

            # Map category
            rule = match.get("rule", {})
            category_data = rule.get("category", {})
            category_id = category_data.get("id", "OTHER")

            issue = GrammarIssue(
                offset=offset,
                length=length,
                message=match.get("message", ""),
                rule_id=rule.get("id", "UNKNOWN"),
                category=self._map_category(category_id),
                severity=self._map_severity(match.get("type", {}).get("typeName", "other")),
                original_text=original_span,
                suggestions=suggestions,
                context=context if context else None
            )
            issues.append(issue)

        return issues

    async def is_available(self) -> bool:
        """Check if LanguageTool service is available."""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(f"{self.base_url}/languages")
                return response.status_code == 200
        except Exception:
            return False

    async def get_supported_languages(self) -> List[dict]:
        """Get list of languages supported by LanguageTool."""
        try:
            async with httpx.AsyncClient(timeout=5) as client:
                response = await client.get(f"{self.base_url}/languages")
                response.raise_for_status()
                return response.json()
        except Exception as e:
            logger.error(f"Failed to get languages: {str(e)}")
            return []
