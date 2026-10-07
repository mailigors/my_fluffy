import CoreGraphics
import Foundation
import SwiftUI

struct HeartMark: Identifiable, Equatable {
    let id = UUID()
    var point: CGPoint
    var created: Date
}

private enum KitchenVoiceCue: Hashable {
    case coldWater, hotWater, lowHeat

    var phrases: [String] {
        switch self {
        case .coldWater:
            return [
                "Бр-р, вода холодная. Добавим горячей?",
                "Давай согреем водичку для продуктов.",
                "Чуть-чуть горячей воды, и будет приятно."
            ]
        case .hotWater:
            return [
                "Ой, горячо. Добавим холодной?",
                "Давай немного остудим водичку.",
                "Чуть-чуть холодной воды, и можно мыть."
            ]
        case .lowHeat:
            return [
                "Плите пока прохладно. Добавим тепла?",
                "Чуть прибавь нагрев, и еда начнёт готовиться.",
                "Подвинь ползунок к зелёному. Вот так будет хорошо."
            ]
        }
    }
}

@MainActor
final class RoomViewModel: ObservableObject {
    enum Route: Equatable {
        case loading
        case start
        case onboarding
        case room
        case kitchen
        case bath
        case toilet
        case playMenu
        case fish
        case clouds
        case puzzleMenu
        case puzzle
        case memory
        case ticTacToe
        case beaver
        case airHockey
        case toyTargets
        case shop
        case wardrobe
        case parentGate
        case parentSettings
        case unavailable
    }

    @Published private(set) var route: Route = .loading
    @Published private(set) var needs: PetNeeds
    @Published private(set) var isSleeping = false
    @Published private(set) var petName: String
    @Published private(set) var ageMode: AgeMode
    @Published var showsSleepPrompt = false
    @Published var nightVisible = false
    @Published private(set) var hearts: [HeartMark] = []
    @Published private(set) var look: PetLook = .idle
    @Published private(set) var kitchen: KitchenState = .newcomer
    @Published private(set) var kitchenSession = KitchenSession()
    @Published private(set) var bathSession = BathSession()
    @Published private(set) var toiletSession = ToiletSession()
    @Published private(set) var playProgress = PlayProgress()
    @Published private(set) var shop = ShopState()
    @Published private(set) var parentOptions: ParentOptions
    @Published private(set) var fishRound: FishRound?
    @Published private(set) var cloudRound: CloudRound?
    @Published private(set) var puzzleRound: PuzzleRound?
    @Published private(set) var memoryRound: MemoryRound?
    @Published private(set) var ticTacToeRound: TicTacToeRound?
    @Published private(set) var beaverRound: BeaverRound?
    @Published private(set) var hockeyRound: AirHockeyRound?
    @Published private(set) var toyTargetRound: ToyTargetRound?
    @Published private(set) var isFeeding = false
    @Published private(set) var feedingRecipe: RecipeID?

    var canPet: Bool {
        isSleeping == false && isFeeding == false && CareAccess.allowedActions(for: needs).contains(.petting)
    }

    var canSleep: Bool {
        isSleeping == false && isFeeding == false && CareAccess.allowedActions(for: needs).contains(.sleep)
    }

    private let store: PetStore
    private let defaults: UserDefaults
    private let sound: SoundPlaying
    private let clock: () -> Date
    private var sleepAnchor: Date?
    private var energyAtSleepStart = 0.0
    private var lastPetAt: Date?
    private var lastHappyAt: Date?
    private var lastToyAt: Date?
    private var parentHoldComplete = false
    private var happyResetTask: Task<Void, Never>?
    private var isStroking = false
    private var isSizzling = false
    private var pendingHockeyPaddleX: Double?
    private var spokenCueIndex: [KitchenVoiceCue: Int] = [:]
    private var lastSpokenCue: KitchenVoiceCue?
    private var lastSpokenAt: Date?
    private var timer: Timer?
    private var didPrepare = false
    private var sceneIsActive = true

    init(
        store: PetStore = PetStore(),
        defaults: UserDefaults = .standard,
        sound: SoundPlaying,
        clock: @escaping () -> Date = Date.init,
        autoload: Bool = true
    ) {
        self.store = store
        self.defaults = defaults
        self.sound = sound
        self.clock = clock
        petName = PetSettings.loadName(from: defaults)
        ageMode = PetSettings.loadAgeMode(from: defaults)
        parentOptions = ParentOptions.load(from: defaults)
        needs = PetNeeds.newcomer(at: clock())
        if autoload {
            Task { await self.prepare() }
        }
    }

