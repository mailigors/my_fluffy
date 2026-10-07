import Foundation

struct GameRandom: Equatable, Sendable {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 1 : seed }

    mutating func next(_ upperBound: Int) -> Int {
        precondition(upperBound > 0)
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Int((state >> 32) % UInt64(upperBound))
    }

    mutating func shuffle<T>(_ values: inout [T]) {
        guard values.count > 1 else { return }
        for index in stride(from: values.count - 1, through: 1, by: -1) {
            values.swapAt(index, next(index + 1))
        }
    }
}

struct PuzzleRound: Equatable, Sendable {
    let imageIndex: Int
    let side: Int
    private(set) var pieces: [Int]
    private(set) var selected: Int?
    private(set) var finished = false

    init(imageIndex: Int, mode: AgeMode, seed: UInt64) {
        self.imageIndex = min(3, max(0, imageIndex))
        side = imageIndex >= 2 ? (mode == .toddler ? 4 : 6) : (mode == .toddler ? 3 : 4)
        var random = GameRandom(seed: seed)
        var pieces = Array(0..<(side * side))
        random.shuffle(&pieces)
        if pieces == Array(0..<(side * side)) { pieces.swapAt(0, 1) }
        self.pieces = pieces
    }

    mutating func tap(_ index: Int) {
        guard !finished, pieces.indices.contains(index) else { return }
        guard let first = selected else { selected = index; return }
        selected = nil
        guard first != index else { return }
        pieces.swapAt(first, index)
        finished = pieces == Array(0..<pieces.count)
    }
}

enum MemoryPhase: Equatable, Sendable {
    case child, childMismatch, catReveal, finished
}

enum MemoryOutcome: Equatable, Sendable {
    case child, cat, draw
}

struct MemoryRound: Equatable, Sendable {
    static let sizes: [(rows: Int, columns: Int)] = [
        (2, 2), (2, 3), (2, 4), (3, 4), (4, 4),
        (4, 5), (4, 6), (5, 6), (6, 6), (6, 7),
        (6, 8), (7, 8), (8, 8)
    ]

    let id = UUID()
    let level: Int
    let rows: Int
    let columns: Int
    let symbols: [Int]
    private var random: GameRandom
    private(set) var phase: MemoryPhase = .child
    private(set) var faceUp: Set<Int> = []
    private(set) var matched: Set<Int> = []
    private(set) var childPairs = 0
    private(set) var catPairs = 0
    private(set) var outcome: MemoryOutcome?
    private var firstChildCard: Int?
    private var catCards: [Int] = []

    init(level: Int, seed: UInt64) {
        self.level = min(Self.sizes.count, max(1, level))
        let size = Self.sizes[self.level - 1]
        rows = size.rows
        columns = size.columns
        var random = GameRandom(seed: seed)
        let pairs = size.rows * size.columns / 2
        var symbols = Array(0..<pairs).flatMap { [$0, $0] }
        random.shuffle(&symbols)
        self.symbols = symbols
        self.random = random
    }

    mutating func flip(_ index: Int) {
        guard phase == .child, symbols.indices.contains(index), !matched.contains(index), !faceUp.contains(index) else { return }
        faceUp.insert(index)
        guard let first = firstChildCard else { firstChildCard = index; return }
        firstChildCard = nil
        if symbols[first] == symbols[index] {
            matched.formUnion([first, index])
            childPairs += 1
            faceUp.removeAll()
            finishIfComplete()
        } else {
            phase = .childMismatch
        }
    }

    mutating func revealCatTurn() {
        guard phase == .childMismatch else { return }
        faceUp.removeAll()
        let available = symbols.indices.filter { !matched.contains($0) }
        guard available.count >= 2 else { finishIfComplete(); return }
        let shouldRemember = random.next(100) < 35
        if shouldRemember {
            let symbol = symbols[available[random.next(available.count)]]
            catCards = available.filter { symbols[$0] == symbol }
        } else {
            var shuffled = available
            random.shuffle(&shuffled)
            catCards = Array(shuffled.prefix(2))
        }
        faceUp = Set(catCards)
        phase = .catReveal
    }

    mutating func finishCatTurn() {
        guard phase == .catReveal, catCards.count == 2 else { return }
        if symbols[catCards[0]] == symbols[catCards[1]] {
            matched.formUnion(catCards)
            catPairs += 1
        }
        faceUp.removeAll()
        catCards.removeAll()
        phase = .child
        finishIfComplete()
    }

    private mutating func finishIfComplete() {
        guard matched.count == symbols.count else { return }
        outcome = childPairs > catPairs ? .child : (catPairs > childPairs ? .cat : .draw)
        phase = .finished
    }
}

