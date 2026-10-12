## Purpose

Lets the user configure a rubber bridge scoring session before the first deal: the players, the partnerships, the first dealer, the optional bidding step, the end rule, and the optional scoring components.

## ADDED Requirements

### Requirement: Setup in three steps
The setup SHALL be a wizard with three steps, in this order:
1. **Players**: the four player names by seat, the partnership names, and the first dealer.
2. **Game rules**: the end rule, the bidding step, and the optional scoring components.
3. **Scoring**: the selection of "Standard" or "House rules", with a link to view "Standard" or to change "House rules".

The wizard SHALL show the number of the current step and the names of all steps. "Next" SHALL check only the fields of the current step and SHALL not move to the next step while a field has an error. "Back" SHALL return to the previous step and SHALL keep all entered values. Only the last step SHALL have "Start session".

#### Scenario: Error stops Next
- **WHEN** the user is at the "Players" step with an empty name and selects "Next"
- **THEN** the system shows the error at that name and stays at the "Players" step

#### Scenario: Back keeps values
- **WHEN** the user is at the "Scoring" step and selects "Back" twice
- **THEN** the "Players" step shows the names that the user entered

#### Scenario: Start from last step
- **WHEN** the user is at the "Scoring" step with no errors and selects "Start session"
- **THEN** the system starts the session and opens the first deal

### Requirement: Player names by seat
The system SHALL ask for four player names before a session starts. Player 1 SHALL sit North, player 2 East, player 3 South, and player 4 West. Each name MUST contain at least one character that is not a space, and the four names MUST be different (case-insensitive, with leading and trailing spaces removed).

#### Scenario: Valid names
- **WHEN** the user enters "Alice", "Bob", "Carol", and "Dave" as players 1 to 4
- **THEN** the system seats Alice North, Bob East, Carol South, and Dave West

#### Scenario: Empty name
- **WHEN** the user leaves the name of player 3 empty or enters only spaces
- **THEN** the system shows an error at player 3 and does not start the session

#### Scenario: Duplicate name
- **WHEN** the user enters "Alice" for player 1 and "alice " for player 4
- **THEN** the system shows an error that each player needs a different name and does not start the session

### Requirement: Partnerships named from players
The system SHALL form two fixed partnerships for the full session: player 1 with player 3 (North-South), and player 2 with player 4 (East-West). The system SHALL name each partnership with the names of its two players in the format "<player 1> & <player 3>" and "<player 2> & <player 4>", and SHALL use these names everywhere the UI refers to a side.

#### Scenario: Partnership names
- **WHEN** the players are Alice, Bob, Carol, and Dave
- **THEN** the system names the sides "Alice & Carol" and "Bob & Dave"

### Requirement: First dealer selection
The system SHALL let the user select which of the four players deals the first deal. The default first dealer SHALL be player 1.

#### Scenario: Default first dealer
- **WHEN** the user does not change the first dealer
- **THEN** player 1 deals the first deal

#### Scenario: Custom first dealer
- **WHEN** the user selects player 2 as the first dealer
- **THEN** player 2 deals the first deal

### Requirement: End rule configuration
The system SHALL let the user select exactly one end rule for the session:
- **Number of deals**: the session ends after N deals, where N is an integer from 1 to 200.
- **Target score**: the session ends after the deal in which one or both sides reach a session total of at least T points, where T is an integer from 100 to 100000.

The default end rule SHALL be "Number of deals" with N = 16.

#### Scenario: Number of deals selected
- **WHEN** the user selects "Number of deals" and enters 8
- **THEN** the system saves an end rule that stops the session after the 8th deal

#### Scenario: Target score selected
- **WHEN** the user selects "Target score" and enters 3000
- **THEN** the system saves an end rule that stops the session after the deal in which a side reaches 3000 points or more

#### Scenario: Value out of range
- **WHEN** the user enters 0 deals, or a value that is not an integer
- **THEN** the system shows an error and does not start the session