    deinit {
        timer?.invalidate()
        happyResetTask?.cancel()
    }

    func prepare() async {
        guard didPrepare == false else { return }
        didPrepare = true
        do {
            try await store.loadStores()
            sound.prepareSession()
            sound.effectsEnabled = parentOptions.effectsEnabled
            sound.setMix(effects: parentOptions.effectsVolume,
                         music: parentOptions.musicVolume,
                         voice: parentOptions.voiceVolume)
            if PetSettings.didFinishOnboarding(in: defaults) {
                try restoreRoom()
            }
            route = .start
            sound.setMusicQuiet(isSleeping)
            if sceneIsActive { sound.startMusic() }
        } catch {
            route = .unavailable
            sound.stopMusic()
        }
    }

    func retry() {
        didPrepare = false
        route = .loading
        Task { await prepare() }
    }

    func startGame() {
        guard route == .start else { return }
        if PetSettings.didFinishOnboarding(in: defaults) {
            returnedToForeground()
            route = .room
            if sceneIsActive { sound.startMusic() }
        } else {
            route = .onboarding
        }
    }

    func leaveGame() {
        guard route == .room else { return }
        endStroke()
        stopTimer()
        sound.stopSnore()
        happyResetTask?.cancel()
        showsSleepPrompt = false
        persist()
        route = .start
    }

    func finishOnboarding(name: String, mode: AgeMode) {
        PetSettings.saveName(name, to: defaults)
        PetSettings.saveAgeMode(mode, to: defaults)
        PetSettings.setFinishedOnboarding(true, in: defaults)
        petName = PetSettings.loadName(from: defaults)
        ageMode = mode
        let now = clock()
        needs = PetNeeds.newcomer(at: now)
        kitchen = .newcomer
        playProgress = PlayProgress()
        shop = ShopState()
        isSleeping = false
        nightVisible = false
        do {
            try store.save(StoredPet(needs: needs, isSleeping: false, kitchen: kitchen, playProgress: playProgress, shop: shop))
            updateLook(now: now)
            route = .room
            if sceneIsActive { sound.startMusic() }
        } catch {
            route = .unavailable
        }
    }

    func beginStroke() {
        guard canPet, isStroking == false else { return }
        isStroking = true
        sound.startPurr()
    }

    func endStroke() {
        guard isStroking else { return }
        isStroking = false
        sound.stopPurr()
    }

    func pet(at point: CGPoint) {
        let now = clock()
        guard canPet else { return }
        let outcome = Petting.applying(needs, at: now, lastPetAt: lastPetAt)
        needs = outcome.needs
        lastPetAt = outcome.lastPetAt
        let wasHappy = look == .happy
        if outcome.didApply {
            hearts.append(HeartMark(point: point, created: now))
            lastHappyAt = now
            scheduleHappyReset()
            persist()
        }
        pruneHearts(now: now)
        updateLook(now: now)
        if outcome.didApply, wasHappy == false, look == .happy {
            sound.playHappyMeow()
        }
    }

    func requestSleep() {
        guard canSleep else { return }
        showsSleepPrompt = true
    }

    func cancelSleepPrompt() {
        showsSleepPrompt = false
    }

    func beginSleep() {
        guard canSleep else { return }
        let now = clock()
        endStroke()
        showsSleepPrompt = false
        isSleeping = true
        nightVisible = true
        energyAtSleepStart = needs.energy
        sleepAnchor = now
        needs.lastCalculated = now
        startTimer()
        sound.startSnore()
        sound.setMusicQuiet(true)
        persist()
        updateLook(now: now)
    }

    func wake() {
        guard isSleeping else { return }
        refreshOpenSleep()
        isSleeping = false
        nightVisible = false
        stopTimer()
        needs.lastCalculated = clock()
        sound.stopSnore()
        sound.setMusicQuiet(false)
        sound.playMeow()
        persist()
        updateLook(now: clock())
    }

