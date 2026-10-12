## 1. Demo data

- [x] 1.1 Add `ScoringDemo` and `DemoStep`, and a demo script for each of the 34 scoring values; check with a test that each field has a demo with 1 to 3 steps
- [x] 1.2 Add the step replay with `RubberLedger` and the unfinished rubber bonus for session-end demos; check with a test that each demo changes its final totals when its field value changes, and that each highlighted component has points in the last step with the standard values

## 2. Demo UI

- [x] 2.1 Add the demo dialog with the step text, the highlighted breakdown, the small score sheet, and "Back", "Next", and "Done"; check with widget tests for the "Step through a demo" and "Unfinished rubber demo" scenarios
- [x] 2.2 Add "Show demo" to the help overlay, with the values on the screen and a disabled state for values that are not valid; check with widget tests for the "Open a demo", "Demo uses the values on the screen", and "Value that is not valid" scenarios
- [x] 2.3 Check that the demo dialog has no overflow at 360 px with each text size, and that `flutter analyze` and `flutter test` pass
