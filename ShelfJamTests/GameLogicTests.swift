import XCTest
@testable import ShelfJam

final class GameLogicTests: XCTestCase {
    func testLevelProviderHasExpandedLevelSet() {
        XCTAssertGreaterThanOrEqual(StaticLevelProvider().levels.count, 60)
    }

    func testGeneratedLevelsDoNotUseBombItems() {
        for level in StaticLevelProvider().levels {
            XCTAssertFalse(
                level.shelves.flatMap { $0 }.compactMap { $0 }.contains { $0.isBomb },
                "Level \(level.id) still contains a bomb item."
            )
        }
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
            }
        }
    }

    func testLevelsWithoutSpecialClearersUseMatchableItemCounts() {
        let levels = StaticLevelProvider().levels.filter { level in
            level.shelves.flatMap { $0 }.compactMap { $0 }.allSatisfy { !$0.isBomb && !$0.isJoker }
        }

        for level in levels {
            let counts = itemCounts(in: level)
            for (type, count) in counts {
                XCTAssertEqual(
                    count % 3,
                    0,
                    "Level \(level.id) leaves \(count) \(type.rawValue) item(s). Without bombs/jokers, each type must be divisible by 3."
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

    func testChallengeLevelsUseDistinctPressureRules() {
        let provider = StaticLevelProvider()

        let rush = provider.level(id: 35)
        XCTAssertEqual(rush?.title, "Rush Challenge 35")
        XCTAssertEqual(rush?.moveLimit, 35)
        XCTAssertEqual(rush?.timeLimit, 26)

        let precision = provider.level(id: 40)
        XCTAssertEqual(precision?.title, "Precision Challenge 40")
        XCTAssertEqual(precision?.moveLimit, 9)
        XCTAssertEqual(precision?.timeLimit, 0)
    }

    func testAllLevelsAreSolvableWithinMoveLimit() {
        let solver = LevelSolvabilitySolver()

        for level in StaticLevelProvider().levels {
            let solution = solver.solve(level: level)
            XCTAssertNotNil(
                solution,
                "Level \(level.id) (\(level.title)) could not be solved within \(level.moveLimit) moves."
            )

            if let solution {
                XCTAssertLessThanOrEqual(
                    solution.moveCount,
                    level.moveLimit,
                    "Level \(level.id) was solved in \(solution.moveCount) moves, above limit \(level.moveLimit)."
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

    func testLockedItemsDoNotMatchBeforeUnlock() {
        let matches = MatchResolver().findMatches(in: [
            [lockedItem(.apple), lockedItem(.apple), lockedItem(.apple), nil, nil]
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

    func testFiveMatchUnlocksAndClearsLockedItemsInCascade() {
        let viewModel = makeViewModel(
            shelves: [
                row(.apple, .apple, nil, .apple, .apple),
                [lockedItem(.apple), lockedItem(.apple), lockedItem(.apple), nil, nil],
                row(.apple, nil, nil, nil, nil)
            ],
            moveLimit: 3
        )

        viewModel.selectItem(at: Position(shelfIndex: 2, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 2))

        XCTAssertTrue(viewModel.isBoardCleared)
        XCTAssertGreaterThan(viewModel.score, 280)
    }

    func testFiveMatchUnlocksScatteredLockedItemsWithoutClearingThemAutomatically() {
        let viewModel = makeViewModel(
            shelves: [
                row(.apple, .apple, nil, .apple, .apple),
                mixedRow(lockedItem(.apple), item(.car), nil, item(.car), nil),
                mixedRow(item(.book), lockedItem(.apple), item(.book), nil, nil),
                mixedRow(item(.cup), nil, item(.cup), lockedItem(.apple), nil),
                row(.apple, nil, nil, nil, nil)
            ],
            moveLimit: 6
        )

        viewModel.selectItem(at: Position(shelfIndex: 4, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 2))

        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 1, slotIndex: 0))?.isLocked, false)
        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 2, slotIndex: 1))?.isLocked, false)
        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 3, slotIndex: 3))?.isLocked, false)
        XCTAssertFalse(viewModel.isBoardCleared)
    }

    func testAdjacentThreeMatchUnlocksMatchingLockedItems() {
        let viewModel = makeViewModel(
            shelves: [
                row(.book, .book, .book, nil, nil),
                mixedRow(nil, lockedItem(.book), nil, nil, nil),
                mixedRow(nil, nil, lockedItem(.book), nil, nil)
            ]
        )

        viewModel.clearMatches()

        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 1, slotIndex: 1))?.isLocked, false)
        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 2, slotIndex: 2))?.isLocked, false)
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

    func testTimerStartsWithLevelTimeLimit() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ], timeLimit: 42)

        XCTAssertEqual(viewModel.timeRemaining, 42)
    }

    func testTimerTickDecreasesTime() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ], timeLimit: 42)

        viewModel.tickTimer(by: 5)

        XCTAssertEqual(viewModel.timeRemaining, 37)
    }

    func testTimerReachingZeroFailsLevelAndConsumesLife() {
        let store = InMemoryProgressStore()
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            timeLimit: 3,
            progressStore: store
        )

        viewModel.tickTimer(by: 3)

        XCTAssertEqual(viewModel.status, .failed)
        XCTAssertEqual(store.lives, GameConstants.maxLives - 1)
    }

    func testTimerDoesNotTickWhenPaused() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ], timeLimit: 42)

        viewModel.pauseTimer()
        viewModel.tickTimer(by: 8)

        XCTAssertEqual(viewModel.timeRemaining, 42)
    }

    func testTimerDoesNotTickAfterLevelEnds() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ], timeLimit: 42)

        viewModel.failLevel()
        viewModel.tickTimer(by: 8)

        XCTAssertEqual(viewModel.timeRemaining, 42)
    }

    func testUntimedLevelDoesNotTickDown() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ], timeLimit: 0)

        viewModel.tickTimer(by: 20)

        XCTAssertEqual(viewModel.timeRemaining, 0)
        XCTAssertEqual(viewModel.status, .playing)
    }

    func testStarsCalculation() {
        XCTAssertEqual(GameViewModel.calculateStars(movesLeft: 4, moveLimit: 10), 3)
        XCTAssertEqual(GameViewModel.calculateStars(movesLeft: 2, moveLimit: 10), 2)
        XCTAssertEqual(GameViewModel.calculateStars(movesLeft: 1, moveLimit: 10), 1)
    }

    func testUndoRestoresPreviousState() {
        let viewModel = makeViewModel(shelves: [
            row(.apple, nil, .car, .book, .cup)
        ], timeLimit: 50)

        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))
        viewModel.tickTimer(by: 7)
        viewModel.undo()

        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0))?.type, .apple)
        XCTAssertNil(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 1)))
        XCTAssertEqual(viewModel.movesLeft, 8)
        XCTAssertEqual(viewModel.timeRemaining, 43)
    }

    func testAbandonLevelConsumesOneLife() {
        let store = InMemoryProgressStore()
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            progressStore: store
        )

        viewModel.abandonLevel()

        XCTAssertEqual(store.lives, GameConstants.maxLives - 1)
        XCTAssertEqual(viewModel.status, .failed)
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

    func testShuffleKeepsLockedItemsFixed() {
        let viewModel = makeViewModel(shelves: [
            [lockedItem(.apple), item(.car), item(.book), item(.cup), nil],
            row(nil, nil, nil, nil, nil)
        ])

        viewModel.shuffle()

        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0))?.type, .apple)
        XCTAssertEqual(viewModel.item(at: Position(shelfIndex: 0, slotIndex: 0))?.isLocked, true)
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

    func testRetryResetsTimer() {
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            moveLimit: 1,
            timeLimit: 30
        )

        viewModel.tickTimer(by: 12)
        viewModel.selectItem(at: Position(shelfIndex: 0, slotIndex: 0))
        viewModel.moveSelectedItem(to: Position(shelfIndex: 0, slotIndex: 1))
        viewModel.retry()

        XCTAssertEqual(viewModel.timeRemaining, 30)
        XCTAssertEqual(viewModel.movesLeft, 1)
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.status, .playing)
    }

    func testSettingsSeparateBackgroundMusicAndGameSoundToggles() {
        let store = InMemoryProgressStore()
        let settings = SettingsViewModel(progressStore: store)

        settings.backgroundMusicEnabled = false
        XCTAssertFalse(store.isBackgroundMusicEnabled)
        XCTAssertTrue(store.isGameSoundEnabled)

        settings.gameSoundEnabled = false
        XCTAssertFalse(store.isBackgroundMusicEnabled)
        XCTAssertFalse(store.isGameSoundEnabled)
    }

    @MainActor
    func testRewardedAdSuccessAddsFiveMovesAndResumesPlay() async {
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            moveLimit: 1,
            rewardedAdService: TestRewardedAdService(result: true)
        )
        viewModel.failLevel()

        viewModel.watchRewardedAdForExtraMoves()
        await Task.yield()

        XCTAssertEqual(viewModel.movesLeft, 6)
        XCTAssertEqual(viewModel.status, .playing)
    }

    @MainActor
    func testRewardedAdFailureDoesNotAddMoves() async {
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            moveLimit: 1,
            rewardedAdService: TestRewardedAdService(result: false)
        )
        viewModel.failLevel()

        viewModel.watchRewardedAdForExtraMoves()
        await Task.yield()

        XCTAssertEqual(viewModel.movesLeft, 1)
        XCTAssertEqual(viewModel.status, .failed)
    }

    @MainActor
    func testRewardedAdCanOnlyBeUsedOncePerRun() async {
        let viewModel = makeViewModel(
            shelves: [row(.apple, nil, .car, .book, .cup)],
            moveLimit: 1,
            rewardedAdService: TestRewardedAdService(result: true)
        )
        viewModel.failLevel()
        viewModel.watchRewardedAdForExtraMoves()
        await Task.yield()
        viewModel.failLevel()

        XCTAssertFalse(viewModel.canWatchRewardedAdForMoves)
    }

    private func makeViewModel(
        shelves: [[ShelfItem?]],
        moveLimit: Int = 10,
        timeLimit: TimeInterval? = nil,
        progressStore: InMemoryProgressStore = InMemoryProgressStore(),
        rewardedAdService: any RewardedAdManaging = MockRewardedAdService()
    ) -> GameViewModel {
        let level = ShelfLevel(
            id: 999,
            title: "Test",
            shelves: shelves,
            moveLimit: moveLimit,
            timeLimit: timeLimit,
            difficulty: .easy,
            targetScore: nil,
            theme: .kitchen,
            unlockRequirement: nil
        )

        return GameViewModel(
            level: level,
            progressStore: progressStore,
            haptics: NoopHapticsManager(),
            sound: NoopSoundManager(),
            rewardedAdService: rewardedAdService
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
    var isBackgroundMusicEnabled = true
    var isGameSoundEnabled = true
    var isHapticsEnabled = true
    var lives = GameConstants.maxLives
    var diamonds = 0
    var undoInventory = 0
    var hintInventory = 0
    var shuffleInventory = 0
    var hasSeenOnboarding = false
    var hasSeenLockTutorial = false

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
        undoInventory = 0
        hintInventory = 0
        shuffleInventory = 0
        hasSeenOnboarding = false
        hasSeenLockTutorial = false
    }

    func getLives() -> Int {
        lives
    }

    func loseLife() {
        lives = max(0, lives - 1)
    }

    func addLife() {
        lives = min(GameConstants.maxLives, lives + 1)
    }

    func getDiamonds() -> Int {
        diamonds
    }

    func addDiamonds(_ amount: Int) {
        diamonds += amount
    }

    func spendDiamonds(_ amount: Int) -> Bool {
        guard amount > 0, diamonds >= amount else { return false }
        diamonds -= amount
        return true
    }

    func spendDiamondsForLife() -> Bool {
        guard lives < GameConstants.maxLives, spendDiamonds(GameConstants.lifeDiamondCost) else { return false }
        addLife()
        return true
    }

    func getUndoInventory() -> Int {
        undoInventory
    }

    func addUndoInventory(_ amount: Int) {
        undoInventory += max(0, amount)
    }

    func consumeUndoInventory(_ amount: Int) -> Int {
        let consumed = min(undoInventory, max(0, amount))
        undoInventory -= consumed
        return consumed
    }

    func getHintInventory() -> Int {
        hintInventory
    }

    func addHintInventory(_ amount: Int) {
        hintInventory += max(0, amount)
    }

    func consumeHintInventory(_ amount: Int) -> Int {
        let consumed = min(hintInventory, max(0, amount))
        hintInventory -= consumed
        return consumed
    }

    func getShuffleInventory() -> Int {
        shuffleInventory
    }

    func addShuffleInventory(_ amount: Int) {
        shuffleInventory += max(0, amount)
    }

    func consumeShuffleInventory(_ amount: Int) -> Int {
        let consumed = min(shuffleInventory, max(0, amount))
        shuffleInventory -= consumed
        return consumed
    }

    func setHasSeenOnboarding(_ value: Bool) {
        hasSeenOnboarding = value
    }

    func setHasSeenLockTutorial(_ value: Bool) {
        hasSeenLockTutorial = value
    }
}

