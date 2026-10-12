## MODIFIED Requirements

### Requirement: App name, icon, and colors
The installed app SHALL have the name "IB Scoring" and an icon that shows a white ♠ above the letters "IB" on felt green with rounded corners. The web app SHALL use this icon for the browser tab, for "Add to Home Screen", and as a maskable icon whose ♠ and letters stay inside the safe zone. The Android and iOS builds SHALL use the same icon. The web manifest SHALL use the felt green as its theme color and background color. The home screen of the app SHALL show the heading "International Bridge Scoring". The app name, the home heading, and the descriptions of the app SHALL not use the words "rubber bridge"; the scoring terms "rubber", "rubber bonus", and "unfinished rubber" SHALL stay.

#### Scenario: Add to Home Screen
- **WHEN** the user adds the web app to the home screen of a phone
- **THEN** the home screen shows the IB Scoring icon with the name "IB Scoring"

#### Scenario: Browser tab
- **WHEN** the user opens the web app in a browser
- **THEN** the tab shows the IB Scoring icon and the title "IB Scoring"

#### Scenario: Home heading
- **WHEN** the user opens the home screen
- **THEN** the app bar shows "IB Scoring" and the heading shows "International Bridge Scoring"

## ADDED Requirements

### Requirement: Install action
The home screen SHALL show an "Install IB Scoring" action when the app runs in a browser and is not installed:
- When the browser offers an install prompt for the app (for example Chrome, Edge, or Chrome on Android), the action SHALL show that prompt.
- On iPhone and iPad, where the browser offers no prompt, the action SHALL show a short guide: tap Share, then "Add to Home Screen".
- In other browsers with no prompt, the action SHALL not show.

The action SHALL not show when the app runs installed (as a home screen app or as an Android or iOS build), and SHALL hide after the user installs the app from the prompt.

#### Scenario: Install in Chrome
- **WHEN** the user opens the web app in Chrome, and Chrome offers an install prompt
- **THEN** the home screen shows "Install IB Scoring", and a tap shows the install prompt of Chrome

#### Scenario: iPhone guide
- **WHEN** the user opens the web app in Safari on an iPhone
- **THEN** a tap on "Install IB Scoring" shows the guide "Tap Share, then Add to Home Screen"

#### Scenario: Installed app
- **WHEN** the app runs from the home screen
- **THEN** the home screen does not show the install action

### Requirement: Heading font
Page titles, section titles, the contract headline, and the winner line of the final summary SHALL use the Montserrat font. Normal text, buttons, and values SHALL keep the default font. The app SHALL bundle the heading font, so that headings look the same offline. The heading font SHALL keep the weights of the "Visual emphasis of important information" requirement.

#### Scenario: Section title font
- **WHEN** the user opens the setup step "Game rules"
- **THEN** the section title "End rule" uses Montserrat, and the text "Number of deals" uses the default font
