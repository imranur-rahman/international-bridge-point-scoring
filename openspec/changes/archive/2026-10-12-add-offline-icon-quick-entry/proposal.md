## Why

Players use the app at a card table, often with a weak network or none. The web app now needs a network each time it opens, although all scores are on the device: Flutter's service worker in this version removes itself and caches nothing. The installed app also shows the Flutter logo and Flutter blue, so players do not find it on their home screen as "IB Score". Each deal takes six stages of taps when the bidding step is off; many tables want to record a played deal in one screen. Last, most text on the pages has the same weight: headings, totals, and names look almost like body text, so the important parts do not stand out.

## What Changes

- The web app works offline after the first visit and opens at once on later visits: a service worker keeps a complete copy of the app for each version, opens the app from it, and gets a new version in the background.
- The first visit downloads about 15% less: the suit symbol font keeps only the four suit glyphs (0.54 MB → a few KB).
- A new app icon (a white ♠ and "IB" on felt green) for web (favicon, home screen, maskable icons), Android, and iOS. The web manifest uses the felt green for its theme and background colors.
- An even result screen: all 14 results in a grid of 2 rows × 7 equal cells, colored by group (undertricks, made, overtricks), with no sideways scroll, and the honors in an even 2-column grid.
- A clear visual order on each page: bold headings, bold key values (contracts, results, totals, the winner), and a highlighted current item.
- A session option "Quick entry" in the "Game rules" setup step. It is available when the bidding step is off. With it on, one screen records the contract, the declarer, the result, and the honors of a deal, and shows the dummy and the opening leader.

## Capabilities

### New Capabilities
- `app-shell`: How the web app loads and installs (offline use after the first visit, fast start, updates, the app name, icon, and colors) and the visual order of the text on its pages.

### Modified Capabilities
- `session-setup`: Adds the session option "Quick entry".
- `deal-lifecycle`: The deal stages change when quick entry is on; adds the quick-entry screen; the result buttons show in an even grid.

## Impact

- New `web/sw.js` and a registration in `web/index.html`. Only the web build uses it. The deploy workflow writes the commit id into `sw.js`, so each deployment has its own cache.
- `assets/fonts/NotoSansSymbols2-Regular.ttf` becomes a subset with the four suit glyphs, made by a script in `tool/`.
- New icon files in `web/`, `web/icons/`, `android/app/src/main/res/mipmap-*/`, and `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, made by a script in `tool/`.
- `SessionSettings` gets a `quickEntry` value with a default of off. Stored sessions without it read as off, so no data migration is necessary.
- The session controller gets one command that records a complete deal from the quick-entry screen. The scoring rules do not change.
