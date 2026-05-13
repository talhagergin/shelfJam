import SwiftUI

struct ShelfSlotView: View {
    let item: ShelfItem?
    let position: Position
    let isSelected: Bool
    let isMatched: Bool
    let isHinted: Bool
    let isInvalid: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.tileCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.88),
                                Color(red: 1.00, green: 0.91, blue: 0.52).opacity(0.48),
                                Color(red: 0.76, green: 0.48, blue: 1.00).opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: AppStyle.tileCornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.62), style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
                    }
                    .shadow(color: .purple.opacity(0.16), radius: 7, y: 4)
                    .overlay {
                        if isHinted {
                            RoundedRectangle(cornerRadius: AppStyle.tileCornerRadius, style: .continuous)
                                .stroke(.yellow.opacity(0.9), lineWidth: 3)
                                .shadow(color: .yellow.opacity(0.55), radius: 10)
                        }
                    }
                    .shadow(color: .white.opacity(0.35), radius: 1, y: -1)

                if let item {
                    ItemTileView(
                        item: item,
                        isSelected: isSelected,
                        isMatched: isMatched,
                        position: position
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.82).combined(with: .opacity),
                        removal: .scale(scale: 1.28).combined(with: .opacity)
                    ))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .offset(x: isInvalid ? -4 : 0)
            .animation(.spring(response: 0.08, dampingFraction: 0.25).repeatCount(isInvalid ? 3 : 1), value: isInvalid)
            .scaleEffect(isHinted ? 1.04 : 1)
            .animation(.easeInOut(duration: 0.55).repeatCount(isHinted ? 4 : 1, autoreverses: true), value: isHinted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item == nil ? "Empty slot, shelf \(position.shelfIndex + 1), slot \(position.slotIndex + 1)" : "")
    }
}
