import Foundation

struct GamePoint: Equatable, Sendable {
    let x: Double
    let y: Double

    func distance(to other: GamePoint) -> Double {
        hypot(x - other.x, y - other.y)
    }
}

enum BathStep: Equatable, Sendable {
    case bubbles, soap, shower, towel, comb, finished
}

struct BathSession: Equatable, Sendable {
    static let bubbleCount = 10
    static let soapTarget = 5
    static let foamPositions: [GamePoint] = [
        .init(x: 0.38, y: 0.43), .init(x: 0.61, y: 0.43),
        .init(x: 0.5, y: 0.54), .init(x: 0.39, y: 0.65), .init(x: 0.62, y: 0.65)
    ]
    private(set) var step: BathStep = .bubbles
    private(set) var popped: Set<Int> = []
    private(set) var soapStrokes = 0
    private(set) var rinsed: Set<Int> = []
    private(set) var showerTaken = false
    private(set) var towelDistance = 0.0
    private(set) var combStrokes = 0
    private(set) var heldTool: BathStep?

    var towelProgress: Double { min(1, towelDistance / 0.6) }
    var foamRemaining: Int { Self.foamPositions.count - rinsed.count }

    private func onCat(_ point: GamePoint) -> Bool {
        (0.18...0.82).contains(point.x) && (0.30...0.80).contains(point.y)
    }

    mutating func popBubble(_ index: Int) {
        guard step == .bubbles, (0..<Self.bubbleCount).contains(index) else { return }
        popped.insert(index)
        if popped.count == Self.bubbleCount { step = .soap }
    }

    mutating func soapStroke(from start: GamePoint, to end: GamePoint) {
        guard step == .soap, heldTool == .soap, onCat(start), onCat(end), start.distance(to: end) >= 0.08 else { return }
        soapStrokes += 1
        if soapStrokes >= Self.soapTarget { step = .shower; heldTool = nil }
    }

    mutating func moveShower(to point: GamePoint) {
        guard step == .shower, showerTaken, onCat(point) else { return }
        for (index, foam) in Self.foamPositions.enumerated() where point.distance(to: foam) <= 0.13 {
            rinsed.insert(index)
        }
        if foamRemaining == 0 {
            step = .towel
            heldTool = nil
        }
    }

    mutating func pickUpShower() {
        guard step == .shower else { return }
        showerTaken = true
        heldTool = .shower
    }

    mutating func pickUpTool() {
        guard step == .soap || step == .towel || step == .comb else { return }
        heldTool = step
    }

    mutating func rubTowel(from start: GamePoint, to end: GamePoint) {
        guard step == .towel, heldTool == .towel, onCat(start) || onCat(end) else { return }
        let movement = start.distance(to: end)
        guard movement > 0 else { return }
        towelDistance += min(0.2, movement)
        if towelDistance >= 0.6 - 0.000001 { step = .comb; heldTool = nil }
    }

    mutating func combStroke(from start: GamePoint, to end: GamePoint) {
        guard step == .comb, heldTool == .comb, onCat(start), onCat(end), end.y - start.y >= 0.09 else { return }
        combStrokes += 1
        if combStrokes >= 5 { step = .finished }
    }
}

enum ToiletStep: Equatable, Sendable {
    case paper, wipe, flush, finished
}

struct ToiletSession: Equatable, Sendable {
    static let clumpPositions = [
        GamePoint(x: 0.25, y: 0.68), GamePoint(x: 0.43, y: 0.74),
        GamePoint(x: 0.62, y: 0.65), GamePoint(x: 0.76, y: 0.77)
    ]
    static let pawPositions = [
        GamePoint(x: 0.2, y: 0.62), GamePoint(x: 0.39, y: 0.72),
        GamePoint(x: 0.6, y: 0.64), GamePoint(x: 0.79, y: 0.73)
    ]
    private(set) var step: ToiletStep = .paper
    private(set) var collected: Set<Int> = []
    private(set) var wiped: Set<Int> = []

    mutating func movePaper(to point: GamePoint) {
        guard step == .paper else { return }
        for (index, position) in Self.clumpPositions.enumerated() where point.distance(to: position) <= 0.15 {
            collected.insert(index)
        }
        if collected.count == Self.clumpPositions.count { step = .wipe }
    }

    mutating func moveSponge(to point: GamePoint) {
        guard step == .wipe else { return }
        for (index, position) in Self.pawPositions.enumerated() where point.distance(to: position) <= 0.12 {
            wiped.insert(index)
        }
        if wiped.count == Self.pawPositions.count { step = .flush }
    }

    mutating func flush() {
        guard step == .flush else { return }
        step = .finished
    }
}

enum MiniGameKind: Equatable, Sendable {
    case fish, clouds
}

struct PlayProgress: Codable, Equatable, Sendable {
    private(set) var memoryLevel = 1
    private(set) var beaverLevel = 1
    private(set) var fishLevel = 1

    init() {}