### Requirement: Optional bidding step
The system SHALL let the user switch the bidding step on or off for the session. The default SHALL be off. When the bidding step is on, each deal SHALL use the auction to set the contract. When the bidding step is off, the user SHALL enter the final contract directly.

#### Scenario: Bidding step off
- **WHEN** the user starts a session with the bidding step off
- **THEN** each deal goes from the deal start directly to the contract entry

#### Scenario: Bidding step on
- **WHEN** the user starts a session with the bidding step on
- **THEN** each deal goes from the deal start to the auction

### Requirement: Optional scoring components
The system SHALL let the user switch these scoring components on or off for the session. Each component SHALL default to on:
- Honors
- Unfinished rubber bonus

When a component is off, the system SHALL not ask for it and SHALL not add it to the score.

#### Scenario: Honors off
- **WHEN** the user switches honors off
- **THEN** the result entry does not show the honors input, and no deal scores honors points

#### Scenario: Unfinished rubber bonus off
- **WHEN** the user switches the unfinished rubber bonus off and the session ends during a rubber
- **THEN** the system adds no unfinished rubber bonus

### Requirement: Scoring presets
The system SHALL offer two scoring presets at setup: "Standard" and "House rules". The user SHALL select exactly one preset for the session. The session SHALL copy the scoring values of the selected preset when the session starts.
- "Standard" SHALL hold the standard defaults from the "Scoring values table" requirement of the rubber-scoring capability. The user SHALL not be able to change it.
- "House rules" SHALL hold values that the user can change. On a device where the user never changed "House rules", it SHALL hold the "House rules" defaults from the same table (the standard defaults, except for the honors, rubber, and unfinished rubber values).

The default selection SHALL be the preset of the most recent session that the user started on this device, or "Standard" if no earlier session exists.

#### Scenario: Default preset on first use
- **WHEN** the user starts the first session on a device and does not change the preset
- **THEN** the session uses "Standard" and the standard default for every scoring value

#### Scenario: House rules on first use
- **WHEN** the user opens "House rules" for the first time on a device
- **THEN** the screen shows the "House rules" defaults, with 80 for 4 trump honors in one hand

#### Scenario: House rules used
- **WHEN** "House rules" sets the small slam bonus for a side that is not vulnerable to 400, and the user selects "House rules" and starts the session
- **THEN** every small slam that a side that is not vulnerable makes in this session scores 400 slam bonus points

#### Scenario: Last preset selected
- **WHEN** the most recent session used "House rules" and the user starts a new session
- **THEN** the setup shows "House rules" as the selected preset

#### Scenario: Standard is read-only
- **WHEN** the user opens the "Standard" preset
- **THEN** the system shows all values as read-only

### Requirement: Edit House rules
The system SHALL let the user change every scoring value of "House rules" from the setup screen. The system SHALL save the changed "House rules" on the device for later sessions. Each value MUST be an integer from 0 to 100000. The game threshold MUST be at least 1. A change to "House rules" SHALL not change the scoring values of a session that already started.

#### Scenario: Value not valid
- **WHEN** the user enters -50 or a value that is not an integer for a value in "House rules"
- **THEN** the system shows an error at that value and does not save "House rules"

#### Scenario: Started session keeps its values
- **WHEN** a session started with "House rules" and a rubber bonus of 600, and the user later changes the "House rules" rubber bonus to 800
- **THEN** the started session continues to score 600 for that rubber bonus

### Requirement: House rules screen layout
The "House rules" screen SHALL show the scoring values in these groups, in this order: Trick values, Double and redouble, Game, Slams, Undertricks (penalties), Honors, Rubber. Each group SHALL be collapsible. When the screen opens, the groups that contain a value different from "Standard" SHALL be expanded, and the other groups SHALL be collapsed. A collapsed group SHALL show the number of values in it and a mark when one of its values is different from "Standard". The "Undertricks" group SHALL show a read-only line that says that redoubled values are 2 × the doubled values.

The "Standard" screen SHALL use the same layout, with all values read-only and with no "Save" or "Restore" action.

