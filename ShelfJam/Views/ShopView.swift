import SwiftUI

struct ShopView: View {
    let progressStore: any ProgressStore
    let rewardedAdService: any RewardedAdManaging
    let onChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var lives = GameConstants.maxLives
    @State private var diamonds = 0
    @State private var undoInventory = 0
    @State private var hintInventory = 0
    @State private var shuffleInventory = 0
    @State private var loadingAction: ShopAdAction?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.11, blue: 0.28),
                        Color(red: 0.16, green: 0.38, blue: 0.47),
                        Color(red: 1.00, green: 0.56, blue: 0.36)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        walletCard

                        shopSection(title: "Lives", subtitle: "Keep playing when a challenge bites back.") {
                            shopRow(
                                icon: "heart.fill",
                                tint: .pink,
                                title: "+1 Life",
                                subtitle: "\(GameConstants.lifeDiamondCost) diamonds",
                                buttonTitle: "Buy"
                            ) {
                                buyLifeWithDiamonds()
                            }

                            shopRow(
                                icon: "play.rectangle.fill",
                                tint: .orange,
                                title: "+1 Life",
                                subtitle: "Watch a rewarded test ad",
                                buttonTitle: loadingAction == .life ? "Loading..." : "Watch"
                            ) {
                                watchAdForLife()
                            }
                            .disabled(loadingAction != nil)
                        }

                        shopSection(title: "Boosts", subtitle: "Small help, expensive enough to matter.") {
                            shopRow(icon: "arrow.uturn.backward", tint: .mint, title: "Undo x2", subtitle: "\(GameConstants.undoPackCost) diamonds", buttonTitle: "Buy") {
                                buyPack(cost: GameConstants.undoPackCost, success: { progressStore.addUndoInventory(2) }, name: "Undo x2")
                            }
                            shopRow(icon: "lightbulb.fill", tint: .yellow, title: "Tip x2", subtitle: "\(GameConstants.hintPackCost) diamonds", buttonTitle: "Buy") {
                                buyPack(cost: GameConstants.hintPackCost, success: { progressStore.addHintInventory(2) }, name: "Tip x2")
                            }
                            shopRow(icon: "shuffle", tint: .cyan, title: "Shuffle x1", subtitle: "\(GameConstants.shufflePackCost) diamonds", buttonTitle: "Buy") {
                                buyPack(cost: GameConstants.shufflePackCost, success: { progressStore.addShuffleInventory(1) }, name: "Shuffle x1")
                            }
                        }

                        shopSection(title: "Diamonds", subtitle: "Temporary MVP pack until payments are added.") {
                            shopRow(
                                icon: "diamond.fill",
                                tint: .cyan,
                                title: "+\(GameConstants.adDiamondReward) Diamonds",
                                subtitle: "Watch a rewarded test ad",
                                buttonTitle: loadingAction == .diamonds ? "Loading..." : "Watch"
                            ) {
                                watchAdForDiamonds()
                            }
                            .disabled(loadingAction != nil)
                        }

                        if let message {
                            Text(message)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.88))
                                .padding(.top, 4)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: refresh)
        }
    }

    private var walletCard: some View {
        HStack(spacing: 12) {
            walletPill(icon: "heart.fill", value: "\(lives)/\(GameConstants.maxLives)", tint: .pink)
            walletPill(icon: "diamond.fill", value: "\(diamonds)", tint: .cyan)
            walletPill(icon: "sparkles", value: "\(undoInventory + hintInventory + shuffleInventory)", tint: .yellow)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func walletPill(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(.headline.weight(.black))
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
    }

    private func shopSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.black))
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        }
    }

    private func shopRow(icon: String, tint: Color, title: String, subtitle: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(12)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func buyLifeWithDiamonds() {
        guard lives < GameConstants.maxLives else {
            message = "Lives are already full."
            return
        }
        guard progressStore.spendDiamonds(GameConstants.lifeDiamondCost) else {
            message = "Not enough diamonds."
            return
        }
        progressStore.addLife()
        message = "+1 life added."
        refreshAndNotify()
    }

    private func buyPack(cost: Int, success: () -> Void, name: String) {
        guard progressStore.spendDiamonds(cost) else {
            message = "Not enough diamonds."
            return
        }
        success()
        message = "\(name) added."
        refreshAndNotify()
    }

    private func watchAdForLife() {
        guard lives < GameConstants.maxLives else {
            message = "Lives are already full."
            return
        }
        Task {
            loadingAction = .life
            let rewarded = await rewardedAdService.showRewardedStoreAd()
            if rewarded {
                progressStore.addLife()
                message = "+1 life added."
            } else {
                message = "Reward was not completed."
            }
            loadingAction = nil
            refreshAndNotify()
        }
    }

    private func watchAdForDiamonds() {
        Task {
            loadingAction = .diamonds
            let rewarded = await rewardedAdService.showRewardedStoreAd()
            if rewarded {
                progressStore.addDiamonds(GameConstants.adDiamondReward)
                message = "+\(GameConstants.adDiamondReward) diamonds added."
            } else {
                message = "Reward was not completed."
            }
            loadingAction = nil
            refreshAndNotify()
        }
    }

    private func refreshAndNotify() {
        refresh()
        onChanged()
    }

    private func refresh() {
        lives = progressStore.getLives()
        diamonds = progressStore.getDiamonds()
        undoInventory = progressStore.getUndoInventory()
        hintInventory = progressStore.getHintInventory()
        shuffleInventory = progressStore.getShuffleInventory()
    }
}

private enum ShopAdAction {
    case life
    case diamonds
}

