"""
Pipeline Integration Tests.

Tests for the complete grammar checking pipeline.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from app.models.request import CheckRequest, CheckMode, Tone
from app.models.response import GrammarIssue, IssueCategory, IssueSeverity
from app.services.pipeline import GrammarPipeline
from app.services.validator import ValidationService, ValidationResult


class TestPipeline:
    """Test suite for the grammar pipeline."""

    @pytest.fixture
    def mock_issues(self):
        """Create mock grammar issues."""
        return [
            GrammarIssue(
                offset=8,
                length=2,
                message="Use 'het' instead of 'de' with 'boek'",
                rule_id="DE_HET",
                category=IssueCategory.GRAMMAR,
                severity=IssueSeverity.ERROR,
                original_text="de",
                suggestions=["het"],
                context="Ik heb de boek gelezen"
            )
        ]

    @pytest.fixture
    def sample_request(self):
        """Create a sample check request."""
        return CheckRequest(
            text="Ik heb de boek gelezen.",
            language="nl",
            mode=CheckMode.STYLE,
            tone=Tone.FORMAL,
            include_explanations=True
        )

    def test_request_creation(self, sample_request):
        """Test request model creation."""
        assert sample_request.text == "Ik heb de boek gelezen."
        assert sample_request.language == "nl"
        assert sample_request.mode == CheckMode.STYLE
        assert sample_request.tone == Tone.FORMAL

    def test_rule_based_fix_application(self, mock_issues):
        """Test that rule-based fixes are applied correctly."""
        pipeline = GrammarPipeline()
        text = "Ik heb de boek gelezen."

        result = pipeline._apply_rule_based_fixes(text, mock_issues)

        assert "het boek" in result
        assert "de boek" not in result

    def test_basic_explanation_generation(self, mock_issues):
        """Test basic explanation generation."""
        pipeline = GrammarPipeline()

        explanations = pipeline._generate_basic_explanations(mock_issues)

        assert len(explanations) == 1
        assert explanations[0].original == "de"
        assert explanations[0].corrected == "het"

    def test_multiple_fixes_reverse_order(self):
        """Test that multiple fixes are applied in correct order."""
        pipeline = GrammarPipeline()
        text = "Hij loop naar de werk."

        issues = [
            GrammarIssue(
                offset=4,
                length=4,
                message="Verb conjugation",
                rule_id="VERB",
                category=IssueCategory.GRAMMAR,
                severity=IssueSeverity.ERROR,
                original_text="loop",
                suggestions=["loopt"]
            ),
            GrammarIssue(
                offset=14,
                length=2,
                message="Article error",
                rule_id="DE_HET",
                category=IssueCategory.GRAMMAR,
                severity=IssueSeverity.ERROR,
                original_text="de",
                suggestions=["het"]
            )
        ]

        result = pipeline._apply_rule_based_fixes(text, issues)

        assert "loopt" in result
        assert "het werk" in result


class TestValidation:
    """Test suite for the validation service."""

    @pytest.fixture
    def mock_languagetool(self):
        """Create a mock LanguageTool service."""
        mock = AsyncMock()
        mock.check_text = AsyncMock(return_value=[])
        return mock

    @pytest.fixture
    def validation_service(self, mock_languagetool):
        """Create a validation service with mock LanguageTool."""
        return ValidationService(mock_languagetool)

    @pytest.mark.asyncio
    async def test_valid_correction(self, validation_service):
        """Test that valid corrections pass validation."""
        result = await validation_service.validate_correction(
            corrected_text="Ik heb het boek gelezen.",
            original_issues=[
                GrammarIssue(
                    offset=8,
                    length=2,
                    message="Article error",
                    rule_id="DE_HET",
                    category=IssueCategory.GRAMMAR,
                    severity=IssueSeverity.ERROR,
                    original_text="de",
                    suggestions=["het"]
                )
            ],
            language="nl"
        )

        assert result.is_valid

    @pytest.mark.asyncio
    async def test_invalid_correction_new_errors(
        self, mock_languagetool
    ):
        """Test that corrections with new errors fail validation."""
        # Mock LanguageTool to return new issues
        mock_languagetool.check_text = AsyncMock(return_value=[
            GrammarIssue(
                offset=0,
                length=3,
                message="New error",
                rule_id="NEW_ERROR",
                category=IssueCategory.GRAMMAR,
                severity=IssueSeverity.ERROR,
                original_text="Ik",
                suggestions=["ik"]
            )
        ])

        validation_service = ValidationService(mock_languagetool)

        result = await validation_service.validate_correction(
            corrected_text="Ik heb het boek gelezen.",
            original_issues=[],  # No original issues
            language="nl"
        )

        assert not result.is_valid
        assert len(result.new_issues) == 1

    def test_similar_issue_detection(self, validation_service):
        """Test detection of similar issues."""
        issue = GrammarIssue(
            offset=10,  # Different offset
            length=2,
            message="Article error",
            rule_id="DE_HET",
            category=IssueCategory.GRAMMAR,
            severity=IssueSeverity.ERROR,
            original_text="de",
            suggestions=["het"]
        )

        original = [
            GrammarIssue(
                offset=8,  # Original offset
                length=2,
                message="Article error",
                rule_id="DE_HET",
                category=IssueCategory.GRAMMAR,
                severity=IssueSeverity.ERROR,
                original_text="de",
                suggestions=["het"]
            )
        ]

        # Same rule ID and same original text should be considered similar
        is_similar = validation_service._is_similar_issue(issue, original)
        assert is_similar


class TestCaching:
    """Test suite for caching functionality."""

    def test_cache_key_generation(self):
        """Test that cache keys are generated correctly."""
        from app.utils.cache import GrammarCache

        cache = GrammarCache()

        key1 = cache._make_key("test", "nl", "strict")
        key2 = cache._make_key("test", "nl", "strict")
        key3 = cache._make_key("test", "en", "strict")

        assert key1 == key2  # Same input = same key
        assert key1 != key3  # Different language = different key

    def test_cache_set_get(self):
        """Test cache set and get operations."""
        from app.utils.cache import GrammarCache

        cache = GrammarCache()

        cache.set("test", "nl", {"result": "cached"}, "strict")
        result = cache.get("test", "nl", "strict")

        assert result is not None
        assert result["result"] == "cached"

    def test_cache_miss(self):
        """Test cache miss returns None."""
        from app.utils.cache import GrammarCache

        cache = GrammarCache()

        result = cache.get("nonexistent", "nl", "strict")

        assert result is None

    def test_cache_stats(self):
        """Test cache statistics."""
        from app.utils.cache import GrammarCache

        cache = GrammarCache()

        cache.set("test", "nl", {}, "strict")
        cache.get("test", "nl", "strict")  # Hit
        cache.get("miss", "nl", "strict")  # Miss

        stats = cache.get_stats()

        assert stats["hits"] == 1
        assert stats["misses"] == 1