#### Scenario: Groups on open
- **WHEN** "House rules" holds its defaults and the user opens the screen
- **THEN** only the "Honors" group and the "Rubber" group are expanded

### Requirement: Save House rules
Changes on the "House rules" screen SHALL take effect only when the user selects "Save". "Save" SHALL be disabled while a field has an error. When the user leaves the screen with changes that are not saved, the system SHALL ask whether to discard the changes. The sample calculator SHALL use the values on the screen, also before "Save".

#### Scenario: Leave without save
- **WHEN** the user changes a value and selects "Back" without "Save"
- **THEN** the system asks "Discard changes?", and if the user confirms, "House rules" keeps its earlier values

#### Scenario: Save
- **WHEN** the user changes a value and selects "Save"
- **THEN** the system saves "House rules" on the device and shows the new value the next time the screen opens

### Requirement: Restore House rules defaults
The "House rules" screen SHALL have a "Restore House rules defaults" action that sets all "House rules" values back to the "House rules" defaults, after a confirmation. The screen SHALL mark each value that is different from its "Standard" value, so that the user can see each difference from the Laws.

#### Scenario: Restore
- **WHEN** "House rules" has three changed values and the user confirms "Restore House rules defaults"
- **THEN** all "House rules" values show the "House rules" defaults

#### Scenario: Marks for differences from Standard
- **WHEN** "House rules" holds its defaults
- **THEN** the screen marks the five honors values and the four rubber and unfinished rubber values as different from "Standard", and no other value

### Requirement: Help for each scoring value
The "House rules" screen and the read-only "Standard" screen SHALL show a help button next to each scoring value. When the user taps or clicks the help button, the system SHALL show an overlay next to the value with:
- the traditional name of the value and what it means,
- when the value applies (for example, "only when the contract is doubled and the declaring side is vulnerable"),
- the standard default,
- one short example with the points.

On a device with a mouse, the system SHALL also show a short version of the help text when the pointer stays over the help button. The user SHALL close the overlay with a tap or a click outside it, a close button, or the Escape key. Only one overlay SHALL be open at a time. The help text SHALL also explain the values that the user cannot configure (for example, that redoubled undertricks are 2 × the doubled values).

#### Scenario: Open help
- **WHEN** the user taps the help button next to "Undertrick, doubled, not vulnerable"
- **THEN** the system shows an overlay that explains undertricks, shows the standard values 100 / 200 / 300, and gives the example "4♠ doubled, down 3: 100 + 200 + 200 = 500 for the defenders"

#### Scenario: Close help
- **WHEN** an overlay is open and the user taps outside it
- **THEN** the system closes the overlay

#### Scenario: One overlay at a time
- **WHEN** an overlay is open and the user taps the help button of a different value
- **THEN** the system closes the first overlay and shows the second

### Requirement: Sample calculator for House rules
The "House rules" screen SHALL have a sample calculator. The user SHALL select a contract (level and denomination), the double state, the vulnerability of the declaring side, the tricks that the declarer took, the honors, and whether the deal completes a game or a rubber. The calculator SHALL show each score component and the total for the current "House rules" values, next to the same deal scored with "Standard". The calculator SHALL update the result each time the user changes a value or a sample input. The calculator SHALL not record a deal or change a session.

#### Scenario: Compare with Standard
- **WHEN** "House rules" sets the doubled undertrick, vulnerable, 1st position to 250, and the user enters 4♠ doubled, vulnerable, 9 tricks
- **THEN** the calculator shows "Down 1" with 250 for the defenders in "House rules", next to 200 in "Standard"

#### Scenario: Value that is not valid
- **WHEN** a "House rules" field has a value that is not valid
- **THEN** the calculator shows that it cannot calculate until the value is corrected

### Requirement: Settings fixed after start
The system SHALL not permit changes to the players, the seats, the end rule, the bidding step, the scoring components, or the scoring values after the first deal of the session starts. The system SHALL show these settings as read-only during the session.

#### Scenario: Attempt to change settings during a session
- **WHEN** the session has at least one started deal and the user opens the session settings
- **THEN** the system shows the settings as read-only
