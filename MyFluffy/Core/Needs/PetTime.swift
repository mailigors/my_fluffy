import Foundation

/// Возврат в игру: обычный decay, а во сне энергия догоняет вместо падения.
enum PetTime {
    static func applyingReturn(
        _ needs: PetNeeds,
        isSleeping: Bool,
        at now: Date,
        mode: AgeMode
    ) -> PetNeeds {
        let energyBefore = needs.energy
        var next = NeedsDecay.applying(needs, at: now, mode: mode)
        if isSleeping {
            let elapsed = now.timeIntervalSince(needs.lastCalculated)
            next.energy = SleepRecovery.catchingUp(energy: energyBefore, elapsed: elapsed)
        }
        return next
    }
}
