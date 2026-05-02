import Foundation
import Combine

final class LevelSelectViewModel: ObservableObject {
    @Published private(set) var levels: [ShelfLevel]
    @Published private(set) var highestUnlockedLevel: Int
    @Published private(set) var lives: Int

    private let progressStore: any ProgressStore

    init(levelProvider: any LevelProvider, progressStore: any ProgressStore) {
        self.levels = levelProvider.levels
        self.progressStore = progressStore
        self.highestUnlockedLevel = progressStore.getHighestUnlockedLevel()
        self.lives = progressStore.getLives()
    }

    func refresh() {
        highestUnlockedLevel = progressStore.getHighestUnlockedLevel()
        lives = progressStore.getLives()
    }

    func isUnlocked(_ level: ShelfLevel) -> Bool {
        level.id <= highestUnlockedLevel
    }

    func canPlay(_ level: ShelfLevel) -> Bool {
        isUnlocked(level) && lives > 0
    }

    func bestScore(for level: ShelfLevel) -> Int {
        progressStore.getBestScore(levelID: level.id)
    }

    func bestStars(for level: ShelfLevel) -> Int {
        progressStore.getBestStars(levelID: level.id)
    }
}
