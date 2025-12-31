# Grammar Checker Flutter App

Cross-platform Flutter application for grammar checking and text rewriting.

## Features

- Multi-language support (Dutch, English, German, French, Spanish)
- Real-time grammar error highlighting
- Animated squiggly underlines for errors
- Text diff view for corrections
- Rewrite suggestions with tone selection
- Dark/light theme support
- Works on iOS, Android, Web, macOS, Windows, Linux

## Screenshots

The app includes:
- Grammar editor with error highlighting
- Issue list with suggestions
- Rewrite carousel with tone badges
- Text diff visualization
- Settings screen with backend status

## Quick Start

### Prerequisites

- Flutter SDK 3.2.0+
- Running backend server
- Running LanguageTool server

### 1. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure API Endpoint

Edit `lib/core/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:8000';
```

For mobile devices, use your machine's IP:
```dart
static const String apiBaseUrl = 'http://192.168.1.xxx:8000';
```

### 3. Run the App

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome

# macOS
flutter run -d macos
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # App widget with theming
├── core/
│   ├── config/            # App and language configuration
│   ├── theme/             # Theme definitions
│   └── constants/         # API constants, enums
├── data/
│   ├── models/            # Data models (JSON serialization)
│   ├── repositories/      # Data access layer
│   └── services/          # API service
├── domain/
│   └── entities/          # Business entities
├── presentation/
│   ├── providers/         # Riverpod state management
│   ├── screens/           # App screens
│   └── widgets/           # UI components
└── utils/                 # Utility functions
```

## Architecture

The app follows clean architecture principles:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│              (Screens, Widgets, Providers)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│                    (Entities, Logic)                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│              (Models, Repositories, Services)                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Backend API                              │
│                  (FastAPI Server)                            │
└─────────────────────────────────────────────────────────────┘
```

## State Management

The app uses Riverpod for state management:

- `grammarProvider` - Main grammar check state
- `settingsProvider` - App settings (language, mode, theme)
- `backendHealthProvider` - Backend connection status

## Key Components

### GrammarTextField
Rich text editor with custom painter for error underlines.

### IssueCard
Displays a single grammar issue with suggestions.

### RewriteCarousel
Horizontally scrollable list of rewrite suggestions.

### TextDiffView
Shows text differences using diff_match_patch algorithm.

### ConfidenceIndicator
Visual score indicator (0-10) for suggestions.

## Customization

### Adding a New Language

1. Add to `lib/core/config/language_config.dart`:
```dart
const LanguageConfig(
  code: 'pt',
  name: 'Portuguese',
  nativeName: 'Português',
  flag: '🇵🇹',
),
```

2. Add to backend `config.py`:
```python
"pt": {
    "code": "pt",
    "name": "Portuguese",
    ...
}
```

### Changing Theme Colors

Edit `lib/core/theme/app_theme.dart`.

## Platform Notes

### iOS
- Requires Xcode 15+
- Add network permissions in `Info.plist` for local server

### Android
- Requires API 21+ (Android 5.0)
- Add network permission for local server:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Web
- CORS must be configured on backend
- Works best in Chrome/Edge

### Desktop
- macOS: Requires enabling network client in entitlements
- Windows/Linux: Works out of the box

## Building for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# macOS
flutter build macos --release
```

## Dependencies

- `flutter_riverpod` - State management
- `dio` - HTTP client
- `shimmer` - Loading animations
- `diff_match_patch` - Text diff algorithm
- `flutter_animate` - Animations

## Troubleshooting

### Cannot connect to backend
1. Check if backend is running: `curl http://localhost:8000/health`
2. For mobile, use machine's IP instead of localhost
3. Ensure CORS is enabled on backend

### Shimmer effect not showing
Make sure `shimmer` package is installed:
```bash
flutter pub get
```

### Text not highlighting
Check that the backend returns issues with correct offset/length.
