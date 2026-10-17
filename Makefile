PROJECT      := BeGrid/BeGrid.xcodeproj
SCHEME       := BeGrid
DESTINATION  ?= platform=iOS Simulator,name=iPhone 17
DERIVED_DATA := build/DerivedData

TOOLS_PATH   := Tools
SWIFTLINT    := swift run --quiet --package-path $(TOOLS_PATH) -c release swiftlint

XCODEBUILD   := xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
                -destination '$(DESTINATION)' -derivedDataPath $(DERIVED_DATA)

.DEFAULT_GOAL := help
.PHONY: help bootstrap lint lint-fix build test clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Resolve and build pinned dev tools (SwiftLint via SPM)
	swift package --package-path $(TOOLS_PATH) resolve
	swift build --package-path $(TOOLS_PATH) -c release --product swiftlint

lint: ## Lint Swift sources (warnings fail the build)
	$(SWIFTLINT) lint --strict

lint-fix: ## Auto-correct lint violations, then lint again
	$(SWIFTLINT) lint --fix
	$(SWIFTLINT) lint --strict

build: ## Build the app for the simulator (override DESTINATION=...)
	$(XCODEBUILD) build

test: ## Run unit tests on the simulator (override DESTINATION=...)
	$(XCODEBUILD) test

clean: ## Remove build output (keeps the built tools cache)
	rm -rf build
