import Foundation

protocol ProgressStore {
    func getBestScore(levelID: Int) -> Int
    func saveBestScore(levelID: Int, score: Int)
    func getBestStars(levelID: Int) -> Int
    func saveBestStars(levelID: Int, stars: Int)
    func getHighestUnlockedLevel() -> Int
    func unlockNextLevel(after levelID: Int)
    func resetProgress()
    func getLives() -> Int
    func loseLife()
    func getDiamonds() -> Int
    func addDiamonds(_ amount: Int)
    func spendDiamondsForLife() -> Bool

    var isSoundEnabled: Bool { get set }
    var isHapticsEnabled: Bool { get set }
}

final class UserDefaultsProgressStore: ProgressStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.highestUnlockedLevel) == nil {
            defaults.set(1, forKey: Keys.highestUnlockedLevel)
        }
        if defaults.object(forKey: Keys.lives) == nil {
            defaults.set(GameConstants.maxLives, forKey: Keys.lives)
        }
    }

    var isSoundEnabled: Bool {
        get {
            guard defaults.object(forKey: Keys.soundEnabled) != nil else { return true }
            return defaults.bool(forKey: Keys.soundEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    var isHapticsEnabled: Bool {
        get {
            guard defaults.object(forKey: Keys.hapticsEnabled) != nil else { return true }
            return defaults.bool(forKey: Keys.hapticsEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.hapticsEnabled) }
    }

    func getBestScore(levelID: Int) -> Int {
        defaults.integer(forKey: Keys.bestScore(levelID))
    }

    func saveBestScore(levelID: Int, score: Int) {
        let key = Keys.bestScore(levelID)
        defaults.set(max(score, defaults.integer(forKey: key)), forKey: key)
    }

    func getBestStars(levelID: Int) -> Int {
        defaults.integer(forKey: Keys.bestStars(levelID))
    }

    func saveBestStars(levelID: Int, stars: Int) {
        let key = Keys.bestStars(levelID)
        defaults.set(max(stars, defaults.integer(forKey: key)), forKey: key)
    }

    func getHighestUnlockedLevel() -> Int {
        max(defaults.integer(forKey: Keys.highestUnlockedLevel), 1)
    }

    func unlockNextLevel(after levelID: Int) {
        let nextLevel = levelID + 1
        if nextLevel > getHighestUnlockedLevel() {
            defaults.set(nextLevel, forKey: Keys.highestUnlockedLevel)
        }
    }

    func getLives() -> Int {
        refreshLivesIfNeeded()
        return min(defaults.integer(forKey: Keys.lives), GameConstants.maxLives)
    }

    func loseLife() {
        refreshLivesIfNeeded()
        let currentLives = getLives()
        guard currentLives > 0 else { return }
        defaults.set(currentLives - 1, forKey: Keys.lives)
        if currentLives == GameConstants.maxLives {
            defaults.set(Date().timeIntervalSince1970 + GameConstants.lifeRefillInterval, forKey: Keys.nextLifeRefillDate)
        }
    }

    func getDiamonds() -> Int {
        defaults.integer(forKey: Keys.diamonds)
    }

    func addDiamonds(_ amount: Int) {
        guard amount > 0 else { return }
        defaults.set(getDiamonds() + amount, forKey: Keys.diamonds)
    }

    func spendDiamondsForLife() -> Bool {
        refreshLivesIfNeeded()
        let lives = getLives()
        let diamonds = getDiamonds()
        guard lives < GameConstants.maxLives, diamonds >= GameConstants.lifeDiamondCost else { return false }
        defaults.set(diamonds - GameConstants.lifeDiamondCost, forKey: Keys.diamonds)
        defaults.set(lives + 1, forKey: Keys.lives)
        if lives + 1 >= GameConstants.maxLives {
            defaults.removeObject(forKey: Keys.nextLifeRefillDate)
        }
        return true
    }

    func resetProgress() {
        let persistentDomain = Bundle.main.bundleIdentifier ?? "ShelfJam"
        defaults.removePersistentDomain(forName: persistentDomain)
        defaults.set(1, forKey: Keys.highestUnlockedLevel)
        defaults.set(true, forKey: Keys.soundEnabled)
        defaults.set(true, forKey: Keys.hapticsEnabled)
        defaults.set(GameConstants.maxLives, forKey: Keys.lives)
        defaults.set(0, forKey: Keys.diamonds)
        defaults.removeObject(forKey: Keys.nextLifeRefillDate)
    }

    private func refreshLivesIfNeeded() {
        let currentLives = min(defaults.integer(forKey: Keys.lives), GameConstants.maxLives)
        guard currentLives < GameConstants.maxLives else {
            defaults.removeObject(forKey: Keys.nextLifeRefillDate)
            return
        }

        let nextRefill = defaults.double(forKey: Keys.nextLifeRefillDate)
        guard nextRefill > 0 else {
            defaults.set(Date().timeIntervalSince1970 + GameConstants.lifeRefillInterval, forKey: Keys.nextLifeRefillDate)
            return
        }

        let now = Date().timeIntervalSince1970
        guard now >= nextRefill else { return }

        let refillCount = Int((now - nextRefill) / GameConstants.lifeRefillInterval) + 1
        let updatedLives = min(GameConstants.maxLives, currentLives + refillCount)
        defaults.set(updatedLives, forKey: Keys.lives)
        if updatedLives >= GameConstants.maxLives {
            defaults.removeObject(forKey: Keys.nextLifeRefillDate)
        } else {
            defaults.set(nextRefill + Double(refillCount) * GameConstants.lifeRefillInterval, forKey: Keys.nextLifeRefillDate)
        }
    }

    private enum Keys {
        static let highestUnlockedLevel = "highestUnlockedLevel"
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let lives = "lives"
        static let diamonds = "diamonds"
        static let nextLifeRefillDate = "nextLifeRefillDate"

        static func bestScore(_ levelID: Int) -> String {
            "bestScore.level.\(levelID)"
        }

        static func bestStars(_ levelID: Int) -> String {
            "bestStars.level.\(levelID)"
        }
    }
}
