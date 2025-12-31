"""
LLM Service Client.

Uses OpenAI-compatible API to communicate with local LLM for semantic
correction and rewrite generation. This is Stage 2 of the pipeline.

Designed to work with any OpenAI-compatible endpoint (local LLM, Ollama, etc.)
"""

import httpx
import json
import logging
import re
from typing import Optional, Dict, Any, List

from ..config import get_settings, SUPPORTED_LANGUAGES, TONE_DESCRIPTIONS
from ..models.request import Tone
from ..models.response import GrammarIssue, RewriteSuggestion, Explanation
from ..prompts.grammar_prompts import build_grammar_prompt

logger = logging.getLogger(__name__)


class LLMError(Exception):
    """Exception raised when LLM API fails."""
    pass


class LLMResponse:
    """Parsed response from the LLM."""

    def __init__(
        self,
        corrected_text: str,
        rewrites: List[RewriteSuggestion],
        explanations: List[Explanation]
    ):
        self.corrected_text = corrected_text
        self.rewrites = rewrites
        self.explanations = explanations


class LLMService:
    """
    Client for OpenAI-compatible LLM API.

    This service handles:
    - Building language-aware prompts
    - Calling the LLM API
    - Parsing strict JSON responses
    - Fallback handling on parse failures
    """

    def __init__(self):
        self.settings = get_settings()
        self.base_url = self.settings.llm_url
        self.model = self.settings.llm_model
        self.temperature = self.settings.llm_temperature
        self.max_tokens = self.settings.llm_max_tokens
        self.timeout = self.settings.llm_timeout

    async def generate_correction(
        self,
        text: str,
        issues: List[GrammarIssue],
        language: str = "nl",
        tone: Tone = Tone.NEUTRAL,
        include_rewrites: bool = True
    ) -> Optional[LLMResponse]:
        """
        Generate corrected text and rewrites using the LLM.

        Args:
            text: Original text with issues
            issues: List of detected grammar issues from LanguageTool
            language: ISO language code
            tone: Desired tone for rewrites
            include_rewrites: Whether to generate rewrite suggestions

        Returns:
            LLMResponse with corrections, rewrites, and explanations
            None if the LLM call fails
        """
        if not issues:
            # No issues to fix, return original
            return LLMResponse(
                corrected_text=text,
                rewrites=[],
                explanations=[]
            )

        # Build the prompt
        prompt = build_grammar_prompt(
            text=text,
            issues=issues,
            language=language,
            tone=tone,
            include_rewrites=include_rewrites
        )

        # Call the LLM
        try:
            response_text = await self._call_llm(prompt)
            if response_text is None:
                return None

            # Parse the JSON response
            return self._parse_response(response_text, text)

        except Exception as e:
            logger.error(f"LLM generation failed: {str(e)}")
            return None

    async def _call_llm(self, prompt: str) -> Optional[str]:
        """
        Call the OpenAI-compatible LLM API.

        Args:
            prompt: The prompt to send

        Returns:
            The response text, or None on failure
        """
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": "You are a precise grammar correction assistant. You MUST respond with valid JSON only. Never include any text outside the JSON object."
                },
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": self.temperature,
            "max_tokens": self.max_tokens
            # Note: response_format removed for compatibility with local LLMs
        }

        headers = {
            "Content-Type": "application/json"
        }

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    self.base_url,
                    json=payload,
                    headers=headers
                )
                response.raise_for_status()
                data = response.json()

                # Extract the response content
                choices = data.get("choices", [])
                if not choices:
                    logger.error("LLM returned no choices")
                    return None

                message = choices[0].get("message", {})
                content = message.get("content", "")

                return content.strip()

        except httpx.TimeoutException:
            logger.error("LLM request timeout")
            raise LLMError("LLM service timeout")
        except httpx.HTTPStatusError as e:
            logger.error(f"LLM HTTP error: {e.response.status_code}")
            raise LLMError(f"LLM HTTP error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"LLM error: {str(e)}")
            raise LLMError(f"LLM error: {str(e)}")

    def _parse_response(self, response_text: str, original_text: str) -> Optional[LLMResponse]:
        """
        Parse the LLM JSON response.

        Args:
            response_text: Raw response from LLM
            original_text: Original input text (for fallback)

        Returns:
            Parsed LLMResponse, or None on parse failure
        """
        try:
            # Try to extract JSON from the response
            json_match = re.search(r'\{[\s\S]*\}', response_text)
            if not json_match:
                logger.error("No JSON found in LLM response")
                return None

            json_str = json_match.group()
            data = json.loads(json_str)

            # Extract corrected text
            corrected_text = data.get("corrected_text", original_text)

            # Extract rewrites
            rewrites = []
            for rw in data.get("rewrites", []):
                try:
                    rewrites.append(RewriteSuggestion(
                        text=rw.get("text", ""),
                        tone=rw.get("tone", "neutral"),
                        score=float(rw.get("score", 5)),
                        changes_summary=rw.get("changes_summary")
                    ))
                except Exception as e:
                    logger.warning(f"Failed to parse rewrite: {e}")
                    continue

            # Extract explanations
            explanations = []
            for exp in data.get("explanations", []):
                try:
                    # Handle both old and new explanation formats
                    span = exp.get("span", "")
                    original = exp.get("original", span)
                    corrected = exp.get("corrected", "")
                    reason = exp.get("reason", "")

                    explanations.append(Explanation(
                        span=span,
                        original=original,
                        corrected=corrected,
                        reason=reason
                    ))
                except Exception as e:
                    logger.warning(f"Failed to parse explanation: {e}")
                    continue

            return LLMResponse(
                corrected_text=corrected_text,
                rewrites=rewrites,
                explanations=explanations
            )

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse LLM JSON: {e}")
            return None
        except Exception as e:
            logger.error(f"Error parsing LLM response: {e}")
            return None

    async def generate_rewrites_only(
        self,
        text: str,
        language: str = "nl",
        tone: Tone = Tone.NEUTRAL
    ) -> Optional[LLMResponse]:
        """
        Generate style rewrites and check for issues LLM might find.

        Called when LanguageTool found no issues but user wants style suggestions.
        The LLM will also check for potential issues that LanguageTool missed.

        Args:
            text: Text to analyze and rewrite
            language: ISO language code
            tone: Desired tone for rewrites

        Returns:
            LLMResponse with potential corrections, rewrites, and explanations
        """
        from ..prompts.grammar_prompts import build_style_rewrite_prompt

        prompt = build_style_rewrite_prompt(
            text=text,
            language=language,
            tone=tone
        )

        try:
            response_text = await self._call_llm(prompt)
            if response_text is None:
                return None

            return self._parse_response(response_text, text)

        except Exception as e:
            logger.error(f"LLM rewrite generation failed: {str(e)}")
            return None

    async def is_available(self) -> bool:
        """Check if LLM service is available."""
        try:
            # Try a simple completion
            payload = {
                "model": self.model,
                "messages": [
                    {"role": "user", "content": "Say 'ok'"}
                ],
                "max_tokens": 5,
                "temperature": 0
            }

            async with httpx.AsyncClient(timeout=10) as client:
                response = await client.post(
                    self.base_url,
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
                return response.status_code == 200
        except Exception:
            return False
