import SwiftUI

struct LevelResultOverlay: View {
    let status: LevelStatus
    let score: Int
    let movesLeft: Int
    let lives: Int
    let diamonds: Int
    let earnedDiamonds: Int
    let canBuyLife: Bool
    let canWatchAdForMoves: Bool
    let isAdLoading: Bool
    let onRetry: () -> Void
    let onLevels: () -> Void
    let onBuyLife: () -> Void
    let onWatchAdForMoves: () -> Void
    let onNext: (() -> Void)?
    @State private var contentVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                switch status {
                case .completed(let stars, let finalScore):
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.yellow)
                        .scaleEffect(contentVisible ? 1 : 0.7)
                    Text("Shelf cleared!")
                        .font(.largeTitle.bold())
                    AnimatedStarsView(stars: stars)
                    Text("Score \(finalScore)")
                        .font(.title3.weight(.semibold))
                    Text("\(movesLeft) moves left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if earnedDiamonds > 0 {
                        Label("+\(earnedDiamonds) diamonds", systemImage: "diamond.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.cyan)
                    }
                    if let onNext {
                        Button("Next Level", action: onNext)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    }
                case .failed:
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.orange)
                    Text("So close")
                        .font(.largeTitle.bold())
                    Text("The shelf still needs a little sorting.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Label("\(lives)/\(GameConstants.maxLives) lives left", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Button {
                        onBuyLife()
                    } label: {
                        Label("Buy Life \(GameConstants.lifeDiamondCost)", systemImage: "diamond.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canBuyLife)
                    Button {
                        onWatchAdForMoves()
                    } label: {
                        Label(isAdLoading ? "Loading..." : "Watch Ad +5 Moves", systemImage: "play.rectangle.fill")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canWatchAdForMoves)
                case .playing:
                    EmptyView()
                }

                Label("\(diamonds) diamonds", systemImage: "diamond.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan)

                HStack(spacing: 12) {
                    Button("Retry", action: onRetry)
                        .buttonStyle(.bordered)
                        .disabled(status == .failed && lives <= 0)
                    Button("Levels", action: onLevels)
                        .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
            .padding()
            .scaleEffect(contentVisible ? 1 : 0.92)
            .opacity(contentVisible ? 1 : 0)
            .animation(.spring(response: 0.42, dampingFraction: 0.8), value: contentVisible)
        }
        .onAppear {
            contentVisible = true
        }
    }
}

private struct AnimatedStarsView: View {
    let stars: Int
    @State private var visibleStars = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(index <= stars ? .yellow : .secondary)
                    .scaleEffect(index <= visibleStars ? 1 : 0.25)
                    .opacity(index <= visibleStars || index > stars ? 1 : 0)
                    .rotationEffect(.degrees(index <= visibleStars ? 0 : -24))
                    .animation(.spring(response: 0.34, dampingFraction: 0.55).delay(Double(index) * 0.12), value: visibleStars)
            }
        }
        .accessibilityLabel("\(stars) out of 3 stars")
        .onAppear {
            visibleStars = stars
        }
    }
}
