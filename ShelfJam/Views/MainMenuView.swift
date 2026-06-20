import SwiftUI

struct MainMenuView: View {
    let progressStore: any ProgressStore
    let levelProvider: any LevelProvider
    private let rewardedAdService: any RewardedAdManaging
    @State private var lives = GameConstants.maxLives
    @State private var diamonds = 0
    @State private var showingShop = false
    @State private var showingOnboarding = false

    init(progressStore: any ProgressStore, levelProvider: any LevelProvider) {
        self.progressStore = progressStore
        self.levelProvider = levelProvider
        #if canImport(GoogleMobileAds)
        self.rewardedAdService = GoogleRewardedAdService()
        #else
        self.rewardedAdService = MockRewardedAdService()
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("ThemeKitchen")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay {
                        LinearGradient(
                            colors: [
                                .black.opacity(0.22),
                                .black.opacity(0.03),
                                Color(red: 0.96, green: 0.38, blue: 0.48).opacity(0.25)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }

                VStack(spacing: 20) {
                    Spacer(minLength: 20)

                    VStack(spacing: 8) {
                        Text("Shelf Jam")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.00, green: 0.92, blue: 0.24),
                                        Color(red: 1.00, green: 0.52, blue: 0.86),
                                        Color(red: 0.72, green: 0.46, blue: 1.00)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.70), radius: 16, y: 5)
                            .shadow(color: .black.opacity(0.42), radius: 8, y: 3)
                        Text("Cozy sorting puzzle")
                            .font(.title3.weight(.black))
                            .foregroundStyle(.white.opacity(0.92))
                            .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
                    }
                    .accessibilityElement(children: .combine)

                    VStack(spacing: 16) {
                        HStack(spacing: 10) {
                            Button {
                                showingShop = true
                            } label: {
                                menuStat(title: "Lives", value: "\(lives)/\(GameConstants.maxLives)", systemImage: "heart.fill", tint: .pink)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open shop for lives")

                            Button {
                                showingShop = true
                            } label: {
                                menuStat(title: "Diamonds", value: "\(diamonds)", systemImage: "diamond.fill", tint: .cyan)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Open shop for diamonds")
                        }

                        VStack(spacing: 12) {
                            if let continueLevel = levelProvider.level(id: min(progressStore.getHighestUnlockedLevel(), levelProvider.levels.count)) {
                                NavigationLink {
                                    GameFlowView(
                                        initialLevel: continueLevel,
                                        levelProvider: levelProvider,
                                        progressStore: progressStore
                                    )
                                } label: {
                                    Label("Continue", systemImage: "play.fill")
                                        .font(.headline.weight(.black))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryMenuButtonStyle())
                                .disabled(lives <= 0)
                            }

                            NavigationLink {
                                LevelSelectView(levelProvider: levelProvider, progressStore: progressStore)
                            } label: {
                                Label("Play", systemImage: "square.grid.2x2.fill")
                                    .font(.headline.weight(.black))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryMenuButtonStyle())
                        }

                        HStack(spacing: 10) {
                            NavigationLink {
                                SettingsView(progressStore: progressStore)
                            } label: {
                                Label("Settings", systemImage: "gearshape.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassMenuButtonStyle())

                            Button {
                                showingShop = true
                            } label: {
                                Label("Shop", systemImage: "bag.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassMenuButtonStyle())
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(
                                LinearGradient(colors: [.white.opacity(0.72), .yellow.opacity(0.35), .purple.opacity(0.42)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.6
                            )
                    }
                    .shadow(color: .purple.opacity(0.24), radius: 22, y: 12)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 520)
            }
            .onAppear {
                refreshEconomy()
                BackgroundMusicManager.shared.setEnabled(progressStore.isBackgroundMusicEnabled)
                showingOnboarding = !progressStore.hasSeenOnboarding
            }
            .sheet(isPresented: $showingShop, onDismiss: refreshEconomy) {
                ShopView(
                    progressStore: progressStore,
                    rewardedAdService: rewardedAdService,
                    onChanged: refreshEconomy
                )
                .presentationDetents([.large])
            }
            .fullScreenCover(isPresented: $showingOnboarding, onDismiss: refreshEconomy) {
                OnboardingView {
                    progressStore.setHasSeenOnboarding(true)
                    showingOnboarding = false
                }
            }
        }
    }

    private func refreshEconomy() {
        lives = progressStore.getLives()
        diamonds = progressStore.getDiamonds()
    }

    private func menuStat(title: String, value: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.black))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.20, green: 0.10, blue: 0.36).opacity(0.78), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.42), lineWidth: 1.2)
        }
        .foregroundStyle(.white)
    }
}

private struct PrimaryMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 15)
            .foregroundStyle(Color(red: 0.18, green: 0.08, blue: 0.30))
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.94, blue: 0.28),
                        Color(red: 1.00, green: 0.64, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: .yellow.opacity(0.35), radius: 14, y: 8)
    }
}

private struct SecondaryMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.73, green: 0.38, blue: 1.00),
                        Color(red: 0.98, green: 0.38, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: .purple.opacity(0.32), radius: 14, y: 8)
    }
}

private struct GlassMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.black))
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(Color.white.opacity(configuration.isPressed ? 0.18 : 0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
            }
    }
}

#Preview {
    MainMenuView(progressStore: UserDefaultsProgressStore(defaults: .standard), levelProvider: StaticLevelProvider())
}