    func refreshOpenSleep() {
        guard isSleeping, let anchor = sleepAnchor else { return }
        let now = clock()
        let ticked = SleepRecovery.ticking(energy: energyAtSleepStart, since: anchor, until: now)
        var next = NeedsDecay.applying(needs, at: now, mode: ageMode)
        next.energy = ticked.energy
        let energyChanged = next.energy != needs.energy
        needs = next
        pruneHearts(now: now)
        updateLook(now: now)
        if energyChanged {
            persist()
        }
    }

    func openKitchen() {
        guard route == .room, !isSleeping, !isFeeding else { return }
        endStroke()
        kitchenSession = KitchenSession()
        route = .kitchen
    }

    func closeKitchen() {
        guard route == .kitchen else { return }
        sound.stopSpeech()
        sound.stopWater()
        stopSizzle()
        kitchenSession = KitchenSession()
        route = .room
    }

    func openBath() {
        guard route == .room, !isSleeping, !isFeeding else { return }
        endStroke()
        bathSession = BathSession()
        route = .bath
    }

    func popBathBubble(_ index: Int) {
        guard route == .bath else { return }
        let poppedBefore = bathSession.popped.count
        bathSession.popBubble(index)
        if bathSession.popped.count > poppedBefore {
            sound.playBubblePop(variant: poppedBefore % 4)
            if needs.cleanliness < 100 {
                needs.cleanliness = min(99, needs.cleanliness + 4)
            }
            updateLook(now: clock())
            persist()
        }
    }

    func soapBath(from start: GamePoint, to end: GamePoint) {
        guard route == .bath else { return }
        bathSession.soapStroke(from: start, to: end)
    }

    func pickUpBathShower() {
        guard route == .bath, bathSession.step == .shower else { return }
        bathSession.pickUpShower()
        sound.startWater()
    }

    func moveBathShower(to point: GamePoint) {
        guard route == .bath else { return }
        bathSession.moveShower(to: point)
        if bathSession.step == .towel { sound.stopWater() }
    }

    func pickUpBathTool() {
        guard route == .bath else { return }
        bathSession.pickUpTool()
    }

    func rubBathTowel(from start: GamePoint, to end: GamePoint) {
        guard route == .bath else { return }
        bathSession.rubTowel(from: start, to: end)
    }

    func combBath(from start: GamePoint, to end: GamePoint) {
        guard route == .bath else { return }
        let wasFinished = bathSession.step == .finished
        bathSession.combStroke(from: start, to: end)
        guard !wasFinished, bathSession.step == .finished else { return }
        needs.cleanliness = 100
        kitchen.coins += 6
        sound.playHappyMeow()
        updateLook(now: clock())
        persist()
    }

    func openToilet() {
        guard route == .room, !isSleeping, !isFeeding, needs.toilet > 70 else { return }
        endStroke()
        toiletSession = ToiletSession()
        route = .toilet
    }

    func movePaper(to point: GamePoint) {
        guard route == .toilet else { return }
        toiletSession.movePaper(to: point)
    }

    func moveSponge(to point: GamePoint) {
        guard route == .toilet else { return }
        toiletSession.moveSponge(to: point)
    }

    func flushToilet() {
        guard route == .toilet, toiletSession.step == .flush else { return }
        toiletSession.flush()
        sound.playGameCue(.flush)
        needs.toilet = 0
        kitchen.coins += 6
        sound.playHappyMeow()
        updateLook(now: clock())
        persist()
    }

    func openPlayMenu() {
        guard route == .room, !isSleeping, !isFeeding else { return }
        endStroke()
        route = .playMenu
    }

    func openShop() {
        guard route == .room, !isSleeping, !isFeeding else { return }
        route = .shop
    }

    func addTestCoins() {
        guard route == .shop, kitchen.coins < 9_999 else { return }
        kitchen.coins = min(9_999, kitchen.coins + 100)
        sound.playGameCue(.select)
        persist()
    }

    func buyShopItem(_ item: ShopItem) {
        guard route == .shop else { return }
        var updatedShop = shop
        var updatedKitchen = kitchen
        guard updatedShop.buy(item, kitchen: &updatedKitchen) else { return }
        if item.category == .outfits {
            updatedShop.toggleOutfit(item)
        }
        shop = updatedShop
        kitchen = updatedKitchen
        sound.playGameCue(.select)
        persist()
    }

