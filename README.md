# Shelf Jam

Shelf Jam is a cozy SwiftUI casual puzzle MVP for iOS 17+. Players move cute shelf items between slots, clear adjacent groups of three or more identical items, and try to finish each handcrafted level with moves to spare.

## Rules

- Tap an item to select it, then tap an empty slot to move it.
- Each valid move costs 1 move.
- Three or more identical adjacent items on the same shelf clear after a move.
- Match scoring is 100 for 3, 180 for 4, and 280 for 5 items.
- Multiple matches from one move apply combo multipliers: x1, x1.5, or x2.
- Combos of 2 or more grant +1 move.
- Win by clearing every item from the shelves.
- Lose when moves reach zero before the board is cleared.
- Stars are based on remaining moves: 3 stars at 40%+, 2 stars at 20%+, otherwise 1.

## Architecture

The app follows MVVM with small, testable rule services:

- `Models/` contains shelf items, levels, positions, move records, themes, and result state.
- `ViewModels/` owns screen state and gameplay commands.
- `Views/` contains SwiftUI screens and reusable components.
- `Services/` contains level data, match resolution, progress persistence, sound, haptics, and future monetization boundaries.
- `Utilities/` contains shared styling constants and lightweight helpers.

Local progress is stored behind `ProgressStore` using `UserDefaultsProgressStore`, keeping the persistence implementation replaceable.

## How To Run

1. Open `ShelfJam.xcodeproj` in Xcode.
2. Select the `ShelfJam` scheme.
3. Choose an iOS 17+ simulator or device.
4. Build and run.

To run logic tests, select the `ShelfJam` scheme and press `Command-U`, or run:

```sh
xcodebuild test -scheme ShelfJam -destination 'platform=iOS Simulator,name=iPhone 17'
```

## MVP Contents

- Main menu, level select, game, settings, complete, and failed screens.
- 20 handcrafted levels.
- Move limits, scoring, combos, stars, and local best score/star persistence.
- Limited undo.
- Hint and shuffle placeholders.
- Haptic and sound hooks.
- Unit tests for core game rules.

## Future Roadmap

- Online leaderboard
- Cosmetic shelf themes
- Cloud save
- Locked items
- Hidden boxes
- Joker items
- Frozen shelves
- Special objectives
