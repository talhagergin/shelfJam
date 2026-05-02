import Foundation

enum LevelDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }

    var defaultTimeLimit: TimeInterval {
        switch self {
        case .easy: 75
        case .medium: 55
        case .hard: 42
        case .expert: 34
        }
    }
}

struct ShelfLevel: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let shelves: [[ShelfItem?]]
    let moveLimit: Int
    let timeLimit: TimeInterval
    let difficulty: LevelDifficulty
    let targetScore: Int?
    let theme: ShelfTheme
    let unlockRequirement: Int?

    var hasTimeLimit: Bool {
        timeLimit > 0
    }

    init(
        id: Int,
        title: String,
        shelves: [[ShelfItem?]],
        moveLimit: Int,
        timeLimit: TimeInterval? = nil,
        difficulty: LevelDifficulty,
        targetScore: Int?,
        theme: ShelfTheme,
        unlockRequirement: Int?
    ) {
        self.id = id
        self.title = title
        self.shelves = shelves
        self.moveLimit = moveLimit
        self.timeLimit = timeLimit ?? difficulty.defaultTimeLimit
        self.difficulty = difficulty
        self.targetScore = targetScore
        self.theme = theme
        self.unlockRequirement = unlockRequirement
    }
}
