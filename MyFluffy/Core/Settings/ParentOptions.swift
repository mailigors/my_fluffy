import Foundation

enum RewardOption: String, Codable, CaseIterable, Sendable {
    case quickCooking = "R1"
    case extraIngredient = "R2"
    case secondChance = "R4"
    case doubleCoins = "R6"

    var title: String {
        switch self {
        case .quickCooking: "Быстрая готовка"
        case .extraIngredient: "Дополнительный продукт"
        case .secondChance: "Второй шанс в игре"
        case .doubleCoins: "Двойные монеты"
        }
    }
}

struct ParentOptions: Codable, Equatable, Sendable {
    var effectsEnabled = true
    var effectsVolume = 1.0
    var musicVolume = 1.0
    var voiceVolume = 1.0
    var quietHoursEnabled = false
    var quietStart = 20
    var quietEnd = 8
    var allowedRewards = Set(RewardOption.allCases)

    static let storageKey = "parentOptions"

    static func load(from defaults: UserDefaults) -> ParentOptions {
        guard let data = defaults.data(forKey: storageKey),
              let options = try? JSONDecoder().decode(ParentOptions.self, from: data) else { return ParentOptions() }
        return options
    }

    func save(to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
