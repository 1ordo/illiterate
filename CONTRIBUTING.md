# Contributing to ileterate

First off, thank you for considering contributing to ileterate! It's people like you that make ileterate such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How Can I Contribute?](#how-can-i-contribute)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment (see below)
4. Create a new branch for your feature or bugfix
5. Make your changes
6. Test your changes thoroughly
7. Submit a pull request

## Development Setup

### Prerequisites

- Python 3.11+
- Flutter SDK 3.2.0+
- Docker and Docker Compose
- Git

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your configuration

# Start LanguageTool
cd ../languagetool
docker-compose up -d

# Run backend
cd ../backend
uvicorn app.main:app --reload --port 8001
```

### Flutter App Setup

```bash
cd flutter_app
flutter pub get
flutter run --device-id chrome
```

### Running Tests

**Backend:**
```bash
cd backend
pytest
```

**Flutter:**
```bash
cd flutter_app
flutter test
```

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots, etc.)
- **Describe the behavior you observed and what you expected**
- **Include your environment details** (OS, Flutter version, Python version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

### Pull Requests

- Fill in the required template
- Follow the style guidelines
- Include appropriate test coverage
- Update documentation as needed
- End all files with a newline

## Style Guidelines

### Python Code Style

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where appropriate
- Maximum line length: 100 characters
- Use meaningful variable and function names
- Write docstrings for all public functions and classes

```python
def process_text(text: str, language: str = "en") -> dict[str, Any]:
    """
    Process text through the grammar pipeline.
    
    Args:
        text: The text to process
        language: Language code (default: "en")
        
    Returns:
        Dictionary containing corrections and suggestions
    """
    # Implementation
```

### Dart/Flutter Code Style

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` before committing
- Use meaningful widget and variable names
- Extract complex widgets into separate classes
- Write widget tests for UI components

```dart
/// Displays grammar errors with animated highlighting
class ErrorHighlightWidget extends StatefulWidget {
  /// The error to display
  final GrammarError error;
  
  const ErrorHighlightWidget({
    Key? key,
    required this.error,
  }) : super(key: key);
  
  @override
  State<ErrorHighlightWidget> createState() => _ErrorHighlightWidgetState();
}
```

### Documentation

- Keep README.md files up to date
- Document all public APIs
- Add inline comments for complex logic
- Update CHANGELOG.md for notable changes

## Commit Messages

Write clear, concise commit messages that explain **what** changed and **why**:

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools

### Examples

```
feat(backend): add support for French language

Implemented French language support in the grammar pipeline
with custom prompts and validation rules.

Closes #123
```

```
fix(flutter): resolve text selection offset issue

Fixed incorrect cursor positioning when applying corrections
to multi-line text selections.

Fixes #456
```

## Pull Request Process

1. **Update Documentation**: Ensure all relevant documentation is updated
2. **Add Tests**: Include tests for new functionality
3. **Run All Tests**: Verify all tests pass before submitting
4. **Update CHANGELOG**: Add an entry to CHANGELOG.md
5. **One Feature Per PR**: Keep pull requests focused on a single feature or fix
6. **Describe Your Changes**: Provide a clear description of what your PR does
7. **Link Issues**: Reference any related issues
8. **Request Review**: Tag relevant maintainers for review
9. **Address Feedback**: Respond to review comments promptly
10. **Squash Commits**: Consider squashing commits before merging (if requested)

### PR Template

When creating a PR, use this template:

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe the tests you've added or run

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
```

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

Thank you for contributing to ileterate! 🚀