private struct TestRewardedAdService: RewardedAdManaging {
    let result: Bool

    func showRewardedExtraMovesAd() async -> Bool {
        result
    }

    func showRewardedStoreAd() async -> Bool {
        result
    }
}

private struct LevelSolution {
    let moves: [SolvedMove]

    var moveCount: Int {
        moves.count
    }
}

private struct SolvedMove {
    let from: Position
    let to: Position
}

private struct LevelSolvabilitySolver {
    private typealias Board = [[SolverCell?]]

    func solve(level: ShelfLevel) -> LevelSolution? {
        let board = level.shelves.map { shelf in
            shelf.map { item -> SolverCell? in
                guard let item else { return nil }
                return SolverCell(type: item.type, isLocked: item.isLocked, isJoker: item.isJoker, isBomb: item.isBomb)
            }
        }
        var memo: [String: Int] = [:]
        var path: [SolvedMove] = []

        guard search(board: board, movesLeft: level.moveLimit, memo: &memo, path: &path) else {
            return nil
        }

        return LevelSolution(moves: path)
    }

    private func search(
        board: Board,
        movesLeft: Int,
        memo: inout [String: Int],
        path: inout [SolvedMove]
    ) -> Bool {
        if isCleared(board) {
            return true
        }

        guard movesLeft > 0 else {
            return false
        }

        let key = stateKey(for: board)
        if let bestMovesLeft = memo[key], bestMovesLeft >= movesLeft {
            return false
        }
        memo[key] = movesLeft

        let candidateMoves = legalMoves(on: board)
        for move in candidateMoves {
            let movedBoard = apply(move, to: board)
            let clearedBoard = clearMatches(in: movedBoard)
            path.append(move)
            if search(board: clearedBoard, movesLeft: movesLeft - 1, memo: &memo, path: &path) {
                return true
            }
            path.removeLast()
        }

        return false
    }

