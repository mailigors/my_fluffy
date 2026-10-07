import Foundation

enum ArcadeOutcome: Equatable, Sendable { case child, cat, draw }

struct AirHockeyRound: Equatable, Sendable {
    let startedAt: Date
    private(set) var puck = GamePoint(x: 0.5, y: 0.5)
    private(set) var childX = 0.5
    private(set) var catX = 0.5
    private(set) var childScore = 0
    private(set) var catScore = 0
    private(set) var outcome: ArcadeOutcome?
    private(set) var collisionCount = 0
    private(set) var goalCount = 0
    private var velocity = GamePoint(x: 0.19, y: 0.42)
    private var lastTick: Date
    private var serveAt: Date?
    private let catSpeed: Double
    private var catMissesThisPass = false
    private var catWillMiss = false
    private var random: GameRandom

    init(now: Date, mode: AgeMode, seed: UInt64? = nil) {
        startedAt = now
        lastTick = now
        catSpeed = mode == .toddler ? 0.24 : 0.38
        random = GameRandom(seed: seed ?? UInt64(now.timeIntervalSince1970 * 1_000))
    }

    var secondsRemaining: Int { max(0, Int(ceil(75 - lastTick.timeIntervalSince(startedAt)))) }
    var puckSpeed: Double { hypot(velocity.x, velocity.y) }

    mutating func moveChild(to x: Double) {
        guard outcome == nil else { return }
        childX = min(0.9, max(0.1, x))
    }

    mutating func tick(at now: Date) {
        guard outcome == nil else { return }
        let dt = min(0.25, max(0, now.timeIntervalSince(lastTick)))
        lastTick = now
        if now.timeIntervalSince(startedAt) >= 75 {
            outcome = childScore > catScore ? .child : (catScore > childScore ? .cat : .draw)
            return
        }
        if let serveAt {
            guard now >= serveAt else { return }
            self.serveAt = nil
        }
        let steps = max(1, Int(ceil(dt / 0.02)))
        for index in 0..<steps {
            advance(by: dt / Double(steps), at: now.addingTimeInterval(-dt + Double(index + 1) * dt / Double(steps)))
            if outcome != nil || serveAt != nil { break }
        }
    }

    private mutating func advance(by dt: Double, at now: Date) {
        let catTarget = puck.x + (catSpeed < 0.3 ? 0.17 : 0.11) * sin(now.timeIntervalSince(startedAt) * 1.3)
        let chase = min(catSpeed * dt, abs(catTarget - catX))
        catX += catTarget > catX ? chase : -chase
        catX = min(0.9, max(0.1, catX))
        puck = GamePoint(x: puck.x + velocity.x * dt, y: puck.y + velocity.y * dt)
        if puck.x <= 0.055 || puck.x >= 0.945 {
            puck = GamePoint(x: min(0.945, max(0.055, puck.x)), y: puck.y)
            velocity = GamePoint(x: -velocity.x, y: velocity.y)
            collisionCount += 1
        }
        if velocity.y > 0, puck.y >= 0.77, puck.y <= 0.87, abs(puck.x - childX) <= 0.13 {
            bounce(from: childX, towardChild: false)
        } else if velocity.y < 0, puck.y <= 0.23, puck.y >= 0.13, abs(puck.x - catX) <= 0.12, !catMissesThisPass {
            if catWillMiss { catMissesThisPass = true }
            else { bounce(from: catX, towardChild: true) }
        }
        if puck.y <= 0.04 {
            if (0.28...0.72).contains(puck.x) { score(forChild: true, at: now) }
            else { puck = GamePoint(x: puck.x, y: 0.04); velocity = GamePoint(x: velocity.x, y: abs(velocity.y)); collisionCount += 1 }
        } else if puck.y >= 0.96 {
            if (0.28...0.72).contains(puck.x) { score(forChild: false, at: now) }
            else { puck = GamePoint(x: puck.x, y: 0.96); velocity = GamePoint(x: velocity.x, y: -abs(velocity.y)); chooseCatMiss(); collisionCount += 1 }
        }
    }

    private mutating func bounce(from paddleX: Double, towardChild: Bool) {
        let offset = (puck.x - paddleX) / 0.13
        let speed = min(1.15, max(0.52, puckSpeed * 1.08))
        var horizontal = max(-speed * 0.7, min(speed * 0.7, velocity.x * 0.55 + offset * 0.28))
        if abs(horizontal) < 0.08 { horizontal = velocity.x < 0 ? -0.08 : 0.08 }
        let vertical = sqrt(speed * speed - horizontal * horizontal)
        velocity = GamePoint(x: horizontal, y: towardChild ? vertical : -vertical)
        puck = GamePoint(x: puck.x, y: towardChild ? 0.24 : 0.76)
        if !towardChild { chooseCatMiss() }
        collisionCount += 1
    }

    private mutating func chooseCatMiss() {
        catMissesThisPass = false
        catWillMiss = random.next(100) < (catSpeed < 0.3 ? 27 : 15)
    }

    private mutating func score(forChild: Bool, at now: Date) {
        if forChild { childScore += 1 } else { catScore += 1 }
        goalCount += 1
        if childScore >= 3 { outcome = .child }
        else if catScore >= 3 { outcome = .cat }
        else {
            puck = GamePoint(x: 0.5, y: 0.5)
            velocity = GamePoint(x: forChild ? -0.17 : 0.17, y: forChild ? 0.43 : -0.43)
            catMissesThisPass = false
            catWillMiss = false
            serveAt = now.addingTimeInterval(0.7)
        }
    }
}

enum ToyTargetOutcome: Equatable, Sendable { case win, lose }

struct ToyTargetRound: Equatable, Sendable {
    let startedAt: Date
    let mode: AgeMode
    private(set) var hits = 0
    private(set) var shots = 0
    private(set) var outcome: ToyTargetOutcome?
    private var hiddenUntil: [Date?] = Array(repeating: nil, count: 3)

    init(now: Date, mode: AgeMode) {
        startedAt = now
        self.mode = mode
    }

    var targetHits: Int { mode == .toddler ? 6 : 8 }
    var maxShots: Int { mode == .toddler ? 14 : 13 }

    func secondsRemaining(at now: Date) -> Int {
        max(0, Int(ceil(55 - now.timeIntervalSince(startedAt))))
    }

    func isVisible(_ index: Int, at now: Date) -> Bool {
        (0..<3).contains(index) && hiddenUntil[index].map({ now >= $0 }) != false
    }

    func position(_ index: Int, at now: Date) -> GamePoint {
        let time = now.timeIntervalSince(startedAt)
        let speed = mode == .toddler ? 0.75 : 1.15
        let phase = Double(index) * 2.1
        return GamePoint(x: 0.5 + 0.32 * sin(time * speed + phase),
                         y: 0.48 + 0.14 * sin(time * speed * 0.57 + phase * 1.3))
    }

    mutating func shoot(at point: GamePoint, now: Date) -> Bool {
        guard outcome == nil else { return false }
        if secondsRemaining(at: now) == 0 { outcome = .lose; return false }
        shots += 1
        let radius = mode == .toddler ? 0.12 : 0.09
        let hit = (0..<3).first { isVisible($0, at: now) && point.distance(to: position($0, at: now)) <= radius }
        if let hit {
            hits += 1
            hiddenUntil[hit] = now.addingTimeInterval(0.55)
            if hits >= targetHits { outcome = .win }
        }
        if outcome == nil && shots >= maxShots { outcome = .lose }
        return hit != nil
    }

    mutating func tick(at now: Date) {
        if outcome == nil && secondsRemaining(at: now) == 0 { outcome = .lose }
    }
}
