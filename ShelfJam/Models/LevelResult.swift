import Foundation

enum LevelStatus: Equatable {
    case playing
    case completed(stars: Int, finalScore: Int)
    case failed
}

struct LevelProgress: Codable, Hashable {
    var bestScore: Int
    var bestStars: Int
}

struct MatchGroup: Equatable, Hashable {
    let shelfIndex: Int
    let slotIndexes: [Int]
    let itemType: ShelfItemType
}

struct MatchEffect: Identifiable, Equatable {
    let id = UUID()
    let kind: MatchEffectKind

    init(itemType: ShelfItemType) {
        self.kind = .match(itemType)
    }

    init(kind: MatchEffectKind) {
        self.kind = kind
    }
}

enum MatchEffectKind: Equatable {
    case match(ShelfItemType)
    case bomb
    case joker
    case unlock
}

extension MatchEffect {
    var itemType: ShelfItemType {
        switch kind {
        case .match(let itemType):
            itemType
        case .bomb:
            .gift
        case .joker:
            .book
        case .unlock:
            .plant
        }
    }
}
