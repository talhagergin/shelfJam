import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif

protocol SoundManaging {
    func playMove()
    func playMatch()
    func playWin()
    func playFail()
}

final class SoundManager: SoundManaging {
    private let isGameSoundEnabled: () -> Bool

    init(isGameSoundEnabled: @escaping () -> Bool) {
        self.isGameSoundEnabled = isGameSoundEnabled
    }

    func playMove() {
        guard isGameSoundEnabled() else { return }
        playSystemSound(1104)
    }

    func playMatch() {
        guard isGameSoundEnabled() else { return }
        playSystemSound(1057)
    }

    func playWin() {
        guard isGameSoundEnabled() else { return }
        playSystemSound(1025)
    }

    func playFail() {
        guard isGameSoundEnabled() else { return }
        playSystemSound(1053)
    }

    private func playSystemSound(_ id: UInt32) {
        #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(SystemSoundID(id))
        #endif
    }
}

struct NoopSoundManager: SoundManaging {
    func playMove() {}
    func playMatch() {}
    func playWin() {}
    func playFail() {}
}
