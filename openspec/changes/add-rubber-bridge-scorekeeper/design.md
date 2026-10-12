## Context

The repository contains only the OpenSpec setup. This change creates the full app. See proposal.md for the motivation and the specs in `specs/` for the required behavior.

Constraints:
- One code base for Android, iOS, and web. Web is the main way to reach all platforms.
- The app works with no network connection and no server.
- The user asked for a modular, decoupled design with clear interfaces between the modules.
- The score must be correct. Scoring rules are the area with the highest risk of errors, so they need the most tests.

## Goals / Non-Goals

**Goals:**
- Keep all bridge rules (auction, scoring, deal stages, end rule) in pure Dart folders that do not import Flutter. Tests for these folders do not need a device or a widget.
- Let each module depend only on the public interface (the barrel file) of another module, never on its internal files. An automated test enforces this.
- Calculate every score from the session settings and the ordered list of recorded deals. This makes undo, edit, and reload simple and correct.

**Non-Goals:**
- No server, accounts, or sync between devices.
- No code generation (for example, `freezed` or `json_serializable`) in the first version.
- No desktop-specific UI work. Desktop builds can come later.

## Decisions

### D1. One Flutter package with strict module folders

The Flutter project is at the repository root. Each module is one folder under `lib/`:

```
lib/
  main.dart
  core/       core.dart + src/   pure Dart: Seat, Side, Strain, Bid, Call, Doubling, Contract, Vulnerability
  auction/    auction.dart + src/   pure Dart: Auction, legal calls, final contract and declarer
  scoring/    scoring.dart + src/   pure Dart: ScoringValues, ScoringPreset, DealScorer, RubberLedger
  session/    session.dart + src/   pure Dart: SessionSettings, EndRule, DealStage machine, SessionState
  storage/    storage.dart + src/   SessionRepository, PresetRepository, and their implementations
  ui/         app, routing, theme, features/ (home, setup, deal, auction, sheet, past)
test/
  architecture/   boundary test
  core/ auction/ scoring/ session/ storage/ ui/
```

Allowed dependencies between modules (an arrow means "may import"):

```
ui ──► session ──► scoring ──► core
 │        └──────► auction ──► core
 └──► storage ──► session (models and JSON only)
```

Rules:
- Each module has one barrel file (for example, `lib/scoring/scoring.dart`) that exports its public types. Other modules import only that barrel file, never a file under `src/`.
- `core`, `auction`, `scoring`, and `session` do not import `package:flutter` or any plugin.
- `auction` and `scoring` do not import each other.
- Only `ui` imports Flutter widgets. Only `storage` imports the storage plugin.

A test in `test/architecture/` reads every Dart file under `lib/`, parses its `import` lines, and fails when an import breaks one of these rules. This test runs with the other tests, so a boundary error stops the build.

Alternative: separate Dart packages in a pub workspace. The package system enforces the boundaries without a custom test, but it adds set-up work. Rejected by the user in favor of one package.

### D2. Interfaces between modules

- `auction`:
  - `Auction` is immutable. `Auction.start(dealer)` makes a new auction.
  - `auction.legalCalls()` returns the set of legal calls for the player to call.
  - `auction.add(call)` returns a new `Auction`, or throws `IllegalCallException`.
  - `auction.undo()` returns the auction without its last call.
  - `auction.outcome` is a sealed type: `InProgress`, `PassedOut`, or `ContractReached(contract, declarer)`.
- `scoring`:
  - `ScoringValues` holds every value from the "Scoring values table" in the rubber-scoring spec. `ScoringValues.standard()` gives the defaults. `validate()` returns a list of field errors. `differsFrom(other)` returns the fields that are different, for the "changed" marks.
  - `ScoringPreset` is an enum: `standard` and `houseRules`.
  - `DealScorer.score(DealResult, Vulnerability, ScoringValues, ScoringComponents)` returns `DealScore`, a list of `ScoreItem(side, component, points, aboveLine)`.
  - `RubberLedger.replay(List<DealResult?> deals, ScoringValues, ScoringComponents)` returns `LedgerSnapshot`. The snapshot holds the rubbers, the games, the vulnerability before each deal, the score items for each deal, and the totals. `null` in the list means a passed-out deal.
  - `ledger.unfinishedRubberBonus()` returns the score items that apply if the session ends now.
