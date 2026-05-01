import SwiftUI

struct MatchEffectOverlay: View {
    let effect: MatchEffect
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch effect.itemType {
                case .car:
                    carDriveEffect(in: proxy.size)
                case .gift:
                    confettiEffect
                case .apple:
                    burstEffect(symbols: ["🍎", "✨", "🍃"], color: .red)
                case .teddy:
                    burstEffect(symbols: ["🧸", "💛", "✨"], color: .brown)
                case .book:
                    burstEffect(symbols: ["📚", "📖", "✨"], color: .purple)
                case .cup:
                    burstEffect(symbols: ["☕️", "〰️", "✨"], color: .orange)
                case .plant:
                    burstEffect(symbols: ["🪴", "🍃", "✨"], color: .green)
                case .ball:
                    bounceEffect
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 1.65)) {
                isAnimating = true
            }
        }
    }

    private func carDriveEffect(in size: CGSize) -> some View {
        HStack(spacing: 8) {
            Text("🚗")
            Text("💨")
                .opacity(isAnimating ? 0.2 : 0.9)
        }
        .font(.system(size: 54))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .offset(
            x: isAnimating ? size.width + 120 : -150,
            y: size.height * 0.28
        )
        .scaleEffect(isAnimating ? 1.18 : 0.88)
        .opacity(isAnimating ? 0 : 1)
    }

    private var confettiEffect: some View {
        ZStack {
            ForEach(0..<22, id: \.self) { index in
                Text(confettiSymbol(for: index))
                    .font(.system(size: index.isMultiple(of: 3) ? 28 : 20))
                    .rotationEffect(.degrees(isAnimating ? Double(index * 27) : 0))
                    .offset(
                        x: isAnimating ? CGFloat((index % 7) - 3) * 42 : 0,
                        y: isAnimating ? CGFloat((index / 7) - 1) * 58 : 0
                    )
                    .scaleEffect(isAnimating ? 1.45 : 0.2)
                    .opacity(isAnimating ? 0.05 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sparkleEffect: some View {
        burstEffect(symbols: ["✨", "✦", "⭐️"], color: effect.itemType.color)
    }

    private var bounceEffect: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Text("⚽️")
                    .font(.system(size: 34))
                    .offset(
                        x: CGFloat(index - 2) * 34,
                        y: isAnimating ? CGFloat(abs(index - 2)) * 18 - 110 : 30
                    )
                    .scaleEffect(isAnimating ? 0.4 : 1.2)
                    .opacity(isAnimating ? 0.05 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func burstEffect(symbols: [String], color: Color) -> some View {
        ZStack {
            ForEach(0..<16, id: \.self) { index in
                Text(symbols[index % symbols.count])
                    .font(.system(size: index.isMultiple(of: 4) ? 30 : 22))
                    .foregroundStyle(color)
                    .offset(
                        x: isAnimating ? CGFloat((index % 8) - 3) * 36 : 0,
                        y: isAnimating ? CGFloat((index / 8) - 1) * 54 : 0
                    )
                    .rotationEffect(.degrees(isAnimating ? Double(index * 21) : 0))
                    .scaleEffect(isAnimating ? 1.38 : 0.1)
                    .opacity(isAnimating ? 0.04 : 0.95)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func confettiSymbol(for index: Int) -> String {
        ["🎁", "🎉", "✨", "💫", "⭐️"][index % 5]
    }
}
