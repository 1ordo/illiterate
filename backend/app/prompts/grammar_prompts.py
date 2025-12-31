"""
Language-aware prompt templates for grammar correction.

These prompts are designed to:
1. Be deterministic (low temperature)
2. Prevent hallucination of new errors
3. Return strict JSON output
4. Adapt to the target language
"""

import json
from typing import List

from ..config import SUPPORTED_LANGUAGES, TONE_DESCRIPTIONS
from ..models.request import Tone
from ..models.response import GrammarIssue


def get_language_name(language_code: str) -> str:
    """Get the full language name for a code."""
    lang_config = SUPPORTED_LANGUAGES.get(language_code, {})
    return lang_config.get("name", language_code.upper())


def format_issues_for_prompt(issues: List[GrammarIssue]) -> str:
    """Format grammar issues as a structured list for the prompt."""
    formatted = []
    for i, issue in enumerate(issues, 1):
        suggestions_str = ", ".join(f'"{s}"' for s in issue.suggestions[:3])
        formatted.append(
            f"{i}. Position {issue.offset}-{issue.offset + issue.length}: "
            f'"{issue.original_text}" → Suggestions: [{suggestions_str}] '
            f"| Rule: {issue.rule_id} | Issue: {issue.message}"
        )
    return "\n".join(formatted)


def build_grammar_prompt(
    text: str,
    issues: List[GrammarIssue],
    language: str = "nl",
    tone: Tone = Tone.NEUTRAL,
    include_rewrites: bool = True
) -> str:
    """
    Build a language-aware prompt for grammar correction.

    Args:
        text: Original text with issues
        issues: Detected grammar issues from LanguageTool
        language: ISO language code
        tone: Desired tone for rewrites
        include_rewrites: Whether to request rewrite suggestions

    Returns:
        Complete prompt string for the LLM
    """
    language_name = get_language_name(language)
    tone_description = TONE_DESCRIPTIONS.get(tone.value, TONE_DESCRIPTIONS["neutral"])
    issues_formatted = format_issues_for_prompt(issues)

    # Build the rewrite instruction if needed
    rewrite_instruction = ""
    if include_rewrites:
        rewrite_instruction = f"""
Additionally, provide 2 alternative rewrites:
1. FIRST rewrite MUST be in "{tone.value}" tone ({tone_description}) - this is the user's selected tone
2. SECOND rewrite can be in a contrasting tone for comparison
Each rewrite should preserve the original meaning while improving clarity or style.
"""

    prompt = f"""You are a precise grammar correction assistant for {language_name}.

ORIGINAL TEXT:
"{text}"

DETECTED ISSUES (from LanguageTool - treat as ground truth):
{issues_formatted}

YOUR TASK:
1. Create a corrected version by applying ONLY the fixes for the detected issues above
2. For each fix, provide a brief explanation
{rewrite_instruction}
CRITICAL RULES:
- ONLY fix the issues listed above
- NEVER invent new errors or make unnecessary changes
- Preserve the original meaning exactly
- Maintain the original text structure and formatting
- Use the suggested corrections when appropriate
- Respond in valid JSON only

OUTPUT FORMAT (strict JSON):
{{
  "corrected_text": "The text with ONLY the listed issues fixed",
  "rewrites": [
    {{
      "text": "Alternative version of the corrected text",
      "tone": "neutral|formal|casual|academic",
      "score": 8,
      "changes_summary": "Brief description of style changes"
    }}
  ],
  "explanations": [
    {{
      "span": "the problematic word or phrase",
      "original": "original text",
      "corrected": "corrected text",
      "reason": "Brief explanation in {language_name}"
    }}
  ]
}}

IMPORTANT:
- The "corrected_text" must contain ONLY fixes for the {len(issues)} detected issues
- Explanations should be in {language_name} language
- If no rewrites requested, return empty array for rewrites
- Score should reflect how natural and well-written the rewrite is (0-10)

Respond with JSON only, no additional text."""

    return prompt


