<div align="center">

<img src="assets/ileterate-logo-only.png" alt="ileterate Logo" width="200" height="200">

# ileterate

### AI-Powered Multilingual Grammar Checker & Rewriter

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Flutter 3.2+](https://img.shields.io/badge/flutter-3.2+-blue.svg)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://www.docker.com/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

*A production-ready, local-first grammar checking and intelligent rewriting system powered by a validated AI pipeline.*

[Features](#-features) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [API](#-api-reference) • [Security](#-security) • [Contributing](CONTRIBUTING.md)

</div>

---

## 📖 Overview

**ileterate** is a comprehensive grammar checking system that combines rule-based analysis with AI-powered corrections. It uses a unique two-stage pipeline with validation to ensure high-quality, hallucination-free corrections.

### Why ileterate?

- **🔒 Privacy-First**: Run entirely on your own infrastructure
- **🎯 Validated AI**: Unique validation loop prevents LLM hallucinations
- **🌍 Multilingual**: Full support for Dutch, English, German, French, and Spanish
- **📱 Cross-Platform**: Native apps for iOS, Android, Web, and Desktop
- **🔐 Secure**: API key authentication and optional E2E encryption
- **🐳 Docker-Ready**: Single command deployment

---

## ✨ Features

### Grammar Checking
- **Rule-Based Detection**: Powered by LanguageTool for accurate error detection
- **AI Corrections**: LLM-powered semantic understanding for natural fixes
- **Validation Loop**: Automatic verification prevents AI-introduced errors

### Rewriting
- **Multiple Tones**: Neutral, Formal, Casual, Academic
- **Style Suggestions**: Improve clarity and readability
- **Detailed Explanations**: Learn why corrections are made

### Security
- **API Key Authentication**: Secure your API endpoints
- **End-to-End Encryption**: RSA + AES hybrid encryption
- **Rate Limiting**: Protect against abuse

### Developer Experience
- **RESTful API**: OpenAPI/Swagger documentation
- **Docker Compose**: One-command deployment
- **CI/CD Ready**: GitHub Actions workflows included

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                               │
│              (iOS, Android, Web, Desktop)                    │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ API Service │──│ Encryption  │──│ Secure Storage      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS + API Key + E2E Encryption
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  FastAPI Gateway                       │  │
│  │                  (Port 8000)                           │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐ │  │
│  │  │   Auth   │  │ Encrypt  │  │ Grammar Pipeline     │ │  │
│  │  │Middleware│  │Middleware│  │  1. LanguageTool     │ │  │
│  │  └──────────┘  └──────────┘  │  2. LLM Correction   │ │  │
│  │                              │  3. Validation       │ │  │
│  │                              └──────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                              │                               │
│              ┌───────────────┴───────────────┐              │
│              ▼                               ▼              │
│  ┌──────────────────────────┐  ┌──────────────────────────┐ │
│  │      LanguageTool        │  │      External LLM        │ │
│  │    (Internal Network)    │  │   (OpenAI Compatible)    │ │
│  └──────────────────────────┘  └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### The Validation Pipeline

```
1. User Input → LanguageTool detects N issues
2. LLM generates correction based on detected issues
3. LanguageTool validates LLM output
4. If new issues detected → Reject LLM output, use rule-based fix
5. Return validated correction with confidence flag
```

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- (Optional) An OpenAI-compatible LLM endpoint

### 1. Clone & Configure

```bash
git clone https://github.com/1ordo/ileterate.git
cd ileterate

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# At minimum, set LLM_URL and LLM_MODEL
```

### 2. Start Services

```bash
# Development (no authentication)
docker-compose up -d

# Production (with authentication)
./scripts/generate-api-key.sh  # Note the generated key
# Add API_KEY to .env
docker-compose -f docker-compose.prod.yml up -d
```

### 3. Verify Installation

```bash
# Check health
curl http://localhost:8000/health

# Test grammar check (add -H "X-API-Key: YOUR_KEY" if auth enabled)
curl -X POST http://localhost:8000/check \
  -H "Content-Type: application/json" \
  -d '{
    "text": "I has been working here.",
    "language": "en",
    "mode": "style"
  }'
```

### 4. Run Flutter App

```bash
cd flutter_app
flutter pub get
flutter run

# With custom configuration
flutter run --dart-define=API_BASE_URL=http://your-server:8000 \
            --dart-define=API_KEY=your-api-key
```

---

## 📚 API Reference

### Authentication

If `API_KEY` is configured, include the header in all requests:

```
X-API-Key: your-api-key-here
```

### Endpoints

#### Check Grammar
```http
POST /check
Content-Type: application/json
```

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
      "message": "Use 'het' instead of 'de' for neuter nouns",
      "offset": 7,
      "length": 2,
      "category": "GRAMMAR",
      "severity": "ERROR",
      "suggestions": ["het"]
    }
  ],
  "rewrites": [
    {
      "text": "Ik heb het boek gelezen.",
      "tone": "formal",
      "changes": ["Corrected article"]
    }
  ],
  "explanations": [
    {
      "issue": "de/het confusion",
      "explanation": "In Dutch, 'boek' is a neuter noun...",
      "rule": "Dutch article agreement"
    }
  ],
  "validation_passed": true,
  "fallback_used": false
}
```

#### Get Languages
```http
GET /languages
```

#### Health Check
```http
GET /health
```

#### Get Public Key (for E2E encryption)
```http
GET /security/public-key
```

### Supported Languages

| Code | Language | Native Name |
|------|----------|-------------|
| `nl` | Dutch | Nederlands |
| `en` | English | English |
| `de` | German | Deutsch |
| `fr` | French | Français |
| `es` | Spanish | Español |

### Check Modes

| Mode | Description |
|------|-------------|
| `strict` | Grammar and spelling corrections only |
| `style` | Includes rewrite suggestions and style improvements |

### Tones (for rewrites)

| Tone | Description |
|------|-------------|
| `neutral` | Balanced, standard tone |
| `formal` | Professional, business-appropriate |
| `casual` | Relaxed, conversational |
| `academic` | Scholarly, precise terminology |

---

## 🔐 Security

### API Key Authentication

1. Generate an API key:
   ```bash
   ./scripts/generate-api-key.sh
   ```

2. Add to `.env`:
   ```env
   API_KEY=your-generated-key
   ```

3. Include in requests:
   ```bash
   curl -H "X-API-Key: your-key" http://localhost:8000/check
   ```

### End-to-End Encryption

For sensitive data, enable E2E encryption:

1. Generate RSA keys:
   ```bash
   ./scripts/generate-keys.sh
   ```

2. Enable in `.env`:
   ```env
   ENCRYPTION_ENABLED=true
   ```

3. Client fetches public key and encrypts requests:
   ```http
   GET /security/public-key
   ```

### Production Recommendations

- [ ] Always use HTTPS in production
- [ ] Set a strong `API_KEY`
- [ ] Restrict `CORS_ORIGINS` to your domains
- [ ] Enable encryption for sensitive data
- [ ] Use `docker-compose.prod.yml` for production
- [ ] Set `DEBUG=false` and `LOG_LEVEL=WARNING`
- [ ] Configure rate limiting

---

## 🛠️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `API_PORT` | `8000` | API server port |
| `DEBUG` | `false` | Enable debug mode and /docs |
| `LOG_LEVEL` | `INFO` | Logging level |
| `LLM_URL` | - | LLM API endpoint (required) |
| `LLM_MODEL` | `gpt-4` | Model name |
| `LLM_API_KEY` | - | LLM provider API key |
| `API_KEY` | - | API authentication key |
| `ENCRYPTION_ENABLED` | `false` | Enable E2E encryption |
| `CORS_ORIGINS` | `["*"]` | Allowed CORS origins |
| `MAX_TEXT_LENGTH` | `10000` | Max input characters |
| `CACHE_TTL` | `300` | Cache duration (seconds) |

See [.env.example](.env.example) for all options.

### Flutter Configuration

Configure via compile-time defines:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=API_KEY=your-key \
  --dart-define=ENCRYPTION_ENABLED=true
```

