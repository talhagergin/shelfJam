import Foundation

enum LevelDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }
}

struct ShelfLevel: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let shelves: [[ShelfItem?]]
    let moveLimit: Int
    let difficulty: LevelDifficulty
    let targetScore: Int?
    let theme: ShelfTheme
    let unlockRequirement: Int?
}
