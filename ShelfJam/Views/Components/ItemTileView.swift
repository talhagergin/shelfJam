import SwiftUI

struct ItemTileView: View {
    let item: ShelfItem
    let isSelected: Bool
    let isMatched: Bool
    let position: Position

    var body: some View {
        Text(item.isHidden ? "?" : item.type.icon)
            .font(.system(size: 29))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.tileCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                item.type.color.opacity(0.44),
                                Color.white.opacity(0.86),
                                item.type.color.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppStyle.tileCornerRadius, style: .continuous)
                    .stroke(isSelected ? item.type.color : .white.opacity(0.58), lineWidth: isSelected ? 3 : 1.2)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: AppStyle.tileCornerRadius, style: .continuous)
                        .stroke(item.type.color.opacity(0.35), lineWidth: 7)
                        .blur(radius: 5)
                }
            }
            .scaleEffect(isMatched ? 1.34 : (isSelected ? 1.1 : 1))
            .rotationEffect(.degrees(isSelected ? -2 : 0))
            .opacity(isMatched ? 0.04 : 1)
            .shadow(color: isSelected ? item.type.color.opacity(0.55) : item.type.color.opacity(0.20), radius: isSelected ? 16 : 7, y: isSelected ? 6 : 4)
            .animation(.spring(response: 0.34, dampingFraction: 0.62), value: isSelected)
            .animation(.easeInOut(duration: 0.82), value: isMatched)
            .accessibilityLabel("\(item.type.displayName) item, shelf \(position.shelfIndex + 1), slot \(position.slotIndex + 1)")
    }
}
