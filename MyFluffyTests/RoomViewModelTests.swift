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
    private(set) var waterStarts = 0
    private(set) var waterStops = 0
    private(set) var sizzleStarts = 0
    private(set) var sizzleStops = 0
    private(set) var musicStarts = 0
    private(set) var musicStops = 0
    private(set) var musicQuiet = false
    func prepareSession() {}
    func playMeow() { meows += 1 }
    func playHappyMeow() { happyMeows += 1 }
    func playEating() { eatingSounds += 1 }
    func startPurr() { purrStarts += 1 }
    func stopPurr() { purrStops += 1 }
    func startSnore() { snoreStarts += 1 }
    func stopSnore() { snoreStops += 1 }
    func playFaucetOpen() { faucetOpens += 1 }
    func startWater() { waterStarts += 1 }
    func stopWater() { waterStops += 1 }
    func startSizzle() { sizzleStarts += 1 }
    func stopSizzle() { sizzleStops += 1 }
    func startMusic() { musicStarts += 1 }
    func stopMusic() { musicStops += 1 }
    func setMusicQuiet(_ quiet: Bool) { musicQuiet = quiet }
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

    func testRestockPersistsWithoutChangingCoinsAndMusicFollowsScene() async throws {
        let harness = try await makeRoom(mood: 80, energy: 60)
        XCTAssertEqual(harness.sound.musicStarts, 1)
        harness.model.openKitchen()
        harness.model.restockIngredient(.fish)
        XCTAssertEqual(harness.model.kitchen.available(.fish), 5)
        XCTAssertEqual(harness.model.kitchen.coins, 0)
        XCTAssertEqual(try harness.store.load()?.kitchen.available(.fish), 5)
        harness.model.sceneChanged(to: .background)
        XCTAssertEqual(harness.sound.musicStops, 1)
        harness.model.sceneChanged(to: .active)
        XCTAssertEqual(harness.sound.musicStarts, 2)
    }

    private func makeRoom(mood: Double, energy: Double, satiety: Double = 100) async throws -> (model: RoomViewModel, sound: SpySound, clock: ManualClock, store: PetStore) {
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
