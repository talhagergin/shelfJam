import SwiftUI

struct ShelfView: View {
    let shelf: [ShelfItem?]
    let shelfIndex: Int
    let selectedPosition: Position?
    let matchedPositions: Set<Position>
    let hintPositions: Set<Position>
    let invalidTargetPosition: Position?
    let theme: ShelfTheme
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
                            colors: theme.railGradient,
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
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: AppStyle.shelfCornerRadius - 4, style: .continuous)
                    .fill(.white.opacity(0.18))
                    .frame(height: 18)
                    .padding(.horizontal, 18)
                    .offset(y: 5)
            }
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Color(red: 0.24, green: 0.08, blue: 0.34).opacity(0.40))
                    .frame(height: 15)
                    .padding(.horizontal, 16)
                    .offset(y: -5)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: theme.shelfSymbol)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.42))
                    .padding(.top, 8)
                    .padding(.trailing, 12)
            }
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
                        Color(red: 1.00, green: 0.88, blue: 0.38).opacity(0.92),
                        theme.accent.opacity(0.78),
                        Color(red: 0.36, green: 0.12, blue: 0.52).opacity(0.74)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.shelfCornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.28), .clear],
                            center: .topLeading,
                            startRadius: 10,
                            endRadius: 240
                        )
                    )
            }
    }
}
