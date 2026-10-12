## 1. Project set-up

- [ ] 1.1 Create the Flutter project at the repository root with the Android, iOS, and web platforms, and check that `flutter run -d chrome` shows the default app
- [ ] 1.2 Add the dependencies `flutter_riverpod`, `go_router`, `shared_preferences`, and `fl_chart`, and check that `flutter pub get` completes with no errors
- [ ] 1.3 Turn on strict analysis in `analysis_options.yaml` (`flutter_lints`, `implementation_imports`, strict casts and inference), and check that `flutter analyze` reports no issues
- [ ] 1.4 Create the module folders `lib/core`, `lib/auction`, `lib/scoring`, `lib/session`, `lib/storage`, `lib/ui`, each with its barrel file and `src/` folder, and the matching folders under `test/`; check that `flutter analyze` passes
- [ ] 1.5 Write the boundary test in `test/architecture/` that parses the imports under `lib/` and enforces the rules of design D1; check that it passes, and that it fails on a temporary import of `package:flutter` in `lib/scoring`

## 2. Core module

- [ ] 2.1 Add `Seat` (with clockwise next, partner, and left-hand opponent), `Side` (N-S, E-W), and `Strain` (with rank order ♣ < ♦ < ♥ < ♠ < NT); check with unit tests for rotation, partner, and rank
- [ ] 2.2 Add `Bid` (level 1–7 and strain, with comparison), `Call` (bid, pass, double, redouble), `Doubling`, `Contract`, and `Vulnerability`, with `toJson` and `fromJson`; check with unit tests for comparison and JSON round trip

## 3. Auction module

- [ ] 3.1 Add the immutable `Auction` with `start(dealer)`, the player to call, `add(call)`, `undo()`, and the call history by round; check with tests for the "Turn order", "Call history", and "Undo last call" scenarios
- [ ] 3.2 Add `legalCalls()` for bids, double, and redouble; check with tests for each scenario of "Legal bids only" and "Legal double and redouble"
- [ ] 3.3 Add `outcome` (`InProgress`, `PassedOut`, `ContractReached`) with the final contract, the double state, and the declarer rule; check with tests for each scenario of "End of auction" and "Final contract and declarer"
- [ ] 3.4 Add a random test that makes 10 000 auctions with only legal calls, and check that each auction ends and that each declarer belongs to the side of the last bid

## 4. Scoring module

- [ ] 4.1 Add `ScoringValues` with the 34 fields, `standard()`, `houseDefaults()`, `validate()`, `differsFrom()`, and JSON; check with tests that the two defaults match the spec table exactly and that values out of range give field errors
- [ ] 4.2 Add `ScoringComponents` (honors on/off, unfinished rubber bonus on/off), `HonorsHolding` (the suit and no trump holdings, with the side), and `DealResult`; check with JSON round trip tests
- [ ] 4.3 Add `DealScorer` for contract points, overtricks, the insult bonus, and slam bonuses, with redoubled overtricks as 2 × doubled; check with tests for each scenario of these requirements and for 7NT, 1♣ redoubled, and overtricks at no trump
- [ ] 4.4 Add undertrick penalties with the three positions and redoubled as 2 × doubled; check with a table test for 1 to 13 undertricks in each double state and vulnerability, and with the "Equal undertricks in House rules" scenario
- [ ] 4.5 Add the honors model (majority side, 4 or 5 in one hand, each other honor); check with tests for every honors scenario for "Standard" and "House rules", including the 2 + 2 aces case
- [ ] 4.6 Add `RubberLedger.replay` for games, the game line, part-scores, the game bonus, vulnerability, rubber completion and bonus, the new rubber, and session totals; check with tests for each scenario of these requirements, including "Full rubber with a clean slate after it"
- [ ] 4.7 Add `unfinishedRubberBonus()`; check with tests for the "Standard" and "House rules" scenarios and for the component switched off
- [ ] 4.8 Add a test that changes each of the 34 fields one at a time and checks that a matching sample deal changes its score, so that no field is ignored; add a test that the same deal list always gives the same snapshot

## 5. Session module

