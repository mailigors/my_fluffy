import XCTest
@testable import MyFluffy

final class PetCareTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    func testPettingAddsFourMood() {
        let needs = PetNeeds.newcomer(at: origin)
        let outcome = Petting.applying(needs, at: origin, lastPetAt: nil)
        XCTAssertTrue(outcome.didApply)
        XCTAssertEqual(outcome.needs.mood, 100)
        XCTAssertEqual(outcome.lastPetAt, origin)
    }

    func testPettingRaisesMoodFromALowerValue() {
        var needs = PetNeeds.newcomer(at: origin)
        needs.mood = 40
        let outcome = Petting.applying(needs, at: origin, lastPetAt: nil)
        XCTAssertEqual(outcome.needs.mood, 44)
    }

    func testPettingClampsMoodAtOneHundred() {
        var needs = PetNeeds.newcomer(at: origin)
        needs.mood = 98
        let outcome = Petting.applying(needs, at: origin, lastPetAt: nil)
        XCTAssertEqual(outcome.needs.mood, 100)
    }

    func testPettingCooldownBlocksARepeat() {
        let needs = PetNeeds.newcomer(at: origin)
        let first = Petting.applying(needs, at: origin, lastPetAt: nil)
        let second = Petting.applying(first.needs, at: origin.addingTimeInterval(0.49), lastPetAt: first.lastPetAt)
        XCTAssertFalse(second.didApply)
        XCTAssertEqual(second.needs.mood, first.needs.mood)
        XCTAssertEqual(second.lastPetAt, origin)
    }

    func testPettingAppliesAgainAfterCooldown() {
        var needs = PetNeeds.newcomer(at: origin)
        needs.mood = 40
        let first = Petting.applying(needs, at: origin, lastPetAt: nil)
        let second = Petting.applying(first.needs, at: origin.addingTimeInterval(0.5), lastPetAt: first.lastPetAt)
        XCTAssertTrue(second.didApply)
        XCTAssertEqual(second.needs.mood, 48)
    }

    func testOpenSleepAddsFourEnergyPerFiveSeconds() {
        let tick = SleepRecovery.ticking(energy: 60, since: origin, until: origin.addingTimeInterval(5))
        XCTAssertEqual(tick.energy, 64)
        XCTAssertEqual(tick.anchor, origin.addingTimeInterval(5))
    }

    func testOpenSleepIgnoresAnIncompleteStep() {
        let tick = SleepRecovery.ticking(energy: 60, since: origin, until: origin.addingTimeInterval(4.9))
        XCTAssertEqual(tick.energy, 60)
        XCTAssertEqual(tick.anchor, origin)
    }

    func testOpenSleepCountsOnlyFullSteps() {
        let tick = SleepRecovery.ticking(energy: 60, since: origin, until: origin.addingTimeInterval(12))
        XCTAssertEqual(tick.energy, 68)
        XCTAssertEqual(tick.anchor, origin.addingTimeInterval(10))
    }

    func testOpenSleepDoesNotPassOneHundred() {
        let tick = SleepRecovery.ticking(energy: 98, since: origin, until: origin.addingTimeInterval(10))
        XCTAssertEqual(tick.energy, 100)
    }

    func testBackgroundSleepStaysPutAtZeroElapsed() {
        XCTAssertEqual(SleepRecovery.catchingUp(energy: 40, elapsed: 0), 40)
    }

    func testBackgroundSleepReachesOneHundredInTenMinutes() {
        XCTAssertEqual(SleepRecovery.catchingUp(energy: 0, elapsed: 10 * 60), 100)
    }

    func testBackgroundSleepStaysAtOneHundredAfterTenMinutes() {
        XCTAssertEqual(SleepRecovery.catchingUp(energy: 40, elapsed: 20 * 60), 100)
    }

    func testBackgroundSleepIsHalfwayAtFiveMinutes() {
        XCTAssertEqual(SleepRecovery.catchingUp(energy: 0, elapsed: 5 * 60), 50)
    }

    func testSleepingReturnDoesNotDecayEnergy() {
        var needs = PetNeeds.newcomer(at: origin)
        needs.energy = 40
        let later = origin.addingTimeInterval(10 * 60)
        let asleep = PetTime.applyingReturn(needs, isSleeping: true, at: later, mode: .older)
        let awake = PetTime.applyingReturn(needs, isSleeping: false, at: later, mode: .older)
        XCTAssertEqual(asleep.energy, 100)
        XCTAssertEqual(awake.energy, 39, accuracy: 0.000_001)
        XCTAssertEqual(asleep.satiety, 98, accuracy: 0.000_001)
        XCTAssertEqual(asleep.lastCalculated, later)
    }

    func testScalesShowOnlyBelowSeventy() {
        XCTAssertTrue(CareAccess.showsScale(.satiety, value: 69.9))
        XCTAssertFalse(CareAccess.showsScale(.energy, value: 70))
        XCTAssertFalse(CareAccess.showsScale(.toilet, value: 80))
        XCTAssertTrue(CareAccess.showsScale(.toilet, value: 69))
    }

    func testToiletIconBlinksOnlyAboveSeventy() {
        XCTAssertFalse(CareAccess.blinksToiletIcon(70))
        XCTAssertTrue(CareAccess.blinksToiletIcon(70.1))
    }

    func testPettingRemainsAvailableInRedZone() {
        let calm = PetNeeds.newcomer(at: origin)
        XCTAssertEqual(CareAccess.allowedActions(for: calm), [.petting, .sleep])

        var hungry = calm
        hungry.satiety = 10
        XCTAssertEqual(CareAccess.allowedActions(for: hungry), [.petting])

        var tired = calm
        tired.energy = 10
        XCTAssertEqual(CareAccess.allowedActions(for: tired), [.petting, .sleep])

        var sadAndTired = tired
        sadAndTired.mood = 10
        XCTAssertEqual(CareAccess.allowedActions(for: sadAndTired), [.petting, .sleep])
    }

    func testLookFollowsSleepThenTheFirstRedNeed() {
        let calm = PetNeeds.newcomer(at: origin)
        XCTAssertEqual(PetAppearance.look(needs: calm, isSleeping: true, pettedRecently: true), .sleeping)
        XCTAssertEqual(PetAppearance.look(needs: calm, isSleeping: false, pettedRecently: true), .happy)
        XCTAssertEqual(PetAppearance.look(needs: calm, isSleeping: false, pettedRecently: false), .idle)

        var hungry = calm
        hungry.satiety = 10
        hungry.mood = 10
        XCTAssertEqual(PetAppearance.look(needs: hungry, isSleeping: false, pettedRecently: true), .happy)
        XCTAssertEqual(PetAppearance.look(needs: hungry, isSleeping: false, pettedRecently: false), .hungry)
    }
}
