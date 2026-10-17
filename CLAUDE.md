# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Objective

**BeGrid**: an iOS app that displays an **image feed in a grid layout** (visual gallery style). Users can browse Unsplash's **Editorial feed** and **search** for specific topics. Browsing must stay smooth and performant at scale (long feeds, many images).

## Commands

All run from the repo root. Run `make` alone to list targets.

```sh
make bootstrap   # resolve + build pinned SwiftLint (first run builds from source, ~5 min)
make lint        # swiftlint lint --strict (warnings fail)
make lint-fix    # swiftlint --fix, then strict lint
make build       # xcodebuild build for the simulator
make test        # xcodebuild test (BeGridTests) for the simulator
make clean       # rm -rf build/ (keeps the Tools/.build tool cache)
```

- Simulator defaults to `iPhone 17`. Override it with `make test DESTINATION='platform=iOS Simulator,name=iPhone 16e'`.
- Build output goes to `build/DerivedData` (git-ignored), not the global DerivedData.

## Repository layout and tooling

- `BeGrid/BeGrid.xcodeproj` has two targets: `BeGrid` (app) and `BeGridTests` (unit tests). It has a single shared scheme, `BeGrid`, committed under `xcshareddata/`.
- The project uses **file-system synchronized groups**. Any file added under `BeGrid/BeGrid/` or `BeGrid/BeGridTests/` is compiled automatically, so don't edit `project.pbxproj` to register files.
- `Tools/` is a standalone SwiftPM package for dev tooling only. Don't use a Homebrew `swiftlint`.

## Compiler settings that shape the code

- **Swift 6 language mode** gives full strict concurrency checking. Data races are compile errors.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** and approachable concurrency are set on the app target. Types and functions are `@MainActor` by default, so mark networking and decoding work `nonisolated` (or move it to an actor) to keep it off the main thread. The test target does **not** set default MainActor isolation.
- Tests use **Swift Testing.**
- The minimum target is iOS 17.0 at both project and target level.

## Hard constraints

- **Language/UI**: Swift and SwiftUI. UIKit only where necessary, and every use must be justified.
- **Data source**: Unsplash API. Images must be fetched at runtime. No bundled static image assets standing in for API data.
- Third-party libraries: Allowed only if they don't implement the core feature.