- [ ] 5.1 Add `SessionSettings`, `Players` with name validation and partnership names, and `EndRule` (`DealCountRule`, `TargetScoreRule`) with range validation; check with tests for each scenario of "Player names by seat", "Partnerships named from players", and "End rule configuration"
- [ ] 5.2 Add `DealStage`, `DealDraft`, `DealRecord` (with auction, `auctionEdited`, original result, and edit times), and `SessionState`, with JSON; check with JSON round trip tests
- [ ] 5.3 Add `SessionController` commands for the deal stages with and without the bidding step, "Back" by one stage, direct contract entry, passed-out deals, and dealer rotation; check with tests for each scenario of "Deal stages", "Direct contract entry", "Contract from auction is read-only", "Passed-out deal", and "Dealer rotation", and that a command that is not valid in the current stage is rejected
- [ ] 5.4 Add `PlayRoles.of(declarer)` and the result options ("Down N", "Made", "+N") for a contract; check with tests for the "Play roles" and "Result entry" scenarios
- [ ] 5.5 Add the end rule check after each scored deal, "End session" between deals, the unfinished rubber bonus at the end, and reopen after a correction; check with tests for each scenario of "Session end" and "Reopen after correction"
- [ ] 5.6 Add `UndoLastDeal`, `EditDeal` (with the passed-out check box and auction replacement), and the edit preview from two replays; check with tests for each scenario of "Undo last deal", "Edit a recorded deal", "Preview of the effect of an edit", and "Edit mark and original entry"
- [ ] 5.7 Add the pure functions for the final summary (winner and margin, rows for each rubber, chart points, three biggest deals, player statistics) and for the "New session, same players" settings; check with tests for each scenario of "Final summary" and "New session with the same players"
- [ ] 5.8 Make sure that a session copies the preset values at start; check with a test that a later change to "House rules" does not change the snapshot of a started session

## 6. Storage module

- [ ] 6.1 Add the `SessionRepository`, `PresetRepository`, and `DisplayPreferencesRepository` interfaces and their in-memory versions; check with a shared contract test that runs against the in-memory versions
- [ ] 6.2 Add the `shared_preferences` implementations with the keys of design D6 and `formatVersion`; check that the shared contract test also passes against them with the `shared_preferences` test mock
- [ ] 6.3 Add the migration step for each `formatVersion` and the "Cannot be opened" entry for data that cannot be read; check with tests for an old version and for damaged JSON, and that the damaged data stays unchanged
- [ ] 6.4 Check with tests the scenarios of "Store House rules and last preset", "Past sessions", and "Delete a past session"

## 7. UI foundation

- [ ] 7.1 Add the Riverpod providers: `SessionNotifier` (commands, auto-save after each state), the derived `LedgerSnapshot` and `PlayRoles` providers, the preset providers, and `DisplaySettings`; check with provider tests that use the in-memory repositories and that each command saves the state
- [ ] 7.2 Add the theme (Material 3, felt green seed, light and dark), the theme mode, and the text scale from `DisplaySettings`; check with a widget test that "Dark" shows the dark theme on a light device
- [ ] 7.3 Add the `SuitText` widget with two-color and four-color modes; check with a unit test that each suit color has a contrast ratio of at least 4.5:1 in both themes
- [ ] 7.4 Add the `go_router` routes of design D7 and a reload of `/deal` that opens the stage from the saved state; check with a widget test that a new app with a saved state at the auction opens the auction

## 8. Home, setup, and House rules screens

- [ ] 8.1 Build the home screen with "Continue session", "New session", "Past sessions", the gear icon, and the web storage note; check with widget tests for the "Resume active session" scenarios
- [ ] 8.2 Build the setup wizard step "Players" (names by seat, partnership names, first dealer); check with widget tests for name errors and "Next"
- [ ] 8.3 Build the setup wizard step "Game rules" (end rule, bidding step, scoring components); check with widget tests for value errors and "Back keeps values"
- [ ] 8.4 Build the setup wizard step "Scoring" (preset selection with the last preset, links to "Standard" and "House rules", "Start session"); check with widget tests for the "Scoring presets" scenarios and "Start from last step"
- [ ] 8.5 Build the "House rules" and "Standard" screens with the seven collapsible groups, the "different from Standard" marks, "Save", the discard question, and "Restore House rules defaults"; check with widget tests for each scenario of "House rules screen layout", "Save House rules", and "Restore House rules defaults"
- [ ] 8.6 Add the help texts for all 34 fields and the redoubled rule, and the help overlay (tap, hover tooltip, close by outside tap, close button, or Escape, one at a time); check with a test that each field has a help text, and with widget tests for the "Help for each scoring value" scenarios
- [ ] 8.7 Build the sample calculator that uses `DealScorer` with "House rules" and "Standard"; check with widget tests for the "Sample calculator for House rules" scenarios

