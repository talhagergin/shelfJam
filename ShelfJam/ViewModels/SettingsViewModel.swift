import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var soundEnabled: Bool {
        didSet { progressStore.isSoundEnabled = soundEnabled }
    }

    @Published var hapticsEnabled: Bool {
        didSet { progressStore.isHapticsEnabled = hapticsEnabled }
    }

    private var progressStore: any ProgressStore

    init(progressStore: any ProgressStore) {
        self.progressStore = progressStore
        self.soundEnabled = progressStore.isSoundEnabled
        self.hapticsEnabled = progressStore.isHapticsEnabled
    }

    func resetProgress() {
        progressStore.resetProgress()
        soundEnabled = progressStore.isSoundEnabled
        hapticsEnabled = progressStore.isHapticsEnabled
    }
}