    private enum CodingKeys: String, CodingKey { case memoryLevel, beaverLevel, fishLevel }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memoryLevel = min(MemoryRound.sizes.count, max(1, try values.decodeIfPresent(Int.self, forKey: .memoryLevel) ?? 1))
        beaverLevel = min(12, max(1, try values.decodeIfPresent(Int.self, forKey: .beaverLevel) ?? 1))
        fishLevel = min(10, max(1, try values.decodeIfPresent(Int.self, forKey: .fishLevel) ?? 1))
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memoryLevel, forKey: .memoryLevel)
        try values.encode(beaverLevel, forKey: .beaverLevel)
        try values.encode(fishLevel, forKey: .fishLevel)
    }

    mutating func advanceMemoryLevel() {
        memoryLevel = min(MemoryRound.sizes.count, memoryLevel + 1)
    }

    mutating func advanceBeaverLevel() {
        beaverLevel = min(12, beaverLevel + 1)
    }

    mutating func advanceFishLevel() {
        fishLevel = min(10, fishLevel + 1)
    }

}

enum FishKind: Equatable, Sendable {
    case blue, orange, puffer, gold

    var emoji: String {
        switch self {
        case .blue: "🐟"
        case .orange: "🐠"
        case .puffer: "🐡"
        case .gold: "🐠"
        }
    }
}

enum FishQuestRule: Equatable, Sendable {
    case any, avoidGold, only(FishKind)
}

struct FishRound: Equatable, Sendable {
    static let kinds: [FishKind] = [.blue, .orange, .puffer, .blue, .orange, .puffer, .gold]
    let startedAt: Date
    let mode: AgeMode
    let level: Int
    private(set) var caught: Set<Int> = []
    private var respawnAt: [Date?] = Array(repeating: nil, count: 7)
    private(set) var caughtCount = 0
    private(set) var mistakes = 0
    private(set) var penaltySeconds = 0
    private(set) var coins = 0
    private(set) var finished = false
    private(set) var won = false

    init(startedAt: Date, mode: AgeMode, level: Int = 1) {
        self.startedAt = startedAt
        self.mode = mode
        self.level = max(1, level)
    }

    var targetCount: Int { min(12, (mode == .toddler ? 3 : 5) + level - 1) }
    var questRule: FishQuestRule {
        switch (level - 1) % 5 {
        case 1: .only(.blue)
        case 2: .avoidGold
        case 3: .only(.orange)
        case 4: .only(.puffer)
        default: .any
        }
    }

    func kind(_ index: Int) -> FishKind { Self.kinds[index] }

    func secondsRemaining(at now: Date) -> Int {
        max(0, Int(ceil(40 + Double(max(0, targetCount - 3) * 3) - now.timeIntervalSince(startedAt) - Double(penaltySeconds))))
    }

    func position(_ index: Int, at now: Date) -> GamePoint {
        let time = now.timeIntervalSince(startedAt)
        let speed = (mode == .toddler ? 0.40 : 0.72) * (index == 6 ? 1.45 : 1)
        let phase = Double(index) * 1.37
        return GamePoint(x: 0.5 + 0.32 * sin(time * speed + phase),
                         y: 0.52 + 0.19 * sin(time * speed * 0.63 + phase * 1.72))
    }

    mutating func catchFish(_ index: Int, at now: Date) -> Int {
        guard !finished, secondsRemaining(at: now) > 0,
              (0..<7).contains(index), !caught.contains(index) else { return 0 }
        let fish = kind(index)
        let correct: Bool
        switch questRule {
        case .any: correct = true
        case .avoidGold: correct = fish != .gold
        case .only(let required): correct = fish == required
        }
        guard correct else {
            mistakes += 1
            penaltySeconds += 2
            return 0
        }
        caught.insert(index)
        respawnAt[index] = now.addingTimeInterval(index == 6 ? 3.0 : 1.3)
        caughtCount += 1
        let earned = fish == .gold ? 3 : 1
        coins += earned
        if caughtCount >= targetCount { finished = true; won = true }
        return earned
    }

    mutating func tick(at now: Date) {
        if secondsRemaining(at: now) == 0 { finished = true }
        for index in respawnAt.indices where respawnAt[index].map({ now >= $0 }) == true {
            caught.remove(index)
            respawnAt[index] = nil
        }
    }
}

struct CloudRound: Equatable, Sendable {
    private(set) var attempts = 0
    private(set) var jumps = 0
    private(set) var misses = 0
    private(set) var coins = 0
    private(set) var finished = false
    private(set) var won = false
    private(set) var currentCloud = 0
    private(set) var targetCloud: Int
    private(set) var targetUntil: Date
    private var random: GameRandom
    private let interval: TimeInterval

    init(now: Date, mode: AgeMode, seed: UInt64) {
        random = GameRandom(seed: seed)
        targetCloud = 1
        interval = mode == .toddler ? 2.5 : 1.7
        targetUntil = now.addingTimeInterval(interval)
    }

    mutating func tapCloud(_ index: Int, at now: Date) -> Int {
        tick(at: now)
        guard !finished, (0..<5).contains(index) else { return 0 }
        attempts += 1
        if index == targetCloud {
            jumps += 1
            currentCloud = index
            let earned = jumps >= 8 ? 6 : 1
            coins += earned
            if jumps >= 8 { won = true; finished = true }
            else { nextTarget(at: now) }
            return earned
        }
        misses += 1
        if misses >= 3 { finished = true }
        return 0
    }

    mutating func tick(at now: Date) {
        guard !finished, now >= targetUntil else { return }
        misses += 1
        if misses >= 3 { finished = true }
        else { nextTarget(at: now) }
    }

    private mutating func nextTarget(at now: Date) {
        targetCloud = (targetCloud + 1 + random.next(4)) % 5
        targetUntil = now.addingTimeInterval(interval)
    }
}
