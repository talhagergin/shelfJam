import Foundation
import Combine

final class GameViewModel: ObservableObject {
    @Published private(set) var level: ShelfLevel
    @Published var shelves: [[ShelfItem?]]
    @Published var selectedPosition: Position?
    @Published var movesLeft: Int
    @Published var score: Int = 0
    @Published var comboCount: Int = 0
    @Published var status: LevelStatus = .playing
    @Published var matchedPositions: Set<Position> = []
    @Published var recentMatchEffects: [MatchEffect] = []
    @Published var invalidTargetPosition: Position?
    @Published var hintPositions: Set<Position> = []
    @Published var hintMessage: String?
    @Published var unlockMessage: String?
    @Published var showComboText = false
    @Published private(set) var lives: Int
    @Published private(set) var diamonds: Int
    @Published private(set) var earnedDiamonds = 0
    @Published private(set) var rewardedMoveUsesLeft = 1
    @Published private(set) var isRewardedAdLoading = false
    @Published private(set) var timeRemaining: TimeInterval
    @Published private(set) var isTimerPaused = false

    private(set) var undoStack: [MoveRecord] = []
    @Published private(set) var undoUsesLeft: Int
    @Published private(set) var hintUsesLeft: Int
    @Published private(set) var shuffleUsesLeft: Int

    private let progressStore: any ProgressStore
    private let matchResolver: MatchResolver
    private let haptics: HapticsManaging
    private let sound: SoundManaging
    private let rewardedAdService: any RewardedAdManaging
    private var timerCancellable: AnyCancellable?

    init(
        level: ShelfLevel,
        progressStore: any ProgressStore,
        matchResolver: MatchResolver = MatchResolver(),
        haptics: HapticsManaging = NoopHapticsManager(),
        sound: SoundManaging = NoopSoundManager(),
        rewardedAdService: any RewardedAdManaging = MockRewardedAdService()
    ) {
        self.level = level
        self.shelves = level.shelves
        self.movesLeft = level.moveLimit
        self.timeRemaining = level.timeLimit
        self.progressStore = progressStore
        self.matchResolver = matchResolver
        self.haptics = haptics
        self.sound = sound
        self.rewardedAdService = rewardedAdService
        self.lives = progressStore.getLives()
        self.diamonds = progressStore.getDiamonds()
        self.undoUsesLeft = GameConstants.maxUndoUses + progressStore.consumeUndoInventory(2)
        self.hintUsesLeft = GameConstants.maxHintUses + progressStore.consumeHintInventory(2)
        self.shuffleUsesLeft = GameConstants.maxShuffleUses + progressStore.consumeShuffleInventory(1)
    }

    var selectedItemID: UUID? {
        guard let selectedPosition, let selectedItem = item(at: selectedPosition) else { return nil }
        return selectedItem.id
    }

    var isBoardCleared: Bool {
        shelves.flatMap { $0 }.allSatisfy { $0 == nil }
    }

    var canUndo: Bool {
        undoUsesLeft > 0 && undoStack.isNotEmpty && status == .playing
    }

    var canUseHint: Bool {
        hintUsesLeft > 0 && status == .playing
    }

    var canShuffle: Bool {
        shuffleUsesLeft > 0
            && status == .playing
            && shelves.flatMap { $0 }.compactMap { $0 }.filter { !$0.isLocked }.count > 1
    }

    var isBackgroundMusicEnabled: Bool {
        progressStore.isBackgroundMusicEnabled
    }

    var canWatchRewardedAdForMoves: Bool {
        status == .failed && rewardedMoveUsesLeft > 0 && !isRewardedAdLoading
    }

    var hasLockedItems: Bool {
        shelves.flatMap { $0 }.compactMap { $0 }.contains { $0.isLocked }
    }

    func item(at position: Position) -> ShelfItem? {
        guard shelves.indices.contains(position.shelfIndex),
              shelves[position.shelfIndex].indices.contains(position.slotIndex)
        else { return nil }
        return shelves[position.shelfIndex][position.slotIndex]
    }

    func selectItem(at position: Position) {
        guard status == .playing else { return }
        if selectedPosition == position {
            selectedPosition = nil
            haptics.selection()
            return
        }

        guard let item = item(at: position) else {
            selectedPosition = nil
            return
        }

        guard !item.isLocked else {
            haptics.warning()
            selectedPosition = nil
            return
        }

        selectedPosition = position
        hintPositions = []
        hintMessage = nil
        unlockMessage = nil
        haptics.selection()
    }

