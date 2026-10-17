# BeGrid Architecture

BeGrid is a SwiftUI app that shows Unsplash's Editorial feed and search results in an endless grid, with a full-screen viewer.
This document describes how the app is structured and why. Implementation details belong in the code.

## Pattern

**Feature-based MVVM**: SwiftUI views backed by `@Observable` view models, on top of a small shared core.

```
Features  (views + view models)
   │
   ▼
Data      (repositories)  ──►  Networking
   │                              │
   ▼                              ▼
Models    (domain types)  ◄───────┘

ImagePipeline: a standalone subsystem used by views
```

## Rules

- **Dependencies point downward.** Features depend on Data and Models, never on Networking. Core never depends on Features.
- **Boundaries are protocols.** Layers communicate through protocols (`PhotoRepository`, `PhotoSource`, `ImageLoading`, `HTTPClient`), so each layer can be replaced or faked in tests.
- **Domain models are API-agnostic.** Unsplash's response format is mapped to domain types at the data layer. Features never see DTOs.
- **One composition root.** Concrete types are created once at app start and passed down through initializers. There is no DI framework.

## Layout

| Folder | Responsibility |
|---|---|
| `App/` | Entry point, root view, composition root, configuration |
| `Core/Models/` | Domain types and the mapping from API types |
| `Core/Networking/` | HTTP transport and Unsplash endpoint definitions |
| `Core/Data/` | Repositories: the single source of photo data |
| `Core/ImagePipeline/` | Image loading, caching, and sizing |
| `Features/<Name>/` | One folder per screen or shared feature (`Grid`, `Feed`, `Search`, `Detail`) |
| `DesignSystem/` | Reusable visual components with no business logic |

Tests mirror this layout.

## Key decisions

### Feed and search share one grid

Feed and search have the same UI and the same endless-scroll behavior. They differ only in where pages come from. That difference is captured by `PhotoSource`, and one grid feature (view + view model) works with any source. Pagination, deduplication, and loading/error states are written and tested once.

### Each mode owns its own state

The feed's state lives for the whole session. Each search gets its own state. Leaving search returns to the feed unchanged, without reloading anything.

### The image pipeline is its own subsystem

Image loading drives most of the app's performance, so it is a dedicated component behind `ImageLoading`, not done in views. It is responsible for:

- deduplicating requests
- cancelling work that is no longer needed
- memory caching
- downsampling to display size

Views ask for an image at a size. How it is produced is hidden from them.

### Views receive values, not view models

Grid cells take plain `Equatable` data. Changes to list-level state, such as pagination, therefore don't re-render visible cells.

## Concurrency

The app target uses Swift 6 strict concurrency, and code runs on the main actor by default.

- **Main actor:** views and view models.
- **Off the main actor:** models, networking, data, and image pipeline types are `nonisolated` and `Sendable`, or are actors.
- **Crossing the boundary:** only through `async` calls.
