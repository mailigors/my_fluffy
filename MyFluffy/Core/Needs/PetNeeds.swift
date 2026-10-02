import Foundation

enum AgeMode: String, Sendable, Equatable {
    /// 3–4 года. Скорость падения шкал ×0,6.
    case toddler
    /// 6–7 лет. Скорости из таблицы потребностей.
    case older
}

enum Need: String, Sendable, CaseIterable {
    case satiety
    case cleanliness
    case mood
    case energy
    case toilet

    /// Секунд на один пункт в режиме «большой».
    var secondsPerPoint: TimeInterval {
        switch self {
        case .satiety:
            return 5 * 60
        case .cleanliness:
            return 6 * 60
        case .mood:
            return 7 * 60
        case .energy:
            return 10 * 60
        case .toilet:
            return 2 * 60
        }
    }

    func isInRedZone(_ value: Double) -> Bool {
        switch self {
        case .satiety, .cleanliness, .mood:
            return value < 30
        case .energy:
            return value < 25
        case .toilet:
            return value > 70
        }
    }
}

struct PetNeeds: Equatable, Sendable {
    var satiety: Double
    var cleanliness: Double
    var mood: Double
    var energy: Double
    var toilet: Double
    var lastCalculated: Date

    func value(_ need: Need) -> Double {
        switch need {
        case .satiety:
            return satiety
        case .cleanliness:
            return cleanliness
        case .mood:
            return mood
        case .energy:
            return energy
        case .toilet:
            return toilet
        }
    }

    func isInRedZone(_ need: Need) -> Bool {
        need.isInRedZone(value(need))
    }

    /// Энергия ниже 70, чтобы рост во сне был виден сразу.
    static func newcomer(at date: Date) -> PetNeeds {
        PetNeeds(
            satiety: 100,
            cleanliness: 100,
            mood: 100,
            energy: 60,
            toilet: 0,
            lastCalculated: date
        )
    }
}
