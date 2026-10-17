# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

Greenfield tech test: no code exists yet. Update this file with build/test commands and architecture notes once the Xcode project is created.

## Objective

An iOS app that displays an **image feed in a grid layout** (visual gallery style). Users can browse Unsplash's **Editorial feed** and **search** for specific topics. Browsing must stay smooth and performant at scale (long feeds, many images).

## Hard constraints (from the brief)

- **Language/UI**: Swift and SwiftUI. UIKit only where necessary, and every use must be justified (e.g. in code comments or the README).
- **Minimum deployment target**: iOS 17. iOS 17 APIs (`@Observable`, `NavigationStack`, etc.) are available.
- **Data source**: Unsplash API. Images must be fetched at runtime. No bundled static image assets standing in for API data.
- **API key**: The Unsplash Access Key must come from local configuration or another environment-specific mechanism (e.g. a git-ignored `.xcconfig` read via `Info.plist`). Never hardcode or commit it.
- **Third-party libraries**: Allowed only if they don't implement the core feature. Each one needs a written justification. If an image-loading library is used, document what it provides and how it is configured (cache limits, downsampling, prefetching, etc.).
