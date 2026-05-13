import SwiftUI

struct GameView: View {
    let progressStore: any ProgressStore
    let onNextLevel: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: GameViewModel
    @State private var showingSettings = false
    @State private var showingExitConfirmation = false
    @State private var showingLockTutorial = false
    @State private var backgroundMusicEnabled = true

    init(level: ShelfLevel, progressStore: any ProgressStore, onNextLevel: (() -> Void)? = nil) {
        self.progressStore = progressStore
        self.onNextLevel = onNextLevel
        let rewardedAdService: any RewardedAdManaging
        #if canImport(GoogleMobileAds)
        rewardedAdService = GoogleRewardedAdService()
        #else
        rewardedAdService = MockRewardedAdService()
        #endif
        _viewModel = StateObject(
            wrappedValue: GameViewModel(
                level: level,
                progressStore: progressStore,
                haptics: HapticsManager { progressStore.isHapticsEnabled },
                sound: SoundManager { progressStore.isGameSoundEnabled },
                rewardedAdService: rewardedAdService
            )
        )
    }

    var body: some View {
        ZStack {
            levelBackground

            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 700
                VStack(spacing: isCompactHeight ? 8 : 12) {
                    topBar
                    if let statusMessage = viewModel.unlockMessage ?? viewModel.hintMessage {
                        Text(statusMessage)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
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
                    canWatchAdForMoves: viewModel.canWatchRewardedAdForMoves,
                    isAdLoading: viewModel.isRewardedAdLoading,
                    onRetry: viewModel.retry,
                    onLevels: { dismiss() },
                    onBuyLife: viewModel.buyLifeWithDiamonds,
                    onWatchAdForMoves: viewModel.watchRewardedAdForExtraMoves,
                    onNext: onNextLevel
                )
            }

            if showingExitConfirmation {
                ExitConfirmationOverlay(
                    lives: viewModel.lives,
                    onKeepPlaying: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showingExitConfirmation = false
                        }
                        viewModel.resumeTimer()
                    },
                    onLeave: {
                        viewModel.abandonLevel()
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            if showingLockTutorial {
                LockTutorialOverlay {
                    progressStore.setHasSeenLockTutorial(true)
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        showingLockTutorial = false
                    }
                    viewModel.resumeTimer()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            backgroundMusicEnabled = progressStore.isBackgroundMusicEnabled
            BackgroundMusicManager.shared.setEnabled(viewModel.isBackgroundMusicEnabled)
            viewModel.startTimer()
            if viewModel.hasLockedItems && !progressStore.hasSeenLockTutorial {
                viewModel.pauseTimer()
                showingLockTutorial = true
            }
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            backgroundMusicEnabled = progressStore.isBackgroundMusicEnabled
            BackgroundMusicManager.shared.setEnabled(backgroundMusicEnabled)
            viewModel.resumeTimer()
        }) {
            NavigationStack {
                SettingsView(progressStore: progressStore)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
        .onChange(of: viewModel.invalidTargetPosition) { _, newValue in
            guard newValue != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                viewModel.clearInvalidTarget()
            }
        }
        .onChange(of: viewModel.matchedPositions) { _, newValue in
            guard newValue.isNotEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) {
                viewModel.clearTransientEffects()
            }
        }
        .onChange(of: viewModel.recentMatchEffects) { _, newValue in
            guard newValue.isNotEmpty, viewModel.matchedPositions.isEmpty else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) {
                viewModel.clearTransientEffects()
            }
        }
    }

