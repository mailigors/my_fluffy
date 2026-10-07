import XCTest
@testable import MyFluffy

final class ParentOptionsTests: XCTestCase {
    func testOptionsPersistInIsolatedDefaults() throws {
        let suite = "ParentOptionsTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { XCTFail(); return }
        defer { defaults.removePersistentDomain(forName: suite) }
        var options = ParentOptions()
        options.effectsEnabled = false
        options.musicVolume = 0.3
        options.effectsVolume = 0.6
        options.voiceVolume = 0.8
        options.quietHoursEnabled = true
        options.quietStart = 19
        options.allowedRewards.remove(.doubleCoins)
        options.save(to: defaults)
        XCTAssertEqual(ParentOptions.load(from: defaults), options)
    }
}
