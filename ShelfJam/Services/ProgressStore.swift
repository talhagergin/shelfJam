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
    func addLife()
    func getDiamonds() -> Int
    func addDiamonds(_ amount: Int)
    func spendDiamonds(_ amount: Int) -> Bool
    func spendDiamondsForLife() -> Bool
    func getUndoInventory() -> Int
    func addUndoInventory(_ amount: Int)
    func consumeUndoInventory(_ amount: Int) -> Int
    func getHintInventory() -> Int
    func addHintInventory(_ amount: Int)
    func consumeHintInventory(_ amount: Int) -> Int
    func getShuffleInventory() -> Int
    func addShuffleInventory(_ amount: Int)
    func consumeShuffleInventory(_ amount: Int) -> Int
    var hasSeenOnboarding: Bool { get set }
    var hasSeenLockTutorial: Bool { get set }
    func setHasSeenOnboarding(_ value: Bool)
    func setHasSeenLockTutorial(_ value: Bool)

    var isBackgroundMusicEnabled: Bool { get set }
    var isGameSoundEnabled: Bool { get set }
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
        migrateSplitSoundSettingsIfNeeded()
    }

    var isBackgroundMusicEnabled: Bool {
        get {
            guard defaults.object(forKey: Keys.backgroundMusicEnabled) != nil else { return true }
            return defaults.bool(forKey: Keys.backgroundMusicEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.backgroundMusicEnabled) }
    }

    var isGameSoundEnabled: Bool {
        get {
            guard defaults.object(forKey: Keys.gameSoundEnabled) != nil else { return true }
            return defaults.bool(forKey: Keys.gameSoundEnabled)
        }
        set { defaults.set(newValue, forKey: Keys.gameSoundEnabled) }
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

    func addLife() {
        refreshLivesIfNeeded()
        let lives = getLives()
        guard lives < GameConstants.maxLives else { return }
        defaults.set(lives + 1, forKey: Keys.lives)
        if lives + 1 >= GameConstants.maxLives {
            defaults.removeObject(forKey: Keys.nextLifeRefillDate)
        }
    }

    func getDiamonds() -> Int {
        defaults.integer(forKey: Keys.diamonds)
    }

    func addDiamonds(_ amount: Int) {
        guard amount > 0 else { return }
        defaults.set(getDiamonds() + amount, forKey: Keys.diamonds)
    }

    func spendDiamonds(_ amount: Int) -> Bool {
        guard amount > 0 else { return false }
        let diamonds = getDiamonds()
        guard diamonds >= amount else { return false }
        defaults.set(diamonds - amount, forKey: Keys.diamonds)
        return true
    }

    func spendDiamondsForLife() -> Bool {
        refreshLivesIfNeeded()
        let lives = getLives()
        guard lives < GameConstants.maxLives, spendDiamonds(GameConstants.lifeDiamondCost) else { return false }
        defaults.set(lives + 1, forKey: Keys.lives)
        if lives + 1 >= GameConstants.maxLives {
            defaults.removeObject(forKey: Keys.nextLifeRefillDate)
        }
        return true
    }

    func getUndoInventory() -> Int {
        defaults.integer(forKey: Keys.undoInventory)
    }

    func addUndoInventory(_ amount: Int) {
        addInventory(amount, key: Keys.undoInventory)
    }

    func consumeUndoInventory(_ amount: Int) -> Int {
        consumeInventory(amount, key: Keys.undoInventory)
    }

    func getHintInventory() -> Int {
        defaults.integer(forKey: Keys.hintInventory)
    }

    func addHintInventory(_ amount: Int) {
        addInventory(amount, key: Keys.hintInventory)
    }

    func consumeHintInventory(_ amount: Int) -> Int {
        consumeInventory(amount, key: Keys.hintInventory)
    }

    func getShuffleInventory() -> Int {
        defaults.integer(forKey: Keys.shuffleInventory)
    }

    func addShuffleInventory(_ amount: Int) {
        addInventory(amount, key: Keys.shuffleInventory)
    }

    func consumeShuffleInventory(_ amount: Int) -> Int {
        consumeInventory(amount, key: Keys.shuffleInventory)
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
    }

    var hasSeenLockTutorial: Bool {
        get { defaults.bool(forKey: Keys.hasSeenLockTutorial) }
        set { defaults.set(newValue, forKey: Keys.hasSeenLockTutorial) }
    }

    func setHasSeenOnboarding(_ value: Bool) {
        hasSeenOnboarding = value
    }

    func setHasSeenLockTutorial(_ value: Bool) {
        hasSeenLockTutorial = value
    }

    func resetProgress() {
        let persistentDomain = Bundle.main.bundleIdentifier ?? "ShelfJam"
        defaults.removePersistentDomain(forName: persistentDomain)
        defaults.set(1, forKey: Keys.highestUnlockedLevel)
        defaults.set(true, forKey: Keys.backgroundMusicEnabled)
        defaults.set(true, forKey: Keys.gameSoundEnabled)
        defaults.set(true, forKey: Keys.hapticsEnabled)
        defaults.set(GameConstants.maxLives, forKey: Keys.lives)
        defaults.set(0, forKey: Keys.diamonds)
        defaults.removeObject(forKey: Keys.nextLifeRefillDate)
        defaults.set(false, forKey: Keys.hasSeenOnboarding)
        defaults.set(false, forKey: Keys.hasSeenLockTutorial)
    }

    private func addInventory(_ amount: Int, key: String) {
        guard amount > 0 else { return }
        defaults.set(defaults.integer(forKey: key) + amount, forKey: key)
    }

    private func consumeInventory(_ amount: Int, key: String) -> Int {
        guard amount > 0 else { return 0 }
        let current = defaults.integer(forKey: key)
        let consumed = min(current, amount)
        defaults.set(current - consumed, forKey: key)
        return consumed
    }

    private func migrateSplitSoundSettingsIfNeeded() {
        let hasBackgroundMusic = defaults.object(forKey: Keys.backgroundMusicEnabled) != nil
        let hasGameSound = defaults.object(forKey: Keys.gameSoundEnabled) != nil
        guard !hasBackgroundMusic || !hasGameSound else { return }

        let legacyEnabled: Bool
        if defaults.object(forKey: Keys.legacySoundEnabled) != nil {
            legacyEnabled = defaults.bool(forKey: Keys.legacySoundEnabled)
        } else {
            legacyEnabled = true
        }

        if !hasBackgroundMusic {
            defaults.set(legacyEnabled, forKey: Keys.backgroundMusicEnabled)
        }
        if !hasGameSound {
            defaults.set(legacyEnabled, forKey: Keys.gameSoundEnabled)
        }
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
        static let legacySoundEnabled = "soundEnabled"
        static let backgroundMusicEnabled = "backgroundMusicEnabled"
        static let gameSoundEnabled = "gameSoundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let lives = "lives"
        static let diamonds = "diamonds"
        static let nextLifeRefillDate = "nextLifeRefillDate"
        static let undoInventory = "undoInventory"
        static let hintInventory = "hintInventory"
        static let shuffleInventory = "shuffleInventory"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let hasSeenLockTutorial = "hasSeenLockTutorial"

        static func bestScore(_ levelID: Int) -> String {
            "bestScore.level.\(levelID)"
        }

        static func bestStars(_ levelID: Int) -> String {
            "bestStars.level.\(levelID)"
        }
    }
}
