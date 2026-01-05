"""
ileterate Grammar API - FastAPI Application.

A production-ready, multilingual grammar checking and rewriting system
using LanguageTool (rule-based) and LLM (semantic correction).

Author: ileterate Team
Version: 1.0.0
License: MIT
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from .config import get_settings, SUPPORTED_LANGUAGES, DEFAULT_LANGUAGE
from .models import CheckRequest, CheckMode, Tone
from .models.response import (
    CheckResponse,
    LanguageInfo,
    HealthResponse
)
from .services.pipeline import GrammarPipeline
from .utils.cache import get_cache
from .middleware.auth import api_key_middleware
from .middleware.encryption import encryption_service, EncryptionMiddleware

# Configure logging
settings = get_settings()
logging.basicConfig(
    level=getattr(logging, settings.log_level.upper(), logging.INFO),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global pipeline instance
pipeline: GrammarPipeline = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    global pipeline

    # Startup
    logger.info("Starting ileterate Grammar API...")
    logger.info(f"Version: {settings.app_version}")
    logger.info(f"Debug mode: {settings.debug}")

    # Initialize encryption if enabled
    if settings.encryption_enabled:
        if encryption_service.initialize(
            private_key_path=settings.rsa_private_key_path,
            public_key_path=settings.rsa_public_key_path
        ):
            logger.info("Encryption service initialized")
        else:
            logger.warning("Encryption enabled but failed to initialize")

    # Log security status
    if settings.api_key:
        logger.info("API key authentication: ENABLED")
    else:
        logger.warning("API key authentication: DISABLED (set GRAMMAR_API_KEY to enable)")

    # Initialize pipeline
    pipeline = GrammarPipeline()

    # Check services
    service_status = await pipeline.check_services()
    logger.info(f"Service status: {service_status}")

    if not service_status["languagetool"]:
        logger.warning(
            "LanguageTool is not available! "
            "Make sure it's running on the configured URL."
        )

    if not service_status["llm"]:
        logger.warning(
            "LLM is not available! "
            "Will use rule-based fallback for corrections."
        )

    yield

    # Shutdown
    logger.info("Shutting down ileterate Grammar API...")
    get_cache().clear()


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="""
## ileterate - Multilingual Grammar Checking API

A two-stage grammar correction pipeline:
1. **LanguageTool** - Rule-based grammar, spelling, and style detection
2. **LLM** - Semantic correction and rewrite suggestions

### Features
- Multi-language support (Dutch, English, German, French, Spanish)
- Validation loop to prevent LLM hallucinations
- Automatic fallback to rule-based correction
- Rewrite suggestions with different tones
- Detailed explanations for corrections
- API key authentication (optional)
- End-to-end encryption (optional)

### Authentication
If API key is configured, include the `X-API-Key` header in all requests.

### Encryption
For E2E encryption, use `Content-Type: application/x-encrypted` for requests
and `Accept: application/x-encrypted` for responses.

### Default Language
The default language is **Dutch (nl)**.
    """,
    version=settings.app_version,
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=settings.cors_allow_methods,
    allow_headers=settings.cors_allow_headers,
)

# Add encryption middleware if enabled
if settings.encryption_enabled:
    app.add_middleware(EncryptionMiddleware)


# ===================== ENDPOINTS =====================


@app.get("/", tags=["Info"])
async def root():
    """Root endpoint with API info."""
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "description": "ileterate - Multilingual Grammar Checking API",
        "documentation": "/docs" if settings.debug else "Disabled in production",
        "endpoints": {
            "check": "/check",
            "languages": "/languages",
            "health": "/health",
            "public_key": "/security/public-key"
        },
        "authentication": "API key required" if settings.api_key else "Disabled"
    }


@app.get("/security/public-key", tags=["Security"])
async def get_public_key():
    """
    Get the server's RSA public key for encryption.

    Returns the public key in PEM format that clients can use
    to encrypt their requests.
    """
    if not settings.encryption_enabled:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Encryption not enabled"
        )

    public_key = encryption_service.get_public_key_pem()
    if not public_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Encryption service not initialized"
        )

    return {
        "public_key": public_key,
        "algorithm": "RSA-OAEP-SHA256",
        "key_encryption": "AES-256-GCM",
        "version": "1.0"
    }


@app.post(
    "/check",
    response_model=CheckResponse,
    tags=["Grammar"],
    summary="Check text for grammar issues",
    description="""
