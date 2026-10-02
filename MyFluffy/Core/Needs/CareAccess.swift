import Foundation

enum CareAction: Equatable, Hashable, Sendable {
    case petting
    case sleep
}

enum PetLook: Equatable, Sendable {
    case idle
    case happy
    case hungry
    case dirty
    case bored
    case sleepy
    case needsToilet
    case sleeping
}

enum CareAccess {
    static let happyDuration: TimeInterval = 2

    static func showsScale(_ need: Need, value: Double) -> Bool {
        value < 70
    }

    static func blinksToiletIcon(_ toilet: Double) -> Bool {
        toilet > 70
    }

    /// Ласка доступна всегда; сон остаётся действием для усталости.
    static func allowedActions(for needs: PetNeeds) -> Set<CareAction> {
        let red = Need.allCases.filter { needs.isInRedZone($0) }
        if red.isEmpty {
            return [.petting, .sleep]
        }
        var actions: Set<CareAction> = [.petting]
        for need in red {
            switch need {
            case .mood:
                break
            case .energy:
                actions.insert(.sleep)
            case .satiety, .cleanliness, .toilet:
                break
            }
        }
        return actions
    }

    static func blinkingNeeds(for needs: PetNeeds) -> [Need] {
        Need.allCases.filter { need in
            if need == .toilet {
                return blinksToiletIcon(needs.toilet)
            }
            return needs.isInRedZone(need)
        }
    }
}

enum PetAppearance {
    static func look(needs: PetNeeds, isSleeping: Bool, pettedRecently: Bool) -> PetLook {
        if isSleeping {
            return .sleeping
        }
        if pettedRecently {
            return .happy
        }
        if needs.isInRedZone(.satiety) {
            return .hungry
        }
        if needs.isInRedZone(.cleanliness) {
            return .dirty
        }
        if needs.isInRedZone(.toilet) {
            return .needsToilet
        }
        if needs.isInRedZone(.energy) {
            return .sleepy
        }
        if needs.isInRedZone(.mood) {
            return .bored
        }
        return .idle
    }
}
