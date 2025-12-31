<div align="center">

# ✍️ ileterate

### AI-Powered Multilingual Grammar Checker & Rewriter

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Flutter](https://img.shields.io/badge/flutter-3.2.0+-blue.svg)](https://flutter.dev/)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-❤️-red.svg)](https://github.com/1ordo/ileterate)

*A production-ready, local-first grammar checking and intelligent rewriting system powered by a validated AI pipeline.*

[Features](#-features) • [Quick Start](#-quick-start) • [Architecture](#-architecture) • [Contributing](CONTRIBUTING.md) • [License](#-license)

</div>

---

## Overview

This system uses a two-stage pipeline to provide high-quality grammar corrections:

1. **LanguageTool (Stage 1)**: Rule-based grammar, spelling, and style detection
2. **Local LLM (Stage 2)**: Semantic correction and rewrite generation
3. **Validation Loop (Stage 3)**: Prevents LLM hallucinations

## ✨ Features

- **Multi-language support**: Dutch (primary), English, German, French, Spanish
- **Two check modes**:
  - **Strict**: Grammar and spelling fixes only
  - **Style**: Includes rewrite suggestions with tone selection
- **Validation**: LLM output is re-checked to prevent new errors
- **Fallback**: Automatic fallback to rule-based correction if LLM fails
- **Cross-platform**: iOS, Android, Web, macOS, Windows, Linux

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                               │
│              (iOS, Android, Web, Desktop)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                           │
│                    (Port 8000)                               │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│      LanguageTool        │    │        Local LLM         │
│       (Port 8081)        │    │   (192.168.1.77:1234)    │
│     Docker Container     │    │    OpenAI-compatible     │
└──────────────────────────┘    └──────────────────────────┘
```

## 🚀 Quick Start

### 1. Start LanguageTool

```bash
cd languagetool
docker-compose up -d
```

Verify: `curl http://localhost:8081/v2/languages`

### 2. Start Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verify: `curl http://localhost:8000/health`

### 3. Run Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

## Directory Structure

```
lang_app/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── main.py         # API endpoints
│   │   ├── config.py       # Configuration
│   │   ├── models/         # Request/Response models
│   │   ├── services/       # Business logic
│   │   ├── prompts/        # LLM prompts
│   │   └── utils/          # Utilities
│   ├── tests/              # Test cases
│   ├── requirements.txt
│   └── Dockerfile
│
├── languagetool/           # LanguageTool setup
│   ├── docker-compose.yml
│   └── README.md
│
├── flutter_app/            # Flutter application
│   ├── lib/
│   │   ├── core/          # Config, theme, constants
│   │   ├── data/          # Models, services
│   │   ├── presentation/  # Providers, screens, widgets
│   │   └── utils/         # Utilities
│   └── pubspec.yaml
│
└── README.md               # This file
```

## 🔧 Configuration

### Backend (.env)

```env
GRAMMAR_LANGUAGETOOL_URL=http://localhost:8081/v2
GRAMMAR_LLM_URL=http://192.168.1.77:1234/v1/chat/completions
GRAMMAR_LLM_MODEL=local-model
```

### Flutter (lib/core/config/app_config.dart)

```dart
static const String apiBaseUrl = 'http://localhost:8000';
```

## API Usage

### Check Grammar

```bash
curl -X POST http://localhost:8000/check \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Ik heb de boek gelezen.",
    "language": "nl",
    "mode": "style",
    "tone": "formal"
  }'
```

### Response

```json
{
  "original_text": "Ik heb de boek gelezen.",
  "corrected_text": "Ik heb het boek gelezen.",
  "issues": [...],
  "rewrites": [...],
  "explanations": [...],
  "validation_passed": true,
  "fallback_used": false
}
```

## Dutch Test Cases

| Input | Error | Correction |
|-------|-------|------------|
| "Ik heb de boek gelezen." | de/het | het boek |
| "Hij loop naar huis." | verb conjugation | loopt |
| "Ik wil dat je komt morgen." | word order | morgen komt |
| "Wij gaat naar de winkel." | subject-verb agreement | gaan |

## LLM Prompt Strategy

The LLM prompt is designed to:

1. **Be language-aware**: Adapts to the selected language
2. **Be deterministic**: Low temperature (0.1) for consistent output
3. **Prevent hallucination**: Explicitly forbids inventing errors
4. **Return strict JSON**: Required output format

Example prompt structure:
```
You are a precise grammar correction assistant for Dutch.
You MUST fix ONLY the following detected issues:
[list of LanguageTool issues]

RULES:
1. Apply ONLY the fixes listed above
2. NEVER invent new errors
3. Preserve original meaning exactly
4. Return STRICT JSON only
```

## Validation Loop

The validation loop is critical for preventing LLM hallucinations:

```
1. LanguageTool checks original text → finds N issues
2. LLM generates corrected text
3. LanguageTool checks corrected text → finds M issues
4. If M > 0 (new issues):
   - Reject LLM output
   - Use rule-based correction instead
   - Set fallback_used = true
5. Return validated result
```

## Supported Languages

| Code | Language | Native Name |
|------|----------|-------------|
| nl | Dutch | Nederlands |
| en | English | English |
| de | German | Deutsch |
| fr | French | Français |
| es | Spanish | Español |

## Development

### Running Tests

```bash
# Backend
cd backend
pytest tests/ -v

# Flutter
cd flutter_app
flutter test
```

### Building for Production

```bash
# Backend Docker
docker build -t grammar-backend ./backend

# Flutter Web
flutter build web --release

# Flutter iOS
flutter build ios --release
```

## 🐛 Troubleshooting

### LanguageTool not starting
```bash
docker-compose logs languagetool
```

### LLM not responding
Check that the LLM server is running at the configured URL.

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on:

- Setting up your development environment
- Code style guidelines
- How to submit pull requests
- Reporting bugs and suggesting features

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [LanguageTool](https://languagetool.org/) for rule-based grammar checking
- [Flutter](https://flutter.dev/) for cross-platform UI framework
- [FastAPI](https://fastapi.tiangolo.com/) for the backend framework

## 📧 Contact

**GitHub**: [@1ordo](https://github.com/1ordo)

---

<div align="center">

Made with ❤️ by the ileterate team

**[⭐ Star this repo](https://github.com/1ordo/ileterate)** if you find it useful!

</div>

### Flutter can't connect to backend
- For web: Ensure CORS is enabled
- For mobile: Use machine IP, not localhost

## License

MIT License

## Credits

- [LanguageTool](https://languagetool.org/) - Open source grammar checker
- [Flutter](https://flutter.dev/) - UI framework
- [FastAPI](https://fastapi.tiangolo.com/) - Python web framework
- [Riverpod](https://riverpod.dev/) - State management
