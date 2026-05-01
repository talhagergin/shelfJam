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
    @Published var showComboText = false
    @Published private(set) var lives: Int
    @Published private(set) var diamonds: Int
    @Published private(set) var earnedDiamonds = 0

    private(set) var undoStack: [MoveRecord] = []
    @Published private(set) var undoUsesLeft = GameConstants.maxUndoUses
    @Published private(set) var hintUsesLeft = GameConstants.maxHintUses
    @Published private(set) var shuffleUsesLeft = GameConstants.maxShuffleUses

    private let progressStore: any ProgressStore
    private let matchResolver: MatchResolver
    private let haptics: HapticsManaging
    private let sound: SoundManaging

    init(
        level: ShelfLevel,
        progressStore: any ProgressStore,
        matchResolver: MatchResolver = MatchResolver(),
        haptics: HapticsManaging = NoopHapticsManager(),
        sound: SoundManaging = NoopSoundManager()
    ) {
        self.level = level
        self.shelves = level.shelves
        self.movesLeft = level.moveLimit
        self.progressStore = progressStore
        self.matchResolver = matchResolver
        self.haptics = haptics
        self.sound = sound
        self.lives = progressStore.getLives()
        self.diamonds = progressStore.getDiamonds()
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
        shuffleUsesLeft > 0 && status == .playing && shelves.flatMap { $0 }.compactMap { $0 }.count > 1
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
        movesLeft -= 1

        haptics.selection()
        if movesLeft <= GameConstants.lowMovesWarningThreshold, movesLeft > 0 {
            haptics.warning()
        }
        sound.playMove()
        checkMatches()
        checkLevelEnd()
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
        recentMatchEffects = Array(Set(resolvedMatches.map(\.itemType)))
            .map { MatchEffect(itemType: $0) }

        let baseScore = resolvedMatches.reduce(0) { total, group in
            total + matchResolver.baseScore(for: group.slotIndexes.count)
        }
        let multiplier = matchResolver.multiplier(for: resolvedMatches.count)
        score += Int(Double(baseScore) * multiplier)

        if resolvedMatches.count >= 2 {
            movesLeft += 1
            showComboText = true
        }

        haptics.match()
        sound.playMatch()

        for group in resolvedMatches {
            for slotIndex in group.slotIndexes {
                shelves[group.shelfIndex][slotIndex] = nil
            }
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
        let occupiedPositions = allPositions().filter { item(at: $0) != nil }
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
        shelves = record.previousShelvesSnapshot
        movesLeft = record.previousMovesLeft
        score = record.previousScore
        comboCount = record.previousCombo
        selectedPosition = nil
        status = .playing
        matchedPositions = []
        recentMatchEffects = []
        hintPositions = []
        hintMessage = nil
        undoUsesLeft -= 1
        haptics.selection()
    }

    func retry() {
        shelves = level.shelves
        selectedPosition = nil
        movesLeft = level.moveLimit
        score = 0
        comboCount = 0
        undoStack = []
        undoUsesLeft = GameConstants.maxUndoUses
        hintUsesLeft = GameConstants.maxHintUses
        shuffleUsesLeft = GameConstants.maxShuffleUses
        matchedPositions = []
        recentMatchEffects = []
        hintPositions = []
        hintMessage = nil
        earnedDiamonds = 0
        status = .playing
        refreshEconomy()
    }

    func completeLevel() {
        guard status == .playing else { return }
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
