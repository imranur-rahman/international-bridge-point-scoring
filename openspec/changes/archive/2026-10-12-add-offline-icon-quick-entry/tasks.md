## 1. Offline web app

- [x] 1.1 Add `web/sw.js` (cache first, one cache for each `BUILD_ID`, complete background update, no `skipWaiting`) and register it in `web/index.html`; set `BUILD_ID` to the commit id in the deploy workflow; check that `flutter build web` copies it to `build/web`
- [x] 1.2 Check in Chrome with a local server: open the app once, stop the server, and reload (the app must open with the active session); then build with a new `BUILD_ID`, open twice, and check that the second open shows the new version
- [x] 1.3 Add `tool/subset_font.py` and replace the suit font with a subset of the four suit glyphs; check with a test that the font file is smaller than 20 KB and with a look in Chrome that the suits still show

## 2. App icon and colors

- [x] 2.1 Add `tool/make_icons.py` and make the icon files for web, Android, and iOS; check the sizes of the files and that the iOS icons have no transparency
- [x] 2.2 Set the felt green as `theme_color` and `background_color` in `web/manifest.json`; check that the web build shows the new favicon in Chrome, and that `flutter build apk` and `flutter build ios --no-codesign` complete

## 3. Even result screen

- [x] 3.1 Change `ResultPicker` to an even grid of 2 rows × 7 equal cells, colored by group, with the full result line in the group color; check with widget tests for "Buttons for a game contract", "Even grid on a phone" (all cells the same width at 360 px), and "No overtrick at the grand slam"
- [x] 3.2 Change `HonorsPicker` to a side choice with two equal halves and the holdings in rows of two equal cells; check with a widget test that the cells of one row have the same width
- [x] 3.3 Check the result screen at 360 px with each text size for overflow, and look at it in Chrome in the light and dark theme

## 4. Visual emphasis

- [x] 4.1 Set the text weights in the theme and the primary color in `SectionTitle`; check with a widget test that page and section titles are bold and that section titles use the primary color
- [x] 4.2 Use the theme styles for the key values and the current items on each page (contract headline, full result, play roles, totals rows, winner line, breakdown items, demo step); check with widget tests for each scenario of "Visual emphasis of important information"
- [x] 4.3 Check that the primary color and each bold text keep a contrast of at least 4.5:1 in both themes, and look at each main page in Chrome in the light and dark theme

## 5. Quick entry

- [x] 5.1 Add `quickEntry` to `SessionSettings` with JSON and the missing-value default; check with tests for the round trip and for an older stored session
- [x] 5.2 Add the `entry` stage and the `RecordQuickDeal` command, with the start, next-deal, and undo behavior; check with session tests that a quick deal records the same result as the full stages, that a passed-out quick deal works, and that the end rule still applies
- [x] 5.3 Add the "Quick entry" switch to the "Game rules" setup step and to the read-only session settings; check with widget tests for each scenario of "Quick entry option"
- [x] 5.4 Build the quick-entry screen; check with widget tests for each scenario of "Quick-entry screen" and "Deal with quick entry"
- [x] 5.5 Check that the quick-entry screen has no overflow at 360 px with each text size, and that `flutter analyze` and `flutter test` pass