    private func legalMoves(on board: Board) -> [SolvedMove] {
        var scoredMoves: [(move: SolvedMove, clearedCount: Int)] = []

        for sourceShelf in board.indices {
            for sourceSlot in board[sourceShelf].indices {
                guard let sourceCell = board[sourceShelf][sourceSlot], !sourceCell.isLocked else { continue }
                let from = Position(shelfIndex: sourceShelf, slotIndex: sourceSlot)
                for targetShelf in board.indices {
                    for targetSlot in board[targetShelf].indices where board[targetShelf][targetSlot] == nil {
                        let to = Position(shelfIndex: targetShelf, slotIndex: targetSlot)
                        guard from != to else { continue }

                        let movedBoard = apply(SolvedMove(from: from, to: to), to: board)
                        let matches = findMatches(in: movedBoard)
                        let clearedCount = matches.reduce(0) { $0 + $1.slotIndexes.count }
                        scoredMoves.append((SolvedMove(from: from, to: to), clearedCount))
                    }
                }
            }
        }

        let priorityMoves = scoredMoves.filter { $0.clearedCount > 0 }
        let movesToSearch = priorityMoves.isEmpty ? scoredMoves : priorityMoves

        return movesToSearch
            .sorted { lhs, rhs in
                if lhs.clearedCount != rhs.clearedCount {
                    return lhs.clearedCount > rhs.clearedCount
                }
                return lhs.move.from.shelfIndex < rhs.move.from.shelfIndex
            }
            .map(\.move)
    }