Or for release builds:

```bash
flutter build apk \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=API_KEY=your-key
```

---

## 📁 Project Structure

```
ileterate/
├── backend/                    # FastAPI Backend
│   ├── app/
│   │   ├── main.py            # Application entry
│   │   ├── config.py          # Configuration
│   │   ├── middleware/        # Auth & encryption
│   │   ├── models/            # Pydantic models
│   │   ├── services/          # Business logic
│   │   └── utils/             # Utilities
│   ├── Dockerfile             # Development image
│   ├── Dockerfile.prod        # Production image
│   └── requirements.txt
│
├── flutter_app/               # Flutter Frontend
│   ├── lib/
│   │   ├── core/             # Config, services
│   │   ├── data/             # Models, API
│   │   └── presentation/     # UI components
│   └── pubspec.yaml
│
├── languagetool/             # LanguageTool Setup
│   └── docker-compose.yml    # Standalone config
│
├── scripts/                  # Utility scripts
│   ├── generate-keys.sh     # RSA key generation
│   └── generate-api-key.sh  # API key generation
│
├── docker-compose.yml        # Development setup
├── docker-compose.prod.yml   # Production setup
├── .env.example              # Environment template
└── README.md
```

---

## 🧪 Development

### Running Tests

```bash
# Backend tests
cd backend
pip install -r requirements.txt
pytest tests/ -v --cov=app

# Flutter tests
cd flutter_app
flutter test
```

### Local Development

```bash
# Start LanguageTool only
cd languagetool
docker-compose up -d

# Run backend locally
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Run Flutter
cd flutter_app
flutter run
```

### Building for Production

```bash
# Backend Docker image
docker build -f backend/Dockerfile.prod -t ileterate-api ./backend

# Flutter Web
cd flutter_app
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.example.com

# Flutter Android
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com

# Flutter iOS
flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for:

- Setting up your development environment
- Code style guidelines
- How to submit pull requests
- Reporting bugs and suggesting features

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

This project uses the following open-source components:

- **[LanguageTool](https://languagetool.org/)** - LGPL 2.1
- **[FastAPI](https://fastapi.tiangolo.com/)** - MIT
- **[Flutter](https://flutter.dev/)** - BSD 3-Clause

---

## 🙏 Acknowledgments

- [LanguageTool](https://languagetool.org/) for the excellent rule-based grammar checking
- [FastAPI](https://fastapi.tiangolo.com/) for the modern Python web framework
- [Flutter](https://flutter.dev/) for the cross-platform UI toolkit
- All our [contributors](https://github.com/1ordo/ileterate/graphs/contributors)

---

## 📧 Contact & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/1ordo/ileterate/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/1ordo/ileterate/discussions)
- **Author**: [@1ordo](https://github.com/1ordo)

---

<div align="center">

**[⭐ Star this repo](https://github.com/1ordo/ileterate)** if you find it useful!

Made with ❤️ by the ileterate team

</div>