- `session`:
  - `SessionSettings`: players, first dealer, `EndRule`, bidding step on/off, `ScoringComponents`, the selected `ScoringPreset`, and a copy of its `ScoringValues`. The copy makes each session independent of later changes to "House rules".
  - `EndRule` is sealed: `DealCountRule(n)` and `TargetScoreRule(points)`. `isReached(LedgerSnapshot, dealCount)` returns a bool.
  - `SessionState` is immutable: settings, the list of `DealRecord` (result + optional auction + an `auctionEdited` flag + an optional `original` result and a list of edit times), the current `DealDraft` with its `DealStage`, and the status (active or ended).
  - `SessionController` is pure Dart. It takes `SessionState` and a command (for example, `RecordCall`, `ConfirmContract`, `EnterResult`, `UndoLastDeal`, `EditDeal`, `EndSession`) and returns a new `SessionState`. It rejects a command that is not valid in the current stage.
  - `PlayRoles.of(declarer)` returns the declarer, the dummy, and the opening leader.
- `storage`:
  - `abstract interface class SessionRepository` with `loadActive()`, `saveActive(state)`, `listPast()`, `loadPast(id)`, `archive(state)`, `deletePast(id)`.
  - `abstract interface class PresetRepository` with `loadHouseRules()`, `saveHouseRules(values)`, `loadLastPreset()`, `saveLastPreset(preset)`.
  - `InMemorySessionRepository` and `InMemoryPresetRepository` for tests.

The `ui` module talks to the other modules only through `SessionController`, `LedgerSnapshot`, `PlayRoles`, `ScoringValues`, `SessionRepository`, and `PresetRepository`.

### D3. Event list as the source of truth

The stored session is the settings plus the ordered list of recorded deals plus the current draft. The app never stores totals, games, or vulnerability. `RubberLedger.replay` calculates them each time the list changes. A session has at most a few hundred deals, so a full replay takes much less than one millisecond.

This makes undo ("remove the last record"), edit ("replace record k"), and reopen after an edit (the spec "Reopen after correction") simple, and it meets the "Deterministic recalculation" requirement directly.

Alternative: update running totals for each deal. Rejected because edit of an early deal changes vulnerability and games of later deals, and running totals then need complex correction code.

### D4. Integer arithmetic and a table-driven scorer

All points are `int`. The scorer reads every number from `ScoringValues`, and the code contains no score constants. `ScoringValues` has 34 fields. `ScoringValues.standard()` and `ScoringValues.houseDefaults()` give the two sets of defaults. The undertrick penalty uses three positions (1st, 2nd and 3rd, 4th and later) for each vulnerability when doubled. The undoubled case uses one value for each undertrick. The scorer calculates the redoubled overtrick and undertrick values as 2 × the doubled values, so `ScoringValues` has no fields for them. The contract-point multipliers and the insult bonuses stay separate fields for doubled and redoubled.

Honors use one model for both presets. The scorer finds the majority side (3 or more honors), then adds the "4 in one hand" or "5 in one hand" value and the "each other honor" value for the rest of the honors of that side. With "each other honor" = 0, this gives the Laws result. The result stage records the holding as an enum (for example, `fourInOneHandPlusOne`), so that the scorer does not need the cards of each hand.

The game bonus (default 0) lets "House rules" give a bonus for each game, in the style of Chicago scoring. Because its default is 0, "Standard" gives the result of the Laws.

The sample calculator on the "House rules" screen calls the same `DealScorer` twice, with the "House rules" values and with `ScoringValues.standard()`. The calculator therefore can never show a result that differs from the real scorer. For the game bonus and the rubber bonus, the calculator uses a small `LedgerSnapshot` that it builds from the sample inputs "completes a game" and "completes a rubber".

### D5. State management with Riverpod

The app uses `flutter_riverpod`. A `SessionNotifier` holds the `SessionState`, sends commands to `SessionController`, and calls `SessionRepository.saveActive` after each new state. Derived providers expose the `LedgerSnapshot` and the `PlayRoles`, so that each widget rebuilds only for the data it uses.

Alternatives: `bloc` (more boilerplate for the same pattern) and `provider` (less support for derived state). Riverpod also lets tests replace the repositories with the in-memory versions.

### D6. Storage with `shared_preferences`, JSON, and a version number

The `storage` module stores each session as one JSON string with a `formatVersion` field. The key for the active session is fixed. Each past session has its own key, and an index key lists the past sessions. "House rules" and the last preset have their own keys. "Standard" is not stored, because `ScoringValues.standard()` gives it. `shared_preferences` uses `localStorage` on web, `NSUserDefaults` on iOS, and `SharedPreferences` on Android. One session is a few tens of kilobytes at most, so the size limit of `localStorage` (about 5 MB) is enough for hundreds of sessions.

Each model has hand-written `toJson` and `fromJson`. A migration function for each older `formatVersion` changes old JSON to the current form. If a session cannot be read, the repository returns an "unreadable" entry and does not change the stored data.

Alternatives: `hive` and `sembast` (more features than needed, extra web set-up), `drift` (SQL is not necessary for this data).

### D7. Navigation and screens

