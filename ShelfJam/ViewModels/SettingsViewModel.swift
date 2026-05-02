import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var backgroundMusicEnabled: Bool {
        didSet {
            progressStore.isBackgroundMusicEnabled = backgroundMusicEnabled
            BackgroundMusicManager.shared.setEnabled(backgroundMusicEnabled)
        }
    }

    @Published var gameSoundEnabled: Bool {
        didSet {
            progressStore.isGameSoundEnabled = gameSoundEnabled
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet { progressStore.isHapticsEnabled = hapticsEnabled }
    }

    private var progressStore: any ProgressStore

    init(progressStore: any ProgressStore) {
        self.progressStore = progressStore
        self.backgroundMusicEnabled = progressStore.isBackgroundMusicEnabled
        self.gameSoundEnabled = progressStore.isGameSoundEnabled
        self.hapticsEnabled = progressStore.isHapticsEnabled
    }

    func resetProgress() {
        progressStore.resetProgress()
        backgroundMusicEnabled = progressStore.isBackgroundMusicEnabled
        gameSoundEnabled = progressStore.isGameSoundEnabled
        hapticsEnabled = progressStore.isHapticsEnabled
    }
}