    private func apply(_ move: SolvedMove, to board: Board) -> Board {
        var next = board
        let item = next[move.from.shelfIndex][move.from.slotIndex]
        next[move.from.shelfIndex][move.from.slotIndex] = nil
        next[move.to.shelfIndex][move.to.slotIndex] = item
        return next
    }

    private func clearMatches(in board: Board) -> Board {
        var next = board
        let matches = findMatches(in: board)
        var clearPositions = Set(
            matches.flatMap { match in
                match.slotIndexes.map { Position(shelfIndex: match.shelfIndex, slotIndex: $0) }
            }
        )

        for position in clearPositions {
            guard board[position.shelfIndex][position.slotIndex]?.isBomb == true else { continue }
            let candidatePositions = [
                Position(shelfIndex: position.shelfIndex, slotIndex: position.slotIndex - 1),
                Position(shelfIndex: position.shelfIndex, slotIndex: position.slotIndex + 1),
                Position(shelfIndex: position.shelfIndex - 1, slotIndex: position.slotIndex),
                Position(shelfIndex: position.shelfIndex + 1, slotIndex: position.slotIndex)
            ]
            for candidate in candidatePositions {
                guard board.indices.contains(candidate.shelfIndex),
                      board[candidate.shelfIndex].indices.contains(candidate.slotIndex),
                      let cell = board[candidate.shelfIndex][candidate.slotIndex],
                      !cell.isLocked
                else { continue }
                clearPositions.insert(candidate)
            }
        }

        let fiveMatchTypes = Set(matches.filter { $0.slotIndexes.count >= 5 }.map(\.itemType))
        let adjacentLockTypes = Set(matches.compactMap { match -> ShelfItemType? in
            let matchedPositions = match.slotIndexes.map {
                Position(shelfIndex: match.shelfIndex, slotIndex: $0)
            }
            let touchesMatchingLock = matchedPositions.contains { position in
                adjacentPositions(to: position, on: board).contains { adjacent in
                    guard let adjacentCell = board[adjacent.shelfIndex][adjacent.slotIndex] else { return false }
                    return adjacentCell.isLocked && adjacentCell.type == match.itemType
                }
            }
            return touchesMatchingLock ? match.itemType : nil
        })
        let unlockedTypes = fiveMatchTypes.union(adjacentLockTypes)
        if unlockedTypes.isNotEmpty {
            for shelfIndex in next.indices {
                for slotIndex in next[shelfIndex].indices {
                    guard var cell = next[shelfIndex][slotIndex],
                          cell.isLocked,
                          unlockedTypes.contains(cell.type)
                    else { continue }
                    cell.isLocked = false
                    next[shelfIndex][slotIndex] = cell
                }
            }
        }

        for position in clearPositions {
            next[position.shelfIndex][position.slotIndex] = nil
        }
        if findMatches(in: next).isNotEmpty {
            return clearMatches(in: next)
        }
        return next
    }

