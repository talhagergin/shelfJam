import Foundation

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

protocol RewardedAdManaging {
    func showRewardedExtraMovesAd() async -> Bool
}

struct MockRewardedAdService: RewardedAdManaging {
    func showRewardedExtraMovesAd() async -> Bool {
        try? await Task.sleep(nanoseconds: 850_000_000)
        return true
    }
}

// Google Mobile Ads integration point:
// Replace MockRewardedAdService with a GoogleMobileAds-backed implementation
// that loads RewardedAd with the AdMob test unit, presents it, and returns true
// only from the userDidEarnReward handler.

#if canImport(GoogleMobileAds)
@MainActor
final class GoogleRewardedAdService: NSObject, RewardedAdManaging, FullScreenContentDelegate {
    private var rewardedAd: RewardedAd?
    private let adUnitID: String

    init(adUnitID: String = "ca-app-pub-3940256099942544/1712485313") {
        self.adUnitID = adUnitID
        super.init()
    }

    func showRewardedExtraMovesAd() async -> Bool {
        do {
            rewardedAd = try await RewardedAd.load(with: adUnitID, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
        } catch {
            return false
        }

        guard let rewardedAd else { return false }
        return await withCheckedContinuation { continuation in
            rewardedAd.present(from: nil) {
                continuation.resume(returning: true)
            }
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
    }
}
#endif
