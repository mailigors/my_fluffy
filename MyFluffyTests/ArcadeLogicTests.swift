import XCTest
@testable import MyFluffy

final class ArcadeLogicTests: XCTestCase {
    func testHockeyPaddleTracksFingerAndRoundEnds() {
        let start = Date(timeIntervalSince1970: 1_000)
        var round = AirHockeyRound(now: start, mode: .toddler)
        round.moveChild(to: 1.5)
        XCTAssertEqual(round.childX, 0.9)
        round.moveChild(to: -1)
        XCTAssertEqual(round.childX, 0.1)
        for frame in 1...1_500 where round.outcome == nil {
            let now = start.addingTimeInterval(Double(frame) * 0.05)
            round.moveChild(to: round.puck.x)
            round.tick(at: now)
        }
        XCTAssertNotNil(round.outcome)
        XCTAssertGreaterThan(round.collisionCount + round.goalCount, 0)
    }

    func testHockeyKeepsMovingWithSparseTicksAndPaddleTouches() {
        let start = Date(timeIntervalSince1970: 1_000)
        var round = AirHockeyRound(now: start, mode: .toddler, seed: 1)
        for frame in 1...5 {
            round.moveChild(to: 0.2 + Double(frame) * 0.1)
            round.tick(at: start.addingTimeInterval(Double(frame) * 0.12))
        }
        XCTAssertEqual(round.puck.y, 0.5 + 0.42 * 0.6, accuracy: 0.001)
    }

    func testHockeyPuckAcceleratesAfterPaddleHit() {
        let start = Date(timeIntervalSince1970: 1_000)
        var round = AirHockeyRound(now: start, mode: .toddler, seed: 1)
        let initialSpeed = round.puckSpeed
        for frame in 1...100 where round.collisionCount == 0 {
            round.moveChild(to: round.puck.x)
            round.tick(at: start.addingTimeInterval(Double(frame) * 0.02))
        }
        XCTAssertGreaterThan(round.collisionCount, 0)
        XCTAssertGreaterThan(round.puckSpeed, initialSpeed)
    }

    func testToyTargetsNeedAccurateShotsAndFinish() {
        let start = Date(timeIntervalSince1970: 1_000)
        var round = ToyTargetRound(now: start, mode: .toddler)
        XCTAssertFalse(round.shoot(at: .init(x: 0.02, y: 0.95), now: start))
        XCTAssertEqual(round.shots, 1)
        for shot in 1...round.targetHits {
            let now = start.addingTimeInterval(Double(shot) * 0.7)
            XCTAssertTrue(round.shoot(at: round.position(0, at: now), now: now))
        }
        XCTAssertEqual(round.outcome, .win)
        XCTAssertEqual(round.hits, 6)
        XCTAssertFalse(round.shoot(at: round.position(0, at: start), now: start))
    }

    func testToyTargetsLoseAfterRunningOutOfShots() {
        let start = Date(timeIntervalSince1970: 1_000)
        var round = ToyTargetRound(now: start, mode: .older)
        for _ in 0..<round.maxShots {
            _ = round.shoot(at: .init(x: 0.02, y: 0.95), now: start)
        }
        XCTAssertEqual(round.outcome, .lose)
    }
}