    private func adjacentPositions(to position: Position, on board: Board) -> [Position] {
        [
            Position(shelfIndex: position.shelfIndex, slotIndex: position.slotIndex - 1),
            Position(shelfIndex: position.shelfIndex, slotIndex: position.slotIndex + 1),
            Position(shelfIndex: position.shelfIndex - 1, slotIndex: position.slotIndex),
            Position(shelfIndex: position.shelfIndex + 1, slotIndex: position.slotIndex)
        ].filter { adjacent in
            board.indices.contains(adjacent.shelfIndex)
                && board[adjacent.shelfIndex].indices.contains(adjacent.slotIndex)
        }
    }

    private func findMatches(in board: Board) -> [MatchGroup] {
        var matches: [MatchGroup] = []

        for (shelfIndex, shelf) in board.enumerated() {
            let candidates = Set(shelf.compactMap { cell -> ShelfItemType? in
                guard let cell, !cell.isLocked, !cell.isJoker else { return nil }
                return cell.type
            })
            var shelfMatches: [MatchGroup] = []

            for itemType in candidates {
                for startIndex in shelf.indices {
                    guard isCompatible(shelf[startIndex], with: itemType) else { continue }

                    var slotIndexes: [Int] = []
                    var cursor = startIndex
                    while cursor < shelf.count, isCompatible(shelf[cursor], with: itemType) {
                        slotIndexes.append(cursor)
                        cursor += 1
                    }

                    guard slotIndexes.count >= 3,
                          slotIndexes.contains(where: { shelf[$0]?.isJoker == false })
                    else { continue }

                    shelfMatches.append(MatchGroup(shelfIndex: shelfIndex, slotIndexes: slotIndexes, itemType: itemType))
                }
            }

            matches.append(contentsOf: nonOverlapping(shelfMatches))
        }

        return matches
    }

