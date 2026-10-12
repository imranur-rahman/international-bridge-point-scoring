## Context

See proposal.md for the motivation and `specs/` for the requirements. The web build uses Flutter 3.47.7. Its generated `flutter_service_worker.js` unregisters itself, so the app has no offline support. `web/` and the platform icon folders still hold the Flutter template icons. The deal stages live in `SessionController`; the UI shows one view for each stage.

## Goals / Non-Goals

**Goals:**
- Open the web app offline after one visit, and at once on later visits, with no build step that must list files.
- One icon source for all platforms.
- Quick entry with no change to the scoring rules and no data migration.

**Non-Goals:**
- Offline use before the first visit.
- An "update available" message. A new version starts at the next open.
- Quick entry with the bidding step on.

## Decisions

### D1. Own service worker: cache first, one complete cache for each version

A hand-written `web/sw.js` replaces the use of Flutter's service worker. `web/index.html` registers it (only over HTTPS or on localhost). `sw.js` holds a constant `BUILD_ID`. The deploy workflow replaces it with the commit id (`github.sha`), so each deployment has a different `sw.js`, and the browser installs the new worker in the background when it checks for updates (at each open, as browsers do for service workers).

- **Fetch:** Requests for the app's own files and for Google fonts are answered from the cache `ib-score-<BUILD_ID>` first. A file that is not in the cache comes from the network, and the worker adds it to the cache.
- **Install of a new version:** The new worker reads the list of URLs in the current cache and downloads each of them from the network (with `cache: 'reload'`) into its own new cache. It finishes the install only when all downloads succeed. A failed download stops the install, and the old worker and its complete cache stay in use.
- **Activate:** The new worker deletes the caches of older versions. It does not call `skipWaiting`, so an open page keeps its version, and the new version starts at the next open.
- **First visit:** There is no cache yet, so the files come from the network and fill the cache.

This meets "never open with files from two versions", because each cache holds only one version and the switch happens between two opens.

Alternatives: network-first with a timeout (each open waits for the network, so it is not instant); a precache list made at build time (needs a script that reads `build/web`, and the CanvasKit folder holds 36 MB of variants that one browser never loads). Rejected.

### D1a. Suit font subset

`tool/subset_font.py` uses `fontTools` (`pyftsubset`) to keep only U+2660, U+2663, U+2665, and U+2666 from Noto Sans Symbols 2. The result replaces `assets/fonts/NotoSansSymbols2-Regular.ttf` (the OFL license file stays). The font family name in `pubspec.yaml` does not change. A test reads the font file and checks that it is smaller than 20 KB, so a full font cannot come back by mistake.

### D2. Icon script

`tool/make_icons.py` draws one 1024 × 1024 master icon with Pillow: felt green (`#1E6B45`) with rounded corners, a white ♠ from the bundled Noto Sans Symbols 2 font, and "IB" from a bold sans-serif font file given on the command line (Roboto Bold from the Google Fonts repository, Apache License 2.0; the script does not ship it). The script then writes each size for web (favicon 32 px, 192 px, 512 px, and maskable 192 px and 512 px with the content inside the inner 80 %), Android (`mipmap-*` `ic_launcher.png`), and iOS (each file in `AppIcon.appiconset`, without transparency, as Apple needs). The PNG files are committed, so builds do not need Python.

### D3. Quick entry in the session

- `SessionSettings.quickEntry` (bool, default false; `fromJson` reads a missing value as false).
- `DealStage` gets a value `entry`. With quick entry on, `SessionController.start` and `NextDeal` create drafts at `entry`, and "Undo last deal" returns to `entry`.
- A new command `RecordQuickDeal(DealResult? result)` is valid only at `entry`. It records the deal with the same `_record` path as `ScoreDeal` and `PassOut`, so the end rule, the dealer rotation, and the scored stage behave the same.
- The UI keeps the entry inputs in the widget state and sends one command. The draft does not store a half-complete quick entry; a reload at the entry stage shows an empty entry screen. This is acceptable, because the quick-entry screen holds no more than a few taps of data.

### D4. Visual emphasis through the theme

The theme in `ui/src/theme.dart` sets the weights once: `headlineSmall`, `titleLarge`, and `titleMedium` at weight 700, `titleSmall` and `labelLarge` at weight 600. `SectionTitle` uses `titleMedium` in the primary color. The screens then use these text styles for headings and key values instead of local `FontWeight` values, so that each page uses the same order. One widget test reads the text style of each key element in the "Visual emphasis" requirement and checks its weight. The existing contrast test covers the primary color on the surface colors.

### D5. Even result and honors grids

`ResultPicker` becomes a grid of 2 rows × 7 columns. Each row is a `Row` of 7 `Expanded` cells, so all cells have the same width at each screen width. Each cell is at least 44 logical pixels high, and its text sits in a `FittedBox`, so "Made" and "−10" fit at the extra large text size on a 360 px screen. The cell colors come from the color scheme: `errorContainer` for undertricks, `primaryContainer` for "Made", and `tertiaryContainer` for overtricks, with the matching `on…` colors for the text; the selected cell uses the strong color (`error`, `primary`, `tertiary`). The full result line under the grid uses the same group color, bold.

`HonorsPicker` shows the side choice as a `SegmentedButton` with two equal halves, and the holdings in rows of two `Expanded` cells, with the label at the start and the points at the end of each cell. A no trump contract has 4 holdings, so 2 rows; a suit contract has 6, so 3 rows.

Alternative: keep the `Wrap` of chips with a fixed chip width. The last row still ends unevenly, and the number of chips in a row changes with the screen width. Rejected.

### D6. UI reuse

The quick-entry screen reuses the contract chips, `ResultPicker`, `HonorsPicker`, `PlayRoles`, and `VulnerabilityLabel`. The stage bar shows "Entry" and "Scored".

## Risks / Trade-offs

- [A user sees a new version only at the second open after a deployment] → This is the cost of an instant start. The background download is small after the first visit (about 1 to 3 MB).
- [Browsers limit cache storage] → The cache holds only the files that one browser loaded (about 5 to 10 MB). This is far under the browser limits.
- [The icon text font is not in the repository] → The PNG files are committed, and the script documents where to get the font.
