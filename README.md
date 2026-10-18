# BeGrid

An iOS app for browsing Unsplash's Editorial feed and searching photos in an endless two-column grid, with a full-screen viewer.

- **Swift 6 / SwiftUI**, iOS 17+, iPhone
- **No third-party dependencies in the app.** Networking, the image pipeline, caching, BlurHash decoding and offline mode are all written from scratch.
- **188 unit test cases** (Swift Testing)

---

## Setup

### Requirements

- Xcode 26 or later (the code uses Swift 6.2 features such as `@concurrent`)
- An Unsplash Access Key ([create an app](https://unsplash.com/oauth/applications))

### Unsplash Access Key

The key is read from a git-ignored xcconfig at build time:

```sh
cp BeGrid/Config/Secrets.example.xcconfig BeGrid/Config/Secrets.xcconfig
# then edit Secrets.xcconfig:
# UNSPLASH_ACCESS_KEY = <your key>
```

How it flows: `App.xcconfig` optionally includes `Secrets.xcconfig` → the build setting is injected into `Info.plist` as `UnsplashAccessKey` → `AppConfiguration` reads and validates it at launch. If the key is missing or still the placeholder, the app shows a setup screen instead of crashing.

### Run

Open `BeGrid/BeGrid.xcodeproj` and run the `BeGrid` scheme, or use the Makefile:

```sh
make build       # build for the simulator
make test        # run unit tests
make bootstrap   # one-time: build the pinned SwiftLint (~5 min)
make lint        # strict lint (warnings fail)
```

The simulator defaults to `iPhone 17`. Override it with `make test DESTINATION='platform=iOS Simulator,name=iPhone 16e'`.

---

## Features

| Requirement | Implementation |
|---|---|
| Grid feed | 2-column `LazyVGrid` of 4:5 cells, Editorial feed from `GET /photos` |
| Cell content | Image plus a 2-line caption over a gradient scrim. Text comes from `alt_description`, then `description`, then the placeholder "Photo by *photographer*". VoiceOver reads the same text |
| Endless scroll | The next page loads when any of the last 10 items appears. Duplicate IDs across pages are filtered out |
| Smoothness | Downsampled, pre-decoded images; BlurHash and average-colour placeholders; prefetching; cells that don't redraw on pagination (see [Performance](#performance)) |
| Full screen | Zoom transition from the tapped cell (iOS 18+, cross-fade on iOS 17); horizontal paging through the loaded photos; pinch and double-tap zoom; photographer credit; the grid scrolls to keep the current photo's cell in view on return |
| Search | `.searchable` with recent searches and suggestions, 500 ms debounce, same grid and endless scroll |
| Feed ↔ search | The feed stays alive under the search results, so leaving search returns to the same scroll position with no reload. Results cross-fade, and old results dim while a new query is pending |
| Loading states | Shimmer skeleton, pagination spinner, inline retry, empty state, "You're all caught up", pull to refresh |
| Bonus: pipeline | Deduplication, cancellation, priority escalation, downsampling, memory and disk caches, prefetching |
| Bonus: offline | Saved feed and search pages, disk-cached images, offline banner, automatic recovery on reconnect |
| Bonus: tests | 188 test cases across models, networking, data, pipeline and view models |
| Bonus: animations | Grid ↔ full-screen zoom transition, image fade-in, haptic on open |

---

## Architecture

Feature-based **MVVM** with `@Observable` view models over a small shared core. [`ARCHITECTURE.md`](ARCHITECTURE.md) covers the layers, dependency rules and key decisions in full.

```
BeGrid/BeGrid/
├── App/              entry point, composition root, configuration
├── Core/
│   ├── Models/       domain types, DTOs, DTO → domain mapping, image URL builder
│   ├── Networking/   HTTPClient, Unsplash endpoints, API errors, retry policy
│   ├── Data/         repository, photo sources (feed/search), page cache, offline store
│   ├── ImagePipeline/ loading, dedup, decoding, memory/disk cache, prefetching
│   └── Connectivity/ NWPathMonitor wrapper
├── Features/
│   ├── Grid/         shared grid view + view model (used by feed and search)
│   ├── Feed/
│   ├── Search/
│   └── Detail/       full-screen viewer
└── DesignSystem/     reusable views: RemoteImage, BlurHash, shimmer, banners…
```

Key choices:

- **One grid, many sources.** Feed and search differ only in where pages come from, so that difference is a `PhotoSource` protocol (`page(_:) async throws -> Page`). A single `PhotoGridViewModel` handles pagination, de-duplication, loading, error and refresh states for both, and is tested once.
- **Sources compose like decorators.** A search source is `FallbackSource(CachedSource(SearchSource))`: network, then a 5-minute in-memory page cache, then a disk fallback for offline. The view model doesn't know which layer answered.
- **Protocols at every boundary** (`PhotoRepository`, `PhotoSource`, `ImageLoading`, `HTTPClient`). Everything is faked in tests, without network or simulator UI.
- **Domain models are API-agnostic.** Unsplash JSON decodes into DTOs, which `PhotoMapper` maps to `Photo`. Features never see DTOs.
- **One composition root** (`AppEnvironment.live()`). No DI framework, just initializers plus the SwiftUI environment for the image loader and connectivity.
- **Concurrency.** The app target uses Swift 6 strict concurrency with `MainActor` default isolation. Views and view models run on the main actor. Networking, JSON decoding, image decoding and disk I/O are `nonisolated`/`@concurrent` or live in actors (`ImagePipeline`, `DiskImageCache`, `PageCache`, `PageStore`). The compiler rules out data races.

### Why UIKit in one place

UIKit is used only in `Features/Detail/ZoomableView.swift`, which wraps a `UIScrollView` with `UIViewRepresentable`. SwiftUI on iOS 17 has no zoomable scroll view. Building pinch-zoom from `MagnifyGesture` means re-implementing zoom limits, rubber-banding, panning while zoomed, double-tap-to-zoom at a point and its interaction with the pager's paging gesture. `UIScrollView` provides all of that natively. The photo itself is still rendered by SwiftUI inside a hosting controller.

### Third-party libraries

None in the app. The task's core is the feed and its performance, and most of that is the image pipeline, so it's written by hand rather than with Kingfisher or Nuke. BlurHash decoding is a small self-contained implementation.

The only external package is **SwiftLint**, pinned in `Tools/Package.swift`. It's dev tooling and isn't linked into the app.

---

## Unsplash API usage

- **`per_page=30`** (the maximum) on both endpoints. Under the demo limit of 50 requests/hour, this gives 30 photos per request instead of 10.
- **Image sizes.** Cells and the viewer start from the `regular` URL and set `w`, `dpr=1`, `q=80` and `fm=jpg` to the exact pixel size needed (cell width × screen scale, or screen size in the viewer). Unsplash's imgix CDN resizes server-side. Every other query parameter returned by the API, including `ixid`, is kept (`ImageURLBuilder`). CDN requests don't count toward the rate limit, so requesting exact sizes costs nothing in quota.
- **Search requests are throttled** by a 500 ms debounce and a 2-character minimum. Pages are cached in memory for 5 minutes (10 most recent queries), so returning to a recent query doesn't use quota.
- **Errors are classified** (`APIError`): offline, rate-limited (403/429 or `X-Ratelimit-Remaining: 0`), unauthorized, server, decoding. Only transient 5xx/unknown errors are retried (3 attempts, exponential backoff from 500 ms). **Rate limits are never retried**, because the quota is hourly and retrying only wastes it.
- The `Accept-Version: v1` header is set, and the key is sent as `Authorization: Client-ID …`.

---

## Performance

### Image pipeline

`ImagePipeline` is an actor behind the `ImageLoading` protocol. Views ask for "this URL at this pixel size" and don't know how it's produced.

```
RemoteImage ──► memory cache hit? ──► show synchronously (no flash on re-appear)
     │ miss
     ▼
ImagePipeline (actor)
     ├─ in-flight request for same (url, size)? ──► join it (dedup)
     └─ start one task:
          disk cache hit? ──► decode
          else network ──► decode ──► write to disk
          └─► memory cache ──► resume all waiters
```

| Technique | What it does | Why |
|---|---|---|
| **Deduplication** | Concurrent requests for the same URL and size share one task, and each caller waits on a continuation | Prefetch and on-screen load often ask for the same image at the same time |
| **Cancellation** | Each waiter can cancel on its own. The underlying download is cancelled only when the **last** waiter leaves | Fast scrolling cancels off-screen loads without breaking a shared request another view still needs |
| **Priority escalation** | When a visible cell joins a `.utility` prefetch already in flight, the task is escalated to the caller's priority (iOS 26+) | A prefetch that becomes visible shouldn't stay at background priority |
| **Downsampling** | ImageIO `CGImageSourceCreateThumbnailAtIndex` decodes straight to the target size. `preparingForDisplay()` decodes off the main thread | Avoids full-size bitmaps and main-thread decode, which cause most scroll hitches |
| **Memory cache** | `NSCache` costed by real bitmap bytes (`bytesPerRow × height`), limited to 1/8 of physical RAM. Cleared on memory warning and on backgrounding | Memory stays bounded however far you scroll |
| **Disk cache** | Actor-isolated, SHA-256 file names, 200 MB LRU (by access time). Trims to 75% when over the limit. Stores encoded bytes, so it's reused at any target size | Survives relaunch and powers offline mode. `URLCache` is disabled for images to avoid caching twice |
| **Prefetching** | When a cell appears, the next 12 images are requested at `.utility` priority. Prefetches that fall out of the window are cancelled, but ones the user just scrolled past are kept | Images are ready before cells appear, without unbounded background work |
| **Placeholders** | Average colour first, then a 32×32 BlurHash decoded off the main actor, then a 0.2 s fade to the image | No blank cells or layout jumps, even on slow networks |

### Measuring

In Debug builds, each pipeline feature can be turned off with launch arguments for A/B profiling (see `PipelineOptions.overridden()`), for example:

```
-pipeline.dedup NO  -pipeline.downsample NO  -pipeline.memoryCache NO  -pipeline.diskCache NO  -pipeline.prefetch NO
```

#### Instruments results

One **Animation Hitches + Network** run on an iPhone 17 Pro (iOS 27, Debug build, all pipeline features on), starting from a fresh install and fast-scrolling the Editorial feed:

| Metric | Result |
|---|---|
| Scrolled | 5 feed pages, about 150 photos, in about 7 s of continuous fast scrolling |
| Hitches | 2 (8.3 ms and 12.5 ms) |
| Hitch time ratio | about **3 ms/s** while scrolling (Apple's "good" threshold is under 5 ms/s) |
| Hangs | none |
| API requests | 5 (one per page, none wasted) |
| Image requests | 154 for 148 photos. The 6 repeats were cells scrolled past before their download finished: the pipeline cancelled the download, then requested it again when needed |

**Not measured yet:** memory over several hundred images (Allocations), and on/off comparisons for each pipeline feature. The launch arguments above are there for that. The pipeline's behaviour is covered by unit tests instead: deduplication, cancellation, cache limits and eviction.

---

## Offline mode and error handling

- **Saved pages.** The first 3 pages of the feed, and of the 5 most recently *submitted* searches, are saved as JSON to the Caches directory. Searches typed but not submitted aren't saved. When a request fails, the repository returns the saved page marked *stale* instead of an error.
- **Saved images.** These come from the image disk cache. Image requests use `waitsForConnectivity`, so offline misses wait instead of failing.
- **UI.** An offline banner appears at the bottom. When connectivity returns, grids showing stale or failed content reload on their own.
- **Errors while online.** If a refresh fails, or stale pages replace fresh ones, an alert offers **Try Again**, and the photos already on screen stay. If the first load fails with nothing to show, the grid shows a full-screen error with a retry. Pagination failures show an inline footer retry.

---

## Testing

188 test cases (including parameterized ones) with **Swift Testing**, run with `make test`. They need no network and no UI automation.

- **Models:** decoding both response shapes from JSON fixtures, the description fallback, URL building that preserves `ixid`
- **Networking:** request building, HTTP status → `APIError` mapping, retry and backoff with a manual clock
- **Data:** feed and search sources, page cache expiry and LRU, offline fallback, repository wiring
- **Image pipeline:** deduplication (waiter counts), cancellation of shared requests, downsampling maths, memory cache cost and purge, disk LRU eviction, prefetch window
- **View models:** pagination, de-duplication, refresh, stale and failure handling, reconnect recovery, search debounce, recent searches
- **Design system:** BlurHash decoding

Test doubles (`ScriptedSource`, `GatedHTTPClient`, `RecordingImageLoader`, `ManualClock`, etc.) are in `BeGridTests/Support/`.

---

## Trade-offs and possible improvements

**Trade-offs made**

- **Uniform 4:5 cells rather than a masonry layout.** Fixed sizes keep layout cheap and predictable and avoid jumps when images load. Images are aspect-filled, so some cropping is the cost. A waterfall layout using the API's `width`/`height` would show whole photos but needs a custom `Layout`.
- **iOS 17 gets simpler versions** of the zoom transition and search-field focus, which use iOS 18 APIs.

**What I'd do next**

- Show the rate-limit state more clearly (remaining quota from headers, and a countdown when exhausted)
- iPad and landscape: adaptive column count
- UI tests for the main flows, and snapshot tests for cell and loading states
- Load more pages from the full-screen viewer, and add share/save actions
- Masonry layout option
- Persist the feed scroll position across launches
- Use the `color` and `orientation` search filters the API supports

---

## AI usage

I used **Claude Code** as a pair programmer throughout. I made the decisions, and Claude did most of the typing.

- **Constraints written down first.** Before any feature code, the repo had `ARCHITECTURE.md` (layers, dependency rules, key decisions) and `CLAUDE.md` (commands, compiler settings, hard constraints from the brief), so every session started from the same rules.
- **A plan before code.** With Claude, I turned the brief into a phased plan: config → models → networking → data → image pipeline → grid → feed → search → viewer → polish → disk cache/prefetch → offline. I made the product decisions up front, such as the uniform 2-column grid. The plan also recorded constraints like the rate-limit budget and keeping Unsplash URL parameters.
- **One phase, one PR, one review.** Claude implemented one phase at a time on its own branch, and `make lint`, `make build` and `make test` had to pass before each commit. I reviewed and edited each diff before merging (for example, removing explanatory comments and keeping docs high-level). Commits are marked `Co-Authored-By: Claude`.
- **Where it helped most:** Swift 6 strict-concurrency details, the actor-based deduplication and cancellation logic, the BlurHash decoder, and writing test doubles and edge-case tests quickly.
- **Where I steered:** architecture and scope, and UX decisions such as keeping the feed alive under search, saving only *submitted* searches offline, and alerts vs. the offline banner.
