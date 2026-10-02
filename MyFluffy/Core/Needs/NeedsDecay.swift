import Foundation

/// Пересчёт шкал по прошедшему времени. Числа — в `knowledge/needs-and-time.md`.
enum NeedsDecay {
    /// Дольше этого промежутка потребности не копятся: лишнее время отбрасывается.
    static let offlineCap: TimeInterval = 8 * 60 * 60
    static let toddlerFallFactor = 0.6

    static func applying(_ needs: PetNeeds, at now: Date, mode: AgeMode) -> PetNeeds {
        let elapsed = now.timeIntervalSince(needs.lastCalculated)
        let delta = min(max(elapsed, 0), offlineCap)
        let fallFactor = mode == .toddler ? toddlerFallFactor : 1

        var updated = needs
        updated.satiety = clamp(needs.satiety - drop(.satiety, over: delta, fallFactor: fallFactor))
        updated.cleanliness = clamp(needs.cleanliness - drop(.cleanliness, over: delta, fallFactor: fallFactor))
        updated.mood = clamp(needs.mood - drop(.mood, over: delta, fallFactor: fallFactor))
        updated.energy = clamp(needs.energy - drop(.energy, over: delta, fallFactor: fallFactor))
        updated.toilet = clamp(needs.toilet + delta / Need.toilet.secondsPerPoint)
        updated.lastCalculated = now
        return updated
    }

    private static func drop(_ need: Need, over delta: TimeInterval, fallFactor: Double) -> Double {
        (delta / need.secondsPerPoint) * fallFactor
    }

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}