The app uses `go_router` with these routes: `/` (home: continue, new, past sessions), `/setup` (a three-step wizard: Players, Game rules, Scoring), `/setup/house-rules` (view or change "House rules"; the same screen shows "Standard" as read-only), `/deal` (the current deal, one view for each stage; at 900 px or wider it also shows the score sheet on the right), `/sheet` (score sheet and history, used on narrow screens), `/past/:id` (read-only sheet), `/settings` (display settings). Web URLs then work with the browser back button. The `/deal` route reads the stage from `SessionState`, so a reload opens the correct stage.

### D8. Visual design

- Material 3, one fixed seed color (deep green, like the felt of a card table), light and dark themes. A `DisplaySettings` provider holds the theme mode (System, Light, Dark), the text scale (1.0, 1.2, 1.4, multiplied with the device text scale through `MediaQuery`), and the suit colors. `shared_preferences` stores them, apart from sessions.
- One `SuitText` widget draws every suit symbol and reads the suit colors from `DisplaySettings`. Two colors: red for ♥ and ♦, the text color for ♣, ♠, and NT. Four colors: ♣ green and ♦ orange in addition. Each color has a light-theme value and a dark-theme value that pass a 4.5:1 contrast check, and a unit test checks the ratios.
- Widget tests run the main screens at 360 px width with each text scale and fail on a layout overflow.
- Below 900 logical pixels: one column, at most 600 logical pixels wide, centered. At 900 or more: two panes, the deal on the left and the score sheet on the right. One `LayoutBuilder` at the top of `/deal` selects the layout, and both panes read the same providers, so a resize loses no data.
- Large touch targets (at least 48 × 48) for use at the table.
- The score sheet has two widgets that read the same `LedgerSnapshot`: the paper view (default) and the card view. The selected view is a device preference in `shared_preferences`.
- The result stage shows one button for each possible result ("Down N", "Made", "+N"), built from the contract level.
- Each scoring value on the "House rules" and "Standard" screens has a help icon. The help text for each field lives in one `ui` file (a map from the `ScoringValues` field to its title, explanation, rule of use, and example), so that a test can check that each field has a help text.
- The final summary computes the player statistics and the biggest deals from the `LedgerSnapshot` and the deal records, in a pure function in the `session` module, so that tests do not need widgets. The chart uses `fl_chart` (a common Flutter chart package that works on web and mobile).
- A stage bar at the top of the deal screen shows all stages and marks the current stage.
- The auction screen shows the four seats around a square table, a bidding box (levels 1 to 7 × five denominations, plus Pass, Double, Redouble), and the call history grid under the table.

### D9. Tests

- `test/architecture/`: the boundary test from D1.
- `test/scoring/`: a table of known cases for each component (all undertrick counts 1 to 13 for each double state and vulnerability, all slam cases, the honors cases, game from part-scores, rubber 2–0 and 2–1, unfinished rubber). One test for each spec scenario. Tests with changed `ScoringValues` to make sure that the scorer reads every value.
- `test/auction/`: one test for each spec scenario, plus a random test that makes only legal calls and checks that each auction ends.
- `test/session/`: stage transitions, dealer rotation, end rules, undo, edit, reopen, and the copy of preset values at session start.
- `test/storage/`: JSON round trip, version migration, data that cannot be read, "House rules" and last preset.
- `test/ui/`: widget tests for setup validation, the presets, a full deal with and without bidding, and the score sheet.

## Risks / Trade-offs

- [The browser clears `localStorage` (private mode or cleared site data), and the user loses sessions] → The home screen shows a short note on web that the data stays only in this browser. Export is a non-goal for now, but the JSON format makes it easy to add.
- [A user sets scoring values that make no sense, for example a 4th-undertrick value lower than the 1st] → The app accepts any value in range, because the user asked for maximum configurability. The "House rules" screen marks each changed value, "Restore House rules defaults" is always available, and "Standard" can never change.
- [An edit of an early deal changes many later deals, and the players do not see what changed] → Before the save, the edit preview shows the totals before and after and each later deal that changes. The session controller builds the preview with two replays (the current list and the changed list) and a comparison of the two snapshots.
- [The end rule "target score" applies after an edit to an earlier deal] → The session ends only by the current replay result after the last deal, as the score-sheet spec defines. The app does not cut the deals that come after.
- [One package does not enforce module boundaries by itself] → The boundary test in `test/architecture/` fails on each import that breaks the rules in D1.

## Migration Plan

Not applicable. This is a new app with no users and no stored data. Deployment of the web build: `flutter build web` and upload of `build/web` to a static host. Mobile builds go through the normal store process.

## Open Questions

- Which static host to use for the web build (for example, GitHub Pages or Firebase Hosting). This does not change the code.
- The exact seed color and the app icon. These do not change the structure.
