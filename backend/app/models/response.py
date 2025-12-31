"""Response models for the Grammar Checking API."""

from pydantic import BaseModel, Field
from typing import List, Optional
from enum import Enum


class IssueSeverity(str, Enum):
    """Severity level of a grammar issue."""
    ERROR = "error"
    WARNING = "warning"
    STYLE = "style"
    HINT = "hint"


class IssueCategory(str, Enum):
    """Category of grammar issue."""
    GRAMMAR = "grammar"
    SPELLING = "spelling"
    PUNCTUATION = "punctuation"
    STYLE = "style"
    TYPOGRAPHY = "typography"
    WORD_ORDER = "word_order"
    AGREEMENT = "agreement"
    OTHER = "other"


class GrammarIssue(BaseModel):
    """
    Represents a single grammar issue detected in the text.

    Attributes:
        offset: Character offset where the issue starts
        length: Length of the problematic span
        message: Human-readable description of the issue
        rule_id: LanguageTool rule identifier
        category: Category of the issue
        severity: Severity level
        original_text: The problematic text span
        suggestions: List of suggested corrections
        context: Surrounding context for the issue
    """

    offset: int = Field(..., ge=0, description="Character offset of issue start")
    length: int = Field(..., ge=1, description="Length of the problematic span")
    message: str = Field(..., description="Description of the grammar issue")
    rule_id: str = Field(..., description="LanguageTool rule identifier")
    category: IssueCategory = Field(
        default=IssueCategory.OTHER,
        description="Category of the issue"
    )
    severity: IssueSeverity = Field(
        default=IssueSeverity.ERROR,
        description="Severity level"
    )
    original_text: str = Field(..., description="The problematic text span")
    suggestions: List[str] = Field(
        default_factory=list,
        description="Suggested corrections"
    )
    context: Optional[str] = Field(
        default=None,
        description="Surrounding context"
    )


class RewriteSuggestion(BaseModel):
    """
    A rewrite suggestion for the entire text.

    Attributes:
        text: The rewritten text
        tone: The tone of this rewrite
        score: Quality score from 0-10
        changes_summary: Brief summary of changes made
    """

    text: str = Field(..., description="The rewritten text")
    tone: str = Field(..., description="Tone of this rewrite (neutral/formal/casual/academic)")
    score: float = Field(
        ...,
        ge=0,
        le=10,
        description="Quality score from 0-10"
    )
    changes_summary: Optional[str] = Field(
        default=None,
        description="Brief summary of changes made"
    )


class Explanation(BaseModel):
    """
    Explanation for a specific correction.

    Attributes:
        span: The text span that was corrected
        original: Original text
        corrected: Corrected text
        reason: Explanation of why this was corrected
    """

    span: str = Field(..., description="The text span that was corrected")
    original: str = Field(..., description="Original text")
    corrected: str = Field(..., description="Corrected text")
    reason: str = Field(..., description="Explanation of the correction")


class CheckResponse(BaseModel):
    """
    Complete response from the grammar checking pipeline.

    Attributes:
        original_text: The input text
        corrected_text: Text with all corrections applied
        issues: List of detected grammar issues
        rewrites: Alternative rewrite suggestions (if style mode)
        explanations: Explanations for each correction
        validation_passed: Whether LLM output passed validation
        fallback_used: Whether rule-based fallback was used
        language: Language code that was used
        issue_count: Total number of issues found
    """

    original_text: str = Field(..., description="The original input text")
    corrected_text: str = Field(..., description="Text with corrections applied")
    issues: List[GrammarIssue] = Field(
        default_factory=list,
        description="List of detected grammar issues"
    )
    rewrites: List[RewriteSuggestion] = Field(
        default_factory=list,
        description="Alternative rewrite suggestions"
    )
    explanations: List[Explanation] = Field(
        default_factory=list,
        description="Explanations for corrections"
    )
    validation_passed: bool = Field(
        default=True,
        description="Whether LLM output passed validation"
    )
    fallback_used: bool = Field(
        default=False,
        description="Whether rule-based fallback was used"
    )
    language: str = Field(..., description="Language code used for checking")
    issue_count: int = Field(default=0, description="Total number of issues found")

    def model_post_init(self, __context) -> None:
        """Calculate issue count after initialization."""
        object.__setattr__(self, 'issue_count', len(self.issues))


class LanguageInfo(BaseModel):
    """Information about a supported language."""

    code: str = Field(..., description="ISO language code")
    name: str = Field(..., description="Language name in English")
    native_name: str = Field(..., description="Language name in native language")
    examples: List[str] = Field(
        default_factory=list,
        description="Example sentences with errors"
    )


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = Field(default="healthy")
    languagetool_available: bool = Field(default=False)
    llm_available: bool = Field(default=False)
    version: str = Field(default="1.0.0")
