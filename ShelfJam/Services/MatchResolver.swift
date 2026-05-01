import Foundation

struct MatchResolver {
    func findMatches(in shelves: [[ShelfItem?]]) -> [MatchGroup] {
        var matches: [MatchGroup] = []

        for (shelfIndex, shelf) in shelves.enumerated() {
            var index = 0
            while index < shelf.count {
                guard let item = shelf[index] else {
                    index += 1
                    continue
                }

                var slotIndexes = [index]
                var cursor = index + 1
                while cursor < shelf.count, shelf[cursor]?.type == item.type {
                    slotIndexes.append(cursor)
                    cursor += 1
                }

                if slotIndexes.count >= 3 {
                    matches.append(
                        MatchGroup(
                            shelfIndex: shelfIndex,
                            slotIndexes: slotIndexes,
                            itemType: item.type
                        )
                    )
                }

                index = cursor
            }
        }

        return matches
    }

    func baseScore(for matchedCount: Int) -> Int {
        switch matchedCount {
        case 0...2: 0
        case 3: 100
        case 4: 180
        default: 280
        }
    }

    func multiplier(for matchCount: Int) -> Double {
        switch matchCount {
        case 0...1: 1
        case 2: 1.5
        default: 2
        }
    }
}
