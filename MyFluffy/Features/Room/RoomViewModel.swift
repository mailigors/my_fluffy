import CoreGraphics
import Foundation
import SwiftUI

struct HeartMark: Identifiable, Equatable {
    let id = UUID()
    var point: CGPoint
    var created: Date
}

@MainActor
final class RoomViewModel: ObservableObject {
    enum Route: Equatable {
        case loading
        case start
        case onboarding
        case room
        case kitchen
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
    private var happyResetTask: Task<Void, Never>?
    private var isStroking = false
    private var isSizzling = false
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
        isSleeping = false
        nightVisible = false
        do {
            try store.save(StoredPet(needs: needs, isSleeping: false, kitchen: kitchen))
            updateLook(now: now)
            route = .room
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
        sound.stopWater()
        stopSizzle()
        kitchenSession = KitchenSession()
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
                sound.setMusicQuiet(isSleeping)
                sound.startMusic()
            }
        case .inactive, .background:
            sound.stopMusic()
        @unknown default:
            sound.stopMusic()
        }
        switch route {
        case .room, .kitchen: break
        default: return
        }
        switch phase {
        case .active:
            returnedToForeground()
            if route == .kitchen, kitchenSession.step == .washing, kitchenSession.waterOn {
                sound.startWater()
            }
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
            if isSleeping {
                energyAtSleepStart = needs.energy
                sleepAnchor = now
                nightVisible = true
            }
            try store.save(StoredPet(needs: needs, isSleeping: isSleeping, kitchen: kitchen))
        } else {
            needs = PetNeeds.newcomer(at: now)
            kitchen = .newcomer
            try store.save(StoredPet(needs: needs, isSleeping: false, kitchen: kitchen))
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
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self, !Task.isCancelled else { return }
            self.pruneHearts(now: self.clock())
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            self.updateLook(now: self.clock())
        }
    }

    private func persist() {
        do {
            try store.save(StoredPet(needs: needs, isSleeping: isSleeping, kitchen: kitchen))
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
