"""
Configuration for the Grammar Checking Service.

All endpoints, language settings, and service parameters are centralized here
for easy modification and deployment configuration.
"""

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import Dict, List, Optional
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings with environment variable support."""

    # Service Configuration
    app_name: str = "ileterate Grammar API"
    app_version: str = "1.0.0"
    debug: bool = False
    log_level: str = "INFO"

    # LanguageTool Configuration
    languagetool_url: str = "http://localhost:8081/v2"
    languagetool_timeout: int = 30

    # LLM Configuration
    llm_url: str = "http://localhost:1234/v1/chat/completions"
    llm_model: str = "gpt-4"
    llm_api_key: Optional[str] = None  # For OpenAI or other providers
    llm_temperature: float = 0.1  # Low for deterministic output
    llm_max_tokens: int = 2048
    llm_timeout: int = 60

    # API Security
    api_key: Optional[str] = Field(default=None, description="API key for authentication")
    encryption_enabled: bool = Field(default=False, description="Enable E2E encryption")
    rsa_private_key_path: Optional[str] = None
    rsa_public_key_path: Optional[str] = None

    # Rate Limiting
    rate_limit_enabled: bool = True
    rate_limit_requests: int = 100  # requests per window
    rate_limit_window: int = 60  # seconds

    # Processing Configuration
    max_text_length: int = 10000
    chunk_size: int = 1000  # Characters per chunk
    cache_ttl: int = 300  # Cache TTL in seconds
    cache_max_size: int = 1000  # Max cache entries

    # CORS Configuration
    cors_origins: List[str] = ["*"]
    cors_allow_credentials: bool = True
    cors_allow_methods: List[str] = ["*"]
    cors_allow_headers: List[str] = ["*"]

    class Config:
        env_file = ".env"
        env_prefix = "GRAMMAR_"
        case_sensitive = False


# Language Configuration
SUPPORTED_LANGUAGES: Dict[str, dict] = {
    "nl": {
        "code": "nl",
        "name": "Dutch",
        "native_name": "Nederlands",
        "languagetool_code": "nl",
        "examples": [
            "Ik heb de boek gelezen.",
            "Hij loop naar huis.",
            "Zij is naar school gegaan gisteren."
        ]
    },
    "en": {
        "code": "en",
        "name": "English",
        "native_name": "English",
        "languagetool_code": "en-US",
        "examples": [
            "I has been working here.",
            "Their going to the store.",
            "The informations is incorrect."
        ]
    },
    "de": {
        "code": "de",
        "name": "German",
        "native_name": "Deutsch",
        "languagetool_code": "de-DE",
        "examples": [
            "Ich habe das Buch gelest.",
            "Er gehen nach Hause.",
            "Das Auto ist rot gewesen."
        ]
    },
    "fr": {
        "code": "fr",
        "name": "French",
        "native_name": "Français",
        "languagetool_code": "fr",
        "examples": [
            "Je suis allé au magasin hier.",
            "Il a mangé les pommes.",
            "Elle est très belle."
        ]
    },
    "es": {
        "code": "es",
        "name": "Spanish",
        "native_name": "Español",
        "languagetool_code": "es",
        "examples": [
            "Yo tuve un problema ayer.",
            "El libro es muy interesante.",
            "Ella ha ido al mercado."
        ]
    }
}

# Tone Descriptions for LLM prompts
TONE_DESCRIPTIONS: Dict[str, str] = {
    "neutral": "Use a balanced, standard tone",
    "formal": "Use formal, professional language appropriate for business or academic contexts",
    "casual": "Use relaxed, conversational language",
    "academic": "Use scholarly language with precise terminology"
}

# Default language
DEFAULT_LANGUAGE = "nl"


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
