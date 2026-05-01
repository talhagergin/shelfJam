import Foundation

struct MoveRecord: Codable, Hashable {
    let from: Position
    let to: Position
    let movedItem: ShelfItem
    let previousShelvesSnapshot: [[ShelfItem?]]
    let previousMovesLeft: Int
    let previousScore: Int
    let previousCombo: Int
}
