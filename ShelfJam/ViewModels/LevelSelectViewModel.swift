import Foundation
import Combine

final class LevelSelectViewModel: ObservableObject {
    @Published private(set) var levels: [ShelfLevel]
    @Published private(set) var highestUnlockedLevel: Int

    private let progressStore: any ProgressStore

    init(levelProvider: any LevelProvider, progressStore: any ProgressStore) {
        self.levels = levelProvider.levels
        self.progressStore = progressStore
        self.highestUnlockedLevel = progressStore.getHighestUnlockedLevel()
    }

    func refresh() {
        highestUnlockedLevel = progressStore.getHighestUnlockedLevel()
    }

    func isUnlocked(_ level: ShelfLevel) -> Bool {
        level.id <= highestUnlockedLevel
    }

    func bestScore(for level: ShelfLevel) -> Int {
        progressStore.getBestScore(levelID: level.id)
    }

    func bestStars(for level: ShelfLevel) -> Int {
        progressStore.getBestStars(levelID: level.id)
    }
}
