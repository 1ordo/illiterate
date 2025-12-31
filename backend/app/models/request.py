"""Request models for the Grammar Checking API."""

from pydantic import BaseModel, Field, field_validator
from typing import Optional
from enum import Enum


class CheckMode(str, Enum):
    """Grammar checking mode."""
    STRICT = "strict"   # Only grammar fixes, no style suggestions
    STYLE = "style"     # Include rewrite suggestions


class Tone(str, Enum):
    """Desired tone for rewrite suggestions."""
    NEUTRAL = "neutral"
    FORMAL = "formal"
    CASUAL = "casual"
    ACADEMIC = "academic"


class CheckRequest(BaseModel):
    """
    Request model for grammar checking.

    Attributes:
        text: The text to check for grammar issues
        language: ISO language code (default: nl for Dutch)
        mode: Checking mode - strict (grammar only) or style (with rewrites)
        tone: Desired tone for rewrite suggestions
        include_explanations: Whether to include detailed explanations
    """

    text: str = Field(
        ...,
        min_length=1,
        max_length=10000,
        description="Text to check for grammar issues"
    )

    language: str = Field(
        default="nl",
        min_length=2,
        max_length=5,
        description="ISO language code (nl, en, de, fr, es)"
    )

    mode: CheckMode = Field(
        default=CheckMode.STRICT,
        description="Checking mode: strict (grammar only) or style (with rewrites)"
    )

    tone: Tone = Field(
        default=Tone.NEUTRAL,
        description="Desired tone for rewrite suggestions"
    )

    include_explanations: bool = Field(
        default=True,
        description="Include detailed explanations for each correction"
    )

    @field_validator("language")
    @classmethod
    def validate_language(cls, v: str) -> str:
        """Normalize language code to lowercase."""
        return v.lower().strip()

    @field_validator("text")
    @classmethod
    def validate_text(cls, v: str) -> str:
        """Strip leading/trailing whitespace from text."""
        return v.strip()

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "text": "Ik heb de boek gelezen.",
                    "language": "nl",
                    "mode": "style",
                    "tone": "formal",
                    "include_explanations": True
                }
            ]
        }
    }
