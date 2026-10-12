## ADDED Requirements

### Requirement: Score strip on the deal screen
When the deal screen shows without the score sheet beside it (a window narrower than 900 logical pixels), the system SHALL show a score strip above the deal stages. The strip SHALL show for each side:
- the session total (without the unfinished rubber bonus),
- the games won in the current rubber,
- the points below the line in the current game,
- the points it needs for a game: the game threshold minus its points below the line in the current game, as "needs N for game".

The strip SHALL update right after each scored deal, undo, or edit. A tap on the strip SHALL open the score sheet. The strip SHALL fit a 360 logical pixel wide screen at each text size.

#### Scenario: Strip after a part-score
- **WHEN** "Alice & Carol" fulfilled 2♠ (60 below the line) in a new rubber with the standard values
- **THEN** the strip shows "Alice & Carol" with 60, games 0, and "needs 40 for game", and "Bob & Dave" with 0, games 0, and "needs 100 for game"

#### Scenario: Strip after a game
- **WHEN** "Alice & Carol" won a game with 4♠
- **THEN** the strip shows games 1 for "Alice & Carol", and both sides need 100 for the next game

#### Scenario: Open the sheet
- **WHEN** the user taps the score strip on a phone
- **THEN** the system opens the score sheet

#### Scenario: Wide window
- **WHEN** the window is 900 logical pixels wide or wider
- **THEN** the system shows the score sheet beside the deal and no score strip

### Requirement: Scored stage actions
When a deal is scored and the session has not ended, the scored stage SHALL show "Next deal: <player> deals" with the name and seat of the next dealer. Next to "Next deal", the scored stage SHALL show an "Undo deal" action. After a confirmation, it SHALL undo the deal as the "Undo last deal" requirement of the score-sheet capability defines, and SHALL return to the first stage of that deal.

#### Scenario: Next dealer
- **WHEN** Alice (North) dealt the deal that was just scored
- **THEN** the scored stage shows "Next deal: Bob (East) deals"

#### Scenario: Undo from the scored stage
- **WHEN** the user selects "Undo deal" at the scored stage and confirms
- **THEN** the deal is removed, the totals return to their earlier values, and the same dealer starts the deal again
