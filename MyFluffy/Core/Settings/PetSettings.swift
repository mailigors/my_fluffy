import Foundation

enum PetSettings {
    static let nameKey = "petName"
    static let ageModeKey = "ageMode"
    static let onboardingKey = "didFinishOnboarding"
    static let defaultName = "Мурзик"

    static func loadName(from defaults: UserDefaults) -> String {
        let stored = defaults.string(forKey: nameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let stored, stored.isEmpty == false {
            return stored
        }
        return defaultName
    }

    static func saveName(_ raw: String, to defaults: UserDefaults) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmed.isEmpty ? defaultName : trimmed, forKey: nameKey)
    }

    static func loadAgeMode(from defaults: UserDefaults) -> AgeMode {
        guard let raw = defaults.string(forKey: ageModeKey), let mode = AgeMode(rawValue: raw) else {
            return .older
        }
        return mode
    }

    static func saveAgeMode(_ mode: AgeMode, to defaults: UserDefaults) {
        defaults.set(mode.rawValue, forKey: ageModeKey)
    }

    static func didFinishOnboarding(in defaults: UserDefaults) -> Bool {
        defaults.bool(forKey: onboardingKey)
    }

    static func setFinishedOnboarding(_ finished: Bool, in defaults: UserDefaults) {
        defaults.set(finished, forKey: onboardingKey)
    }
}
