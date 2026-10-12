# app-settings Specification

## Purpose

Lets the user change how the app looks on this device: the theme mode, the text size, and the suit colors. These settings change only the display, never the score.

## Requirements

### Requirement: Settings screen access
The system SHALL have one Settings screen. A gear icon on the home screen and an item in the menu of the deal screen SHALL open it. A change on the Settings screen SHALL apply at once, with no "Save" action, and SHALL not change the active session or its deal stage.

#### Scenario: Open from the deal screen
- **WHEN** the user is at the result stage of a deal and opens Settings from the menu
- **THEN** the system shows the Settings screen, and after the user returns, the deal is still at the result stage with the same entered data

### Requirement: Theme mode
The Settings screen SHALL let the user select one theme mode: "System", "Light", or "Dark". The default SHALL be "System". With "System", the app SHALL follow the light or dark setting of the device or the browser, and SHALL change when that setting changes. The app SHALL use one fixed accent color, the green of a card table, in both light and dark themes.

#### Scenario: Default
- **WHEN** the user opens the app for the first time on a device that uses dark mode
- **THEN** the app shows the dark theme

#### Scenario: Dark selected
- **WHEN** the user selects "Dark" and the device uses light mode
- **THEN** the app shows the dark theme

### Requirement: Text size
The Settings screen SHALL let the user select the text size of the app: "Normal", "Large", or "Extra large". The default SHALL be "Normal". The app text size SHALL apply in addition to the text size of the device. At each text size, all screens SHALL show all text and buttons with no cut-off text and no horizontal scroll at a width of 360 logical pixels.

#### Scenario: Extra large on a phone
- **WHEN** the user selects "Extra large" on a phone that is 360 logical pixels wide
- **THEN** the auction bidding box, the result buttons, and the score sheet show all their text with no horizontal scroll of the page

### Requirement: Suit colors
The Settings screen SHALL let the user select the suit colors: "Two colors" (♥ and ♦ red, ♣ and ♠ in the text color) or "Four colors" (♣ green, ♦ orange, ♥ red, ♠ in the text color). The default SHALL be "Two colors". The selected colors SHALL apply in each place where the app shows a suit symbol. Each suit color SHALL have a contrast ratio of at least 4.5:1 with its background in the light theme and in the dark theme.

#### Scenario: Four colors
- **WHEN** the user selects "Four colors"
- **THEN** the auction, the contract, the history, and the score sheet show ♣ in green and ♦ in orange

### Requirement: Settings saved on the device
The system SHALL save the theme mode, the text size, and the suit colors on the device, and SHALL apply them the next time the app starts. These settings SHALL not be part of a session.

#### Scenario: Restart
- **WHEN** the user selects "Dark" and "Large" and restarts the app
- **THEN** the app starts with the dark theme and the large text size
