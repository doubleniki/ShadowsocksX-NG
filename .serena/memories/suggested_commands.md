## Common Commands
- `pod install`: install/update CocoaPods dependencies before opening the workspace (`ShadowsocksX-NG.xcworkspace`).
- `make -C deps` (or `make deps/dist` via the default targets): builds universal binaries for ss-local, privoxy, and bundled SIP003 plugins; run once per toolchain update.
- `make debug` / `make release`: builds the macOS app via xcodebuild for the chosen configuration; artifacts land in `build/Debug` or `build/Release`.
- `make debug-dmg` / `make release-dmg`: package the corresponding `.app` into a DMG (uses existing `build/<Config>/ShadowsocksX-NG.app`).
- `xcodebuild test -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -destination 'platform=macOS' [-enableCodeCoverage YES]`: run the XCTest suite locally (coverage optional).
- `swiftlint lint --strict`: run SwiftLint locally using the repo's `.swiftlint[-strict].yml` configs (CI runs it automatically; run manually before PRs when touching Swift code).
- `agvtool new-marketing-version <version>` (via `make VERSION=...`): bump the marketing version in Info.plist during releases.