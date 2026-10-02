import Foundation

struct PettingOutcome: Equatable, Sendable {
    var needs: PetNeeds
    var lastPetAt: Date?
    var didApply: Bool
}

enum Petting {
    static let moodGain = 4.0
    static let cooldown: TimeInterval = 0.5

    static func applying(_ needs: PetNeeds, at now: Date, lastPetAt: Date?) -> PettingOutcome {
        if let lastPetAt, now.timeIntervalSince(lastPetAt) < cooldown {
            return PettingOutcome(needs: needs, lastPetAt: lastPetAt, didApply: false)
        }
        var updated = needs
        updated.mood = min(100, max(0, needs.mood + moodGain))
        return PettingOutcome(needs: updated, lastPetAt: now, didApply: true)
    }
}
