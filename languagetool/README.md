# LanguageTool Setup

Local LanguageTool server for grammar checking.

## Quick Start

```bash
# Start LanguageTool
docker-compose up -d

# Check if running
curl http://localhost:8081/v2/languages

# Test grammar check
curl -X POST http://localhost:8081/v2/check \
  -d "text=Ik heb de boek gelezen." \
  -d "language=nl"
```

## API Endpoint

- **URL**: `http://localhost:8081/v2`
- **Check endpoint**: `POST /v2/check`
- **Languages**: `GET /v2/languages`

## Request Format

```bash
curl -X POST http://localhost:8081/v2/check \
  -d "text=Your text here" \
  -d "language=nl" \
  -d "enabledOnly=false"
```

## Response Format

```json
{
  "matches": [
    {
      "message": "Use 'het' instead of 'de'",
      "offset": 8,
      "length": 2,
      "replacements": [{"value": "het"}],
      "rule": {
        "id": "DE_HET",
        "category": {"id": "GRAMMAR"}
      }
    }
  ]
}
```

## Supported Languages

| Code | Language |
|------|----------|
| nl | Dutch |
| en-US | English (US) |
| en-GB | English (UK) |
| de-DE | German |
| fr | French |
| es | Spanish |

## Improving Detection (Optional)

For better detection, download n-gram data:

1. Download from: https://languagetool.org/download/ngram-data/
2. Extract to `./ngrams/` directory
3. Restart the container

```bash
# Example for Dutch
wget https://languagetool.org/download/ngram-data/ngrams-nl-20150913.zip
unzip ngrams-nl-20150913.zip -d ./ngrams/
```

## Memory Settings

Adjust in `docker-compose.yml`:

```yaml
environment:
  - Java_Xms=512m   # Initial heap
  - Java_Xmx=2g     # Maximum heap
```

## Troubleshooting

### Container won't start
```bash
docker-compose logs languagetool
```

### High memory usage
Reduce `Java_Xmx` in docker-compose.yml

### Slow responses
- Increase memory allocation
- Add n-gram data for better caching

## Integration with Backend

The backend expects LanguageTool at:
```
http://localhost:8081/v2
```

Configure in backend `.env`:
```
GRAMMAR_LANGUAGETOOL_URL=http://localhost:8081/v2
```
