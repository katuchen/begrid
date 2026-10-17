// swift-tools-version: 6.0
// Developer tooling only — not linked into the app. Pins tool versions so
// `make lint` behaves the same on every machine. Run via the root Makefile.

import PackageDescription

let package = Package(
    name: "BeGridTools",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.65.1"),
    ]
)
