# Development Setup Guide

## Required Tools Installation

### Install Dependencies

1. **SwiftLint** - Linter for Swift code

   ```bash
   brew install swiftlint
   ```

2. **CocoaPods** - Dependency manager

   ```bash
   sudo gem install cocoapods
   ```

3. **Setup Git hooks**

   ```bash
   ./scripts/setup-git-hooks.sh
   ```

### Running Linter

The project uses SwiftLint for code quality checks. Available commands:

```bash
# Lint all project files
swiftlint

# Lint specific file
swiftlint lint --path ShadowsocksX-NG/AppDelegate.swift

# Auto-correct fixable violations
swiftlint autocorrect
```

### Xcode Configuration

1. **Warnings as Errors**: Build Settings → "Treat Warnings as Errors" → Yes (for Release)
2. **SwiftLint Build Phase**:
   - Target → Build Phases → + → New Run Script Phase
   - Script:

     ```bash
     if which swiftlint >/dev/null; then
       swiftlint
     else
       echo "warning: SwiftLint not installed"
     fi
     ```

### Coding Standards

See [SWIFT_STYLE_GUIDE.md](./SWIFT_STYLE_GUIDE.md) for detailed coding guidelines and best practices.

### Code Quality Rules

**Prohibited:**

- Force unwrapping (`!`) - except IBOutlets
- Force try (`try!`)
- Force cast (`as!`)
- Empty catch blocks
- `NSLog` (use `os.log` instead)
- `print()` in production code

**Recommended:**

- Guard statements for early returns
- Codable for serialization
- async/await for asynchronous code
- Protocol-based dependency injection
- Comprehensive error handling

### Running Tests

```bash
# All tests
xcodebuild test \
  -workspace ShadowsocksX-NG.xcworkspace \
  -scheme ShadowsocksX-NG \
  -destination 'platform=macOS'

# With code coverage
xcodebuild test \
  -workspace ShadowsocksX-NG.xcworkspace \
  -scheme ShadowsocksX-NG \
  -destination 'platform=macOS' \
  -enableCodeCoverage YES
```

### Development Workflow

1. Create feature branch from `develop`

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. Make changes and commit

   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

3. Push and create Pull Request

   ```bash
   git push origin feature/your-feature-name
   ```

### CI/CD

GitHub Actions automatically runs:

- SwiftLint checks
- Unit tests
- Build verification
- Code coverage reports

See `.github/workflows/code-quality.yml` for configuration.

## System Requirements

- **macOS**: 11.0 or later (Big Sur+)
- **Xcode**: 14.0 or later (compatible with Xcode 15+)
- **CocoaPods**: 1.10 or later

### Deployment Target

The project uses a unified deployment target across all components:

- Main app: macOS 11.0
- CocoaPods dependencies: macOS 11.0 (enforced via post_install hook)
- LaunchHelper: macOS 11.0

The Podfile includes automatic configuration to ensure all pods use the correct deployment target:

```ruby
platform :macos, '11.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
```

### Xcode Compatibility

The project includes a compatibility fix for Xcode versions < 15. The TOOLCHAIN_DIR variable is automatically patched to fall back to DT_TOOLCHAIN_DIR when not available, ensuring builds work on both older and newer Xcode versions.