enum TicMark: Equatable, Sendable { case child, cat }
enum TicOutcome: Equatable, Sendable { case child, cat, draw }

struct TicTacToeRound: Equatable, Sendable {
    let id = UUID()
    private(set) var board: [TicMark?] = Array(repeating: nil, count: 9)
    private(set) var waitingForCat = false
    private(set) var outcome: TicOutcome?
    private var random: GameRandom

    init(seed: UInt64) { random = GameRandom(seed: seed) }

    mutating func childTap(_ index: Int) {
        guard outcome == nil, !waitingForCat, board.indices.contains(index), board[index] == nil else { return }
        board[index] = .child
        updateOutcome()
        if outcome == nil { waitingForCat = true }
    }

    mutating func catMove() {
        guard waitingForCat, outcome == nil else { return }
        let free = board.indices.filter { board[$0] == nil }
        guard !free.isEmpty else { outcome = .draw; waitingForCat = false; return }
        let winning = immediateMove(for: .cat)
        let blocking = immediateMove(for: .child)
        let roll = random.next(100)
        let choice: Int
        if let winning, roll < 68 { choice = winning }
        else if let blocking, roll < 50 { choice = blocking }
        else { choice = free[random.next(free.count)] }
        board[choice] = .cat
        waitingForCat = false
        updateOutcome()
    }

    private func immediateMove(for mark: TicMark) -> Int? {
        for index in board.indices where board[index] == nil {
            var trial = board
            trial[index] = mark
            if Self.winner(in: trial) == mark { return index }
        }
        return nil
    }

    private mutating func updateOutcome() {
        if let winner = Self.winner(in: board) {
            outcome = winner == .child ? .child : .cat
        } else if !board.contains(where: { $0 == nil }) {
            outcome = .draw
        }
    }

    private static func winner(in board: [TicMark?]) -> TicMark? {
        let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8],
                     [0, 3, 6], [1, 4, 7], [2, 5, 8],
                     [0, 4, 8], [2, 4, 6]]
        for line in lines {
            if let mark = board[line[0]], board[line[1]] == mark, board[line[2]] == mark { return mark }
        }
        return nil
    }
}

enum BeaverOutcome: Equatable, Sendable { case win, lose }

struct BeaverRound: Equatable, Sendable {
    static let winThreshold = 6.0
    static let loseThreshold = -8.0
    let level: Int
    let holeCount: Int
    private(set) var meter = 0.0
    private(set) var activeHoles: [Int: Int] = [:]
    private var expiresAt: [Int: Date] = [:]
    var activeHole: Int? { activeHoles.keys.sorted().first }
    var appearsUntil: Date? { expiresAt.values.min() }
    var simultaneousHeads: Int { min(4, 1 + max(0, level - 1) / 2) }
    private(set) var outcome: BeaverOutcome?
    private var nextSpawnAt: Date
    private var random: GameRandom
    private let visibleSeconds: TimeInterval

    init(now: Date, mode: AgeMode, seed: UInt64, level: Int = 1) {
        self.level = max(1, level)
        holeCount = min(16, 6 + (self.level - 1) * 2)
        random = GameRandom(seed: seed)
        nextSpawnAt = now
        visibleSeconds = max(0.65, (mode == .toddler ? 2.1 : 1.5) - Double(self.level - 1) * 0.075)
        tick(at: now)
    }

    mutating func tick(at now: Date) {
        guard outcome == nil else { return }
        let expired = expiresAt.filter { now >= $0.value }.map(\.key)
        for hole in expired {
            activeHoles.removeValue(forKey: hole)
            expiresAt.removeValue(forKey: hole)
            meter -= 1.25
            if meter <= Self.loseThreshold { outcome = .lose; return }
        }
        if !expired.isEmpty && activeHoles.isEmpty { nextSpawnAt = now.addingTimeInterval(0.3) }
        if activeHoles.isEmpty && now >= nextSpawnAt {
            while activeHoles.count < simultaneousHeads {
                let hole = random.next(holeCount)
                guard activeHoles[hole] == nil else { continue }
                activeHoles[hole] = random.next(4)
                expiresAt[hole] = now.addingTimeInterval(visibleSeconds)
            }
        }
    }

    mutating func tap(_ hole: Int, at now: Date) {
        tick(at: now)
        guard outcome == nil, let expiry = expiresAt[hole], now < expiry else { return }
        activeHoles.removeValue(forKey: hole)
        expiresAt.removeValue(forKey: hole)
        meter += 0.5
        if meter >= Self.winThreshold { outcome = .win; return }
        if activeHoles.isEmpty { nextSpawnAt = now.addingTimeInterval(0.3) }
    }
}