# Language-specific system prompts for additional context
LANGUAGE_SYSTEM_PROMPTS = {
    "nl": """You are an expert Dutch language assistant. You understand:
- Dutch grammar rules including de/het articles
- Verb conjugation patterns
- Word order in main and subordinate clauses
- Common Dutch spelling mistakes
- Formal vs informal Dutch (u vs jij/je)""",

    "en": """You are an expert English language assistant. You understand:
- Subject-verb agreement
- Tense consistency
- Common confused words (their/there/they're, its/it's)
- British vs American English conventions
- Formal vs casual register""",

    "de": """You are an expert German language assistant. You understand:
- German case system (Nominativ, Akkusativ, Dativ, Genitiv)
- Verb placement in main and subordinate clauses
- Noun gender and article agreement
- Compound word formation
- Formal vs informal address (Sie vs du)""",

    "fr": """You are an expert French language assistant. You understand:
- French agreement rules (gender, number)
- Verb conjugation across tenses
- Accent placement and usage
- Liaison and elision rules
- Formal vs informal register (vous vs tu)""",

    "es": """You are an expert Spanish language assistant. You understand:
- Verb conjugation patterns
- Ser vs estar distinction
- Subjunctive mood usage
- Gender and number agreement
- Regional variations (Spain vs Latin America)"""
}


def get_system_prompt(language: str) -> str:
    """Get language-specific system prompt."""
    return LANGUAGE_SYSTEM_PROMPTS.get(
        language,
        "You are a multilingual grammar expert."
    )


def build_style_rewrite_prompt(
    text: str,
    language: str = "nl",
    tone: Tone = Tone.NEUTRAL
) -> str:
    """
    Build a prompt for style analysis and rewriting.

    Used when LanguageTool found no issues, but we still want:
    1. LLM to check for potential issues LanguageTool might have missed
    2. Style improvement suggestions
    3. Alternative rewrites with different tones

    Args:
        text: Text to analyze
        language: ISO language code
        tone: Desired tone for rewrites

    Returns:
        Complete prompt string for the LLM
    """
    language_name = get_language_name(language)
    tone_description = TONE_DESCRIPTIONS.get(tone.value, TONE_DESCRIPTIONS["neutral"])

    prompt = f"""You are an expert {language_name} language assistant and editor.

ORIGINAL TEXT:
"{text}"

A grammar checker found no issues in this text. However, you should:

1. CAREFULLY CHECK for any issues the grammar checker might have missed:
   - Subtle grammar errors
   - Word choice problems
   - Awkward phrasing
   - Contextual errors
   - Style inconsistencies
   - For Dutch: de/het errors, verb conjugation, word order

2. GENERATE 2 rewrite suggestions:
   - FIRST rewrite MUST be in "{tone.value}" tone ({tone_description}) - this is the user's selected tone
   - SECOND rewrite can be in a contrasting tone for comparison
   - Each should improve clarity or readability

IMPORTANT RULES:
- Be thorough but don't invent problems that don't exist
- If the text is genuinely perfect, say so in corrected_text (keep it identical)
- Provide helpful explanations for any issues you find
- Rewrites should preserve the original meaning
- Respond in valid JSON only

OUTPUT FORMAT (strict JSON):
{{
  "corrected_text": "Your corrected version (or identical if no issues found)",
  "rewrites": [
    {{
      "text": "Alternative version with different style",
      "tone": "neutral|formal|casual|academic",
      "score": 8,
      "changes_summary": "Brief description of style improvements"
    }}
  ],
  "explanations": [
    {{
      "span": "the problematic word or phrase (if any)",
      "original": "original text",
      "corrected": "corrected text",
      "reason": "Explanation in {language_name}"
    }}
  ]
}}

NOTES:
- If no issues found, "explanations" can be empty array
- "rewrites" should have exactly 2 suggestions (first in selected tone, second in contrasting tone)
- Score (0-10) reflects how natural and improved the rewrite is
- All explanations and changes_summary should be in {language_name}

Respond with JSON only, no additional text."""

    return prompt
