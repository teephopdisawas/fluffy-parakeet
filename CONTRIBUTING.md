# Contributing to NASBox

Thank you for your interest in contributing to NASBox! This document provides guidelines and information for contributors.

## Code of Conduct

Please be respectful and constructive in all interactions. We are committed to providing a welcoming environment for everyone.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in the Issues section
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce the bug
   - Expected behavior
   - Actual behavior
   - System information (hardware, NASBox version)

### Suggesting Features

1. Check existing feature requests in Issues
2. Create a new issue with the "enhancement" label
3. Describe the feature and its use case
4. Explain why it would benefit NASBox users

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages: `git commit -m "Add: feature description"`
6. Push to your fork: `git push origin feature/my-feature`
7. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/fluffy-parakeet.git
cd fluffy-parakeet

# Install build dependencies
./scripts/install-build-deps.sh

# Start development
make dev-gui  # For GUI development
```

## Code Style

- Shell scripts: Follow Google Shell Style Guide
- Python: Follow PEP 8
- JavaScript: Use ESLint with provided configuration
- HTML/CSS: Follow consistent indentation (2 spaces)

## Testing

Run tests before submitting:

```bash
make test
make lint
```

## Documentation

- Update docs for any user-facing changes
- Add inline comments for complex logic
- Update README if needed

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
