## Before Submitting Changes
1. **Sync & Branching**: Rebase or merge latest `develop`, keep work on a feature/hotfix branch following GitFlow naming (e.g., `feature/<topic>`).
2. **Build**: Run `pod install` (if pods changed), then `make debug` to ensure the workspace compiles with bundled dependencies.
3. **Static Analysis**: Execute `swiftlint lint --strict` (or the Xcode build phase) and resolve warnings/errors; no `NSLog`/`print`, force unwraps, or empty catches should remain.
4. **Tests**: Execute `xcodebuild test -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -destination 'platform=macOS'` (add `-enableCodeCoverage YES` when touching core logic) and ensure all XCTest targets pass.
5. **Artifacts (if needed)**: For release validation, run `make release` and optionally `make release-dmg` to confirm packaging.
6. **PR Prep**: Squash/fixup commits into logical units with conventional prefixes (`feat:`, `fix:`, etc.), update docs or screenshots when UI changes, and describe changes + testing evidence + linked issues in the PR template.