    func buyShopFood(_ ingredient: Ingredient) {
        guard route == .shop else { return }
        var updatedKitchen = kitchen
        guard ShopState.buyFood(ingredient, kitchen: &updatedKitchen) else { return }
        kitchen = updatedKitchen
        sound.playGameCue(.select)
        persist()
    }

    func openWardrobe() {
        guard route == .shop else { return }
        route = .wardrobe
    }

    func returnToShop() {
        guard route == .wardrobe else { return }
        route = .shop
    }

    func toggleOutfit(_ item: ShopItem) {
        guard route == .wardrobe else { return }
        var updated = shop
        updated.toggleOutfit(item)
        guard updated != shop else { return }
        shop = updated
        sound.playGameCue(.select)
        persist()
    }

    func wearShopOutfit(_ item: ShopItem) {
        guard route == .shop, item.category == .outfits, !shop.isEquipped(item) else { return }
        var updated = shop
        updated.toggleOutfit(item)
        guard updated != shop else { return }
        shop = updated
        sound.playGameCue(.select)
        persist()
    }

    func playWithToy(_ item: ShopItem) {
        guard route == .room, !isSleeping, !isFeeding,
              item.category == .toys, shop.owned.contains(item) else { return }
        let now = clock()
        if let lastToyAt, now.timeIntervalSince(lastToyAt) < 2 { return }
        lastToyAt = now
        rewardPlay(mood: 4)
        sound.playGameCue(.select)
    }

    private func rewardPlay(mood: Double = 12) {
        let now = clock()
        needs.mood = min(100, needs.mood + mood)
        lastHappyAt = now
        updateLook(now: now)
        scheduleHappyReset()
        persist()
    }

    func selectRoomDecor(_ item: ShopItem) {
        guard route == .room || route == .shop else { return }
        var updated = shop
        updated.selectDecor(item)
        guard updated != shop else { return }
        shop = updated
        sound.playGameCue(.select)
        persist()
    }

    func openParentGate() {
        guard route == .shop else { return }
        parentHoldComplete = false
        route = .parentGate
    }

    func completeParentHold() {
        guard route == .parentGate else { return }
        parentHoldComplete = true
    }

    func unlockParentSettings(answer: Int) {
        guard route == .parentGate, parentHoldComplete else { return }
        guard answer == 12 else { parentHoldComplete = false; return }
        parentHoldComplete = false
        route = .parentSettings
    }

    func saveParentName(_ name: String) {
        guard route == .parentSettings else { return }
        PetSettings.saveName(name, to: defaults)
        petName = PetSettings.loadName(from: defaults)
    }

    func setParentAge(_ mode: AgeMode) {
        guard route == .parentSettings else { return }
        PetSettings.saveAgeMode(mode, to: defaults)
        ageMode = mode
    }

    func updateParentOptions(_ update: (inout ParentOptions) -> Void) {
        guard route == .parentSettings else { return }
        var updated = parentOptions
        update(&updated)
        parentOptions = updated
        updated.save(to: defaults)
        sound.effectsEnabled = updated.effectsEnabled
        sound.setMix(effects: updated.effectsVolume,
                     music: updated.musicVolume,
                     voice: updated.voiceVolume)
    }

    func startFishRound() {
        guard route == .playMenu || route == .fish else { return }
        fishRound = FishRound(startedAt: clock(), mode: ageMode, level: playProgress.fishLevel)
        route = .fish
        persist()
    }

    func catchFish(_ index: Int) {
        guard route == .fish, var round = fishRound else { return }
        let previousMistakes = round.mistakes
        let earned = round.catchFish(index, at: clock())
        fishRound = round
        if round.mistakes > previousMistakes { sound.playGameCue(.miss); return }
        guard earned > 0 else { return }
        sound.playGameCue(index == 6 ? .gold : .catchFish)
        if round.won {
            sound.playGameCue(.win)
            playProgress.advanceFishLevel()
            rewardPlay()
        }
        kitchen.coins += earned
        persist()
    }

    func tickFishRound() {
        guard route == .fish, var round = fishRound else { return }
        let wasFinished = round.finished
        round.tick(at: clock())
        fishRound = round
        if !wasFinished && round.finished { sound.playGameCue(.lose) }
    }

    func startCloudRound() {
        guard route == .playMenu || route == .clouds else { return }
        cloudRound = CloudRound(now: clock(), mode: ageMode, seed: UInt64.random(in: 1...UInt64.max))
        route = .clouds
        persist()
    }

