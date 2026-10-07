import CoreGraphics
import SwiftUI
import XCTest
@testable import MyFluffy

final class SpySound: SoundPlaying {
    var effectsEnabled = true
    private(set) var meows = 0
    private(set) var happyMeows = 0
    private(set) var eatingSounds = 0
    private(set) var purrStarts = 0
    private(set) var purrStops = 0
    private(set) var snoreStarts = 0
    private(set) var snoreStops = 0
    private(set) var faucetOpens = 0
    private(set) var bubbleVariants: [Int] = []
    private(set) var waterStarts = 0
    private(set) var waterStops = 0
    private(set) var sizzleStarts = 0
    private(set) var sizzleStops = 0
    private(set) var musicStarts = 0
    private(set) var musicStops = 0
    private(set) var musicQuiet = false
    private(set) var spokenPhrases: [String] = []
    private(set) var gameCues: [GameCue] = []
    func prepareSession() {}
    func playMeow() { meows += 1 }
    func playHappyMeow() { happyMeows += 1 }
    func playEating() { eatingSounds += 1 }
    func startPurr() { purrStarts += 1 }
    func stopPurr() { purrStops += 1 }
    func startSnore() { snoreStarts += 1 }
    func stopSnore() { snoreStops += 1 }
    func playFaucetOpen() { faucetOpens += 1 }
    func playBubblePop(variant: Int) { bubbleVariants.append(variant) }
    func startWater() { waterStarts += 1 }
    func stopWater() { waterStops += 1 }
    func startSizzle() { sizzleStarts += 1 }
    func stopSizzle() { sizzleStops += 1 }
    func startMusic() { musicStarts += 1 }
    func stopMusic() { musicStops += 1 }
    func setMusicQuiet(_ quiet: Bool) { musicQuiet = quiet }
    func speak(_ phrase: String) { spokenPhrases.append(phrase) }
    func stopSpeech() {}
    func playGameCue(_ cue: GameCue) { gameCues.append(cue) }
}

final class ManualClock {
    var date: Date
    init(_ date: Date) { self.date = date }
    func now() -> Date { date }
}

@MainActor
final class RoomViewModelTests: XCTestCase {
    private let suiteName = "RoomViewModelTests"
    private var defaults: UserDefaults?

    override func setUp() {
        super.setUp()
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Не удалось создать suite UserDefaults")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        self.defaults = defaults
    }

    override func tearDown() {
        defaults?.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testPettingRespectsCooldownAndPlaysPurr() async throws {
        let harness = try await makeRoom(mood: 40, energy: 60)
        harness.model.beginStroke()
        harness.model.pet(at: CGPoint(x: 20, y: 30))
        harness.model.pet(at: CGPoint(x: 20, y: 30))
        harness.model.endStroke()
        XCTAssertEqual(harness.model.needs.mood, 44)
        XCTAssertEqual(harness.sound.purrStarts, 1)
        XCTAssertEqual(harness.sound.purrStops, 1)
        XCTAssertEqual(harness.sound.happyMeows, 1)
        harness.clock.date = harness.clock.date.addingTimeInterval(0.5)
        harness.model.pet(at: .zero)
        XCTAssertEqual(harness.model.needs.mood, 48)
        XCTAssertEqual(harness.sound.purrStarts, 1)
        XCTAssertEqual(harness.sound.happyMeows, 1)
    }

    func testTestCoinsAreImmediateAndPersist() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openShop()
        harness.model.addTestCoins()
        XCTAssertEqual(harness.model.kitchen.coins, 100)
        XCTAssertEqual(try harness.store.load()?.kitchen.coins, 100)
        harness.model.addTestCoins()
        XCTAssertEqual(harness.model.kitchen.coins, 200)
        XCTAssertEqual(try harness.store.load()?.kitchen.coins, 200)
    }

