## Why

A help text explains a scoring value in words, but players learn faster when they see the value act in a real game. A short demo game for each value shows when the value applies, which side gets the points, and where the points go on the score sheet.

## What Changes

- Add a "Show demo" button to the help overlay of each of the 34 scoring values, on the "House rules" screen and on the "Standard" screen.
- A demo is a scripted mini game of 1 to 3 deals with fixed example players. The user goes through it step by step with "Next" and "Back".
- Each step shows the deal and its result, one line of explanation, the score breakdown of that deal with the points of the value highlighted, and a small score sheet.
- The demo uses the values on the screen: on "House rules" it uses the values as entered (also before "Save"), on "Standard" it uses the standard values.

## Capabilities

### New Capabilities
<!-- None. -->

### Modified Capabilities
- `session-setup`: Adds a requirement for a demo game for each scoring value, opened from its help overlay.

## Impact

- New UI code in the `ui` module: the demo scripts for the 34 values and a demo dialog. The demos use the existing `RubberLedger` and `DealScorer`, so they always match the real scoring.
- The help button gets an optional "Show demo" action.
- No change to stored data, scoring rules, or other modules.