    func tapCloud(_ index: Int) {
        guard route == .clouds, var round = cloudRound else { return }
        let previousMisses = round.misses
        let earned = round.tapCloud(index, at: clock())
        cloudRound = round
        if round.misses > previousMisses { sound.playGameCue(round.finished ? .lose : .miss) }
        if earned > 0 { sound.playGameCue(round.won ? .win : .jump); kitchen.coins += earned }
        if round.won && earned > 0 { rewardPlay() }
        persist()
    }

    func tickCloudRound() {
        guard route == .clouds, var round = cloudRound else { return }
        let previousMisses = round.misses
        round.tick(at: clock())
        cloudRound = round
        if round.misses > previousMisses { sound.playGameCue(round.finished ? .lose : .miss) }
    }

    func openPuzzleMenu() {
        guard route == .playMenu else { return }
        route = .puzzleMenu
    }

    func startPuzzle(imageIndex: Int) {
        guard route == .puzzleMenu || route == .puzzle else { return }
        puzzleRound = PuzzleRound(imageIndex: imageIndex, mode: ageMode, seed: UInt64.random(in: 1...UInt64.max))
        route = .puzzle
        persist()
    }

    func tapPuzzlePiece(_ index: Int) {
        guard route == .puzzle, let before = puzzleRound else { return }
        puzzleRound?.tap(index)
        guard let after = puzzleRound, after != before else { return }
        sound.playGameCue(after.finished ? .win : (after.selected == nil ? .move : .select))
        if after.finished && !before.finished { rewardPlay() }
    }

    func startMemoryRound() {
        guard route == .playMenu || route == .memory else { return }
        memoryRound = MemoryRound(level: playProgress.memoryLevel, seed: UInt64.random(in: 1...UInt64.max))
        route = .memory
        persist()
    }

    func flipMemoryCard(_ index: Int) {
        guard route == .memory, var round = memoryRound else { return }
        let before = round
        let wasFinished = round.phase == .finished
        round.flip(index)
        memoryRound = round
        if round != before {
            sound.playGameCue(round.phase == .finished ? (round.outcome == .child ? .win : .lose) :
                              (round.childPairs > before.childPairs ? .match : .select))
        }
        recordMemoryCompletion(wasFinished: wasFinished)
    }

    func revealMemoryCatTurn(id: UUID) {
        guard route == .memory, var round = memoryRound, round.id == id else { return }
        round.revealCatTurn()
        memoryRound = round
    }

    func finishMemoryCatTurn(id: UUID) {
        guard route == .memory, var round = memoryRound, round.id == id else { return }
        let previousPairs = round.catPairs
        let wasFinished = round.phase == .finished
        round.finishCatTurn()
        memoryRound = round
        if round.catPairs > previousPairs { sound.playGameCue(.match) }
        if round.phase == .finished { sound.playGameCue(round.outcome == .child ? .win : .lose) }
        recordMemoryCompletion(wasFinished: wasFinished)
    }

    private func recordMemoryCompletion(wasFinished: Bool) {
        guard !wasFinished, memoryRound?.phase == .finished else { return }
        if memoryRound?.outcome == .child { playProgress.advanceMemoryLevel() }
        rewardPlay()
        persist()
    }

    func startTicTacToeRound() {
        guard route == .playMenu || route == .ticTacToe else { return }
        ticTacToeRound = TicTacToeRound(seed: UInt64.random(in: 1...UInt64.max))
        route = .ticTacToe
        persist()
    }

    func tapTicTacToe(_ index: Int) {
        guard route == .ticTacToe else { return }
        let previous = ticTacToeRound
        ticTacToeRound?.childTap(index)
        if ticTacToeRound != previous {
            sound.playGameCue(ticTacToeRound?.outcome == .child ? .win : .move)
            if previous?.outcome == nil, ticTacToeRound?.outcome != nil { rewardPlay() }
        }
    }

    func playTicTacToeCat(id: UUID) {
        guard route == .ticTacToe, ticTacToeRound?.id == id else { return }
        ticTacToeRound?.catMove()
        sound.playGameCue(ticTacToeRound?.outcome == .cat ? .lose : .move)
        if ticTacToeRound?.outcome != nil { rewardPlay() }
    }

