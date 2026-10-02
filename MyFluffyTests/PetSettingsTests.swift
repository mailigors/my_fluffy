import XCTest
@testable import MyFluffy

final class PetSettingsTests: XCTestCase {
    private let suiteName = "PetSettingsTests"
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

    func testEmptyNameBecomesMurzik() {
        guard let defaults else {
            XCTFail("Не удалось создать suite UserDefaults")
            return
        }
        PetSettings.saveName("   ", to: defaults)
        XCTAssertEqual(PetSettings.loadName(from: defaults), "Мурзик")
    }

    func testNameAndAgeRoundTrip() {
        guard let defaults else {
            XCTFail("Не удалось создать suite UserDefaults")
            return
        }
        PetSettings.saveName("Барсик", to: defaults)
        PetSettings.saveAgeMode(.toddler, to: defaults)
        PetSettings.setFinishedOnboarding(true, in: defaults)
        XCTAssertEqual(PetSettings.loadName(from: defaults), "Барсик")
        XCTAssertEqual(PetSettings.loadAgeMode(from: defaults), .toddler)
        XCTAssertTrue(PetSettings.didFinishOnboarding(in: defaults))
    }
}
