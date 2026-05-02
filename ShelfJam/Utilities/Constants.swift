import SwiftUI

enum GameConstants {
    static let defaultSlotCount = 5
    static let maxUndoUses = 3
    static let maxHintUses = 2
    static let maxShuffleUses = 1
    static let lowMovesWarningThreshold = 3
    static let lowTimeWarningThreshold: TimeInterval = 10
    static let endLevelMoveBonus = 25
    static let unlockBonus = 125
    static let maxLives = 5
    static let lifeRefillInterval: TimeInterval = 20 * 60
    static let lifeDiamondCost = 80
    static let adDiamondReward = 8
    static let undoPackCost = 45
    static let hintPackCost = 35
    static let shufflePackCost = 55
    static let premiumLifeDiamondCost = 80

    static func diamondReward(for stars: Int) -> Int {
        switch stars {
        case 3: 35
        case 2: 20
        case 1: 10
        default: 0
        }
    }
}

enum AppStyle {
    static let cornerRadius: CGFloat = 18
    static let shelfCornerRadius: CGFloat = 22
    static let tileCornerRadius: CGFloat = 16
}
