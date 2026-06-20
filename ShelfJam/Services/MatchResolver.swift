import Foundation

struct MatchResolver {
    func findMatches(in shelves: [[ShelfItem?]]) -> [MatchGroup] {
        var matches: [MatchGroup] = []

        for (shelfIndex, shelf) in shelves.enumerated() {
            let candidates = Set(shelf.compactMap { item -> ShelfItemType? in
                guard let item, !item.isLocked, !item.isHidden, !item.isJoker else { return nil }
                return item.type
            })
            var shelfMatches: [MatchGroup] = []

            for itemType in candidates {
                for startIndex in shelf.indices {
                    guard isCompatible(shelf[startIndex], with: itemType) else { continue }

                    var slotIndexes: [Int] = []
                    var cursor = startIndex
                    while cursor < shelf.count, isCompatible(shelf[cursor], with: itemType) {
                        slotIndexes.append(cursor)
                        cursor += 1
                    }

                    guard slotIndexes.count >= 3,
                          slotIndexes.contains(where: { shelf[$0]?.isJoker == false })
                    else { continue }

                    shelfMatches.append(
                        MatchGroup(
                            shelfIndex: shelfIndex,
                            slotIndexes: slotIndexes,
                            itemType: itemType
                        )
                    )
                }
            }

            matches.append(contentsOf: nonOverlapping(shelfMatches))
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

    private func isCompatible(_ item: ShelfItem?, with itemType: ShelfItemType) -> Bool {
        guard let item, !item.isLocked, !item.isHidden else { return false }
        return item.isJoker || item.type == itemType
    }

    private func nonOverlapping(_ matches: [MatchGroup]) -> [MatchGroup] {
        var result: [MatchGroup] = []
        var usedSlots: Set<Int> = []

        for match in matches.sorted(by: matchPriority) {
            let slotSet = Set(match.slotIndexes)
            guard usedSlots.isDisjoint(with: slotSet) else { continue }
            result.append(match)
            usedSlots.formUnion(slotSet)
        }

        return result.sorted { ($0.shelfIndex, $0.slotIndexes.first ?? 0) < ($1.shelfIndex, $1.slotIndexes.first ?? 0) }
    }

    private func matchPriority(_ lhs: MatchGroup, _ rhs: MatchGroup) -> Bool {
        if lhs.slotIndexes.count != rhs.slotIndexes.count {
            return lhs.slotIndexes.count > rhs.slotIndexes.count
        }
        return (lhs.slotIndexes.first ?? 0) < (rhs.slotIndexes.first ?? 0)
    }
}