    func startBeaverRound() {
        guard route == .playMenu || route == .beaver else { return }
        let now = clock()
        beaverRound = BeaverRound(now: now, mode: ageMode, seed: UInt64.random(in: 1...UInt64.max), level: playProgress.beaverLevel)
        playProgress.advanceBeaverLevel()
        route = .beaver
        persist()
    }

    func tapBeaverHole(_ index: Int) {
        guard route == .beaver else { return }
        let previousMeter = beaverRound?.meter
        beaverRound?.tap(index, at: clock())
        if let previousMeter, let round = beaverRound, round.meter > previousMeter {
            sound.playGameCue(round.outcome == .win ? .win : .hit)
            if round.outcome == .win { rewardPlay() }
        }
    }

    func tickBeaverRound() {
        guard route == .beaver else { return }
        let previousMeter = beaverRound?.meter
        beaverRound?.tick(at: clock())
        if let previousMeter, let round = beaverRound, round.meter < previousMeter {
            sound.playGameCue(round.outcome == .lose ? .lose : .miss)
        }
    }

    func startAirHockey() {
        guard route == .playMenu || route == .airHockey else { return }
        pendingHockeyPaddleX = nil
        hockeyRound = AirHockeyRound(now: clock(), mode: ageMode)
        route = .airHockey
    }

    func moveHockeyPaddle(to x: Double) {
        guard route == .airHockey else { return }
        pendingHockeyPaddleX = x
    }

    func tickAirHockey() {
        guard route == .airHockey, var round = hockeyRound else { return }
        if let pendingHockeyPaddleX {
            round.moveChild(to: pendingHockeyPaddleX)
            self.pendingHockeyPaddleX = nil
        }
        guard round.outcome == nil else { return }
        let oldCollisions = round.collisionCount
        let oldGoals = round.goalCount
        let oldOutcome = round.outcome
        round.tick(at: clock())
        hockeyRound = round
        if round.collisionCount > oldCollisions { sound.playGameCue(.hockeyHit) }
        if round.goalCount > oldGoals { sound.playGameCue(.hockeyGoal) }
        if oldOutcome == nil, let outcome = round.outcome {
            sound.playGameCue(outcome == .child ? .win : .lose)
            rewardPlay()
            if outcome == .child { kitchen.coins += 5; persist() }
        }
    }

    func startToyTargets() {
        guard route == .playMenu || route == .toyTargets else { return }
        toyTargetRound = ToyTargetRound(now: clock(), mode: ageMode)
        route = .toyTargets
    }

    @discardableResult func shootToyTarget(at point: GamePoint) -> Bool {
        guard route == .toyTargets, var round = toyTargetRound else { return false }
        let previousOutcome = round.outcome
        let hit = round.shoot(at: point, now: clock())
        toyTargetRound = round
        sound.playGameCue(hit ? .toyPop : .toyShot)
        if previousOutcome == nil, let outcome = round.outcome {
            sound.playGameCue(outcome == .win ? .win : .lose)
            rewardPlay()
            if outcome == .win { kitchen.coins += 5; persist() }
        }
        return hit
    }

    func tickToyTargets() {
        guard route == .toyTargets, var round = toyTargetRound else { return }
        let previousOutcome = round.outcome
        round.tick(at: clock())
        toyTargetRound = round
        if previousOutcome == nil, round.outcome == .lose { sound.playGameCue(.lose) }
    }

    func closeActivity() {
        guard [.bath, .toilet, .playMenu, .fish, .clouds, .puzzleMenu, .puzzle, .memory, .ticTacToe, .beaver, .airHockey, .toyTargets, .shop, .wardrobe, .parentGate, .parentSettings].contains(route) else { return }
        sound.stopSpeech()
        sound.stopWater()
        route = .room
    }

    func addIngredient(_ ingredient: Ingredient) {
        guard route == .kitchen else { return }
        kitchenSession.add(ingredient, from: kitchen)
    }

    func restockIngredient(_ ingredient: Ingredient) {
        guard route == .kitchen, kitchenSession.step == .choosing else { return }
        kitchen.restock(ingredient)
        persist()
    }

