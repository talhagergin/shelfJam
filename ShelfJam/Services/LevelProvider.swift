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
        ShelfLevel(id: 2, title: "Cupboard Shuffle", shelves: pairedShelves(for: [.apple, .cup, .teddy]), moveLimit: 9, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: 1),
        ShelfLevel(id: 3, title: "Toy Tidy", shelves: pairedShelves(for: [.car, .book, .apple]), moveLimit: 9, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 2),
        ShelfLevel(id: 4, title: "Open Space", shelves: pairedShelves(for: [.plant, .cup, .apple]), moveLimit: 9, difficulty: .easy, targetScore: nil, theme: .greenhouse, unlockRequirement: 3),
        ShelfLevel(id: 5, title: "Cozy Combo", shelves: pairedShelves(for: [.gift, .ball, .book]), moveLimit: 8, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 4),
        ShelfLevel(id: 6, title: "Four Shelves", shelves: pairedShelves(for: [.apple, .cup, .book, .teddy]), moveLimit: 11, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 5),
        ShelfLevel(id: 7, title: "Soft Sort", shelves: pairedShelves(for: [.plant, .car, .gift, .cup]), moveLimit: 11, difficulty: .medium, targetScore: nil, theme: .greenhouse, unlockRequirement: 6),
        ShelfLevel(id: 8, title: "Book Nook", shelves: pairedShelves(for: [.book, .apple, .teddy, .ball]), moveLimit: 11, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 7),
        ShelfLevel(id: 9, title: "Tight Corners", shelves: pairedShelves(for: [.cup, .plant, .car, .gift]), moveLimit: 10, difficulty: .medium, targetScore: nil, theme: .kitchen, unlockRequirement: 8),
        ShelfLevel(id: 10, title: "Double Clear", shelves: pairedShelves(for: [.apple, .book, .cup, .ball]), moveLimit: 10, difficulty: .medium, targetScore: nil, theme: .playroom, unlockRequirement: 9),
        ShelfLevel(id: 11, title: "Five Finds", shelves: pairedShelves(for: [.apple, .book, .plant, .cup, .teddy]), moveLimit: 13, difficulty: .hard, targetScore: nil, theme: .greenhouse, unlockRequirement: 10),
        ShelfLevel(id: 12, title: "Shelf Steps", shelves: pairedShelves(for: [.gift, .car, .ball, .apple, .book]), moveLimit: 13, difficulty: .hard, targetScore: nil, theme: .library, unlockRequirement: 11),
        ShelfLevel(id: 13, title: "Gentle Jam", shelves: pairedShelves(for: [.cup, .plant, .teddy, .gift, .car]), moveLimit: 12, difficulty: .hard, targetScore: nil, theme: .playroom, unlockRequirement: 12),
        ShelfLevel(id: 14, title: "Pantry Plan", shelves: pairedShelves(for: [.apple, .cup, .book, .plant, .ball]), moveLimit: 12, difficulty: .hard, targetScore: nil, theme: .kitchen, unlockRequirement: 13),
        ShelfLevel(id: 15, title: "Room Reset", shelves: pairedShelves(for: [.gift, .ball, .car, .teddy, .cup]), moveLimit: 11, difficulty: .hard, targetScore: nil, theme: .playroom, unlockRequirement: 14),
        ShelfLevel(id: 16, title: "Careful Clear", shelves: pairedShelves(for: [.apple, .book, .plant, .cup, .car, .gift]), moveLimit: 12, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 15),
        ShelfLevel(id: 17, title: "Combo Cabinet", shelves: pairedShelves(for: [.ball, .gift, .cup, .plant, .book, .apple]), moveLimit: 14, difficulty: .expert, targetScore: nil, theme: .greenhouse, unlockRequirement: 16),
        ShelfLevel(id: 18, title: "Quiet Crunch", shelves: pairedShelves(for: [.teddy, .car, .apple, .book, .cup, .plant]), moveLimit: 14, difficulty: .expert, targetScore: nil, theme: .playroom, unlockRequirement: 17),
        ShelfLevel(id: 19, title: "Final Sort", shelves: pairedShelves(for: [.apple, .gift, .ball, .plant, .car, .book]), moveLimit: 13, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 18),
        ShelfLevel(id: 20, title: "Shelf Jam", shelves: pairedShelves(for: [.cup, .apple, .book, .gift, .plant, .car]), moveLimit: 13, difficulty: .expert, targetScore: nil, theme: .kitchen, unlockRequirement: 19)
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
        return pairedShelves(for: rotated)
    }

    private static func pairedShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let usableTypes = Array(types.prefix(6))

        switch usableTypes.count {
        case 0...3:
            let a = usableTypes.indices.contains(0) ? usableTypes[0] : .apple
            let b = usableTypes.indices.contains(1) ? usableTypes[1] : .cup
            let c = usableTypes.indices.contains(2) ? usableTypes[2] : .book
            return [
                row(a, a, nil, b, b),
                row(c, c, nil, a, b),
                row(c, nil, nil, nil, nil)
            ]
        case 4:
            let a = usableTypes[0], b = usableTypes[1], c = usableTypes[2], d = usableTypes[3]
            return [
                row(a, a, nil, b, b),
                row(c, c, nil, d, d),
                row(a, b, c, d, nil),
                row(nil, nil, nil, nil, nil)
            ]
        case 5:
            let a = usableTypes[0], b = usableTypes[1], c = usableTypes[2], d = usableTypes[3], e = usableTypes[4]
            return [
                row(a, a, nil, b, b),
                row(c, c, nil, d, d),
                row(e, e, nil, a, b),
                row(c, d, e, nil, nil),
                row(nil, nil, nil, nil, nil)
            ]
        default:
            let a = usableTypes[0], b = usableTypes[1], c = usableTypes[2], d = usableTypes[3], e = usableTypes[4], f = usableTypes[5]
            return [
                row(a, a, nil, b, b),
                row(c, c, nil, d, d),
                row(e, e, nil, f, f),
                row(a, b, c, d, e),
                row(f, nil, nil, nil, nil)
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
