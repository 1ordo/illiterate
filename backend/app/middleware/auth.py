"""
API Key Authentication Middleware.

Provides API key validation for securing the grammar checking API.
"""

import secrets
import logging
from typing import Optional
from fastapi import HTTPException, Security, status
from fastapi.security import APIKeyHeader

from ..config import get_settings

logger = logging.getLogger(__name__)

# API Key header configuration
API_KEY_HEADER = APIKeyHeader(
    name="X-API-Key",
    auto_error=False,
    description="API key for authentication. Required when API_KEY is configured."
)


def get_api_key_header():
    """Get the API key header security dependency."""
    return API_KEY_HEADER


async def api_key_middleware(
    api_key: Optional[str] = Security(API_KEY_HEADER)
) -> Optional[str]:
    """
    Validate the API key from request headers.

    If GRAMMAR_API_KEY is not configured, authentication is disabled.
    If configured, all requests must include a valid X-API-Key header.

    Args:
        api_key: The API key from the X-API-Key header

    Returns:
        The validated API key or None if auth is disabled

    Raises:
        HTTPException: 401 if key is missing, 403 if key is invalid
    """
    settings = get_settings()

    # If no API key is configured, authentication is disabled
    if not settings.api_key:
        logger.debug("API key authentication disabled (no key configured)")
        return None

    # API key is required but not provided
    if not api_key:
        logger.warning("Request missing API key")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key required. Include X-API-Key header.",
            headers={"WWW-Authenticate": "ApiKey"},
        )

    # Validate the API key using constant-time comparison
    if not secrets.compare_digest(api_key, settings.api_key):
        logger.warning("Invalid API key attempted")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid API key",
        )

    logger.debug("API key validated successfully")
    return api_key


def generate_api_key(length: int = 32) -> str:
    """
    Generate a secure random API key.

    Args:
        length: Length of the key in bytes (will be hex encoded, so output is 2x)

    Returns:
        A secure random hex string
    """
    return secrets.token_hex(length)


def validate_api_key_format(key: str) -> bool:
    """
    Validate that an API key has a valid format.

    Args:
        key: The API key to validate

    Returns:
        True if the key format is valid
    """
    if not key:
        return False

    # Minimum 32 characters for security
    if len(key) < 32:
        return False

    # Should be alphanumeric (hex or base64-like)
    return key.isalnum() or all(c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_' for c in key)