    func testPurchasedOutfitIsWornImmediately() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openShop()
        harness.model.addTestCoins()
        harness.model.buyShopItem(.bow)
        XCTAssertTrue(harness.model.shop.isEquipped(.bow))
        XCTAssertTrue(try harness.store.load()?.shop.isEquipped(.bow) == true)
    }

    func testOwnedOutfitCanBeWornAgainFromShop() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openShop()
        harness.model.addTestCoins()
        harness.model.buyShopItem(.beret)
        harness.model.openWardrobe()
        harness.model.toggleOutfit(.beret)
        XCTAssertFalse(harness.model.shop.isEquipped(.beret))
        harness.model.returnToShop()
        harness.model.wearShopOutfit(.beret)
        XCTAssertTrue(harness.model.shop.isEquipped(.beret))
        XCTAssertTrue(try harness.store.load()?.shop.isEquipped(.beret) == true)
    }

    func testRedNeedStillAllowsHeartsAndPurr() async throws {
        let harness = try await makeRoom(mood: 40, energy: 60, satiety: 10)
        harness.model.beginStroke()
        harness.model.pet(at: CGPoint(x: 20, y: 30))
        harness.model.endStroke()
        XCTAssertEqual(harness.model.needs.mood, 44)
        XCTAssertEqual(harness.model.hearts.count, 1)
        XCTAssertEqual(harness.model.look, .happy)
        XCTAssertEqual(harness.sound.purrStarts, 1)
        XCTAssertEqual(harness.sound.purrStops, 1)
    }

    func testOpenSleepRaisesEnergyWithoutCoinsAndWakeMeows() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.beginSleep()
        XCTAssertEqual(harness.sound.snoreStarts, 1)
        harness.clock.date = harness.clock.date.addingTimeInterval(5)
        harness.model.refreshOpenSleep()
        XCTAssertEqual(harness.model.needs.energy, 64)
        XCTAssertTrue(harness.model.isSleeping)
        harness.model.wake()
        XCTAssertFalse(harness.model.isSleeping)
        XCTAssertEqual(harness.sound.meows, 1)
        XCTAssertEqual(harness.sound.snoreStops, 1)
        XCTAssertEqual(harness.model.needs.energy, 64)
    }

    func testCompletedPuzzleImprovesMoodAndMakesCatHappy() async throws {
        let harness = try await makeRoom(mood: 22, energy: 60)
        harness.model.openPlayMenu()
        harness.model.openPuzzleMenu()
        harness.model.startPuzzle(imageIndex: 0)
        guard let initial = harness.model.puzzleRound else { return XCTFail("Missing puzzle") }
        for target in initial.pieces.indices {
            guard let pieces = harness.model.puzzleRound?.pieces, pieces[target] != target,
                  let source = pieces.firstIndex(of: target) else { continue }
            harness.model.tapPuzzlePiece(target)
            harness.model.tapPuzzlePiece(source)
        }
        XCTAssertEqual(harness.model.puzzleRound?.finished, true)
        XCTAssertEqual(harness.model.needs.mood, 34)
        XCTAssertEqual(harness.model.look, .happy)
        XCTAssertEqual(try harness.store.load()?.needs.mood, 34)
    }

    func testBackgroundSleepCatchesEnergyUpToOneHundred() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.beginSleep()
        harness.clock.date = harness.clock.date.addingTimeInterval(10 * 60)
        harness.model.sceneChanged(to: .background)
        harness.model.sceneChanged(to: .active)
        XCTAssertEqual(harness.model.needs.energy, 100)
        XCTAssertEqual(harness.model.needs.satiety, 98, accuracy: 0.000_001)
        harness.model.wake()
    }

    func testReturningToStartKeepsPetProgress() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.leaveGame()
        XCTAssertEqual(harness.model.route, .start)
        harness.clock.date = harness.clock.date.addingTimeInterval(5 * 60)
        harness.model.startGame()
        XCTAssertEqual(harness.model.route, .room)
        XCTAssertEqual(harness.model.needs.satiety, 99, accuracy: 0.000_001)
    }

    func testSleepingPetContinuesRestingOnStartScreen() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.beginSleep()
        harness.model.leaveGame()
        XCTAssertEqual(harness.sound.snoreStops, 1)
        harness.clock.date = harness.clock.date.addingTimeInterval(10 * 60)
        harness.model.startGame()
        XCTAssertTrue(harness.model.isSleeping)
        XCTAssertEqual(harness.model.needs.energy, 100)
        XCTAssertEqual(harness.sound.snoreStarts, 2)
        harness.model.wake()
    }

    func testNewPetOpensOnboardingAfterStart() async throws {
        guard let defaults else {
            XCTFail("Не удалось создать suite UserDefaults")
            return
        }
        let store = PetStore(inMemory: true)
        let model = RoomViewModel(store: store, defaults: defaults, sound: SpySound(), autoload: false)
        await model.prepare()
        XCTAssertEqual(model.route, .start)
        model.startGame()
        XCTAssertEqual(model.route, .onboarding)
    }

    func testKitchenMealPersistsImmediately() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60, satiety: 50)
        harness.model.openKitchen()
        XCTAssertEqual(harness.model.route, .kitchen)
        harness.model.addIngredient(.fish)
        harness.model.addIngredient(.rice)
        harness.model.startCooking()
        harness.model.setColdFlow(0.6)
        harness.model.setHotFlow(0.6)
        harness.model.washIngredients(distance: 120)
        harness.model.washIngredients(distance: 120)
        XCTAssertEqual(harness.sound.faucetOpens, 2)
        XCTAssertEqual(harness.sound.waterStarts, 1)
        XCTAssertEqual(harness.sound.waterStops, 1)
        harness.model.chopIngredient()
        harness.model.chopIngredient()
        harness.model.setHeat(0.55)
        harness.model.placeIngredientsInPan()
        XCTAssertEqual(harness.sound.sizzleStarts, 1)
        harness.model.stirPan(distance: 120)
        harness.model.stirPan(distance: 120)
        harness.model.stirPan(distance: 120)
        XCTAssertEqual(harness.sound.sizzleStops, 1)
        harness.model.chooseDecoration(0)
        harness.model.decorateDish()
        harness.model.serveDish()
        XCTAssertEqual(harness.model.route, .room)
        XCTAssertEqual(harness.sound.eatingSounds, 1)
        XCTAssertEqual(harness.model.kitchen.coins, 6)
        XCTAssertEqual(harness.model.kitchen.available(.fish), 1)
        XCTAssertTrue(harness.model.kitchen.discoveredRecipes.contains(.plov))
        XCTAssertEqual(harness.model.needs.satiety, 83.6, accuracy: 0.001)

        let saved = try XCTUnwrap(harness.store.load())
        XCTAssertEqual(saved.kitchen, harness.model.kitchen)
        XCTAssertEqual(saved.needs.satiety, harness.model.needs.satiety)

    }

    func testKitchenVoiceCuesMatchTemperatureAndRotateWithoutRepeatingRapidly() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openKitchen()
        harness.model.addIngredient(.fish)
        harness.model.addIngredient(.rice)
        harness.model.startCooking()

        harness.model.setColdFlow(0.6)
        harness.model.speakWashingCueIfNeeded()
        harness.model.speakWashingCueIfNeeded()
        XCTAssertEqual(harness.sound.spokenPhrases.count, 1)
        XCTAssertTrue(harness.sound.spokenPhrases[0].contains("холодная"))

        harness.clock.date = harness.clock.date.addingTimeInterval(4)
        harness.model.speakWashingCueIfNeeded()
        XCTAssertEqual(harness.sound.spokenPhrases.count, 2)
        XCTAssertNotEqual(harness.sound.spokenPhrases[0], harness.sound.spokenPhrases[1])

        harness.model.setColdFlow(0)
        harness.model.setHotFlow(0.6)
        harness.model.speakWashingCueIfNeeded()
        XCTAssertEqual(harness.sound.spokenPhrases.count, 3)
        XCTAssertTrue(harness.sound.spokenPhrases[2].contains("горячо"))

        harness.model.setColdFlow(0.6)
        harness.model.speakWashingCueIfNeeded()
        XCTAssertEqual(harness.sound.spokenPhrases.count, 3)
        harness.model.washIngredients(distance: 120)
        harness.model.washIngredients(distance: 120)
        harness.model.chopIngredient()
        harness.model.chopIngredient()
        harness.model.setHeat(0.2)
        harness.model.placeIngredientsInPan()
        harness.model.speakLowHeatCueIfNeeded()
        XCTAssertEqual(harness.sound.spokenPhrases.count, 4)
        XCTAssertTrue(harness.sound.spokenPhrases[3].contains("Плите"))
    }

    func testBurntFoodIsSpentAndSavedImmediately() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openKitchen()
        harness.model.addIngredient(.fish)
        harness.model.addIngredient(.rice)
        harness.model.startCooking()
        harness.model.setColdFlow(0.6)
        harness.model.setHotFlow(0.6)
        harness.model.washIngredients(distance: 120)
        harness.model.washIngredients(distance: 120)
        harness.model.chopIngredient()
        harness.model.chopIngredient()
        harness.model.setHeat(0.55)
        harness.model.placeIngredientsInPan()
        harness.model.setHeat(0.9)
        XCTAssertEqual(harness.model.kitchenSession.step, .burnt)
        XCTAssertEqual(harness.sound.sizzleStarts, 1)
        XCTAssertEqual(harness.sound.sizzleStops, 1)
        XCTAssertEqual(harness.model.kitchen.available(.fish), 1)
        XCTAssertEqual(harness.model.kitchen.available(.rice), 1)
        XCTAssertEqual(try harness.store.load()?.kitchen.available(.fish), 1)
        harness.model.discardDish()
        XCTAssertEqual(harness.model.kitchen.available(.fish), 1)
    }

    func testRestockPersistsWithoutChangingCoinsAndMusicContinues() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        XCTAssertGreaterThanOrEqual(harness.sound.musicStarts, 1)
        harness.model.openKitchen()
        harness.model.restockIngredient(.fish)
        XCTAssertEqual(harness.model.kitchen.available(.fish), 5)
        XCTAssertEqual(harness.model.kitchen.coins, 0)
        XCTAssertEqual(try harness.store.load()?.kitchen.available(.fish), 5)
        harness.model.sceneChanged(to: .background)
        harness.model.sceneChanged(to: .active)
        XCTAssertGreaterThanOrEqual(harness.sound.musicStarts, 2)
    }

    func testBathAwardsOnlyAfterCombAndPersists() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openBath()
        for index in 0..<10 { harness.model.popBathBubble(index) }
        XCTAssertEqual(harness.sound.bubbleVariants.count, 10)
        XCTAssertEqual(Set(harness.sound.bubbleVariants).count, 4)
        XCTAssertEqual(harness.model.kitchen.coins, 0)
        harness.model.pickUpBathTool()
        for _ in 0..<5 {
            harness.model.soapBath(from: .init(x: 0.35, y: 0.5), to: .init(x: 0.55, y: 0.5))
        }
        XCTAssertEqual(harness.model.bathSession.step, .shower)
        XCTAssertEqual(harness.sound.waterStarts, 0)
        for point in BathSession.foamPositions { harness.model.moveBathShower(to: point) }
        XCTAssertEqual(harness.model.bathSession.step, .shower)
        harness.model.pickUpBathShower()
        XCTAssertEqual(harness.sound.waterStarts, 1)
        for point in BathSession.foamPositions { harness.model.moveBathShower(to: point) }
        XCTAssertEqual(harness.sound.waterStops, 1)
        XCTAssertNil(harness.model.bathSession.heldTool)
        harness.model.rubBathTowel(from: .init(x: 0.4, y: 0.5), to: .init(x: 0.55, y: 0.5))
        XCTAssertEqual(harness.model.bathSession.towelProgress, 0)
        harness.model.pickUpBathTool()
        for _ in 0..<5 {
            harness.model.rubBathTowel(from: .init(x: 0.4, y: 0.5), to: .init(x: 0.55, y: 0.5))
        }
        XCTAssertEqual(harness.model.bathSession.step, .comb)
        XCTAssertEqual(harness.model.kitchen.coins, 0)
        harness.model.combBath(from: .init(x: 0.5, y: 0.4), to: .init(x: 0.5, y: 0.6))
        XCTAssertEqual(harness.model.bathSession.combStrokes, 0)
        harness.model.pickUpBathTool()
        for _ in 0..<5 {
            harness.model.combBath(from: .init(x: 0.5, y: 0.4), to: .init(x: 0.5, y: 0.6))
        }
        harness.model.combBath(from: .init(x: 0.5, y: 0.4), to: .init(x: 0.5, y: 0.6))
        XCTAssertEqual(harness.model.needs.cleanliness, 100)
        XCTAssertEqual(harness.model.kitchen.coins, 6)
        XCTAssertEqual(try harness.store.load()?.kitchen.coins, 6)
    }

    func testGamesCanRestartWithoutPause() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        for _ in 0..<5 {
            harness.model.openPlayMenu()
            harness.model.startFishRound()
            harness.model.closeActivity()
        }
        harness.model.openPlayMenu()
        harness.model.startCloudRound()
        XCTAssertEqual(harness.model.route, .clouds)
        if let target = harness.model.cloudRound?.targetCloud {
            harness.model.tapCloud(target)
        }
        XCTAssertTrue(harness.sound.gameCues.contains(.jump))
        XCTAssertTrue(harness.sound.spokenPhrases.isEmpty)
    }

    func testFishQuestAdvancesAndPersistsAfterSuccess() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openPlayMenu()
        harness.model.startFishRound()
        for index in 0..<5 { harness.model.catchFish(index) }
        XCTAssertTrue(harness.model.fishRound?.won == true)
        XCTAssertEqual(harness.model.playProgress.fishLevel, 2)
        XCTAssertEqual(try harness.store.load()?.playProgress.fishLevel, 2)
        harness.model.startFishRound()
        XCTAssertEqual(harness.model.fishRound?.questRule, .only(.blue))
    }

    func testToyTargetVictoryAwardsOnceAndHockeyOpens() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openPlayMenu()
        harness.model.startToyTargets()
        XCTAssertEqual(harness.model.route, .toyTargets)
        for shot in 1...8 {
            harness.clock.date.addTimeInterval(0.7)
            let point = harness.model.toyTargetRound!.position(0, at: harness.clock.now())
            XCTAssertTrue(harness.model.shootToyTarget(at: point))
        }
        XCTAssertEqual(harness.model.toyTargetRound?.outcome, .win)
        XCTAssertEqual(harness.model.kitchen.coins, 5)
        _ = harness.model.shootToyTarget(at: .init(x: 0.5, y: 0.5))
        XCTAssertEqual(harness.model.kitchen.coins, 5)
        harness.model.closeActivity()
        harness.model.openPlayMenu()
        harness.model.startAirHockey()
        XCTAssertEqual(harness.model.route, .airHockey)
    }

    func testHockeyTouchIsAppliedOnTick() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openPlayMenu()
        harness.model.startAirHockey()
        harness.model.moveHockeyPaddle(to: 0.8)
        XCTAssertEqual(harness.model.hockeyRound?.childX, 0.5)
        harness.clock.date.addTimeInterval(0.025)
        harness.model.tickAirHockey()
        XCTAssertEqual(harness.model.hockeyRound?.childX, 0.8)
    }

    func testParentGateRequiresCorrectAnswerAndSavesPreferences() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openShop()
        harness.model.openParentGate()
        XCTAssertEqual(harness.model.route, .parentGate)
        harness.model.unlockParentSettings(answer: 12)
        XCTAssertEqual(harness.model.route, .parentGate)
        harness.model.completeParentHold()
        harness.model.unlockParentSettings(answer: 10)
        XCTAssertEqual(harness.model.route, .parentGate)
        harness.model.completeParentHold()
        harness.model.unlockParentSettings(answer: 12)
        XCTAssertEqual(harness.model.route, .parentSettings)
        harness.model.saveParentName("Пушок")
        harness.model.setParentAge(.toddler)
        harness.model.updateParentOptions { $0.effectsEnabled = false }
        XCTAssertEqual(harness.model.petName, "Пушок")
        XCTAssertEqual(harness.model.ageMode, .toddler)
        XCTAssertFalse(harness.sound.effectsEnabled)
        guard let defaults else { XCTFail(); return }
        XCTAssertFalse(ParentOptions.load(from: defaults).effectsEnabled)
    }

    func testToiletRewardsOnlyAfterFlushing() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60, toilet: 80)
        harness.model.openToilet()
        XCTAssertEqual(harness.model.route, .toilet)
        for point in ToiletSession.clumpPositions { harness.model.movePaper(to: point) }
        for point in ToiletSession.pawPositions { harness.model.moveSponge(to: point) }
        XCTAssertEqual(harness.model.toiletSession.step, .flush)
        XCTAssertEqual(harness.model.kitchen.coins, 0)
        harness.model.flushToilet()
        XCTAssertEqual(harness.model.toiletSession.step, .finished)
        XCTAssertEqual(harness.model.needs.toilet, 0)
        XCTAssertEqual(harness.model.kitchen.coins, 6)
        XCTAssertTrue(harness.sound.gameCues.contains(.flush))
    }

    func testMemoryVictoryUnlocksAndPersistsNextLevel() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        harness.model.openPlayMenu()
        harness.model.startMemoryRound()
        guard let symbols = harness.model.memoryRound?.symbols else { XCTFail(); return }
        for symbol in Set(symbols) {
            let pair = symbols.indices.filter { symbols[$0] == symbol }
            harness.model.flipMemoryCard(pair[0])
            harness.model.flipMemoryCard(pair[1])
        }
        XCTAssertEqual(harness.model.memoryRound?.outcome, .child)
        XCTAssertEqual(harness.model.playProgress.memoryLevel, 2)
        XCTAssertEqual(try harness.store.load()?.playProgress.memoryLevel, 2)
    }

    private func makeRoom(mood: Double, energy: Double, satiety: Double = 100, toilet: Double = 0) async throws -> (model: RoomViewModel, sound: SpySound, clock: ManualClock, store: PetStore) {
        guard let defaults else {
            XCTFail("Не удалось создать suite UserDefaults")
            throw PetStoreError.loadFailed
        }
        let origin = Date(timeIntervalSince1970: 1_700_000_000)
        let store = PetStore(inMemory: true)
        try await store.loadStores()
        var needs = PetNeeds.newcomer(at: origin)
        needs.mood = mood
        needs.energy = energy
        needs.satiety = satiety
        needs.toilet = toilet
        try store.save(StoredPet(needs: needs, isSleeping: false))
        PetSettings.setFinishedOnboarding(true, in: defaults)
        PetSettings.saveAgeMode(.older, to: defaults)
        let clock = ManualClock(origin)
        let sound = SpySound()
        let model = RoomViewModel(
            store: store,
            defaults: defaults,
            sound: sound,
            clock: { clock.now() },
            autoload: false
        )
        await model.prepare()
        XCTAssertEqual(model.route, .start)
        model.startGame()
        return (model, sound, clock, store)
    }
}
