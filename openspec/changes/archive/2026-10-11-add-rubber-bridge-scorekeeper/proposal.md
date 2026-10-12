## Why

Rubber bridge players keep score on paper. The rules for trick points, overtricks, undertricks, doubles, redoubles, slams, honors, and rubber bonuses are easy to apply incorrectly, and errors in the score are hard to find afterwards. A cross-platform app that guides each deal step by step and calculates the score from the official rules helps the players keep the score correct.

## What Changes

- Add a new Flutter application that runs on Android, iOS, and web from one code base.
- Add session setup: four player names by seat, partnerships named from their players (for example, "Alice & Carol" for player 1 + player 3), the first dealer, the optional bidding step, and the end rule (a fixed number of deals or a target total score).
- Make every scoring value configurable before the session starts (trick values, overtrick, undertrick, insult, slam, honors, game threshold, rubber and unfinished rubber values). The user selects one of two presets: "Standard" (the standard rubber bridge values, read-only) or "House rules" (values that the user can change and that the app saves on the device). "House rules" starts with the standard values, except for: honors, which use a house pattern (80 for 4 in one hand, 100 for 5 in one hand, 10 for each other honor of the majority side); a rubber bonus of 250 for 2–0 and 2–1; and an unfinished rubber bonus of 125 for one game and 0 for a part-score. The user can restore the "House rules" defaults.
- Add a deal lifecycle with clear stages: deal start → auction (optional) → contract → play → result → scored. Each stage has one clear transition to the next stage.
- Add an optional auction recorder. It shows the four players around a table, shows whose turn it is, permits only legal calls, and finds the final contract, the declarer, and passed-out deals.
- After the contract is set, the app shows the declarer, the dummy, and the player who makes the opening lead.
- Add a rubber bridge scoring engine that calculates, from the configured scoring values, contract points (below the line), overtricks, undertricks (penalties), double and redouble, the insult bonus, small slam and grand slam bonuses, honors, game and part-score tracking, vulnerability, rubber bonuses, and the unfinished rubber bonus.
- When a rubber completes before the end rule applies, the app starts a new rubber. The session total adds the scores of all rubbers.
- Add a score sheet with a deal history. The user can edit or undo a recorded deal, and the app then calculates all totals again.
- Add local storage of sessions and of the "House rules" preset, so that a reload or a restart of the app does not lose the score.
- Use traditional bridge words in the UI: "contract fulfilled", "overtricks", "undertricks", "penalty", "vulnerable", "above the line", "below the line".
- Add a Settings screen for the display: theme mode (System, Light, Dark), text size (Normal, Large, Extra large), and suit colors (two or four colors).
- Use a minimal visual design with a modular architecture. Each module is a separate folder in one Flutter package and communicates with other modules only through defined interfaces.

## Capabilities

### New Capabilities
- `session-setup`: Configuration of a scoring session: player names and seats, partnership names, first dealer, the optional bidding step, the end rule (number of deals or target total), the optional scoring components, and the scoring presets ("Standard" and "House rules").
- `deal-lifecycle`: The stages of one deal, the transitions between the stages, dealer rotation, and the display of declarer, dummy, and opening leader.
- `auction`: The optional record of calls. It covers turn order, legal calls, the end of the auction, passed-out deals, and how the app finds the final contract and the declarer.
- `rubber-scoring`: The calculation of all rubber bridge score components for one deal and for a rubber: trick points, overtricks, undertricks, double/redouble, insult bonus, slam bonuses, honors, games, vulnerability, rubber bonuses, and the unfinished rubber bonus.
- `score-sheet`: The score display for each side (above and below the line), the session totals, the deal history, the edit and undo of a recorded deal, and the session end.
- `app-settings`: The display settings of the app on this device: theme mode, text size, and suit colors.
- `session-persistence`: Local storage of the active session, of past sessions, and of the "House rules" preset on each platform.

### Modified Capabilities
<!-- None. The repository has no specs yet. -->

## Impact

- New Flutter project at the repository root (Dart, Flutter stable channel). Targets: Android, iOS, web. Desktop targets are possible later without code changes to the domain modules.
- New dependencies: a state management package, a local storage package that works on web and mobile, and test packages. The design document names the selections.
- No existing code, API, or system changes. The repository contains only the OpenSpec setup.
- Non-goals for this change: Chicago and duplicate scoring, online multiplayer or sync between devices, user accounts, export of scores, and card-by-card play tracking.