Analyze text for grammar, spelling, and style issues.

The pipeline:
1. Sends text to LanguageTool for rule-based detection
2. Uses LLM to apply corrections semantically
3. Validates LLM output to prevent hallucinations
4. Falls back to rule-based fixes if validation fails

**Modes:**
- `strict`: Only fix grammar/spelling errors
- `style`: Include rewrite suggestions

**Tones (for rewrites):**
- `neutral`: Balanced, standard tone
- `formal`: Professional, business-appropriate
- `casual`: Relaxed, conversational
- `academic`: Scholarly, precise
    """
)
async def check_grammar(
    request: CheckRequest,
    _api_key: str = Depends(api_key_middleware)
) -> CheckResponse:
    """
    Check text for grammar issues and get corrections.

    Args:
        request: CheckRequest with text, language, mode, and tone

    Returns:
        CheckResponse with corrections, issues, rewrites, and explanations
    """
    # Validate language
    if request.language not in SUPPORTED_LANGUAGES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported language: {request.language}. "
                   f"Supported: {list(SUPPORTED_LANGUAGES.keys())}"
        )

    # Validate text length
    if len(request.text) > settings.max_text_length:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Text too long. Maximum: {settings.max_text_length} characters"
        )

    try:
        result = await pipeline.process(request)
        return result

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing request: {str(e)}"
        )


@app.get(
    "/languages",
    response_model=list[LanguageInfo],
    tags=["Languages"],
    summary="Get supported languages"
)
async def get_languages(
    _api_key: str = Depends(api_key_middleware)
) -> list[LanguageInfo]:
    """Get list of supported languages with examples."""
    languages = []
    for code, config in SUPPORTED_LANGUAGES.items():
        languages.append(LanguageInfo(
            code=config["code"],
            name=config["name"],
            native_name=config["native_name"],
            examples=config.get("examples", [])
        ))
    return languages


@app.get(
    "/languages/{code}",
    response_model=LanguageInfo,
    tags=["Languages"],
    summary="Get info for a specific language"
)
async def get_language(
    code: str,
    _api_key: str = Depends(api_key_middleware)
) -> LanguageInfo:
    """Get information about a specific language."""
    if code not in SUPPORTED_LANGUAGES:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Language not found: {code}"
        )

    config = SUPPORTED_LANGUAGES[code]
    return LanguageInfo(
        code=config["code"],
        name=config["name"],
        native_name=config["native_name"],
        examples=config.get("examples", [])
    )


@app.get(
    "/health",
    response_model=HealthResponse,
    tags=["System"],
    summary="Health check"
)
async def health_check() -> HealthResponse:
    """
    Check health of all services.

    This endpoint does not require authentication.
    """
    service_status = await pipeline.check_services()

    return HealthResponse(
        status="healthy" if service_status["languagetool"] else "degraded",
        languagetool_available=service_status["languagetool"],
        llm_available=service_status["llm"],
        version=settings.app_version
    )


@app.get(
    "/cache/stats",
    tags=["System"],
    summary="Cache statistics"
)
async def cache_stats(_api_key: str = Depends(api_key_middleware)):
    """Get cache statistics."""
    return get_cache().get_stats()


@app.post(
    "/cache/clear",
    tags=["System"],
    summary="Clear cache"
)
async def clear_cache(_api_key: str = Depends(api_key_middleware)):
    """Clear the grammar check cache."""
    get_cache().clear()
    return {"status": "cleared"}


# ===================== ERROR HANDLERS =====================


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler."""
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


# ===================== ENTRY POINT =====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug
    )
