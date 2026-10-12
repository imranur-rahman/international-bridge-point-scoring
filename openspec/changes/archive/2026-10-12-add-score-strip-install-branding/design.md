## Context

See proposal.md for the motivation and `specs/` for the requirements. The deal screen (`deal_screen.dart`) already switches between one pane and two panes at 900 logical pixels. `LedgerSnapshot` already has `games`, `partScores`, `totalFor`, and `values` (with the game threshold). The service worker and the icon from the previous change stay as they are.

## Goals / Non-Goals

**Goals:**
- Show the state of the game on a phone without a change of screen.
- An install action that works in each browser, with no extra package.
- Keep all bridge logic in the pure modules; the UI only reads the snapshot.

**Non-Goals:**
- A strip in the two-pane layout (the sheet is already visible there).
- An install prompt in Firefox or desktop Safari, which offer none.
- New scoring terms: rubber stays.

## Decisions

### D1. Score strip

A `ScoreStrip` widget reads `ledgerProvider` and shows one row for each side: the partnership name, the total, "G n" for games, the points below the line, and "needs N for game". It uses `Expanded` cells and `FittedBox` for the numbers, so it fits 360 px at each text size. The "needs" value is `values[gameThreshold] − partScores[side]`, at least 1. The strip is an `InkWell` that opens `/sheet`. `DealScreen` shows it only in the one-pane layout, above the stage bar.

Alternative: put the numbers in the app bar. There is not enough room for two sides at 360 px with large text. Rejected.

### D2. Scored stage actions

The scored view adds a line "Next deal: <name> (<seat>) deals" from `session.dealerOf(session.records.length)`, shown only when the session is active. "Undo deal" is an `OutlinedButton` beside "Next deal" in an `OverflowBar`; it asks for confirmation and sends `UndoLastDeal`, the existing command, so no session code changes.

### D3. Install action

`web/index.html` listens for `beforeinstallprompt`, calls `preventDefault()`, and keeps the event in `window.ibInstallPrompt`; on `appinstalled` it clears it. It also defines:
- `window.ibInstallState()` → `"prompt"` (an event is kept), `"ios"` (iPhone or iPad user agent, not standalone), `"installed"` (`display-mode: standalone` or `navigator.standalone`), or `"none"`.
- `window.ibInstall()` → shows the kept prompt and returns a promise with the user's choice.

In Dart, `ui/src/install/install_prompt.dart` exports an `InstallPrompt` interface with `state()` and `install()`. A conditional import (`if (dart.library.js_interop)`) picks `install_prompt_web.dart` (calls the two functions with `dart:js_interop`) or `install_prompt_stub.dart` (always `none`), so the VM tests and the Android and iOS builds do not use web code. A Riverpod provider holds the `InstallPrompt`; tests override it with a fake. The home screen checks the state when it opens and again every 2 seconds until the state is not `none` or for 10 seconds, because the browser can fire the event after the first frame.

Alternative: a package for PWA install prompts. It adds a dependency for two small functions. Rejected.

### D4. Name and heading font

- The name "IB Scoring" goes into `web/index.html` (title and Apple title), `web/manifest.json` (name and short name), the Android label, the iOS display name, the `MaterialApp` title, and the home app bar. The home heading becomes "International Bridge Scoring", and the descriptions become "Keep the score of each bridge deal by the rules."
- `tool/subset_font.py` gets a second mode that makes static instances of the variable Montserrat font at weights 600 and 700 (with `fontTools.varLib.instancer`) and keeps only Basic Latin, Latin-1, and the punctuation that the app uses (– — · × − ’). The two files go to `assets/fonts/` with Montserrat's OFL file; `pubspec.yaml` declares the family `Montserrat` with weights 600 and 700.
- The theme sets `fontFamily: 'Montserrat'` on `headlineSmall`, `titleLarge`, and `titleMedium`, which the page titles, the section titles, the contract headline, and the winner line already use. Suit symbols keep their own font through `SuitText`.
- A test checks that both font files are smaller than 40 KB.

### D5. Storage actions

- **Offline copy (web):** `web/index.html` defines `ibOfflineSize()` (sums the sizes of the responses in the caches whose names start with `ib-score-`) and `ibRefreshAppFiles()` (deletes those caches, unregisters the service workers of the app, and reloads the page). An `AppFiles` interface in `ui/src/install/` with a web version and a stub (the same conditional import as `InstallPrompt`) calls them; the stub reports no offline copy, so phone builds hide the action.
- **All data:** `KeyValueStore` gets `clear()` (`SharedPreferences.clear()` removes only the keys of this app). A `LocalDataRepository` in `storage` with `deleteAll()` calls it. A `resetAllData` function in the UI providers calls `deleteAll()`, then resets the session, House rules, last preset, and display notifiers to their defaults and reloads the past sessions list, and the app goes to the home screen.
- **Strong confirmation:** a dialog with a text field; "Delete" is enabled only when the field holds "delete" (any letter case, with spaces removed at the ends).

## Risks / Trade-offs

- [A user deletes all data by mistake] → The typed word and the text "This cannot be undone" make an accidental deletion unlikely. A backup feature is a separate change.

- [The browser does not offer an install prompt (for example, the user dismissed it before)] → The action then does not show; the browser menu still has "Install" or "Add to Home Screen".
- [Montserrat headings take more width than Roboto] → The layout tests at 360 px with each text size cover all main screens.
- [A user agent check for iPhone and iPad can miss iPads that report a desktop user agent] → Such iPads see no install action. The browser menu still has "Add to Home Screen".
