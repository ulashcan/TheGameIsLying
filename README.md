# The Game Is Lying

A fast-paced SwiftUI mobile game built around deceptive text and button choices. Do not blindly trust the instructions!

## Overview
**The Game Is Lying** is a portrait iOS puzzle game where the core mechanic revolves around deception. The game presents instructions, but following them blindly often leads to failure. Players must deduce the truth behind the text and button prompts to advance.

## Gameplay
The gameplay loop consists of rapid-fire rounds. Each level presents a prompt and a set of interactions (buttons, gestures). The player must quickly interpret whether the game is telling the truth or lying, and perform the correct action to proceed to the next level. A single mistake breaks the streak.

## Features
- **Fast gameplay rounds:** Quick, bite-sized levels designed for rapid progression and replayability.
- **Text/button-based traps:** Tricky UI elements that deceive the player.
- **Multiple levels:** 30 data-driven levels with varying mechanics.
- **Progression & Persistence:** Tracks your current level and state across sessions.
- **Retry/continue mechanics:** Watch simulated rewarded ads (local stubs) to continue after failing.
- **Audio:** Haptic feedback and sound effects for interactions, success, and failure.
- **Accessibility:** Built-in accessibility support for game elements.
- **Daily Challenges:** Unique daily scenarios to keep players coming back.

## Tech Stack
- Swift
- SwiftUI
- Xcode
- iOS 17+

## Project Structure
- `TheGameIsLying/Game/Core`: Core game engine and session state.
- `TheGameIsLying/Game/Levels`: Data-driven level catalog.
- `TheGameIsLying/Game/Views`: SwiftUI views for Gameplay, Home, and Results.
- `TheGameIsLying/Game/Ads`: Local AdMob stub for rewarded continues.
- `TheGameIsLying/Game/Services`: Persistence, Audio, and Daily Challenges.
- `scripts/`: Utilities for generating the project and running tests.

## Installation
To run the project locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/ulashcan/TheGameIsLying.git
   ```
2. Navigate to the project directory and open the Xcode project:
   ```bash
   cd TheGameIsLying
   open TheGameIsLying.xcodeproj
   ```
3. Select an iPhone Simulator (iOS 17+) or a connected physical device.
4. Press **Run** (Cmd + R).
   *Note: If running on a physical device, ensure you have set your Development Team in the Signing & Capabilities tab.*

## Testing
The project includes both Unit and UI tests.
- **Unit Tests:** Verify game engine invariants, session state, level catalog, and services.
- **UI Tests:** Automate campaign playthroughs and UI flows.

Run the verification script to execute tests (Simulator checks pass):
```bash
# Run Unit Tests
./scripts/verify_mvp.sh

# Run UI Tests
RUN_UI=1 ./scripts/verify_mvp.sh
```

## License
No open-source license is currently provided. All rights reserved by the author. A definitive open-source license (e.g., MIT, GPL) must be added if you wish to allow others to freely modify or distribute this code.