    private func isCompatible(_ cell: SolverCell?, with itemType: ShelfItemType) -> Bool {
        guard let cell, !cell.isLocked else { return false }
        return cell.isJoker || cell.type == itemType
    }

    private func nonOverlapping(_ matches: [MatchGroup]) -> [MatchGroup] {
        var result: [MatchGroup] = []
        var usedSlots: Set<Int> = []

        for match in matches.sorted(by: matchPriority) {
            let slotSet = Set(match.slotIndexes)
            guard usedSlots.isDisjoint(with: slotSet) else { continue }
            result.append(match)
            usedSlots.formUnion(slotSet)
        }

        return result.sorted { ($0.shelfIndex, $0.slotIndexes.first ?? 0) < ($1.shelfIndex, $1.slotIndexes.first ?? 0) }
    }

    private func matchPriority(_ lhs: MatchGroup, _ rhs: MatchGroup) -> Bool {
        if lhs.slotIndexes.count != rhs.slotIndexes.count {
            return lhs.slotIndexes.count > rhs.slotIndexes.count
        }
        return (lhs.slotIndexes.first ?? 0) < (rhs.slotIndexes.first ?? 0)
    }

    private func isCleared(_ board: Board) -> Bool {
        board.allSatisfy { shelf in shelf.allSatisfy { $0 == nil } }
    }

    private func stateKey(for board: Board) -> String {
        board
            .map { shelf in
                shelf.map { cell in
                    guard let cell else { return "-" }
                    let lockPrefix = cell.isLocked ? "L" : ""
                    let jokerPrefix = cell.isJoker ? "J" : ""
                    let bombPrefix = cell.isBomb ? "B" : ""
                    return "\(lockPrefix)\(jokerPrefix)\(bombPrefix)\(cell.type.rawValue)"
                }.joined(separator: ",")
            }
            .joined(separator: "|")
    }
}

private struct SolverCell: Equatable {
    let type: ShelfItemType
    var isLocked: Bool
    var isJoker: Bool
    var isBomb: Bool
}
