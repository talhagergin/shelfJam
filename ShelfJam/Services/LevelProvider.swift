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
        ], moveLimit: 5, timeLimit: 62, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: nil),
        ShelfLevel(id: 2, title: "Cupboard Shuffle", shelves: pairedShelves(for: [.apple, .cup, .teddy]), moveLimit: 5, timeLimit: 58, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: 1),
        ShelfLevel(id: 3, title: "Toy Tidy", shelves: pairedShelves(for: [.car, .book, .apple]), moveLimit: 5, timeLimit: 56, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 2),
        ShelfLevel(id: 4, title: "Open Space", shelves: pairedShelves(for: [.plant, .cup, .apple]), moveLimit: 5, timeLimit: 54, difficulty: .easy, targetScore: nil, theme: .greenhouse, unlockRequirement: 3),
        ShelfLevel(id: 5, title: "Cozy Combo", shelves: pairedShelves(for: [.gift, .ball, .book]), moveLimit: 5, timeLimit: 52, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 4),
        ShelfLevel(id: 6, title: "Four Shelves", shelves: pairedShelves(for: [.apple, .cup, .book, .teddy]), moveLimit: 6, timeLimit: 50, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 5),
        ShelfLevel(id: 7, title: "Soft Sort", shelves: pairedShelves(for: [.plant, .car, .gift, .cup]), moveLimit: 6, timeLimit: 48, difficulty: .medium, targetScore: nil, theme: .greenhouse, unlockRequirement: 6),
        ShelfLevel(id: 8, title: "Book Nook", shelves: pairedShelves(for: [.book, .apple, .teddy, .ball]), moveLimit: 6, timeLimit: 46, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 7),
        ShelfLevel(id: 9, title: "Tight Corners", shelves: pairedShelves(for: [.cup, .plant, .car, .gift]), moveLimit: 6, timeLimit: 44, difficulty: .medium, targetScore: nil, theme: .kitchen, unlockRequirement: 8),
        ShelfLevel(id: 10, title: "Double Clear", shelves: pairedShelves(for: [.apple, .book, .cup, .ball]), moveLimit: 6, timeLimit: 42, difficulty: .medium, targetScore: nil, theme: .playroom, unlockRequirement: 9),
        ShelfLevel(id: 11, title: "Five Finds", shelves: pairedShelves(for: [.apple, .book, .plant, .cup, .teddy]), moveLimit: 7, timeLimit: 40, difficulty: .hard, targetScore: nil, theme: .greenhouse, unlockRequirement: 10),
        ShelfLevel(id: 12, title: "Shelf Steps", shelves: pairedShelves(for: [.gift, .car, .ball, .apple, .book]), moveLimit: 7, timeLimit: 39, difficulty: .hard, targetScore: nil, theme: .library, unlockRequirement: 11),
        ShelfLevel(id: 13, title: "Gentle Jam", shelves: pairedShelves(for: [.cup, .plant, .teddy, .gift, .car]), moveLimit: 7, timeLimit: 38, difficulty: .hard, targetScore: nil, theme: .playroom, unlockRequirement: 12),
        ShelfLevel(id: 14, title: "Pantry Plan", shelves: pairedShelves(for: [.apple, .cup, .book, .plant, .ball]), moveLimit: 7, timeLimit: 37, difficulty: .hard, targetScore: nil, theme: .kitchen, unlockRequirement: 13),
        ShelfLevel(id: 15, title: "Room Reset", shelves: pairedShelves(for: [.gift, .ball, .car, .teddy, .cup]), moveLimit: 7, timeLimit: 36, difficulty: .hard, targetScore: nil, theme: .playroom, unlockRequirement: 14),
        ShelfLevel(id: 16, title: "Careful Clear", shelves: staggeredShelves(for: [.apple, .book, .plant, .cup, .car, .gift]), moveLimit: 8, timeLimit: 35, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 15),
        ShelfLevel(id: 17, title: "Combo Cabinet", shelves: staggeredShelves(for: [.ball, .gift, .cup, .plant, .book, .apple]), moveLimit: 8, timeLimit: 34, difficulty: .expert, targetScore: nil, theme: .greenhouse, unlockRequirement: 16),
        ShelfLevel(id: 18, title: "Quiet Crunch", shelves: staggeredShelves(for: [.teddy, .car, .apple, .book, .cup, .plant]), moveLimit: 8, timeLimit: 33, difficulty: .expert, targetScore: nil, theme: .playroom, unlockRequirement: 17),
        ShelfLevel(id: 19, title: "Final Sort", shelves: staggeredShelves(for: [.apple, .gift, .ball, .plant, .car, .book]), moveLimit: 8, timeLimit: 32, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 18),
        ShelfLevel(id: 20, title: "Shelf Jam", shelves: staggeredShelves(for: [.cup, .apple, .book, .gift, .plant, .car]), moveLimit: 8, timeLimit: 31, difficulty: .expert, targetScore: nil, theme: .kitchen, unlockRequirement: 19)
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
            let challenge = challengeRule(for: id, difficulty: difficulty)
            let baseMoves = difficulty == .medium ? 10 : (difficulty == .hard ? 12 : 11)
            return ShelfLevel(
                id: id,
                title: challenge.title ?? "Shelf Mix \(id)",
                shelves: generatedShelves(for: types, offset: id),
                moveLimit: challenge.moveLimit ?? (baseMoves + (id % 3)),
                timeLimit: challenge.timeLimit,
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
        if offset >= 46 {
            return challengeLockedShelves(for: rotated)
        }
        if offset >= 31 {
            return scatteredLockedShelves(for: rotated)
        }
        if offset >= 16 {
            return staggeredShelves(for: rotated)
        }
        return pairedShelves(for: rotated)
    }

    private static func challengeRule(for id: Int, difficulty: LevelDifficulty) -> (title: String?, moveLimit: Int?, timeLimit: TimeInterval?) {
        guard id >= 25, id.isMultiple(of: 5) else { return (nil, nil, nil) }

        if id.isMultiple(of: 10) {
            let moveLimit = difficulty == .expert ? 8 : 9
            return ("Precision Challenge \(id)", moveLimit, 0)
        } else {
            let timeLimit: TimeInterval = difficulty == .expert ? 22 : 26
            return ("Rush Challenge \(id)", 35, timeLimit)
        }
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

    private static func staggeredShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let usableTypes = Array(types.prefix(6))
        if usableTypes.count >= 6 {
            let a = usableTypes[0], b = usableTypes[1], c = usableTypes[2], d = usableTypes[3], e = usableTypes[4], f = usableTypes[5]
            return [
                row(a, nil, a, b, nil),
                row(b, c, nil, c, nil),
                row(d, nil, d, e, nil),
                row(e, f, nil, f, nil),
                row(a, b, c, d, e),
                row(f, nil, nil, nil, nil)
            ]
        } else {
            let padded = usableTypes + [.apple, .cup, .book, .plant, .gift]
            let a = padded[0], b = padded[1], c = padded[2], d = padded[3], e = padded[4]
            return [
                row(a, nil, a, b, nil),
                row(b, c, nil, c, nil),
                row(d, nil, d, e, nil),
                row(e, a, b, c, d),
                row(e, nil, nil, nil, nil)
            ]
        }
    }

    private static func scatteredLockedShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let usableTypes = Array(types.prefix(6))
        if usableTypes.count >= 6 {
            let a = usableTypes[0], b = usableTypes[1], c = usableTypes[2], d = usableTypes[3], e = usableTypes[4], f = usableTypes[5]
            return [
                row(a, a, nil, a, nil),
                row(b, nil, a, b, f),
                mixedRow(lockedItem(a), item(c), nil, item(c), nil),
                mixedRow(item(d), lockedItem(a), item(d), item(e), nil),
                mixedRow(item(f), nil, item(f), lockedItem(a), item(e)),
                row(a, b, c, d, e)
            ]
        } else {
            let padded = usableTypes + [.apple, .cup, .book, .plant, .gift]
            let a = padded[0], b = padded[1], c = padded[2], d = padded[3], e = padded[4]
            return [
                row(a, a, nil, a, nil),
                row(c, nil, c, b, nil),
                mixedRow(lockedItem(a), item(d), nil, item(d), nil),
                mixedRow(item(e), lockedItem(a), item(e), item(b), nil),
                mixedRow(a == b ? nil : lockedItem(a), nil, item(b), item(c), item(d)),
                row(e, nil, nil, nil, nil)
            ]
        }
    }

    private static func challengeLockedShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let usableTypes = Array(types.prefix(6))
        if usableTypes.count >= 6 {
            let a = usableTypes[0], b = usableTypes[1], c = usableTypes[2], d = usableTypes[3], e = usableTypes[4], f = usableTypes[5]
            return [
                row(a, nil, a, b, nil),
                mixedRow(item(b), item(c), nil, item(c), lockedItem(a)),
                mixedRow(item(d), nil, item(d), item(e), nil),
                mixedRow(item(e), lockedItem(a), nil, item(f), nil),
                mixedRow(item(a), item(b), item(c), item(d), lockedItem(a)),
                row(e, f, f, nil, nil)
            ]
        } else {
            let padded = usableTypes + [.apple, .cup, .book, .plant, .gift]
            let a = padded[0], b = padded[1], c = padded[2], d = padded[3], e = padded[4]
            return [
                row(a, nil, a, b, nil),
                mixedRow(item(b), item(c), nil, item(c), lockedItem(a)),
                row(d, nil, d, e, nil),
                mixedRow(item(e), lockedItem(a), nil, nil, nil),
                mixedRow(item(a), item(b), item(c), lockedItem(a), item(d)),
                row(e, nil, nil, nil, nil)
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

func lockedItem(_ type: ShelfItemType) -> ShelfItem {
    ShelfItem(type: type, isLocked: true)
}

func jokerItem(_ type: ShelfItemType) -> ShelfItem {
    ShelfItem(type: type, isJoker: true)
}

func row(_ values: ShelfItemType?...) -> [ShelfItem?] {
    values.map { type in
        guard let type else { return nil }
        return item(type)
    }
}

func mixedRow(_ values: ShelfItem?...) -> [ShelfItem?] {
    values
}
