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
    let itemType: ShelfItemType
}
