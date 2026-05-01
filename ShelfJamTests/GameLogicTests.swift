import XCTest
@testable import ShelfJam

final class GameLogicTests: XCTestCase {
    func testLevelProviderHasExpandedLevelSet() {
        XCTAssertGreaterThanOrEqual(StaticLevelProvider().levels.count, 60)
    }

    func testAllHandcraftedLevelsHaveClearableItemCounts() {
        let levels = StaticLevelProvider().levels

        for level in levels {
            let counts = itemCounts(in: level)
            for (type, count) in counts {
                XCTAssertGreaterThanOrEqual(
                    count,
                    3,
                    "Level \(level.id) has only \(count) \(type.rawValue) item(s), which cannot be cleared by match-3 rules."
                )
                XCTAssertEqual(
                    count % 3,
                    0,
                    "Level \(level.id) has \(count) \(type.rawValue) items; every type must appear in clearable groups of three."
                )
            }
        }
    }

    func testHandcraftedLevelsAfterTutorialDoNotStartWithMatches() {
        let levels = StaticLevelProvider().levels.dropFirst()
        let resolver = MatchResolver()

        for level in levels {
            XCTAssertTrue(
                resolver.findMatches(in: level.shelves).isEmpty,
                "Level \(level.id) starts with an automatic match."
            )
        }
    }

    func testAllHandcraftedLevelsUseFiveSlotsPerShelf() {
        let levels = StaticLevelProvider().levels

        for level in levels {
            for shelf in level.shelves {
                XCTAssertEqual(
                    shelf.count,
                    GameConstants.defaultSlotCount,
                    "Level \(level.id) has a shelf with \(shelf.count) slots."
                )
            }
        }
    }

    func testSelectingUnlockedItemSetsSelectedPosition() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ])

        let position = Position(shelfIndex: 0, slotIndex: 0)
        viewModel.selectItem(at: position)

        XCTAssertEqual(viewModel.selectedPosition, position)
    }

    func testTappingSelectedItemAgainClearsSelection() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ])

        let position = Position(shelfIndex: 0, slotIndex: 0)
        viewModel.selectItem(at: position)
        viewModel.selectItem(at: position)

        XCTAssertNil(viewModel.selectedPosition)
    }

    func testMovingItemFromOneSlotToEmptySlot() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ])

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))

        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0)))
        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 1))?.type, .apple)
    }

    func testCannotMoveToOccupiedSlot() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, .car, nil, .book, .cup)
        ])

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))

        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0))?.type, .apple)
        XCTAssertEqual(viewModel.movesLeft, 10)
    }

    func testCannotSelectLockedItem() {
        var locked = item(.apple)
        locked.isLocked = true
        let viewModel = makeViewModel(shelves: [
            [locked, nil, item(.car), item(.book), item(.cup)]
        ])

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))

        XCTAssertNil(viewModel.selectedPosition)
    }

    func testDetectThreeAdjacentSameItems() {
        let matches = MatchResolver().findMatches(in: [
            row(.apple, .apple, .apple, .car, nil)
        ])

        XCTAssertEqual(matches, [MatchGroup(shelfIndex: 0, slotIndexes: [0, 1, 2], itemType: .apple)])
    }

    func testDetectFourAdjacentSameItems() {
        let matches = MatchResolver().findMatches(in: [
            row(.apple, .apple, .apple, .apple, nil)
        ])

        XCTAssertEqual(matches.first?.slotIndexes, [0, 1, 2, 3])
    }

    func testDoesNotDetectNonAdjacentSameItems() {
        let matches = MatchResolver().findMatches(in: [
            row(.apple, .apple, .car, .apple, .apple)
        ])

        XCTAssertTrue(matches.isEmpty)
    }

    func testClearMatchedItems() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, .apple, .apple, .car, nil)
        ])

        viewModel.clearMatches()

        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0)))
        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 1)))
        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 2)))
        XCTAssertEqual(viewModel.score, 100)
    }

    func testMoveThatCreatesMatchClearsItems() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, .apple, nil, .car, nil),
            row(nil, nil, .apple, nil, nil)
        ])

        viewModel.selectItem(at: Position(shelfIndex: 1, slotIndex: 2))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 2))

        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0)))
        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 1)))
        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 2)))
        XCTAssertEqual(viewModel.score, 100)
    }

    func testMovesDecreaseAfterValidMove() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ])

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))

        XCTAssertEqual(viewModel.movesLeft, 9)
    }

    func testMovesDoNotDecreaseAfterInvalidMove() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, .car, nil, .book, .cup)
        ])

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))

        XCTAssertEqual(viewModel.movesLeft, 10)
    }

    func testStarsCalculation() {
        XCTAssertEqual(GameViewModel.calculateStars(movesLeft: 4, moveLimit: 10), 3)
        XCTAssertEqual(GameViewModel.calculateStars(movesLeft: 2, moveLimit: 10), 2)
        XCTAssertEqual(GameViewModel.calculateStars(movesLeft: 1, moveLimit: 10), 1)
    }

    func testUndoRestoresPreviousState() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ])

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))
        viewModel.undo()

        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0))?.type, .apple)
        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 1)))
        XCTAssertEqual(viewModel.movesLeft, 10)
    }

    func testHintSelectsMoveThatCreatesMatch() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, .apple, nil, .car, nil),
            row(nil, nil, .apple, nil, nil)
        ])

        viewModel.useHint()

        XCTAssertEqual(viewModel.selectedPosition, Position(shelfIndex: 1, slotIndex: 2))
        XCTAssertTrue(viewModel.hintPositions.contains(Position(shelfIndex: 0, slotIndex: 2)))
        XCTAssertEqual(viewModel.hintUsesLeft, GameConstants.maxHintUses - 1)
    }

    func testShuffleReordersItemsWithoutSpendingMove() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, .car, .book, .cup, nil),
            row(nil, nil, nil, nil, nil)
        ])
        let beforeTypes = viewModel.shelves.flatMap { $0 }.compactMap { $0?.type }.sorted { $0.rawValue < $1.rawValue }

        viewModel.shuffle()
        let afterTypes = viewModel.shelves.flatMap { $0 }.compactMap { $0?.type }.sorted { $0.rawValue < $1.rawValue }

        XCTAssertEqual(beforeTypes, afterTypes)
        XCTAssertEqual(viewModel.movesLeft, 10)
        XCTAssertEqual(viewModel.shuffleUsesLeft, GameConstants.maxShuffleUses - 1)
    }

    func testFailWhenMovesReachZero() {
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            moveLimit: 1
        )

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))

        XCTAssertEqual(viewModel.status, .failed)
    }

    func testCompleteWhenBoardIsEmpty() {
        let viewModel = makeViewModel(
            shelves: [
                row(.apple, .apple, nil, nil, nil),
                row(nil, nil, .apple, nil, nil)
            ],
            moveLimit: 3
        )

        viewModel.selectItem(at: Position(shelfIndex: 1, slotIndex: 2))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 2))

        if case .completed(let stars, let finalScore) = viewModel.status {
            XCTAssertEqual(stars, 3)
            XCTAssertGreaterThan(finalScore, 0)
        } else {
            XCTFail("Expected level to complete.")
        }
    }

    func testFailConsumesOneLife() {
        let store = InMemoryProgressStore()
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            moveLimit: 1,
            progressStore: store
        )

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))

        XCTAssertEqual(store.lives, GameConstants.maxLives - 1)
        XCTAssertEqual(viewModel.lives, GameConstants.maxLives - 1)
    }

    func testCompletionAwardsDiamondsForStarImprovement() {
        let store = InMemoryProgressStore()
        let viewModel = makeViewModel(
            shelves: [
                row(.apple, .apple, nil, nil, nil),
                row(nil, nil, .apple, nil, nil)
            ],
            moveLimit: 3,
            progressStore: store
        )

        viewModel.selectItem(at: Position(shelfIndex: 1, slotIndex: 2))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 2))

        XCTAssertEqual(store.diamonds, GameConstants.diamondReward(for: 3))
        XCTAssertEqual(viewModel.earnedDiamonds, GameConstants.diamondReward(for: 3))
    }

    private func makeViewModel(
        shelves: [[ShelfItem?]],
        moveLimit: Int = 10,
        progressStore: InMemoryProgressStore = InMemoryProgressStore()
    ) -> GameViewModel {
        let level = ShelfLevel(
            id: 999,
            title: "Test",
            shelves: shelves,
            moveLimit: moveLimit,
            difficulty: .easy,
            targetScore: nil,
            theme: .kitchen,
            unlockRequirement: nil
        )

        return GameViewModel(
            level: level,
            progressStore: progressStore,
            haptics: NoopHapticsManager(),
            sound: NoopSoundManager()
        )
    }

    private func itemCounts(in level: ShelfLevel) -> [ShelfItemType: Int] {
        var counts: [ShelfItemType: Int] = [:]
        for item in level.shelves.flatMap({ $0 }).compactMap({ $0 }) {
            counts[item.type, default: 0] += 1
        }
        return counts
    }
}

