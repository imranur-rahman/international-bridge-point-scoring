## 1. Name and heading font

- [ ] 1.1 Change the app name to "IB Scoring" in web, Android, iOS, and the UI, the home heading to "International Bridge Scoring", and the descriptions; check with a widget test for the "Home heading" scenario and with `grep` that no app name or description says "IB Score" or "rubber bridge"
- [ ] 1.2 Extend `tool/subset_font.py` to make Montserrat SemiBold and Bold Latin subsets, add them with the OFL file, and declare them in `pubspec.yaml`; check with a test that each file is smaller than 40 KB
- [ ] 1.3 Use Montserrat in the heading text styles of the theme; check with a widget test for the "Section title font" scenario, and that the layout tests at 360 px still pass

## 2. Score strip

- [ ] 2.1 Add the `ScoreStrip` widget and show it in the one-pane deal screen; check with widget tests for "Strip after a part-score", "Strip after a game", "Open the sheet", and "Wide window"
- [ ] 2.2 Check that the strip fits 360 px with each text size, on the deal start, the result, and the quick-entry screens

## 3. Scored stage actions

- [ ] 3.1 Add "Next deal: <player> deals" and "Undo deal" to the scored stage; check with widget tests for "Next dealer" and "Undo from the scored stage", and that the line does not show when the session has ended

## 4. Install action

- [ ] 4.1 Keep the install prompt event in `web/index.html` and add `ibInstallState` and `ibInstall`
- [ ] 4.2 Add the `InstallPrompt` interface with the web and stub implementations, and a provider; check that `flutter test` and `flutter build apk` compile with the stub
- [ ] 4.3 Add the install action and the iPhone guide to the home screen; check with widget tests and a fake `InstallPrompt` for "Install in Chrome", "iPhone guide", and "Installed app"
- [ ] 4.4 Check in Chrome on localhost that the action shows, that it opens the install prompt of Chrome, and that `flutter analyze` and `flutter test` pass
