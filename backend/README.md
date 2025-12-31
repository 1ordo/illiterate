# Grammar Check Backend

FastAPI backend for the multilingual grammar checking system.

## Features

- Two-stage grammar pipeline (LanguageTool + LLM)
- Validation loop to prevent LLM hallucinations
- Multi-language support (Dutch, English, German, French, Spanish)
- Automatic fallback to rule-based correction
- Rewrite suggestions with tone selection
- Detailed explanations for corrections

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment

Create a `.env` file:

```env
GRAMMAR_DEBUG=true
GRAMMAR_LANGUAGETOOL_URL=http://localhost:8081/v2
GRAMMAR_LLM_URL=http://192.168.1.77:1234/v1/chat/completions
GRAMMAR_LLM_MODEL=local-model
```

### 3. Start LanguageTool

```bash
cd ../languagetool
docker-compose up -d
```

### 4. Run the Backend

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### POST /check

Check text for grammar issues.

**Request:**
```json
{
  "text": "Ik heb de boek gelezen.",
  "language": "nl",
  "mode": "style",
  "tone": "formal",
  "include_explanations": true
}
```

**Response:**
```json
{
  "original_text": "Ik heb de boek gelezen.",
  "corrected_text": "Ik heb het boek gelezen.",
  "issues": [
    {
      "offset": 8,
      "length": 2,
      "message": "Use 'het' instead of 'de' with 'boek'",
      "rule_id": "DE_HET",
      "category": "grammar",
      "severity": "error",
      "original_text": "de",
      "suggestions": ["het"]
    }
  ],
  "rewrites": [
    {
      "text": "Ik heb het boek gelezen.",
      "tone": "formal",
      "score": 9.0
    }
  ],
  "explanations": [
    {
      "span": "de boek",
      "original": "de",
      "corrected": "het",
      "reason": "'Boek' is een het-woord in het Nederlands."
    }
  ],
  "validation_passed": true,
  "fallback_used": false,
  "language": "nl",
  "issue_count": 1
}
```

### GET /languages

Get supported languages.

### GET /health

Check service health.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        API Layer                             │
│                    (FastAPI endpoints)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Pipeline Orchestrator                     │
│                    (services/pipeline.py)                    │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│   LanguageTool   │ │    LLM       │ │    Validator     │
│    Service       │ │   Service    │ │    Service       │
│  (Stage 1)       │ │  (Stage 2)   │ │   (Stage 3)      │
└──────────────────┘ └──────────────┘ └──────────────────┘
         │                   │                  │
         ▼                   ▼                  ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐
│  LanguageTool    │ │  Local LLM   │ │  LanguageTool    │
│  HTTP API        │ │  (OpenAI)    │ │  (Re-check)      │
└──────────────────┘ └──────────────┘ └──────────────────┘
```

## Pipeline Flow

1. **Stage 1: LanguageTool Analysis**
   - Send text to LanguageTool API
   - Extract grammar, spelling, style issues
   - This is the ground truth for errors

2. **Stage 2: LLM Correction**
   - Build language-aware prompt with detected issues
   - Call LLM for semantic correction
   - Generate rewrite suggestions
   - LLM must NOT invent new errors

3. **Stage 3: Validation**
   - Re-run LanguageTool on LLM output
   - If new errors detected: reject LLM output
   - Fall back to rule-based correction

## Configuration

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `GRAMMAR_LANGUAGETOOL_URL` | `http://localhost:8081/v2` | LanguageTool API URL |
| `GRAMMAR_LLM_URL` | `http://192.168.1.77:1234/v1/chat/completions` | LLM API URL |
| `GRAMMAR_LLM_MODEL` | `local-model` | LLM model name |
| `GRAMMAR_LLM_TEMPERATURE` | `0.1` | LLM temperature (low for determinism) |
| `GRAMMAR_MAX_TEXT_LENGTH` | `10000` | Maximum text length |
| `GRAMMAR_CACHE_TTL` | `300` | Cache TTL in seconds |

## Docker

Build and run:

```bash
docker build -t grammar-backend .
docker run -p 8000:8000 grammar-backend
```

## Testing

```bash
pytest tests/ -v
```

## Dutch Test Cases

```python
# de/het article error
"Ik heb de boek gelezen."  # → het boek

# Verb conjugation
"Hij loop naar huis."  # → loopt

# Word order
"Ik wil dat je komt morgen."  # → morgen komt
```