private final class InMemoryProgressStore: ProgressStore {
    var bestScores: [Int: Int] = [:]
    var bestStars: [Int: Int] = [:]
    var highestUnlockedLevel = 1
    var isSoundEnabled = true
    var isHapticsEnabled = true
    var lives = GameConstants.maxLives
    var diamonds = 0

    func getBestScore(levelID: Int) -> Int {
        bestScores[levelID, default: 0]
    }

    func saveBestScore(levelID: Int, score: Int) {
        bestScores[levelID] = max(score, bestScores[levelID, default: 0])
    }

    func getBestStars(levelID: Int) -> Int {
        bestStars[levelID, default: 0]
    }

    func saveBestStars(levelID: Int, stars: Int) {
        bestStars[levelID] = max(stars, bestStars[levelID, default: 0])
    }

    func getHighestUnlockedLevel() -> Int {
        highestUnlockedLevel
    }

    func unlockNextLevel(after levelID: Int) {
        highestUnlockedLevel = max(highestUnlockedLevel, levelID + 1)
    }

    func resetProgress() {
        bestScores = [:]
        bestStars = [:]
        highestUnlockedLevel = 1
        lives = GameConstants.maxLives
        diamonds = 0
    }

    func getLives() -> Int {
        lives
    }

    func loseLife() {
        lives = max(0, lives - 1)
    }

    func getDiamonds() -> Int {
        diamonds
    }

    func addDiamonds(_ amount: Int) {
        diamonds += amount
    }

    func spendDiamondsForLife() -> Bool {
        guard lives < GameConstants.maxLives, diamonds >= GameConstants.lifeDiamondCost else { return false }
        diamonds -= GameConstants.lifeDiamondCost
        lives += 1
        return true
    }
}