    private var levelBackground: some View {
        ThemedRoomBackdrop(theme: viewModel.level.theme, colorScheme: colorScheme)
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    requestExit()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(viewModel.level.id)")
                        .font(.headline)
                    Text(viewModel.level.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    Label("\(viewModel.lives)", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                }
                .font(.caption.weight(.black))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())

                Button {
                    viewModel.pauseTimer()
                    showingSettings = true
                } label: {
                    Image(systemName: backgroundMusicEnabled ? "music.note" : "speaker.slash.fill")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }

            HStack(spacing: 8) {
                statPill(
                    title: "Time",
                    value: formattedTime(viewModel.timeRemaining),
                    systemImage: "timer",
                    tint: timeTint,
                    isWarning: viewModel.level.hasTimeLimit && viewModel.timeRemaining <= GameConstants.lowTimeWarningThreshold
                )
                statPill(
                    title: "Moves",
                    value: "\(viewModel.movesLeft)",
                    systemImage: "arrow.left.arrow.right",
                    tint: moveTint,
                    isWarning: viewModel.movesLeft <= GameConstants.lowMovesWarningThreshold
                )
                statPill(title: "Score", value: "\(viewModel.score)", systemImage: "sparkles", tint: .primary)
            }
        }
    }

    private var shelvesArea: some View {
        GeometryReader { proxy in
            let spacing = shelfSpacing(for: proxy.size.height)
            let shelfHeight = shelfHeight(containerHeight: proxy.size.height, spacing: spacing)
            VStack(spacing: spacing) {
                ForEach(viewModel.shelves.indices, id: \.self) { shelfIndex in
                        ShelfView(
                            shelf: viewModel.shelves[shelfIndex],
                            shelfIndex: shelfIndex,
                            selectedPosition: viewModel.selectedPosition,
                            matchedPositions: viewModel.matchedPositions,
                            hintPositions: viewModel.hintPositions,
                            invalidTargetPosition: viewModel.invalidTargetPosition,
                            theme: viewModel.level.theme,
                            preferredHeight: shelfHeight
                        ) { position in
                        handleTap(position)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        .padding(.vertical, 8)
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

    private var timeTint: Color {
        guard viewModel.level.hasTimeLimit else { return .primary }
        if viewModel.timeRemaining <= 5 { return .red }
        if viewModel.timeRemaining <= GameConstants.lowTimeWarningThreshold { return .orange }
        return .primary
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        guard viewModel.level.hasTimeLimit else { return "∞" }
        let totalSeconds = max(0, Int(ceil(seconds)))
        return "\(totalSeconds / 60):\(String(format: "%02d", totalSeconds % 60))"
    }

    private func requestExit() {
        guard viewModel.status == .playing else {
            dismiss()
            return
        }
        viewModel.pauseTimer()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            showingExitConfirmation = true
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        width < 380 ? 10 : 16
    }

    private func shelfSpacing(for height: CGFloat) -> CGFloat {
        height < 480 ? 7 : 10
    }

    private func shelfHeight(containerHeight: CGFloat, spacing: CGFloat) -> CGFloat {
        let shelfCount = CGFloat(max(viewModel.shelves.count, 1))
        let availableHeight = containerHeight - spacing * CGFloat(max(viewModel.shelves.count - 1, 0))
        return min(86, max(68, availableHeight / shelfCount))
    }
}

private struct ExitConfirmationOverlay: View {
    let lives: Int
    let onKeepPlaying: () -> Void
    let onLeave: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.34)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.pink)
                    .frame(width: 76, height: 76)
                    .background(.pink.opacity(0.16), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                VStack(spacing: 7) {
                    Text("Leave this level?")
                        .font(.title2.weight(.black))
                    Text("Your current board will reset and leaving now costs 1 life. You have \(lives) lives right now.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button {
                        onKeepPlaying()
                    } label: {
                        Label("Keep Playing", systemImage: "play.fill")
                            .font(.headline.weight(.black))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(role: .destructive) {
                        onLeave()
                    } label: {
                        Label("Leave and Lose 1 Life", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.44), lineWidth: 1.2)
            }
            .padding(24)
        }
    }
}

private struct LockTutorialOverlay: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.30)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.purple.opacity(0.16))
                        .frame(width: 92, height: 92)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 38, weight: .black))
                        .foregroundStyle(.purple)
                }

                VStack(spacing: 8) {
                    Text("Locked Items")
                        .font(.title2.weight(.black))
                    Text("Locks start appearing here. Match the same item right next to a lock, or make a five-item match of that type, to unlock it.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 8) {
                    Text("📚")
                    Image(systemName: "lock.fill")
                    Text("+")
                    Text("📚📚📚")
                }
                .font(.title2.weight(.black))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(.white.opacity(0.58), in: Capsule())

                Button {
                    onContinue()
                } label: {
                    Text("Got it")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(22)
            .frame(maxWidth: 350)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.44), lineWidth: 1.2)
            }
            .padding(24)
        }
    }
}

