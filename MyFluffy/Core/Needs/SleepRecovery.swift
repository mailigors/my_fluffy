import Foundation

struct SleepTick: Equatable, Sendable {
    var energy: Double
    var anchor: Date
}

/// Сон на открытой сцене и догон энергии в фоне. Монет за сон нет.
enum SleepRecovery {
    static let energyPerStep = 4.0
    static let step: TimeInterval = 5
    static let backgroundDuration: TimeInterval = 10 * 60

    /// +4 за каждые полные 5 секунд. Остаток секунд остаётся на якоре.
    static func ticking(energy: Double, since anchor: Date, until now: Date) -> SleepTick {
        let elapsed = now.timeIntervalSince(anchor)
        guard elapsed > 0 else {
            return SleepTick(energy: clamp(energy), anchor: anchor)
        }
        let steps = floor(elapsed / step)
        let gained = steps * energyPerStep
        return SleepTick(
            energy: clamp(energy + gained),
            anchor: anchor.addingTimeInterval(steps * step)
        )
    }

    /// Линейно до 100 за не более чем 10 минут. Дольше 10 минут всё равно 100.
    static func catchingUp(energy: Double, elapsed: TimeInterval) -> Double {
        let span = min(max(elapsed, 0), backgroundDuration)
        let progress = span / backgroundDuration
        return clamp(energy + (100 - energy) * progress)
    }

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}
