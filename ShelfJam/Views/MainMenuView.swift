import SwiftUI

struct MainMenuView: View {
    let progressStore: any ProgressStore
    let levelProvider: any LevelProvider
    @State private var lives = GameConstants.maxLives
    @State private var diamonds = 0

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.11, green: 0.10, blue: 0.18),
                        Color(red: 0.17, green: 0.35, blue: 0.36),
                        Color(red: 0.94, green: 0.53, blue: 0.33)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 22) {
                    Spacer(minLength: 20)

                    VStack(spacing: 8) {
                        Text("Shelf Jam")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Cozy sorting puzzle")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .accessibilityElement(children: .combine)

                    HStack(spacing: 10) {
                        menuStat(title: "Lives", value: "\(lives)/\(GameConstants.maxLives)", systemImage: "heart.fill", tint: .pink)
                        menuStat(title: "Diamonds", value: "\(diamonds)", systemImage: "diamond.fill", tint: .cyan)
                    }

                    VStack(spacing: 14) {
                        if let continueLevel = levelProvider.level(id: min(progressStore.getHighestUnlockedLevel(), levelProvider.levels.count)) {
                            NavigationLink {
                                GameFlowView(
                                    initialLevel: continueLevel,
                                    levelProvider: levelProvider,
                                    progressStore: progressStore
                                )
                            } label: {
                                Label("Continue", systemImage: "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }

                        NavigationLink {
                            LevelSelectView(levelProvider: levelProvider, progressStore: progressStore)
                        } label: {
                            Label("Play", systemImage: "square.grid.2x2.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    NavigationLink {
                        SettingsView(progressStore: progressStore)
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .buttonStyle(.bordered)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 520)
            }
            .onAppear {
                lives = progressStore.getLives()
                diamonds = progressStore.getDiamonds()
            }
        }
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    MainMenuView(progressStore: UserDefaultsProgressStore(defaults: .standard), levelProvider: StaticLevelProvider())
}
