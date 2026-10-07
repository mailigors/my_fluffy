import XCTest
@testable import MyFluffy

final class TabletopLogicTests: XCTestCase {
    func testPuzzleIsSolvableByTheChildWithoutAnOpponent() {
        for mode in [AgeMode.toddler, .older] {
            var round = PuzzleRound(imageIndex: 0, mode: mode, seed: 12)
            XCTAssertFalse(round.finished)
            XCTAssertEqual(round.side, mode == .toddler ? 3 : 4)
            for target in round.pieces.indices {
                guard let position = round.pieces.firstIndex(of: target) else { XCTFail(); return }
                round.tap(target)
                round.tap(position)
            }
            XCTAssertTrue(round.finished)
            XCTAssertEqual(round.pieces, Array(0..<round.pieces.count))
        }
    }

    func testNewPuzzlesUseLargerBoards() {
        for imageIndex in 2...3 {
            XCTAssertEqual(PuzzleRound(imageIndex: imageIndex, mode: .toddler, seed: 1).side, 4)
            XCTAssertEqual(PuzzleRound(imageIndex: imageIndex, mode: .older, seed: 1).side, 6)
        }
    }

    func testMemoryGrowsEveryLevelToEightByEight() {
        var previousCount = 0
        for level in 1...MemoryRound.sizes.count {
            let round = MemoryRound(level: level, seed: 21)
            XCTAssertGreaterThan(round.symbols.count, previousCount)
            XCTAssertEqual(round.symbols.count, round.rows * round.columns)
            previousCount = round.symbols.count
        }
        let last = MemoryRound(level: MemoryRound.sizes.count, seed: 21)
        XCTAssertEqual(last.rows, 8)
        XCTAssertEqual(last.columns, 8)
        XCTAssertEqual(last.symbols.count, 64)
    }

    func testMemoryChildAndCatTurns() {
        var round = MemoryRound(level: 1, seed: 9)
        let first = 0
        let mismatch = round.symbols.firstIndex(where: { $0 != round.symbols[first] })!
        round.flip(first)
        round.flip(mismatch)
        XCTAssertEqual(round.phase, .childMismatch)
        round.revealCatTurn()
        XCTAssertEqual(round.phase, .catReveal)
        XCTAssertEqual(round.faceUp.count, 2)
        round.finishCatTurn()
        XCTAssertTrue(round.phase == .child || round.phase == .finished)
    }

    func testMemoryLevelSurvivesOldAndNewSaveData() throws {
        var progress = PlayProgress()
        progress.advanceMemoryLevel()
        let restored = try JSONDecoder().decode(PlayProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(restored.memoryLevel, 2)
        let legacy = try JSONDecoder().decode(PlayProgress.self, from: Data("{\"roundsPlayed\":2}".utf8))
        XCTAssertEqual(legacy.memoryLevel, 1)
    }

    func testTicTacToeCatCanWinAndCanLose() {
        var catWins = 0
        var childWins = 0
        for seed in 1...200 {
            var round = TicTacToeRound(seed: UInt64(seed))
            while round.outcome == nil {
                guard let choice = round.board.indices.first(where: { round.board[$0] == nil }) else { break }
                round.childTap(choice)
                round.catMove()
            }
            if round.outcome == .cat { catWins += 1 }
            if round.outcome == .child { childWins += 1 }
        }
        XCTAssertGreaterThan(catWins, 0)
        XCTAssertGreaterThan(childWins, 0)
    }

    func testBeaverWinAndLossComeFromTheMeter() {
        let start = Date(timeIntervalSince1970: 1_000)
        var win = BeaverRound(now: start, mode: .toddler, seed: 7)
        var time = start
        for _ in 0..<12 {
            XCTAssertNotNil(win.activeHole)
            win.tap(win.activeHole!, at: time)
            time.addTimeInterval(0.31)
            win.tick(at: time)
        }
        XCTAssertEqual(win.meter, BeaverRound.winThreshold)
        XCTAssertEqual(win.outcome, .win)
        var lose = BeaverRound(now: start, mode: .older, seed: 11)
        time = start
        for _ in 0..<7 {
            time.addTimeInterval(1.6)
            lose.tick(at: time)
            time.addTimeInterval(0.31)
            lose.tick(at: time)
        }
        XCTAssertLessThanOrEqual(lose.meter, BeaverRound.loseThreshold)
        XCTAssertEqual(lose.outcome, .lose)
    }

    func testBeaverAddsHolesAndGetsFasterEachRound() {
        let now = Date(timeIntervalSince1970: 1_000)
        var progress = PlayProgress()
        var previousDuration = Double.greatestFiniteMagnitude
        for level in 1...12 {
            let round = BeaverRound(now: now, mode: .older, seed: 3, level: progress.beaverLevel)
            XCTAssertEqual(round.holeCount, min(16, 6 + (level - 1) * 2))
            let duration = round.appearsUntil!.timeIntervalSince(now)
            XCTAssertLessThan(duration, previousDuration)
            previousDuration = duration
            progress.advanceBeaverLevel()
        }
        XCTAssertEqual(progress.beaverLevel, 12)
        let restored = try? JSONDecoder().decode(PlayProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(restored?.beaverLevel, 12)
    }

    func testBeaverShowsSeveralAnimalsAtHigherLevels() {
        let now = Date(timeIntervalSince1970: 1_000)
        for (level, count) in [(1, 1), (3, 2), (5, 3), (8, 4)] {
            var round = BeaverRound(now: now, mode: .older, seed: 27, level: level)
            XCTAssertEqual(round.activeHoles.count, count)
            let first = round.activeHole!
            round.tap(first, at: now)
            XCTAssertEqual(round.activeHoles.count, count - 1)
            XCTAssertEqual(round.meter, 0.5)
        }
    }
}
