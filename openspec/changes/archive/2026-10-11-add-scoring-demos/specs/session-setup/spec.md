## ADDED Requirements

### Requirement: Demo game for each scoring value
The help overlay of each of the 34 scoring values SHALL have a "Show demo" action. The action SHALL close the overlay and open a demo game for that value. A demo game SHALL be a scripted sequence of 1 to 3 deals with fixed example players, and it SHALL show these deals one step at a time:
- the deal number, the contract with its declarer, and the result,
- one line of text that says what happens in this step,
- the score breakdown of the deal, with the points that come from the demonstrated value highlighted,
- a small score sheet with the points above and below the line up to this step.

When the demonstrated value applies at the end of a session (the unfinished rubber bonus), the last step SHALL show the session end and the unfinished rubber bonus.

The demo SHALL have "Back", "Next", and "Done" actions. The demo SHALL use the values on the screen: on "House rules", the values as entered, also before "Save"; on "Standard", the standard values. When a value on the "House rules" screen is not valid, the "Show demo" action SHALL be disabled with the text that the values must be corrected first. A demo SHALL not record a deal or change a session.

#### Scenario: Open a demo
- **WHEN** the user opens the help overlay of "Rubber bonus, 2 games to 1" and selects "Show demo"
- **THEN** the system closes the overlay and shows step 1 of the demo

#### Scenario: Step through a demo
- **WHEN** the demo of "Rubber bonus, 2 games to 1" with the standard values is at step 3 of 3
- **THEN** the system shows that one side won the rubber 2 games to 1, and the breakdown highlights "Rubber bonus: 500"

#### Scenario: Demo uses the values on the screen
- **WHEN** the user changes "Rubber bonus, 2 games to 1" to 400 on the "House rules" screen without "Save" and opens its demo
- **THEN** the demo highlights "Rubber bonus: 400"

#### Scenario: Unfinished rubber demo
- **WHEN** the user opens the demo of "Unfinished rubber, one game won"
- **THEN** the last step shows the session end and the unfinished rubber bonus for the side with one game

#### Scenario: Value that is not valid
- **WHEN** a value on the "House rules" screen is not valid and the user opens a help overlay
- **THEN** the "Show demo" action is disabled