## 9. Deal screens

- [ ] 9.1 Build the deal screen frame with the stage bar, the deal number, and the deal start view (dealer and vulnerability); check with widget tests for the "Vulnerability display" scenario and the stage names
- [ ] 9.2 Build the auction view: the table with four seats, the dealer mark, the turn highlight, the bidding box with disabled calls that are not legal, the history grid, and "Undo"; check with widget tests for the "Table view of players" scenario and a full auction to a contract and to passed out
- [ ] 9.3 Build the contract view for direct entry and for a read-only contract from the auction, with "Passed out"; check with widget tests for "Complete contract" and "Incomplete contract"
- [ ] 9.4 Build the play view with the declarer, the dummy, the opening leader, and the vulnerability; check with widget tests for the two "Play roles" scenarios
- [ ] 9.5 Build the result view with the result buttons, the full-word result, and the honors input with points for each holding; check with widget tests for the "Result entry" and "Honors entry" scenarios
- [ ] 9.6 Build the scored view with the score breakdown for the deal and "Next deal"; check with a widget test for the "Breakdown for a doubled failed contract" scenario
- [ ] 9.7 Add the two-pane layout at 900 px or wider and the "Sheet" button below it; check with widget tests for the three scenarios of "Score sheet beside the deal on wide screens"

## 10. Score sheet, history, and summary screens

- [ ] 10.1 Build the paper view of the score sheet (above and below the line, game lines, games won, rubber and session totals, deals left or target); check with widget tests for the "Score sheet layout" and "Totals" scenarios
- [ ] 10.2 Build the card view and the toggle that the device remembers; check with widget tests for the "Two sheet views" scenarios and that both views show the same totals
- [ ] 10.3 Build the history tab with the deal entries, the auction view of a deal, "Undo last deal" with confirmation, and the edit mark with the original entry; check with widget tests for the "Deal history", "Undo last deal", and "Edit mark and original entry" scenarios
- [ ] 10.4 Build the edit deal screen and the preview with "Save edit" and "Cancel"; check with widget tests for the edit and preview scenarios
- [ ] 10.5 Build "End session" with confirmation and the final summary (winner, rubber rows, unfinished bonus, `fl_chart` line chart with the target line, biggest deals, player statistics, and the three actions); check with widget tests for each "Final summary" scenario
- [ ] 10.6 Build the past sessions list, the read-only summary and sheet, the "Cannot be opened" entry, and "Delete" with confirmation; check with widget tests for each scenario of "Past sessions", "Delete a past session", and "Final summary of a past session"
- [ ] 10.7 Show the session settings as read-only after the first deal starts; check with a widget test for the "Settings fixed after start" scenario

## 11. Settings screen

- [ ] 11.1 Build the Settings screen (theme mode, text size, suit colors) with access from the home gear and the deal menu; check with widget tests for each scenario of "Settings screen access", "Theme mode", "Suit colors", and "Settings saved on the device"

## 12. Integration and release checks

- [ ] 12.1 Add layout tests that render each main screen at 360 px width with each text size, and check that no screen reports an overflow
- [ ] 12.2 Add an integration test for a full session of 4 deals with the bidding step on, a game, a rubber, an edit, and an undo; check that the final totals match a total calculated by hand in the test
- [ ] 12.3 Add an integration test that reloads the app at each deal stage and checks that the same stage and data come back
- [ ] 12.4 Run `flutter analyze` and `flutter test`, and check that both pass with no issues
- [ ] 12.5 Run `flutter build web`, `flutter build apk`, and (on macOS) `flutter build ios --no-codesign`, and check that each build completes
- [ ] 12.6 Run `openspec validate add-rubber-bridge-scorekeeper --strict` and check that the change is valid
