## Why

On a phone, the deal screen shows no score: players must open the score sheet to see the totals, the games, or how many points a side needs for a game, although this matters for the bidding. After a deal is scored, the app does not say who deals next, and a wrong entry needs the menu to undo. The app now works offline and has its own icon, but users must find "Add to Home Screen" in the browser menu by themselves. Last, the app name and its home heading should be "IB Scoring" and "International Bridge Scoring", and headings should look different from normal text.

## What Changes

- A score strip at the top of the deal screen on a phone: the session total of each side, the games won in the current rubber, the points below the line in the current game, and the points each side needs for a game. A tap opens the score sheet.
- The scored stage says who deals next, and has an "Undo deal" action next to "Next deal".
- An "Install IB Scoring" action on the home screen: the system install prompt where the browser offers one (Chrome, Edge, Android), and a short guide on iPhone and iPad. The action hides when the app runs installed.
- The app name changes from "IB Score" to "IB Scoring" on all platforms. The home heading becomes "International Bridge Scoring", and the descriptions no longer say "rubber bridge". The scoring terms (rubber, rubber bonus, unfinished rubber) do not change.
- Headings (page titles, section titles, the contract headline, and the final summary winner line) use the Montserrat font, bundled with the app; normal text stays Roboto.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `app-shell`: The app name changes to "IB Scoring"; adds the install action, the home heading text, and the heading font.
- `deal-lifecycle`: Adds the score strip and the scored-stage actions (next dealer, undo).

## Impact

- `web/index.html` keeps the browser's install prompt event for the app. A small Dart file with a conditional import calls it on web and does nothing on other platforms and in tests.
- New font assets `assets/fonts/Montserrat-SemiBold.ttf` and `Montserrat-Bold.ttf` (static, Latin subset, SIL Open Font License), made by `tool/subset_font.py`.
- Name changes in `web/`, `android/`, `ios/`, and the UI. The icon does not change.
- No change to the scoring rules, the stored data, or the other modules.