private struct ThemedRoomBackdrop: View {
    let theme: ShelfTheme
    let colorScheme: ColorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let assetName = theme.backgroundAssetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .black.opacity(colorScheme == .dark ? 0.36 : 0.14),
                                    theme.accent.opacity(0.06),
                                    .black.opacity(colorScheme == .dark ? 0.28 : 0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                } else {
                    LinearGradient(colors: theme.roomGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                }

                wallPattern(size: proxy.size)
                    .opacity(theme.backgroundAssetName == nil ? (colorScheme == .dark ? 0.14 : 0.22) : 0.06)

                decorLayer(size: proxy.size)
                    .opacity(theme.backgroundAssetName == nil ? 1 : 0.34)

                VStack(spacing: 0) {
                    Spacer()
                    floorBand
                        .frame(height: max(140, proxy.size.height * 0.27))
                }

                foregroundMotif(size: proxy.size)
            }
            .ignoresSafeArea()
        }
    }

    private func wallPattern(size: CGSize) -> some View {
        let columns = max(5, Int(size.width / 74))
        let rows = max(5, Int(size.height / 92))

        return ZStack {
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { column in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                        .frame(width: 48, height: 34)
                        .offset(x: CGFloat(column) * 74 - size.width * 0.48 + CGFloat(row % 2) * 26,
                                y: CGFloat(row) * 92 - size.height * 0.42)
                }
            }
        }
    }

    private func decorLayer(size: CGSize) -> some View {
        ZStack {
            ForEach(Array(theme.decorSymbols.enumerated()), id: \.offset) { index, symbol in
                Image(systemName: symbol)
                    .font(.system(size: size.width < 380 ? 24 : 30, weight: .black))
                    .foregroundStyle(.white.opacity(0.18))
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -9 : 12))
                    .offset(x: decorOffsetX(index: index, width: size.width),
                            y: decorOffsetY(index: index, height: size.height))
            }
        }
    }

    private var floorBand: some View {
        LinearGradient(
            colors: [
                theme.accent.opacity(0.02),
                theme.accent.opacity(0.32),
                Color(red: 1.00, green: 0.62, blue: 0.34).opacity(0.72)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.18))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func foregroundMotif(size: CGSize) -> some View {
        switch theme.foregroundMotif {
        case "cabinet":
            motifCabinet(size: size)
        case "blocks":
            motifBlocks(size: size)
        case "bookcase":
            motifBookcase(size: size)
        case "leaves":
            motifLeaves(size: size)
        case "tiles":
            motifTiles(size: size)
        case "lights":
            motifLights(size: size)
        case "workbench":
            motifWorkbench(size: size)
        case "hills":
            motifHills(size: size)
        default:
            motifDesk(size: size)
        }
    }

    private func motifCabinet(size: CGSize) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.10))
                    .frame(width: size.width * 0.22, height: 72)
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(.white.opacity(0.28))
                            .frame(width: 8, height: 8)
                            .padding(14)
                    }
                    .offset(y: index == 1 ? 10 : 0)
            }
        }
        .offset(y: -size.height * 0.34)
    }

    private func motifBlocks(size: CGSize) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(blockColor(for: index).opacity(0.36))
                    .frame(width: 34, height: CGFloat(24 + (index % 3) * 12))
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -8 : 7))
            }
        }
        .offset(x: -size.width * 0.26, y: size.height * 0.34)
    }

    private func motifBookcase(size: CGSize) -> some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { shelf in
                HStack(spacing: 5) {
                    ForEach(0..<8, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(bookColor(for: index + shelf).opacity(0.32))
                            .frame(width: 12, height: CGFloat(30 + ((index + shelf) % 3) * 10))
                    }
                }
                Capsule()
                    .fill(Color(red: 0.46, green: 0.22, blue: 0.12).opacity(0.38))
                    .frame(width: 142, height: 7)
            }
        }
        .offset(x: size.width * 0.26, y: -size.height * 0.30)
    }

    private func motifLeaves(size: CGSize) -> some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(Color.green.opacity(0.18 + Double(index % 3) * 0.05))
                    .frame(width: 32, height: 82)
                    .rotationEffect(.degrees(Double(index) * 31 - 88))
                    .offset(x: CGFloat(index - 3) * 28, y: CGFloat(index % 2) * 18)
            }
        }
        .offset(x: -size.width * 0.32, y: -size.height * 0.28)
    }

    private func motifTiles(size: CGSize) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(38), spacing: 7), count: 4), spacing: 7) {
            ForEach(0..<16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill((index.isMultiple(of: 2) ? Color.cyan : Color.white).opacity(0.16))
                    .frame(width: 38, height: 38)
            }
        }
        .offset(x: size.width * 0.28, y: -size.height * 0.31)
    }

    private func motifLights(size: CGSize) -> some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill((index.isMultiple(of: 2) ? Color.yellow : Color.pink).opacity(0.34))
                    .frame(width: 18, height: 18)
                    .shadow(color: .yellow.opacity(0.28), radius: 10)
            }
        }
        .padding(14)
        .background(.white.opacity(0.08), in: Capsule())
        .offset(y: -size.height * 0.36)
    }

    private func motifWorkbench(size: CGSize) -> some View {
        VStack(spacing: 9) {
            Capsule()
                .fill(.orange.opacity(0.32))
                .frame(width: size.width * 0.58, height: 14)
            HStack(spacing: 16) {
                Image(systemName: "wrench.and.screwdriver.fill")
                Image(systemName: "gearshape.2.fill")
                Image(systemName: "car.fill")
            }
            .font(.title3.weight(.black))
            .foregroundStyle(.white.opacity(0.18))
        }
        .offset(y: size.height * 0.35)
    }

    private func motifHills(size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            Triangle()
                .fill(Color.green.opacity(0.22))
                .frame(width: size.width * 0.54, height: 130)
                .offset(x: -size.width * 0.20)
            Triangle()
                .fill(Color.mint.opacity(0.18))
                .frame(width: size.width * 0.48, height: 108)
                .offset(x: size.width * 0.18)
            Image(systemName: "tent.fill")
                .font(.system(size: 46, weight: .black))
                .foregroundStyle(.orange.opacity(0.28))
                .offset(x: size.width * 0.27, y: -12)
        }
        .offset(y: size.height * 0.32)
    }

    private func motifDesk(size: CGSize) -> some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: size.width * 0.62, height: 16)
            HStack(spacing: 20) {
                Image(systemName: "folder.fill")
                Image(systemName: "pencil")
                Image(systemName: "paperclip")
            }
            .font(.title2.weight(.black))
            .foregroundStyle(.white.opacity(0.18))
        }
        .offset(y: size.height * 0.35)
    }

    private func decorOffsetX(index: Int, width: CGFloat) -> CGFloat {
        switch index {
        case 0: -width * 0.34
        case 1: width * 0.34
        default: width * 0.08
        }
    }

    private func decorOffsetY(index: Int, height: CGFloat) -> CGFloat {
        switch index {
        case 0: -height * 0.34
        case 1: -height * 0.18
        default: height * 0.28
        }
    }

    private func blockColor(for index: Int) -> Color {
        [Color.pink, .yellow, .cyan, .mint, .purple][index % 5]
    }

    private func bookColor(for index: Int) -> Color {
        [Color.indigo, .purple, .orange, .brown][index % 4]
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
