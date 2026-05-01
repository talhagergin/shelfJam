import Foundation

protocol LevelProvider {
    var levels: [ShelfLevel] { get }
    func level(id: Int) -> ShelfLevel?
}

struct StaticLevelProvider: LevelProvider {
    let levels: [ShelfLevel] = StaticLevelProvider.makeLevels()

    private static func makeLevels() -> [ShelfLevel] {
        [
        ShelfLevel(id: 1, title: "First Shelf", shelves: [
            row(.apple, .apple, nil, nil, nil),
            row(.apple, nil, nil, nil, nil),
            row(.teddy, .teddy, .teddy, nil, nil)
        ], moveLimit: 8, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: nil),
        ShelfLevel(id: 2, title: "Cupboard Shuffle", shelves: [
            row(.apple, .cup, nil, .teddy, nil),
            row(.cup, .apple, nil, .teddy, nil),
            row(.apple, .cup, .teddy, nil, nil)
        ], moveLimit: 9, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: 1),
        ShelfLevel(id: 3, title: "Toy Tidy", shelves: [
            row(.car, .book, .car, nil, nil),
            row(.apple, .book, nil, .car, nil),
            row(.book, .apple, nil, .apple, nil)
        ], moveLimit: 9, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 2),
        ShelfLevel(id: 4, title: "Open Space", shelves: [
            row(.plant, .cup, .plant, nil, nil),
            row(.apple, .cup, nil, .plant, nil),
            row(.cup, .apple, nil, .apple, nil)
        ], moveLimit: 9, difficulty: .easy, targetScore: nil, theme: .greenhouse, unlockRequirement: 3),
        ShelfLevel(id: 5, title: "Cozy Combo", shelves: [
            row(.gift, .ball, .gift, .book, nil),
            row(.ball, .book, nil, .gift, nil),
            row(.book, .ball, nil, nil, nil)
        ], moveLimit: 8, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 4),
        ShelfLevel(id: 6, title: "Four Shelves", shelves: [
            row(.apple, .cup, .book, nil, nil),
            row(.teddy, .apple, .cup, nil, nil),
            row(.book, .teddy, .apple, nil, nil),
            row(.cup, .book, .teddy, nil, nil)
        ], moveLimit: 11, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 5),
        ShelfLevel(id: 7, title: "Soft Sort", shelves: [
            row(.plant, .car, .gift, nil, nil),
            row(.cup, .plant, .car, .gift, nil),
            row(.car, .cup, .plant, nil, nil),
            row(.gift, .cup, nil, nil, nil)
        ], moveLimit: 11, difficulty: .medium, targetScore: nil, theme: .greenhouse, unlockRequirement: 6),
        ShelfLevel(id: 8, title: "Book Nook", shelves: [
            row(.book, .apple, .teddy, .ball, nil),
            row(.apple, .book, .ball, nil, nil),
            row(.teddy, .apple, .book, nil, nil),
            row(.ball, .teddy, nil, nil, nil)
        ], moveLimit: 11, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 7),
        ShelfLevel(id: 9, title: "Tight Corners", shelves: [
            row(.cup, .plant, .car, .gift, nil),
            row(.plant, .cup, .gift, .car, nil),
            row(.car, .gift, .cup, nil, nil),
            row(nil, .plant, nil, nil, nil)
        ], moveLimit: 10, difficulty: .medium, targetScore: nil, theme: .kitchen, unlockRequirement: 8),
        ShelfLevel(id: 10, title: "Double Clear", shelves: [
            row(.apple, .book, .cup, .ball, nil),
            row(.book, .apple, .ball, .cup, nil),
            row(.cup, .ball, .apple, nil, nil),
            row(.book, nil, nil, nil, nil)
        ], moveLimit: 10, difficulty: .medium, targetScore: nil, theme: .playroom, unlockRequirement: 9),
        ShelfLevel(id: 11, title: "Five Finds", shelves: [
            row(.apple, .book, .plant, .cup, nil),
            row(.teddy, .apple, .book, .plant, nil),
            row(.cup, .teddy, .apple, nil, nil),
            row(.book, .plant, .cup, nil, nil),
            row(.teddy, nil, nil, nil, nil)
        ], moveLimit: 13, difficulty: .hard, targetScore: nil, theme: .greenhouse, unlockRequirement: 10),
        ShelfLevel(id: 12, title: "Shelf Steps", shelves: [
            row(.gift, .car, .ball, .apple, nil),
            row(.book, .gift, .car, .ball, nil),
            row(.apple, .book, .gift, nil, nil),
            row(.car, .ball, .apple, nil, nil),
            row(.book, nil, nil, nil, nil)
        ], moveLimit: 13, difficulty: .hard, targetScore: nil, theme: .library, unlockRequirement: 11),
        ShelfLevel(id: 13, title: "Gentle Jam", shelves: [
            row(.cup, .plant, .teddy, .gift, nil),
            row(.car, .cup, .plant, .teddy, nil),
            row(.gift, .car, .cup, nil, nil),
            row(.plant, .teddy, .gift, nil, nil),
            row(.car, nil, nil, nil, nil)
        ], moveLimit: 12, difficulty: .hard, targetScore: nil, theme: .playroom, unlockRequirement: 12),
        ShelfLevel(id: 14, title: "Pantry Plan", shelves: [
            row(.apple, .cup, .book, .plant, .ball),
            row(.cup, .book, .plant, .ball, nil),
            row(.book, .plant, .ball, .apple, nil),
            row(nil, .apple, .cup, nil, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 12, difficulty: .hard, targetScore: nil, theme: .kitchen, unlockRequirement: 13),
        ShelfLevel(id: 15, title: "Room Reset", shelves: [
            row(.gift, .ball, .car, .teddy, .cup),
            row(.ball, .car, .teddy, .cup, nil),
            row(.car, .teddy, .cup, .gift, nil),
            row(nil, .gift, .ball, nil, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 11, difficulty: .hard, targetScore: nil, theme: .playroom, unlockRequirement: 14),
        ShelfLevel(id: 16, title: "Careful Clear", shelves: [
            row(.apple, .book, .plant, .cup, .car),
            row(.gift, .apple, .book, .plant, .cup),
            row(.car, .gift, .apple, .book, nil),
            row(.plant, .cup, .car, .gift, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 12, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 15),
        ShelfLevel(id: 17, title: "Combo Cabinet", shelves: [
            row(.ball, .gift, .cup, .plant, .book),
            row(.apple, .ball, .gift, .cup, .plant),
            row(.book, .apple, .ball, .gift, nil),
            row(.cup, .plant, .book, .apple, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 11, difficulty: .expert, targetScore: nil, theme: .greenhouse, unlockRequirement: 16),
        ShelfLevel(id: 18, title: "Quiet Crunch", shelves: [
            row(.teddy, .car, .apple, .book, .cup),
            row(.plant, .teddy, .car, .apple, .book),
            row(.cup, .plant, .teddy, .car, nil),
            row(.apple, .book, .cup, .plant, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 11, difficulty: .expert, targetScore: nil, theme: .playroom, unlockRequirement: 17),
        ShelfLevel(id: 19, title: "Final Sort", shelves: [
            row(.apple, .gift, .ball, .plant, .car),
            row(.book, .apple, .gift, .ball, .plant),
            row(.car, .book, .apple, .gift, nil),
            row(.ball, .plant, .car, .book, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 10, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 18),
        ShelfLevel(id: 20, title: "Shelf Jam", shelves: [
            row(.cup, .apple, .book, .gift, .plant),
            row(.car, .cup, .apple, .book, .gift),
            row(.plant, .car, .cup, .apple, nil),
            row(.book, .gift, .plant, .car, nil),
            row(nil, nil, nil, nil, nil)
        ], moveLimit: 10, difficulty: .expert, targetScore: nil, theme: .kitchen, unlockRequirement: 19)
        ] + makeExtendedLevels()
    }

    private static func makeExtendedLevels() -> [ShelfLevel] {
        let typeSets: [[ShelfItemType]] = [
            [.apple, .teddy, .car, .book, .cup],
            [.plant, .ball, .gift, .apple, .car],
            [.book, .cup, .plant, .teddy, .gift, .ball],
            [.apple, .book, .gift, .plant, .car, .cup],
            [.teddy, .ball, .cup, .book, .plant, .gift],
            [.car, .apple, .plant, .gift, .ball, .book]
        ]

        return (21...60).map { id in
            let types = typeSets[(id - 21) % typeSets.count]
            let difficulty: LevelDifficulty = id < 31 ? .medium : (id < 46 ? .hard : .expert)
            let theme = ShelfTheme.allCases[(id - 1) % ShelfTheme.allCases.count]
            let baseMoves = difficulty == .medium ? 12 : (difficulty == .hard ? 13 : 12)
            return ShelfLevel(
                id: id,
                title: "Shelf Mix \(id)",
                shelves: generatedShelves(for: types, offset: id),
                moveLimit: baseMoves + (id % 3),
                difficulty: difficulty,
                targetScore: nil,
                theme: theme,
                unlockRequirement: id - 1
            )
        }
    }

    private static func generatedShelves(for types: [ShelfItemType], offset: Int) -> [[ShelfItem?]] {
        let rotation = offset % types.count
        let rotated = Array(types.dropFirst(rotation)) + Array(types.prefix(rotation))
        if rotated.count >= 6 {
            let a = rotated[0], b = rotated[1], c = rotated[2], d = rotated[3], e = rotated[4], f = rotated[5]
            return [
                row(a, b, c, d, e),
                row(f, a, b, c, d),
                row(e, f, a, b, c),
                row(d, e, f, nil, nil),
                row(nil, nil, nil, nil, nil)
            ]
        } else {
            let a = rotated[0], b = rotated[1], c = rotated[2], d = rotated[3], e = rotated[4]
            return [
                row(a, b, c, d, e),
                row(b, c, d, e, a),
                row(c, d, e, a, b),
                row(nil, nil, nil, nil, nil),
                row(nil, nil, nil, nil, nil)
            ]
        }
    }

    func level(id: Int) -> ShelfLevel? {
        levels.first { $0.id == id }
    }
}

func item(_ type: ShelfItemType) -> ShelfItem {
    ShelfItem(type: type)
}

func row(_ values: ShelfItemType?...) -> [ShelfItem?] {
    values.map { type in
        guard let type else { return nil }
        return item(type)
    }
}
