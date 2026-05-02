import SwiftUI

struct LevelSelectView: View {
    let levelProvider: any LevelProvider
    let progressStore: any ProgressStore
    @StateObject private var viewModel: LevelSelectViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 132), spacing: 14)
    ]

    init(levelProvider: any LevelProvider, progressStore: any ProgressStore) {
        self.levelProvider = levelProvider
        self.progressStore = progressStore
        _viewModel = StateObject(
            wrappedValue: LevelSelectViewModel(
                levelProvider: levelProvider,
                progressStore: progressStore
            )
        )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.10, blue: 0.18),
                    Color(red: 0.18, green: 0.32, blue: 0.35),
                    Color(red: 0.76, green: 0.45, blue: 0.28).opacity(0.74)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    if viewModel.lives <= 0 {
                        Label("No lives left. Wait for refill or buy a life with diamonds after a fail.", systemImage: "heart.slash.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.28), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(viewModel.levels) { level in
                            if viewModel.canPlay(level) {
                                NavigationLink {
                                    GameFlowView(
                                        initialLevel: level,
                                        levelProvider: levelProvider,
                                        progressStore: progressStore
                                    )
                                } label: {
                                    LevelCard(
                                        level: level,
                                        stars: viewModel.bestStars(for: level),
                                        score: viewModel.bestScore(for: level),
                                        isLocked: false
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                LevelCard(
                                    level: level,
                                    stars: viewModel.bestStars(for: level),
                                    score: viewModel.bestScore(for: level),
                                    isLocked: !viewModel.isUnlocked(level),
                                    isOutOfLives: viewModel.isUnlocked(level) && viewModel.lives <= 0
                                )
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Levels")
        .onAppear { viewModel.refresh() }
    }
}

private struct LevelCard: View {
    let level: ShelfLevel
    let stars: Int
    let score: Int
    let isLocked: Bool
    var isOutOfLives = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(level.id)")
                    .font(.title.bold())
                Spacer()
                Image(systemName: isLocked ? "lock.fill" : (isOutOfLives ? "heart.slash.fill" : "tray.full.fill"))
                    .foregroundStyle(isLocked || isOutOfLives ? .secondary : level.theme.accent)
            }

            Text(level.title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(level.difficulty.rawValue.capitalized)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 2)

            if isLocked {
                Text("Locked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if isOutOfLives {
                Text("No lives")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                StarsView(stars: stars)
                Text(score > 0 ? "Best \(score)" : "No score yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(height: 150)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .opacity(isLocked || isOutOfLives ? 0.62 : 1)
        .accessibilityLabel(isLocked ? "Level \(level.id), locked" : "Level \(level.id), \(stars) stars, best score \(score)")
    }
}
