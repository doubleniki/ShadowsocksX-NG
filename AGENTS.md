# Repository Guidelines

## Project Structure & Module Organization
`ShadowsocksX-NG/` contains the macOS menu-bar app: Swift controllers (AppDelegate, LaunchAgentUtils, MenuBarManager), Objective-C helpers, localized `.lproj` bundles, and bundled binaries (`ss-local`, `privoxy`, SIP003 plugins). `proxy_conf_helper/` stores the privileged tool that flips system proxy settings, while `LaunchHelper/` is the login item stub. Native dependencies are built in `deps/` before being copied into the bundle; touch this only when upgrading upstream proxies. Unit tests live in `ShadowsocksX-NGTests/`, and contributor references (UI roadmap, testing strategy) live under `docs/` plus `CLAUDE.md`.

## Build, Test, and Development Commands
- `pod install` – sync CocoaPods before opening `ShadowsocksX-NG.xcworkspace`.
- `make -C deps` – rebuild the bundled ss-local/privoxy/plugins (required when toolchains change).
- `make debug` / `make release` – wrap `xcodebuild` and drop builds under `build/<Config>`.
- `make debug-dmg` / `make release-dmg` – package the existing `.app` into a DMG for QA.
- `swiftlint lint --strict` – enforce the repository rule set locally.
- `xcodebuild test -workspace ShadowsocksX-NG.xcworkspace -scheme ShadowsocksX-NG -destination 'platform=macOS' [-enableCodeCoverage YES]` – run all XCTest bundles (add coverage when touching core logic).

## Coding Style & Naming Conventions
New Swift files must satisfy `.swiftlint.yml`: 4-space indent, 120-character soft cap, strict type/function length limits, and opt-in rules banning `force_unwrapping`, `force_try`, and sloppy whitespace. Avoid `NSLog`, `print`, and empty catches; prefer `os.Logger`, guard-driven flow, Codable models, and async/await. Branch names follow GitFlow (`feature/<topic>`), commits use Conventional prefixes (`feat:`, `fix:`), with PascalCase types and lowerCamelCase members.

## Testing Guidelines
Mirror source names inside `ShadowsocksX-NGTests/` (e.g., `ServerProfileTests.swift`) and focus on serialization, OS gating, and helper utilities. Run the `xcodebuild test … -enableCodeCoverage YES` variant whenever routing, launchd plumbing, or PAC utilities change, and keep touched files at their previous coverage level. Document manual verifications (menu bar UI, launchctl interactions) in the PR whenever automation is impractical.

## Commit & Pull Request Guidelines
Branch from `develop`, rebase often, and keep commits focused; mention subsystems in the subject when it adds clarity (`feat(proxy): …`). Every PR must list the build/test commands executed, link the tracking issue, and attach screenshots or recordings for UI-visible work (User Rules window, status icon). Update docs/localizations when behavior changes, and note any dependency rebuilds (`deps/`, pods) in the description.
