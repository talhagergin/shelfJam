import SwiftUI

struct GameFlowView: View {
    @State private var currentLevel: ShelfLevel
    let levelProvider: any LevelProvider
    let progressStore: any ProgressStore

    init(initialLevel: ShelfLevel, levelProvider: any LevelProvider, progressStore: any ProgressStore) {
        _currentLevel = State(initialValue: initialLevel)
        self.levelProvider = levelProvider
        self.progressStore = progressStore
    }

    var body: some View {
        GameView(
            level: currentLevel,
            progressStore: progressStore,
            onNextLevel: nextLevel
        )
        .id(currentLevel.id)
    }

    private func nextLevel() {
        guard let next = levelProvider.level(id: currentLevel.id + 1) else { return }
        currentLevel = next
    }
}
