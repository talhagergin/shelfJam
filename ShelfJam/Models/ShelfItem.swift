import Foundation

struct ShelfItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: ShelfItemType
    var isLocked: Bool
    var isHidden: Bool
    var isJoker: Bool

    init(
        id: UUID = UUID(),
        type: ShelfItemType,
        isLocked: Bool = false,
        isHidden: Bool = false,
        isJoker: Bool = false
    ) {
        self.id = id
        self.type = type
        self.isLocked = isLocked
        self.isHidden = isHidden
        self.isJoker = isJoker
    }
}