    func removeLastIngredient() { kitchenSession.removeLast() }
    func startCooking() { kitchenSession.start() }
    func setColdFlow(_ value: Double) {
        let wasOpen = kitchenSession.coldFlow > 0.05
        let waterWasOn = kitchenSession.waterOn
        kitchenSession.setColdFlow(value)
        updateWaterSound(wasOpen: wasOpen, isOpen: kitchenSession.coldFlow > 0.05, waterWasOn: waterWasOn)
    }

    func setHotFlow(_ value: Double) {
        let wasOpen = kitchenSession.hotFlow > 0.05
        let waterWasOn = kitchenSession.waterOn
        kitchenSession.setHotFlow(value)
        updateWaterSound(wasOpen: wasOpen, isOpen: kitchenSession.hotFlow > 0.05, waterWasOn: waterWasOn)
    }

    private func updateWaterSound(wasOpen: Bool, isOpen: Bool, waterWasOn: Bool) {
        guard route == .kitchen, kitchenSession.step == .washing else { return }
        if !wasOpen && isOpen { sound.playFaucetOpen() }
        if !waterWasOn && kitchenSession.waterOn { sound.startWater() }
        if waterWasOn && !kitchenSession.waterOn { sound.stopWater() }
    }

    func washIngredients(distance: Double) {
        let wasWashing = kitchenSession.step == .washing
        kitchenSession.wash(distance: distance)
        if wasWashing && kitchenSession.step != .washing { sound.stopWater() }
    }

    func speakWashingCueIfNeeded() {
        guard route == .kitchen, kitchenSession.step == .washing else { return }
        switch kitchenSession.waterTemperature {
        case .cold: speakKitchenCue(.coldWater)
        case .hot: speakKitchenCue(.hotWater)
        case .off, .warm: break
        }
    }

    func speakLowHeatCueIfNeeded() {
        guard route == .kitchen, kitchenSession.step == .frying,
              kitchenSession.ingredientsInPan, kitchenSession.heatZone == .yellow else { return }
        speakKitchenCue(.lowHeat)
    }

    private func speakKitchenCue(_ cue: KitchenVoiceCue) {
        guard sound.effectsEnabled else { return }
        let now = clock()
        if lastSpokenCue == cue, let lastSpokenAt,
           now.timeIntervalSince(lastSpokenAt) < 3.5 { return }
        let phrases = cue.phrases
        let index = spokenCueIndex[cue, default: 0]
        sound.speak(phrases[index])
        spokenCueIndex[cue] = (index + 1) % phrases.count
        lastSpokenCue = cue
        lastSpokenAt = now
    }
    func chopIngredient() { kitchenSession.chop() }
    func setHeat(_ value: Double) {
        let wasBurnt = kitchenSession.step == .burnt
        kitchenSession.setHeat(value)
        updateCookingAfterChange(wasBurnt: wasBurnt)
    }
    func placeIngredientsInPan() {
        let wasBurnt = kitchenSession.step == .burnt
        kitchenSession.placeIngredientsInPan()
        updateCookingAfterChange(wasBurnt: wasBurnt)
    }
    func stirPan(distance: Double) {
        kitchenSession.stir(distance: distance)
        updateSizzle()
    }

    private func updateCookingAfterChange(wasBurnt: Bool) {
        if !wasBurnt, kitchenSession.step == .burnt,
           let remaining = KitchenEconomy.consumeBurnt(kitchenSession, kitchen: kitchen) {
            kitchen = remaining
            persist()
        }
        updateSizzle()
    }

    private func updateSizzle() {
        let shouldSizzle = route == .kitchen && kitchenSession.step == .frying &&
            kitchenSession.stoveOn && kitchenSession.ingredientsInPan && kitchenSession.heatZone == .green
        if shouldSizzle && !isSizzling {
            sound.startSizzle()
            isSizzling = true
        } else if !shouldSizzle {
            stopSizzle()
        }
    }

    private func stopSizzle() {
        guard isSizzling else { return }
        sound.stopSizzle()
        isSizzling = false
    }
    func chooseDecoration(_ index: Int) { kitchenSession.chooseDecoration(index) }
    func decorateDish() { kitchenSession.decorate() }

    func discardDish() {
        guard route == .kitchen else { return }
        sound.stopSpeech()
        sound.stopWater()
        stopSizzle()
        kitchenSession = KitchenSession()
    }

