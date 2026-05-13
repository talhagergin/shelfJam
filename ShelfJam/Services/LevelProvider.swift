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
        ], moveLimit: 5, timeLimit: 52, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: nil),
        ShelfLevel(id: 2, title: "Cupboard Shuffle", shelves: pairedShelves(for: [.apple, .cup, .teddy]), moveLimit: 5, timeLimit: 48, difficulty: .easy, targetScore: nil, theme: .kitchen, unlockRequirement: 1),
        ShelfLevel(id: 3, title: "Bedside Tidy", shelves: pairedShelves(for: Array(ShelfTheme.bedroom.itemTypes.prefix(3))), moveLimit: 5, timeLimit: 46, difficulty: .easy, targetScore: nil, theme: .bedroom, unlockRequirement: 2),
        ShelfLevel(id: 4, title: "Open Space", shelves: pairedShelves(for: [.plant, .cup, .apple]), moveLimit: 5, timeLimit: 44, difficulty: .easy, targetScore: nil, theme: .greenhouse, unlockRequirement: 3),
        ShelfLevel(id: 5, title: "Cozy Combo", shelves: pairedShelves(for: [.gift, .ball, .book]), moveLimit: 5, timeLimit: 32, difficulty: .easy, targetScore: nil, theme: .playroom, unlockRequirement: 4),
        ShelfLevel(id: 6, title: "Pantry Rush", shelves: pairedShelves(for: Array(ShelfTheme.kitchen.itemTypes.prefix(4))), moveLimit: 6, timeLimit: 34, difficulty: .medium, targetScore: nil, theme: .kitchen, unlockRequirement: 5),
        ShelfLevel(id: 7, title: "Game Setup", shelves: pairedShelves(for: Array(ShelfTheme.gaming.itemTypes.prefix(4))), moveLimit: 6, timeLimit: 33, difficulty: .medium, targetScore: nil, theme: .gaming, unlockRequirement: 6),
        ShelfLevel(id: 8, title: "First Lock", shelves: lockedTrainingShelves(for: Array(ShelfTheme.library.itemTypes.prefix(4))), moveLimit: 7, timeLimit: 40, difficulty: .medium, targetScore: nil, theme: .library, unlockRequirement: 7),
        ShelfLevel(id: 9, title: "Bath Cabinet", shelves: pairedShelves(for: Array(ShelfTheme.bathroom.itemTypes.prefix(4))), moveLimit: 6, timeLimit: 31, difficulty: .medium, targetScore: nil, theme: .bathroom, unlockRequirement: 8),
        ShelfLevel(id: 10, title: "Vanity Mix", shelves: pairedShelves(for: Array(ShelfTheme.vanity.itemTypes.prefix(4))), moveLimit: 6, timeLimit: 30, difficulty: .medium, targetScore: nil, theme: .vanity, unlockRequirement: 9),
        ShelfLevel(id: 11, title: "Greenhouse Grid", shelves: pairedShelves(for: Array(ShelfTheme.greenhouse.itemTypes.prefix(5))), moveLimit: 7, timeLimit: 35, difficulty: .hard, targetScore: nil, theme: .greenhouse, unlockRequirement: 10),
        ShelfLevel(id: 12, title: "Office Stack", shelves: pairedShelves(for: Array(ShelfTheme.office.itemTypes.prefix(5))), moveLimit: 7, timeLimit: 34, difficulty: .hard, targetScore: nil, theme: .office, unlockRequirement: 11),
        ShelfLevel(id: 13, title: "Garage Sort", shelves: pairedShelves(for: Array(ShelfTheme.garage.itemTypes.prefix(5))), moveLimit: 7, timeLimit: 33, difficulty: .hard, targetScore: nil, theme: .garage, unlockRequirement: 12),
        ShelfLevel(id: 14, title: "Camp Bag", shelves: pairedShelves(for: Array(ShelfTheme.camping.itemTypes.prefix(5))), moveLimit: 7, timeLimit: 32, difficulty: .hard, targetScore: nil, theme: .camping, unlockRequirement: 13),
        ShelfLevel(id: 15, title: "Locked Pantry", shelves: lockedTrainingShelves(for: Array(ShelfTheme.kitchen.itemTypes.prefix(5))), moveLimit: 8, timeLimit: 36, difficulty: .hard, targetScore: nil, theme: .kitchen, unlockRequirement: 14),
        ShelfLevel(id: 16, title: "Library Jam", shelves: staggeredShelves(for: Array(ShelfTheme.library.itemTypes.prefix(6))), moveLimit: 10, timeLimit: 37, difficulty: .expert, targetScore: nil, theme: .library, unlockRequirement: 15),
        ShelfLevel(id: 17, title: "Plant Puzzle", shelves: staggeredShelves(for: Array(ShelfTheme.greenhouse.itemTypes.prefix(6))), moveLimit: 10, timeLimit: 36, difficulty: .expert, targetScore: nil, theme: .greenhouse, unlockRequirement: 16),
        ShelfLevel(id: 18, title: "Gaming Jam", shelves: staggeredShelves(for: Array(ShelfTheme.gaming.itemTypes.prefix(6))), moveLimit: 10, timeLimit: 35, difficulty: .expert, targetScore: nil, theme: .gaming, unlockRequirement: 17),
        ShelfLevel(id: 19, title: "Bubble Lock", shelves: scatteredLockedShelves(for: Array(ShelfTheme.bathroom.itemTypes.prefix(6))), moveLimit: 11, timeLimit: 40, difficulty: .expert, targetScore: nil, theme: .bathroom, unlockRequirement: 18),
        ShelfLevel(id: 20, title: "Shelf Jam", shelves: scatteredLockedShelves(for: Array(ShelfTheme.vanity.itemTypes.prefix(6))), moveLimit: 11, timeLimit: 39, difficulty: .expert, targetScore: nil, theme: .vanity, unlockRequirement: 19)
        ] + makeExtendedLevels()
    }

    private static func makeExtendedLevels() -> [ShelfLevel] {
        let themes = ShelfTheme.allCases

        return (21...60).map { id in
            let theme = themes[(id - 21) % themes.count]
            let types = theme.itemTypes
            let difficulty: LevelDifficulty = id < 31 ? .medium : (id < 46 ? .hard : .expert)
            let challenge = challengeRule(for: id, difficulty: difficulty)
            let baseMoves = difficulty == .medium ? 8 : (difficulty == .hard ? 9 : 8)
            return ShelfLevel(
                id: id,
                title: challenge.title ?? "\(theme.title) \(id)",
                shelves: generatedShelves(for: types, offset: id),
                moveLimit: challenge.moveLimit ?? (baseMoves + (id % 2)),
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
        if offset >= 50 {
            return jokerLockedShelves(for: rotated)
        }
        if offset >= 40 {
            return jokerShelves(for: rotated)
        }
        if offset >= 31 {
            return scatteredLockedShelves(for: rotated)
        }
        if offset >= 24 {
            return staggeredShelves(for: rotated)
        }
        if offset >= 16 {
            return staggeredShelves(for: rotated)
        }
        return pairedShelves(for: rotated)
    }

    private static func challengeRule(for id: Int, difficulty: LevelDifficulty) -> (title: String?, moveLimit: Int?, timeLimit: TimeInterval?) {
        guard id >= 25, id.isMultiple(of: 5) else { return (nil, nil, nil) }

        if id.isMultiple(of: 10) {
            let moveLimit = difficulty == .expert ? 7 : 8
            return ("Precision Challenge \(id)", moveLimit, 0)
        } else {
            let timeLimit: TimeInterval = difficulty == .expert ? 18 : 22
            return ("Rush Challenge \(id)", 28, timeLimit)
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

    private static func lockedTrainingShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let padded = Array(types.prefix(5)) + [.apple, .cup, .book, .plant, .gift]
        let a = padded[0], b = padded[1], c = padded[2], d = padded[3], e = padded[4]
        return [
            row(a, a, nil, b, b),
            mixedRow(lockedItem(a), nil, item(a), item(a), item(a)),
            row(d, d, nil, e, e),
            row(c, c, nil, b, nil),
            row(d, e, nil, nil, nil)
        ]
    }

    private static func jokerShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let padded = Array(types.prefix(6)) + [.apple, .cup, .book, .plant, .gift, .ball]
        let a = padded[0], b = padded[1], c = padded[2], d = padded[3], e = padded[4], f = padded[5]
        return [
            row(a, nil, a, b, nil),
            mixedRow(item(a), item(b), nil, jokerItem(b), nil),
            row(c, nil, c, d, nil),
            mixedRow(item(c), item(d), nil, item(d), nil),
            mixedRow(item(e), item(f), nil, item(f), nil),
            mixedRow(jokerItem(e), item(e), nil, nil, nil)
        ]
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

    private static func jokerLockedShelves(for types: [ShelfItemType]) -> [[ShelfItem?]] {
        let padded = Array(types.prefix(6)) + [.apple, .cup, .book, .plant, .gift, .ball]
        let a = padded[0], b = padded[1], c = padded[2], d = padded[3], e = padded[4], f = padded[5]
        return [
            row(a, nil, a, b, nil),
            mixedRow(item(a), item(b), nil, jokerItem(b), lockedItem(a)),
            mixedRow(item(c), nil, item(c), item(c), nil),
            mixedRow(item(d), lockedItem(a), nil, item(d), item(b)),
            mixedRow(item(e), item(f), nil, item(f), lockedItem(a)),
            mixedRow(jokerItem(e), item(e), item(a), nil, nil)
        ]
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