    func moveSelectedItem(to destination: Position) {
        guard status == .playing, let source = selectedPosition else { return }
        guard source != destination else {
            selectedPosition = nil
            return
        }
        guard let movedItem = item(at: source) else {
            selectedPosition = nil
            return
        }
        guard item(at: destination) == nil else {
            markInvalid(destination)
            return
        }

        let snapshot = shelves
        undoStack.append(
            MoveRecord(
                from: source,
                to: destination,
                movedItem: movedItem,
                previousShelvesSnapshot: snapshot,
                previousMovesLeft: movesLeft,
                previousScore: score,
                previousCombo: comboCount
            )
        )

        shelves[source.shelfIndex][source.slotIndex] = nil
        shelves[destination.shelfIndex][destination.slotIndex] = movedItem
        selectedPosition = nil
        hintPositions = []
        hintMessage = nil
        unlockMessage = nil
        movesLeft -= 1

        haptics.selection()
        if movesLeft <= GameConstants.lowMovesWarningThreshold, movesLeft > 0 {
            haptics.warning()
        }
        sound.playMove()
        checkMatches()
        checkLevelEnd()
    }

    func startTimer() {
        guard timerCancellable == nil else {
            resumeTimer()
            return
        }
        isTimerPaused = false
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tickTimer()
            }
    }

    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isTimerPaused = true
    }

    func pauseTimer() {
        isTimerPaused = true
    }

    func resumeTimer() {
        guard status == .playing else { return }
        isTimerPaused = false
    }

    func tickTimer(by seconds: TimeInterval = 1) {
        guard level.hasTimeLimit, status == .playing, !isTimerPaused else { return }
        let wasAboveWarning = timeRemaining > GameConstants.lowTimeWarningThreshold
        timeRemaining = max(0, timeRemaining - seconds)

        if wasAboveWarning, timeRemaining <= GameConstants.lowTimeWarningThreshold, timeRemaining > 0 {
            haptics.warning()
        }

        if timeRemaining <= 0 {
            failLevel()
        }
    }

    func checkMatches() {
        let matches = matchResolver.findMatches(in: shelves)
        guard matches.isNotEmpty else {
            comboCount = 0
            return
        }

        comboCount = matches.count
        clearMatches(matches)
    }

    func clearMatches(_ matches: [MatchGroup]? = nil) {
        let resolvedMatches = matches ?? matchResolver.findMatches(in: shelves)
        guard resolvedMatches.isNotEmpty else { return }

        matchedPositions = Set(
            resolvedMatches.flatMap { group in
                group.slotIndexes.map { Position(shelfIndex: group.shelfIndex, slotIndex: $0) }
            }
        )

        var effects = Array(Set(resolvedMatches.map(\.itemType)))
            .map { MatchEffect(itemType: $0) }
        if containsJoker(in: resolvedMatches) {
            effects.append(MatchEffect(kind: .joker))
        }
        recentMatchEffects = effects

        let baseScore = resolvedMatches.reduce(0) { total, group in
            total + matchResolver.baseScore(for: group.slotIndexes.count)
        }
        let multiplier = matchResolver.multiplier(for: resolvedMatches.count)
        score += Int(Double(baseScore) * multiplier)

        if resolvedMatches.count >= 2 {
            movesLeft += 1
            showComboText = true
        }

        unlockItemsIfNeeded(after: resolvedMatches)
        haptics.match()
        sound.playMatch()

        for position in matchedPositions {
            shelves[position.shelfIndex][position.slotIndex] = nil
        }

        let cascadedMatches = matchResolver.findMatches(in: shelves)
        if cascadedMatches.isNotEmpty {
            clearMatches(cascadedMatches)
            return
        }

        if resolvedMatches.count < 2 {
            showComboText = false
        }
    }

    func useHint() {
        guard canUseHint else { return }
        guard let hint = findHint() else {
            hintMessage = "No clear hint right now"
            haptics.warning()
            return
        }

        hintUsesLeft -= 1
        hintPositions = Set([hint.source, hint.destination])
        selectedPosition = hint.source
        hintMessage = "Try moving \(hint.itemType.displayName)"
        haptics.selection()
    }

    func shuffle() {
        guard canShuffle else { return }
        let occupiedPositions = allPositions().filter { position in
            guard let item = item(at: position) else { return false }
            return !item.isLocked
        }
        var shuffledItems = occupiedPositions.compactMap { item(at: $0) }.shuffled()
        guard shuffledItems.count == occupiedPositions.count else { return }

        let snapshot = shelves
        undoStack.append(
            MoveRecord(
                from: occupiedPositions.first ?? Position(shelfIndex: 0, slotIndex: 0),
                to: occupiedPositions.last ?? Position(shelfIndex: 0, slotIndex: 0),
                movedItem: shuffledItems.first ?? ShelfItem(type: .apple),
                previousShelvesSnapshot: snapshot,
                previousMovesLeft: movesLeft,
                previousScore: score,
                previousCombo: comboCount
            )
        )

        for position in occupiedPositions {
            shelves[position.shelfIndex][position.slotIndex] = shuffledItems.removeFirst()
        }

        shuffleUsesLeft -= 1
        selectedPosition = nil
        hintPositions = []
        hintMessage = nil
        unlockMessage = nil
        haptics.warning()
        sound.playMove()
        checkMatches()
        checkLevelEnd()
    }

    func buyLifeWithDiamonds() {
        if progressStore.spendDiamondsForLife() {
            refreshEconomy()
            haptics.success()
        } else {
            haptics.warning()
        }
    }

    func watchRewardedAdForExtraMoves() {
        guard canWatchRewardedAdForMoves else { return }
        pauseTimer()
        isRewardedAdLoading = true
        Task { @MainActor in
            let didEarnReward = await rewardedAdService.showRewardedExtraMovesAd()
            isRewardedAdLoading = false
            guard didEarnReward else {
                haptics.warning()
                return
            }
            rewardedMoveUsesLeft -= 1
            movesLeft += 5
            status = .playing
            resumeTimer()
            haptics.success()
            sound.playWin()
        }
    }

    func refreshEconomy() {
        lives = progressStore.getLives()
        diamonds = progressStore.getDiamonds()
    }

    func calculateStars() -> Int {
        Self.calculateStars(movesLeft: movesLeft, moveLimit: level.moveLimit)
    }

    static func calculateStars(movesLeft: Int, moveLimit: Int) -> Int {
        guard moveLimit > 0 else { return 1 }
        let ratio = Double(movesLeft) / Double(moveLimit)
        if ratio >= 0.4 { return 3 }
        if ratio >= 0.2 { return 2 }
        return 1
    }

    func undo() {
        guard canUndo, let record = undoStack.popLast() else { return }
        let undoMovesLeft = max(0, movesLeft - 1)
        shelves = record.previousShelvesSnapshot
        movesLeft = undoMovesLeft
        score = record.previousScore
        comboCount = record.previousCombo
        selectedPosition = nil
        status = .playing
        matchedPositions = []
        recentMatchEffects = []
        hintPositions = []
        hintMessage = nil
        unlockMessage = nil
        undoUsesLeft -= 1
        haptics.selection()
        checkLevelEnd()
    }

    func abandonLevel() {
        guard status == .playing else { return }
        stopTimer()
        progressStore.loseLife()
        refreshEconomy()
        status = .failed
    }

    func retry() {
        shelves = level.shelves
        selectedPosition = nil
        movesLeft = level.moveLimit
        timeRemaining = level.timeLimit
        score = 0
        comboCount = 0
        undoStack = []
        undoUsesLeft = GameConstants.maxUndoUses + progressStore.consumeUndoInventory(2)
        hintUsesLeft = GameConstants.maxHintUses + progressStore.consumeHintInventory(2)
        shuffleUsesLeft = GameConstants.maxShuffleUses + progressStore.consumeShuffleInventory(1)
        rewardedMoveUsesLeft = 1
        isRewardedAdLoading = false
        matchedPositions = []
        recentMatchEffects = []
        hintPositions = []
        hintMessage = nil
        unlockMessage = nil
        earnedDiamonds = 0
        status = .playing
        startTimer()
        refreshEconomy()
    }

    func completeLevel() {
        guard status == .playing else { return }
        stopTimer()
        let stars = calculateStars()
        let finalScore = score + movesLeft * GameConstants.endLevelMoveBonus
        let previousBestStars = progressStore.getBestStars(levelID: level.id)
        earnedDiamonds = GameConstants.diamondReward(for: stars) - GameConstants.diamondReward(for: previousBestStars)
        if earnedDiamonds > 0 {
            progressStore.addDiamonds(earnedDiamonds)
        }
        score = finalScore
        progressStore.saveBestScore(levelID: level.id, score: finalScore)
        progressStore.saveBestStars(levelID: level.id, stars: stars)
        progressStore.unlockNextLevel(after: level.id)
        refreshEconomy()
        status = .completed(stars: stars, finalScore: finalScore)
        haptics.success()
        sound.playWin()
    }

    func failLevel() {
        guard status == .playing else { return }
        stopTimer()
        progressStore.loseLife()
        refreshEconomy()
        status = .failed
        haptics.error()
        sound.playFail()
    }

    private func checkLevelEnd() {
        if isBoardCleared {
            completeLevel()
        } else if movesLeft == 0 {
            failLevel()
        }
    }

    private func markInvalid(_ position: Position) {
        invalidTargetPosition = position
        haptics.warning()
    }

    func clearInvalidTarget() {
        invalidTargetPosition = nil
    }

    func clearTransientEffects() {
        matchedPositions = []
        recentMatchEffects = []
        showComboText = false
        unlockMessage = nil
    }

    deinit {
        timerCancellable?.cancel()
    }

    private func findHint() -> HintMove? {
        for source in allPositions() {
            guard let sourceItem = item(at: source), !sourceItem.isLocked else { continue }
            for destination in allPositions() where item(at: destination) == nil {
                var candidate = shelves
                candidate[source.shelfIndex][source.slotIndex] = nil
                candidate[destination.shelfIndex][destination.slotIndex] = sourceItem
                if matchResolver.findMatches(in: candidate).isNotEmpty {
                    return HintMove(source: source, destination: destination, itemType: sourceItem.type)
                }
            }
        }
        return nil
    }

    private func unlockItemsIfNeeded(after matches: [MatchGroup]) {
        let fiveMatchTypes = Set(matches.filter { $0.slotIndexes.count >= 5 }.map(\.itemType))
        let adjacentLockTypes = Set(matches.compactMap { match -> ShelfItemType? in
            let matchedPositions = match.slotIndexes.map {
                Position(shelfIndex: match.shelfIndex, slotIndex: $0)
            }
            let touchesMatchingLock = matchedPositions.contains { position in
                adjacentPositions(to: position).contains { adjacent in
                    guard let adjacentItem = item(at: adjacent) else { return false }
                    return adjacentItem.isLocked && adjacentItem.type == match.itemType
                }
            }
            return touchesMatchingLock ? match.itemType : nil
        })
        let unlockedTypes = fiveMatchTypes.union(adjacentLockTypes)
        guard unlockedTypes.isNotEmpty else { return }

        var unlockedCount = 0
        for shelfIndex in shelves.indices {
            for slotIndex in shelves[shelfIndex].indices {
                guard var item = shelves[shelfIndex][slotIndex],
                      item.isLocked,
                      unlockedTypes.contains(item.type)
                else { continue }
                item.isLocked = false
                shelves[shelfIndex][slotIndex] = item
                unlockedCount += 1
            }
        }

        if unlockedCount > 0 {
            let bonus = unlockedCount * GameConstants.unlockBonus
            score += bonus
            let names = unlockedTypes.map(\.displayName).sorted().joined(separator: ", ")
            unlockMessage = "\(names) unlocked! +\(bonus)"
            recentMatchEffects.append(MatchEffect(kind: .unlock))
            haptics.success()
        }
    }

    private func containsJoker(in matches: [MatchGroup]) -> Bool {
        matches.contains { group in
            group.slotIndexes.contains { slotIndex in
                shelves[group.shelfIndex][slotIndex]?.isJoker == true
            }
        }
    }

    private func adjacentPositions(to position: Position) -> [Position] {
        [
            Position(shelfIndex: position.shelfIndex, slotIndex: position.slotIndex - 1),
            Position(shelfIndex: position.shelfIndex, slotIndex: position.slotIndex + 1),
            Position(shelfIndex: position.shelfIndex - 1, slotIndex: position.slotIndex),
            Position(shelfIndex: position.shelfIndex + 1, slotIndex: position.slotIndex)
        ].filter { adjacent in
            shelves.indices.contains(adjacent.shelfIndex)
                && shelves[adjacent.shelfIndex].indices.contains(adjacent.slotIndex)
        }
    }

    private func allPositions() -> [Position] {
        shelves.indices.flatMap { shelfIndex in
            shelves[shelfIndex].indices.map { slotIndex in
                Position(shelfIndex: shelfIndex, slotIndex: slotIndex)
            }
        }
    }
}

private struct HintMove {
    let source: Position
    let destination: Position
    let itemType: ShelfItemType
}