    func serveDish() {
        guard route == .kitchen, !isFeeding else { return }
        needs = PetTime.applyingReturn(needs, isSleeping: false, at: clock(), mode: ageMode)
        guard let result = KitchenEconomy.serve(kitchenSession, needs: needs, kitchen: kitchen) else { return }
        beginFeeding(result)
    }

    private func beginFeeding(_ result: FeedingResult) {
        isFeeding = true
        feedingRecipe = result.recipe
        route = .room
        sound.stopSpeech()
        sound.playEating()
        needs = result.needs
        kitchen = result.kitchen
        persist()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard let self else { return }
            self.kitchenSession = KitchenSession()
            self.isFeeding = false
            self.feedingRecipe = nil
            self.updateLook(now: self.clock())
        }
    }

    func sceneChanged(to phase: ScenePhase) {
        sceneIsActive = phase == .active
        switch phase {
        case .active:
            if route != .loading && route != .unavailable {
                sound.startMusic()
            }
        case .inactive, .background:
            sound.stopSpeech()
            sound.stopMusic()
        @unknown default:
            sound.stopMusic()
        }
        switch route {
        case .room, .kitchen, .bath, .toilet, .playMenu, .fish, .clouds, .puzzleMenu, .puzzle, .memory, .ticTacToe, .beaver, .airHockey, .toyTargets, .shop, .wardrobe, .parentGate, .parentSettings: break
        default: return
        }
        switch phase {
        case .active:
            returnedToForeground()
            if route == .kitchen, kitchenSession.step == .washing, kitchenSession.waterOn {
                sound.startWater()
            }
            if route == .bath, bathSession.step == .shower, bathSession.showerTaken { sound.startWater() }
            updateSizzle()
        case .background:
            endStroke()
            sound.stopSnore()
            sound.stopWater()
            stopSizzle()
            stopTimer()
            happyResetTask?.cancel()
            persist()
        case .inactive:
            sound.stopWater()
            stopSizzle()
            persist()
        @unknown default:
            persist()
        }
    }

    private func returnedToForeground() {
        let now = clock()
        needs = PetTime.applyingReturn(needs, isSleeping: isSleeping, at: now, mode: ageMode)
        if isSleeping {
            energyAtSleepStart = needs.energy
            sleepAnchor = now
            nightVisible = true
            startTimer()
            sound.startSnore()
        }
        pruneHearts(now: now)
        updateLook(now: now)
        persist()
    }

    private func restoreRoom() throws {
        let now = clock()
        if let stored = try store.load() {
            needs = PetTime.applyingReturn(
                stored.needs,
                isSleeping: stored.isSleeping,
                at: now,
                mode: ageMode
            )
            isSleeping = stored.isSleeping
            kitchen = stored.kitchen
            playProgress = stored.playProgress
            shop = stored.shop
            if isSleeping {
                energyAtSleepStart = needs.energy
                sleepAnchor = now
                nightVisible = true
            }
            try store.save(StoredPet(needs: needs, isSleeping: isSleeping, kitchen: kitchen, playProgress: playProgress, shop: shop))
        } else {
            needs = PetNeeds.newcomer(at: now)
            kitchen = .newcomer
            playProgress = PlayProgress()
            shop = ShopState()
            try store.save(StoredPet(needs: needs, isSleeping: false, kitchen: kitchen, playProgress: playProgress, shop: shop))
        }
        updateLook(now: now)
    }

    private func updateLook(now: Date) {
        let recent: Bool
        if let lastHappyAt {
            recent = now.timeIntervalSince(lastHappyAt) < CareAccess.happyDuration
        } else {
            recent = false
        }
        look = PetAppearance.look(needs: needs, isSleeping: isSleeping, pettedRecently: recent)
    }

    private func pruneHearts(now: Date) {
        hearts.removeAll { now.timeIntervalSince($0.created) > 1.2 }
    }

    private func scheduleHappyReset() {
        happyResetTask?.cancel()
        happyResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(CareAccess.happyDuration * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            self.pruneHearts(now: self.clock())
            guard !Task.isCancelled else { return }
            self.updateLook(now: self.clock())
        }
    }

    private func persist() {
        do {
            try store.save(StoredPet(needs: needs, isSleeping: isSleeping, kitchen: kitchen, playProgress: playProgress, shop: shop))
        } catch {
            return
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshOpenSleep()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
