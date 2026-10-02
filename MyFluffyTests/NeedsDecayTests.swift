import XCTest
@testable import MyFluffy

final class NeedsDecayTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_700_000_000)

    func testOlderSatietyLosesOnePointPerFiveMinutes() {
        let result = NeedsDecay.applying(needs(satiety: 80), at: origin.addingTimeInterval(5 * 60), mode: .older)
        assertClose(result.satiety, 79)
    }

    func testOlderCleanlinessLosesOnePointPerSixMinutes() {
        let result = NeedsDecay.applying(needs(cleanliness: 80), at: origin.addingTimeInterval(6 * 60), mode: .older)
        assertClose(result.cleanliness, 79)
    }

    func testOlderMoodLosesOnePointPerSevenMinutes() {
        let result = NeedsDecay.applying(needs(mood: 80), at: origin.addingTimeInterval(7 * 60), mode: .older)
        assertClose(result.mood, 79)
    }

    func testOlderEnergyLosesOnePointPerTenMinutes() {
        let result = NeedsDecay.applying(needs(energy: 80), at: origin.addingTimeInterval(10 * 60), mode: .older)
        assertClose(result.energy, 79)
    }

    func testToiletFillsOnePointPerTwoMinutes() {
        let result = NeedsDecay.applying(needs(toilet: 10), at: origin.addingTimeInterval(2 * 60), mode: .older)
        assertClose(result.toilet, 11)
    }

    func testDecayUsesFractionalMinutes() {
        let result = NeedsDecay.applying(needs(satiety: 40), at: origin.addingTimeInterval(150), mode: .older)
        assertClose(result.satiety, 39.5)
    }

    func testToddlerSlowsOnlyFallingNeeds() {
        let result = NeedsDecay.applying(
            needs(satiety: 50, cleanliness: 50, mood: 50, energy: 50, toilet: 10),
            at: origin.addingTimeInterval(5 * 60),
            mode: .toddler
        )
        assertClose(result.satiety, 49.4)
        assertClose(result.cleanliness, 49.5)
        assertClose(result.mood, 50 - (5.0 / 7.0) * 0.6)
        assertClose(result.energy, 49.7)
        assertClose(result.toilet, 12.5)
    }

    func testEightHoursAppliesFully() {
        let result = NeedsDecay.applying(
            needs(satiety: 100, energy: 100),
            at: origin.addingTimeInterval(8 * 60 * 60),
            mode: .older
        )
        assertClose(result.satiety, 4)
        assertClose(result.energy, 52)
        XCTAssertEqual(result.lastCalculated, origin.addingTimeInterval(8 * 60 * 60))
    }

    func testTimeBeyondEightHoursIsDiscarded() {
        let later = origin.addingTimeInterval(10 * 60 * 60)
        let result = NeedsDecay.applying(needs(satiety: 100, energy: 100), at: later, mode: .older)
        assertClose(result.satiety, 4)
        assertClose(result.energy, 52)
        XCTAssertEqual(result.lastCalculated, later)
    }

    func testValuesClampToScale() {
        let result = NeedsDecay.applying(
            needs(satiety: 0.4, toilet: 99.2),
            at: origin.addingTimeInterval(5 * 60),
            mode: .older
        )
        assertClose(result.satiety, 0)
        assertClose(result.toilet, 100)
    }

    func testNoElapsedTimeKeepsNeeds() {
        let start = needs(satiety: 80, toilet: 15)
        let result = NeedsDecay.applying(start, at: origin, mode: .older)
        XCTAssertEqual(result, start)
    }

    func testClockMovingBackwardsDoesNotChangeScales() {
        let earlier = origin.addingTimeInterval(-60 * 60)
        let result = NeedsDecay.applying(needs(satiety: 40, toilet: 12), at: earlier, mode: .older)
        assertClose(result.satiety, 40)
        assertClose(result.toilet, 12)
        XCTAssertEqual(result.lastCalculated, earlier)
    }

    func testRedZoneBoundaries() {
        let calm = needs(satiety: 30, cleanliness: 30, mood: 30, energy: 25, toilet: 70)
        XCTAssertFalse(calm.isInRedZone(.satiety))
        XCTAssertFalse(calm.isInRedZone(.cleanliness))
        XCTAssertFalse(calm.isInRedZone(.mood))
        XCTAssertFalse(calm.isInRedZone(.energy))
        XCTAssertFalse(calm.isInRedZone(.toilet))

        let alert = needs(satiety: 29, cleanliness: 29, mood: 29, energy: 24, toilet: 71)
        XCTAssertTrue(alert.isInRedZone(.satiety))
        XCTAssertTrue(alert.isInRedZone(.cleanliness))
        XCTAssertTrue(alert.isInRedZone(.mood))
        XCTAssertTrue(alert.isInRedZone(.energy))
        XCTAssertTrue(alert.isInRedZone(.toilet))
    }

    private func needs(
        satiety: Double = 50,
        cleanliness: Double = 50,
        mood: Double = 50,
        energy: Double = 50,
        toilet: Double = 10,
        at date: Date? = nil
    ) -> PetNeeds {
        PetNeeds(
            satiety: satiety,
            cleanliness: cleanliness,
            mood: mood,
            energy: energy,
            toilet: toilet,
            lastCalculated: date ?? origin
        )
    }

    private func assertClose(
        _ actual: Double,
        _ expected: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(actual, expected, accuracy: 0.000_001, file: file, line: line)
    }
}
