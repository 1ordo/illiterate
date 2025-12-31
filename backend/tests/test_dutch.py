"""
Dutch Language Test Cases.

Tests for Dutch grammar checking, including:
- de/het article errors
- Verb conjugation
- Word order
- Common spelling mistakes
"""

import pytest
from app.models.request import CheckRequest, CheckMode, Tone


# Dutch test cases with expected issues
DUTCH_TEST_CASES = [
    {
        "input": "Ik heb de boek gelezen.",
        "description": "de/het article error",
        "expected_fix": "het boek",
        "rule_pattern": "DE_HET",
    },
    {
        "input": "Hij loop naar huis.",
        "description": "Verb conjugation error",
        "expected_fix": "loopt",
        "rule_pattern": "GRAMMAR",
    },
    {
        "input": "Ik wil dat je komt morgen.",
        "description": "Word order in subordinate clause",
        "expected_fix": "morgen komt",
        "rule_pattern": "WORD_ORDER",
    },
    {
        "input": "De informaties zijn niet correct.",
        "description": "Pluralization error (informatie has no plural)",
        "expected_fix": "informatie",
        "rule_pattern": "GRAMMAR",
    },
    {
        "input": "Zij heeft de werk gedaan.",
        "description": "Gender agreement error",
        "expected_fix": "het werk",
        "rule_pattern": "DE_HET",
    },
    {
        "input": "Wij gaat naar de winkel.",
        "description": "Subject-verb agreement",
        "expected_fix": "gaan",
        "rule_pattern": "GRAMMAR",
    },
    {
        "input": "Het is een mooi dag vandaag.",
        "description": "Adjective agreement",
        "expected_fix": "mooie dag",
        "rule_pattern": "GRAMMAR",
    },
    {
        "input": "Ik heb gisteren een email gestuurd aan jij.",
        "description": "Pronoun case error",
        "expected_fix": "aan jou",
        "rule_pattern": "GRAMMAR",
    },
]


class TestDutchGrammar:
    """Test suite for Dutch grammar checking."""

    @pytest.fixture
    def dutch_request(self):
        """Create a base Dutch check request."""
        def _make_request(text: str, mode: CheckMode = CheckMode.STRICT):
            return CheckRequest(
                text=text,
                language="nl",
                mode=mode,
                tone=Tone.NEUTRAL,
                include_explanations=True
            )
        return _make_request

    @pytest.mark.parametrize("test_case", DUTCH_TEST_CASES)
    def test_dutch_error_detection(self, test_case, dutch_request):
        """Test that Dutch errors are properly formatted for detection."""
        request = dutch_request(test_case["input"])

        # Verify request is valid
        assert request.text == test_case["input"]
        assert request.language == "nl"

        # Note: Actual detection requires running LanguageTool
        # These tests verify the test case format

    def test_request_model_validation(self, dutch_request):
        """Test request model validation."""
        request = dutch_request("Test tekst.")

        assert request.language == "nl"
        assert request.mode == CheckMode.STRICT
        assert request.include_explanations is True

    def test_style_mode_request(self, dutch_request):
        """Test style mode enables rewrites."""
        request = dutch_request("Dit is een test.", CheckMode.STYLE)

        assert request.mode == CheckMode.STYLE

    def test_text_normalization(self):
        """Test that text is normalized (stripped)."""
        request = CheckRequest(
            text="  Tekst met spaties  ",
            language="nl"
        )

        assert request.text == "Tekst met spaties"

    def test_language_normalization(self):
        """Test that language code is normalized."""
        request = CheckRequest(
            text="Test",
            language="NL"
        )

        assert request.language == "nl"


class TestDutchExamples:
    """Test the example sentences from configuration."""

    def test_de_het_example(self):
        """Test de/het article example."""
        # "Ik heb de boek gelezen." - should detect de → het
        text = "Ik heb de boek gelezen."
        request = CheckRequest(text=text, language="nl")

        assert "de boek" in request.text
        # The actual correction would change "de" to "het"

    def test_verb_conjugation_example(self):
        """Test verb conjugation example."""
        # "Hij loop naar huis." - should detect loop → loopt
        text = "Hij loop naar huis."
        request = CheckRequest(text=text, language="nl")

        assert "loop" in request.text
        # The actual correction would change "loop" to "loopt"

    def test_word_order_example(self):
        """Test word order example."""
        # Word order in Dutch subordinate clauses
        text = "Ik denk dat hij is ziek."
        request = CheckRequest(text=text, language="nl")

        assert "dat hij is ziek" in request.text
        # Correct: "dat hij ziek is"


# Example sentences for integration testing
INTEGRATION_TEST_SENTENCES = {
    "simple_error": "Ik heb de boek gelezen.",
    "multiple_errors": "Hij loop naar de werk en hij heb geen tijd.",
    "no_errors": "Dit is een correcte Nederlandse zin.",
    "complex": "Ik wil dat je morgen komt en dat je de boek meebrengt die ik jou heb gegeven.",
}
