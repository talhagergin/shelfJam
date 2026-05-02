import SwiftUI

struct ShelfView: View {
    let shelf: [ShelfItem?]
    let shelfIndex: Int
    let selectedPosition: Position?
    let matchedPositions: Set<Position>
    let hintPositions: Set<Position>
    let invalidTargetPosition: Position?
    var preferredHeight: CGFloat = 92
    let onTap: (Position) -> Void

    var body: some View {
        GeometryReader { proxy in
            let spacing = proxy.size.width < 350 ? 6.0 : 8.0
            let horizontalPadding = proxy.size.width < 350 ? 8.0 : 10.0
            let availableSlotHeight = max(36, proxy.size.height - 34)
            let slotSize = min(
                64,
                availableSlotHeight,
                max(36, (proxy.size.width - horizontalPadding * 2 - spacing * CGFloat(max(shelf.count - 1, 0))) / CGFloat(max(shelf.count, 1)))
            )

            VStack(spacing: 7) {
                HStack(spacing: spacing) {
                    ForEach(shelf.indices, id: \.self) { slotIndex in
                        let position = Position(shelfIndex: shelfIndex, slotIndex: slotIndex)
                        ShelfSlotView(
                            item: shelf[slotIndex],
                            position: position,
                            isSelected: selectedPosition == position,
                            isMatched: matchedPositions.contains(position),
                            isHinted: hintPositions.contains(position),
                            isInvalid: invalidTargetPosition == position
                        ) {
                            onTap(position)
                        }
                        .frame(width: slotSize, height: slotSize)
                    }
                }

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.22, blue: 0.12),
                                Color(red: 1.00, green: 0.64, blue: 0.32),
                                Color(red: 0.55, green: 0.24, blue: 0.15)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 9)
                    .shadow(color: .black.opacity(0.12), radius: 5, y: 3)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(shelfBackground)
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: AppStyle.shelfCornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.46), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
        }
        .frame(height: preferredHeight)
    }

    private var shelfBackground: some View {
        RoundedRectangle(cornerRadius: AppStyle.shelfCornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 1.00, green: 0.83, blue: 0.48).opacity(0.96),
                        Color(red: 1.00, green: 0.48, blue: 0.42).opacity(0.24),
                        Color(red: 0.43, green: 0.79, blue: 0.82).opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
