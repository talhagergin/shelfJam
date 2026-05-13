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
                case .ball:
                    bounceEffect
                default:
                    burstEffect(itemType: effect.itemType, symbols: ["✨", "✦"], color: effect.itemType.color)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 2.3)) {
                isAnimating = true
            }
        }
    }

    private func carDriveEffect(in size: CGSize) -> some View {
        HStack(spacing: 8) {
            effectImage(.car, size: 96)
            HStack(spacing: -8) {
                Text("💨")
                Text("💨")
                    .opacity(0.72)
                Text("💨")
                    .opacity(0.46)
            }
            .opacity(isAnimating ? 0.12 : 0.95)
        }
        .font(.system(size: 72))
        .shadow(color: .black.opacity(0.24), radius: 12, y: 6)
        .offset(
            x: isAnimating ? -210 : size.width + 180,
            y: size.height * 0.28
        )
        .scaleEffect(isAnimating ? 1.22 : 0.78)
        .opacity(isAnimating ? 0 : 1)
    }

    private var confettiEffect: some View {
        ZStack {
            effectImage(.gift, size: 96)
                .scaleEffect(isAnimating ? 1.45 : 0.72)
                .opacity(isAnimating ? 0 : 1)
            ForEach(0..<22, id: \.self) { index in
                Text(confettiSymbol(for: index))
                    .font(.system(size: index.isMultiple(of: 3) ? 42 : 30))
                    .rotationEffect(.degrees(isAnimating ? Double(index * 27) : 0))
                    .offset(
                        x: isAnimating ? CGFloat((index % 11) - 5) * 34 : 0,
                        y: isAnimating ? CGFloat((index / 11) - 1) * 88 : 0
                    )
                    .scaleEffect(isAnimating ? 1.7 : 0.15)
                    .opacity(isAnimating ? 0.03 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sparkleEffect: some View {
        burstEffect(itemType: effect.itemType, symbols: ["✨", "✦", "⭐️"], color: effect.itemType.color)
    }

    private var bounceEffect: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                effectImage(.ball, size: 56)
                    .offset(
                        x: CGFloat(index - 3) * 34,
                        y: isAnimating ? CGFloat(abs(index - 3)) * 20 - 150 : 38
                    )
                    .scaleEffect(isAnimating ? 0.36 : 1.35)
                    .opacity(isAnimating ? 0.03 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func burstEffect(itemType: ShelfItemType, symbols: [String], color: Color) -> some View {
        ZStack {
            effectImage(itemType, size: 92)
                .scaleEffect(isAnimating ? 1.5 : 0.55)
                .opacity(isAnimating ? 0 : 0.95)
            ForEach(0..<16, id: \.self) { index in
                Text(symbols[index % symbols.count])
                    .font(.system(size: index.isMultiple(of: 4) ? 46 : 34))
                    .foregroundStyle(color)
                    .offset(
                        x: isAnimating ? CGFloat((index % 8) - 4) * 34 : 0,
                        y: isAnimating ? CGFloat((index / 8) - 1) * 92 : 0
                    )
                    .rotationEffect(.degrees(isAnimating ? Double(index * 21) : 0))
                    .scaleEffect(isAnimating ? 1.55 : 0.1)
                    .opacity(isAnimating ? 0.03 : 0.95)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func effectImage(_ itemType: ShelfItemType, size: CGFloat) -> some View {
        Group {
            if let assetName = itemType.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(itemType.icon)
                    .font(.system(size: size * 0.74))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }

    private func confettiSymbol(for index: Int) -> String {
        ["🎁", "🎉", "✨", "💫", "⭐️"][index % 5]
    }
}
