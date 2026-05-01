import Foundation
#if canImport(UIKit)
import UIKit
#endif

protocol HapticsManaging {
    func selection()
    func success()
    func warning()
    func error()
    func match()
}

final class HapticsManager: HapticsManaging {
    private let isEnabled: () -> Bool

    init(isEnabled: @escaping () -> Bool) {
        self.isEnabled = isEnabled
    }

    func selection() {
        guard isEnabled() else { return }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    func success() {
        notify(.success)
    }

    func warning() {
        notify(.warning)
    }

    func error() {
        notify(.error)
    }

    func match() {
        guard isEnabled() else { return }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled() else { return }
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(type)
        #endif
    }
}

struct NoopHapticsManager: HapticsManaging {
    func selection() {}
    func success() {}
    func warning() {}
    func error() {}
    func match() {}
}
