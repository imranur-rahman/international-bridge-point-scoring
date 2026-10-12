## Context

See proposal.md for the motivation and `specs/session-setup/spec.md` for the requirement. The help overlay (`HelpButton`) and the 34 help texts already exist in the `ui` module.

## Decisions

### D1. Demo scripts are data in the `ui` module

A `ScoringDemo` holds the field, a title, a list of `DemoStep`s (a `DealResult?` and one line of text), the score component to highlight, and an `endsSession` flag. One map gives a demo for each of the 34 fields. The demos are teaching content, not rules, so they live in `ui`. They contain no score numbers and no claims about results that depend on the values. The text says what the players do ("Carol fulfills 4♠, usually a game"). The dialog adds the vulnerability, the games, and the rubbers from the replay, so a changed House rules value (for example a game threshold of 150) shows a correct outcome.

### D2. The real ledger calculates each step

Step N replays the first N deals with `RubberLedger.replay` and the values on the screen. The demo therefore always shows the same numbers as a real session, also for changed House rules values. For a demo with `endsSession`, the last step adds `LedgerSnapshot.unfinishedRubberBonus()`.

### D3. A test proves that each demo shows its value

For each field, a test replays the demo with the standard values and with the field value + 7, and checks that the final totals differ. This proves that each demo exercises its value. A second test checks that each highlighted component has points in the last step.

### D4. UI

The demo opens in a dialog that is at most 560 logical pixels wide and scrolls on a small screen. It reuses `PaperSheet` for the small score sheet. The breakdown highlights the rows of the demonstrated component with the primary container color and a "This value" label. `HelpButton` gets an optional `onDemo` callback; the House rules screen passes null when a value is not valid, and the overlay then shows a disabled button.

## Risks / Trade-offs

- [A House rules value of 0 makes the highlighted row empty] → The demo then says "This value is 0 in these values, so it adds no points."
