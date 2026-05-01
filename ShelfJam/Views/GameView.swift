import SwiftUI

struct GameView: View {
    let onNextLevel: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: GameViewModel

    init(level: ShelfLevel, progressStore: any ProgressStore, onNextLevel: (() -> Void)? = nil) {
        self.onNextLevel = onNextLevel
        _viewModel = StateObject(
            wrappedValue: GameViewModel(
                level: level,
                progressStore: progressStore,
                haptics: HapticsManager { progressStore.isHapticsEnabled },
                sound: SoundManager { progressStore.isSoundEnabled }
            )
        )
    }

    var body: some View {
        ZStack {
            levelBackground

            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 700
                VStack(spacing: isCompactHeight ? 10 : 16) {
                    topBar
                    if let hintMessage = viewModel.hintMessage {
                        Text(hintMessage)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    shelvesArea
                    Spacer(minLength: 2)
                    actionBar
                }
                .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                .padding(.top, isCompactHeight ? 8 : 14)
                .padding(.bottom, isCompactHeight ? 8 : 14)
            }

            if viewModel.showComboText {
                Text("Combo x\(viewModel.comboCount)!")
                    .font(.title.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: [.pink, .orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: .pink.opacity(0.35), radius: 18, y: 8)
                    .transition(.scale.combined(with: .opacity))
            }

            ForEach(viewModel.recentMatchEffects) { effect in
                MatchEffectOverlay(effect: effect)
                    .transition(.opacity)
            }

            if viewModel.status != .playing {
                LevelResultOverlay(
                    status: viewModel.status,
                    score: viewModel.score,
                    movesLeft: viewModel.movesLeft,
                    lives: viewModel.lives,
                    diamonds: viewModel.diamonds,
                    earnedDiamonds: viewModel.earnedDiamonds,
                    canBuyLife: viewModel.diamonds >= GameConstants.lifeDiamondCost && viewModel.lives < GameConstants.maxLives,
                    onRetry: viewModel.retry,
                    onLevels: { dismiss() },
                    onBuyLife: viewModel.buyLifeWithDiamonds,
                    onNext: onNextLevel
                )
            }
        }
        .navigationBarBackButtonHidden()
        .onChange(of: viewModel.invalidTargetPosition) { _, newValue in
            guard newValue != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                viewModel.clearInvalidTarget()
            }
        }
        .onChange(of: viewModel.matchedPositions) { _, newValue in
            guard newValue.isNotEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
                viewModel.clearTransientEffects()
            }
        }
    }

    private var levelBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.11, blue: 0.38),
                    Color(red: 0.16, green: 0.44, blue: 0.62),
                    Color(red: 0.98, green: 0.52, blue: 0.47),
                    Color(red: 1.00, green: 0.75, blue: 0.38)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [
                    viewModel.level.theme.accent.opacity(colorScheme == .dark ? 0.24 : 0.32),
                    Color.white.opacity(colorScheme == .dark ? 0.04 : 0.16),
                    Color.black.opacity(colorScheme == .dark ? 0.22 : 0.02)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            Circle()
                .fill(.cyan.opacity(colorScheme == .dark ? 0.10 : 0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 52)
                .offset(x: 150, y: -260)
            Circle()
                .fill(.yellow.opacity(colorScheme == .dark ? 0.08 : 0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 64)
                .offset(x: -170, y: 320)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.level.title)
                        .font(.headline)
                Text(viewModel.level.theme.title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()
            }

            HStack(spacing: 10) {
                statPill(
                    title: "Moves",
                    value: "\(viewModel.movesLeft)",
                    systemImage: "arrow.left.arrow.right",
                    tint: moveTint,
                    isWarning: viewModel.movesLeft <= GameConstants.lowMovesWarningThreshold
                )
                statPill(title: "Score", value: "\(viewModel.score)", systemImage: "sparkles", tint: .primary)
            }
            HStack(spacing: 10) {
                economyPill(title: "Lives", value: "\(viewModel.lives)/\(GameConstants.maxLives)", systemImage: "heart.fill", tint: .pink)
                economyPill(title: "Diamonds", value: "\(viewModel.diamonds)", systemImage: "diamond.fill", tint: .cyan)
            }
        }
    }

    private var shelvesArea: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: shelfSpacing(for: proxy.size.height)) {
                    ForEach(viewModel.shelves.indices, id: \.self) { shelfIndex in
                        ShelfView(
                            shelf: viewModel.shelves[shelfIndex],
                            shelfIndex: shelfIndex,
                            selectedPosition: viewModel.selectedPosition,
                            matchedPositions: viewModel.matchedPositions,
                            hintPositions: viewModel.hintPositions,
                            invalidTargetPosition: viewModel.invalidTargetPosition
                        ) { position in
                            handleTap(position)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            ActionButtonView(
                title: "Undo \(viewModel.undoUsesLeft)",
                systemImage: "arrow.uturn.backward",
                isEnabled: viewModel.canUndo,
                action: viewModel.undo
            )
            ActionButtonView(title: "Hint \(viewModel.hintUsesLeft)", systemImage: "lightbulb", isEnabled: viewModel.canUseHint) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.74)) {
                    viewModel.useHint()
                }
            }
            ActionButtonView(title: "Shuffle \(viewModel.shuffleUsesLeft)", systemImage: "shuffle", isEnabled: viewModel.canShuffle) {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                    viewModel.shuffle()
                }
            }
        }
    }

    private func statPill(title: String, value: String, systemImage: String, tint: Color, isWarning: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.black))
                    .foregroundStyle(tint)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isWarning ? tint.opacity(0.24) : Color.white.opacity(colorScheme == .dark ? 0.14 : 0.72))
                .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isWarning ? tint.opacity(0.7) : .white.opacity(0.34), lineWidth: 1.5)
        }
        .scaleEffect(isWarning ? 1.03 : 1)
        .animation(.easeInOut(duration: 0.55).repeatCount(isWarning ? 4 : 1, autoreverses: true), value: isWarning)
    }

    private func economyPill(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.weight(.black))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.66), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.26), lineWidth: 1)
        }
    }

    private func handleTap(_ position: Position) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            if viewModel.selectedPosition != nil {
                if viewModel.item(at: position) == nil {
                    viewModel.moveSelectedItem(to: position)
                } else if viewModel.selectedPosition == position {
                    viewModel.selectItem(at: position)
                } else {
                    viewModel.moveSelectedItem(to: position)
                }
            } else {
                viewModel.selectItem(at: position)
            }
        }
    }

    private var moveTint: Color {
        if viewModel.movesLeft <= 1 { return .red }
        if viewModel.movesLeft <= GameConstants.lowMovesWarningThreshold { return .orange }
        return .primary
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 380 ? 10 : 16
    }

    private func shelfSpacing(for height: CGFloat) -> CGFloat {
        height < 480 ? 8 : 12
    }
}
