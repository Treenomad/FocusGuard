# Contributing to FocusGuard

## Development Setup

### Prerequisites
- macOS 12.0+
- Xcode 14.0+
- XcodeGen (`brew install xcodegen`)

### Build Steps

```bash
# Clone repo
git clone https://github.com/Treenomad/FocusGuard.git
cd FocusGuard

# Generate Xcode project
xcodegen generate

# Open in Xcode
open FocusGuard.xcodeproj
```

### Architecture
- MVVM pattern
- SwiftUI for UI
- SQLite.swift for local storage

## Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for formatting
- 2-space indentation

## Testing
- Unit tests required for new features
- Run tests before submitting PR

## Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit PR with description
5. Wait for review
