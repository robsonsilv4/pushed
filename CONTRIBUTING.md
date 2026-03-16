# Contributing to pushed

Thank you for your interest in contributing to pushed! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/pushed.git`
3. Add upstream remote: `git remote add upstream https://github.com/robsonsilv4/pushed.git`
4. Create a feature branch: `git checkout -b feature/your-feature`

## Development Setup

```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Run analysis
flutter analyze

# Format code
dart format lib/ test/ example/lib/
```

## Making Changes

1. Make your changes in a feature branch
2. Write or update tests as needed
3. Run tests and analysis locally
4. Commit with descriptive message: `git commit -m "feat: description of changes"`

### Commit Message Format

Use conventional commits:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `refactor:` for code refactoring
- `test:` for test changes
- `chore:` for maintenance tasks

## Testing

- Write tests for new features
- Ensure all tests pass: `flutter test`
- Aim for good test coverage

## Code Style

- Follow Dart style guide
- Follow `very_good_analysis` linting rules
- Use `dart format` for formatting
- Fix analysis issues: `flutter analyze`

## Submitting Changes

1. Push to your fork: `git push origin feature/your-feature`
2. Open a Pull Request against `main` branch
3. Provide clear description of changes
4. Link related issues

## Pull Request Guidelines

- One feature per PR
- Descriptive title and description
- Reference issues: `Closes #123`
- Keep PRs focused and manageable
- All tests must pass

## Reporting Bugs

When reporting bugs, please include:

- Dart/Flutter version
- Minimal reproducible example
- Expected vs actual behavior
- Stack trace if applicable

## Feature Requests

When requesting features:

- Describe the use case
- Explain expected behavior
- Provide examples if possible

## Questions

Feel free to open discussions for questions or ideas.

---

Thank you for contributing! 🚀
