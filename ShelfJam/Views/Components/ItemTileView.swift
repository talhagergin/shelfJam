import SwiftUI

struct ItemTileView: View {
    let item: ShelfItem
    let isSelected: Bool
    let isMatched: Bool
    let position: Position

    var body: some View {
        displayContent
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
            .overlay(alignment: .topTrailing) {
                if item.isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(.black.opacity(0.48), in: Circle())
                        .padding(5)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if item.isBomb || item.isJoker {
                    Text(item.type.icon)
                        .font(.system(size: 12))
                        .padding(5)
                        .background(.white.opacity(0.78), in: Circle())
                        .padding(5)
                }
            }
            .saturation(item.isLocked ? 0.45 : 1)
            .brightness(item.isLocked ? -0.05 : 0)
            .scaleEffect(isMatched ? 1.34 : (isSelected ? 1.1 : 1))
            .rotationEffect(.degrees(isSelected ? -2 : 0))
            .opacity(isMatched ? 0.04 : 1)
            .shadow(color: isSelected ? item.type.color.opacity(0.55) : item.type.color.opacity(0.20), radius: isSelected ? 16 : 7, y: isSelected ? 6 : 4)
            .animation(.spring(response: 0.34, dampingFraction: 0.62), value: isSelected)
            .animation(.easeInOut(duration: 0.82), value: isMatched)
            .accessibilityLabel("\(accessibilityName), shelf \(position.shelfIndex + 1), slot \(position.slotIndex + 1)")
    }

    @ViewBuilder
    private var displayContent: some View {
        if item.isHidden {
            Text("📦")
                .font(.system(size: 30))
        } else if item.isBomb {
            Text("💣")
                .font(.system(size: 29))
        } else if item.isJoker {
            Text("⭐️")
                .font(.system(size: 31))
        } else {
            if let assetName = item.type.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .shadow(color: .black.opacity(0.16), radius: 5, y: 3)
            } else {
                Text(item.type.icon)
                    .font(.system(size: 29))
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            }
        }
    }

    private var accessibilityName: String {
        var parts = [item.type.displayName]
        if item.isBomb { parts.append("bomb") }
        if item.isJoker { parts.append("joker") }
        if item.isLocked { parts.append("locked") }
        return parts.joined(separator: ", ")
    }
}
