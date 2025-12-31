"""
Grammar Checking API - FastAPI Application.

A production-ready, multilingual grammar checking and rewriting system
using LanguageTool (rule-based) and local LLM (semantic correction).

Author: Grammar Check System
Version: 1.0.0
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, status
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

# Configure logging
logging.basicConfig(
    level=logging.INFO,
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
    logger.info("Starting Grammar Check API...")
    pipeline = GrammarPipeline()

    # Check services
    status = await pipeline.check_services()
    logger.info(f"Service status: {status}")

    if not status["languagetool"]:
        logger.warning(
            "LanguageTool is not available! "
            "Make sure it's running on the configured URL."
        )

    if not status["llm"]:
        logger.warning(
            "LLM is not available! "
            "Will use rule-based fallback for corrections."
        )

    yield

    # Shutdown
    logger.info("Shutting down Grammar Check API...")
    get_cache().clear()


# Create FastAPI app
settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description="""
## Multilingual Grammar Checking API

A two-stage grammar correction pipeline:
1. **LanguageTool** - Rule-based grammar, spelling, and style detection
2. **LLM** - Semantic correction and rewrite suggestions

### Features
- Multi-language support (Dutch, English, German, French, Spanish)
- Validation loop to prevent LLM hallucinations
- Automatic fallback to rule-based correction
- Rewrite suggestions with different tones
- Detailed explanations for corrections

### Default Language
The default language is **Dutch (nl)**.
    """,
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ===================== ENDPOINTS =====================


@app.get("/", tags=["Info"])
async def root():
    """Root endpoint with API info."""
    return {
        "name": settings.app_name,
        "version": "1.0.0",
        "description": "Multilingual Grammar Checking API",
        "endpoints": {
            "check": "/check",
            "languages": "/languages",
            "health": "/health"
        }
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
async def check_grammar(request: CheckRequest) -> CheckResponse:
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
async def get_languages() -> list[LanguageInfo]:
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
async def get_language(code: str) -> LanguageInfo:
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
    """Check health of all services."""
    service_status = await pipeline.check_services()

    return HealthResponse(
        status="healthy" if service_status["languagetool"] else "degraded",
        languagetool_available=service_status["languagetool"],
        llm_available=service_status["llm"],
        version="1.0.0"
    )


@app.get(
    "/cache/stats",
    tags=["System"],
    summary="Cache statistics"
)
async def cache_stats():
    """Get cache statistics."""
    return get_cache().get_stats()


@app.post(
    "/cache/clear",
    tags=["System"],
    summary="Clear cache"
)
async def clear_cache():
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
        reload=True
    )
