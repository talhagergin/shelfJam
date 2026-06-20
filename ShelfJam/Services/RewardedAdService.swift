import Foundation

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

protocol RewardedAdManaging {
    func showRewardedExtraMovesAd() async -> Bool
    func showRewardedStoreAd() async -> Bool
}

struct MockRewardedAdService: RewardedAdManaging {
    func showRewardedExtraMovesAd() async -> Bool {
        try? await Task.sleep(nanoseconds: 850_000_000)
        return true
    }

    func showRewardedStoreAd() async -> Bool {
        try? await Task.sleep(nanoseconds: 850_000_000)
        return true
    }
}

// Google Mobile Ads integration point:
// Replace MockRewardedAdService with a GoogleMobileAds-backed implementation
// that loads RewardedAd with the AdMob test unit, presents it, and returns true
// only from the userDidEarnReward handler.

#if canImport(GoogleMobileAds)
#if canImport(UIKit)
import UIKit
#endif

final class GoogleRewardedAdService: NSObject, RewardedAdManaging, FullScreenContentDelegate {
    private var rewardedAd: RewardedAd?
    private var rewardContinuation: CheckedContinuation<Bool, Never>?
    private var didEarnReward = false
    private let adUnitID: String

    init(adUnitID: String = "ca-app-pub-3940256099942544/1712485313") {
        self.adUnitID = adUnitID
        super.init()
    }

    func showRewardedExtraMovesAd() async -> Bool {
        await showRewardedExtraMovesAdOnMain()
    }

    func showRewardedStoreAd() async -> Bool {
        await showRewardedExtraMovesAdOnMain()
    }

    @MainActor
    private func showRewardedExtraMovesAdOnMain() async -> Bool {
        rewardContinuation = nil
        didEarnReward = false

        do {
            rewardedAd = try await RewardedAd.load(with: adUnitID, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
        } catch {
            return false
        }

        guard let rewardedAd, let rootViewController = Self.rootViewController() else { return false }
        return await withCheckedContinuation { continuation in
            rewardContinuation = continuation
            rewardedAd.present(from: rootViewController) { [weak self] in
                self?.didEarnReward = true
            }
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardContinuation?.resume(returning: didEarnReward)
        rewardContinuation = nil
        rewardedAd = nil
        didEarnReward = false
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardContinuation?.resume(returning: false)
        rewardContinuation = nil
        rewardedAd = nil
        didEarnReward = false
    }

    private static func rootViewController() -> UIViewController? {
        #if canImport(UIKit)
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let root = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        return topViewController(from: root)
        #else
        return nil
        #endif
    }

    private static func topViewController(from viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        if let tabBarController = viewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(from: presented)
        }
        return viewController
    }
}
#endif
