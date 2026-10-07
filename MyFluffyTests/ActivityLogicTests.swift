import XCTest
@testable import MyFluffy

final class ActivityLogicTests: XCTestCase {
    func testBathRequiresSoapRinseTowelAndComb() {
        var bath = BathSession()
        bath.moveShower(to: BathSession.foamPositions[0])
        XCTAssertEqual(bath.step, .bubbles)
        for index in 0..<BathSession.bubbleCount { bath.popBubble(index) }
        XCTAssertEqual(bath.step, .soap)
        bath.popBubble(0)
        bath.soapStroke(from: .init(x: 0.1, y: 0.4), to: .init(x: 0.5, y: 0.4))
        XCTAssertEqual(bath.soapStrokes, 0)
        bath.pickUpTool()
        for _ in 0..<5 {
            bath.soapStroke(from: .init(x: 0.35, y: 0.5), to: .init(x: 0.55, y: 0.5))
        }
        XCTAssertEqual(bath.step, .shower)
        XCTAssertFalse(bath.showerTaken)
        for point in BathSession.foamPositions { bath.moveShower(to: point) }
        XCTAssertEqual(bath.foamRemaining, BathSession.foamPositions.count)
        XCTAssertEqual(bath.step, .shower)
        bath.pickUpShower()
        for point in BathSession.foamPositions { bath.moveShower(to: point) }
        XCTAssertEqual(bath.foamRemaining, 0)
        XCTAssertEqual(bath.step, .towel)
        XCTAssertNil(bath.heldTool)
        bath.rubTowel(from: .init(x: 0.1, y: 0.5), to: .init(x: 0.5, y: 0.5))
        XCTAssertEqual(bath.towelProgress, 0)
        bath.rubTowel(from: .init(x: 0.4, y: 0.5), to: .init(x: 0.55, y: 0.5))
        XCTAssertEqual(bath.towelProgress, 0)
        bath.pickUpTool()
        for index in 0..<12 {
            let from = index.isMultiple(of: 2) ? 0.4 : 0.45
            let to = index.isMultiple(of: 2) ? 0.45 : 0.4
            bath.rubTowel(from: .init(x: from, y: 0.5), to: .init(x: to, y: 0.5))
        }
        XCTAssertEqual(bath.step, .comb)
        bath.combStroke(from: .init(x: 0.5, y: 0.4), to: .init(x: 0.5, y: 0.6))
        XCTAssertEqual(bath.combStrokes, 0)
        bath.pickUpTool()
        for _ in 0..<5 {
            bath.combStroke(from: .init(x: 0.5, y: 0.4), to: .init(x: 0.5, y: 0.6))
        }
        XCTAssertEqual(bath.step, .finished)
    }

    func testToiletRequiresClumpsThenPawprints() {
        var toilet = ToiletSession()
        toilet.moveSponge(to: ToiletSession.pawPositions[0])
        XCTAssertTrue(toilet.wiped.isEmpty)
        for point in ToiletSession.clumpPositions { toilet.movePaper(to: point) }
        XCTAssertEqual(toilet.step, .wipe)
        for point in ToiletSession.pawPositions { toilet.moveSponge(to: point) }
        XCTAssertEqual(toilet.step, .flush)
        toilet.flush()
        XCTAssertEqual(toilet.step, .finished)
    }

    func testOldPlayPauseDataDoesNotBlockGames() throws {
        let old = Data("{\"roundsPlayed\":5,\"pauseUntil\":9999999999,\"memoryLevel\":3}".utf8)
        let restored = try JSONDecoder().decode(PlayProgress.self, from: old)
        XCTAssertEqual(restored.memoryLevel, 3)
        let saved = String(decoding: try JSONEncoder().encode(restored), as: UTF8.self)
        XCTAssertFalse(saved.contains("pauseUntil"))
    }

    func testFishRewardsOnlyOnceAndTimeLimit() {
        let now = Date(timeIntervalSince1970: 1_000)
        var fish = FishRound(startedAt: now, mode: .older)
        XCTAssertEqual(fish.catchFish(6, at: now), 3)
        XCTAssertEqual(fish.catchFish(6, at: now), 0)
        XCTAssertEqual(fish.catchFish(0, at: now), 1)
        fish.tick(at: now.addingTimeInterval(46))
        XCTAssertTrue(fish.finished)
        XCTAssertEqual(fish.catchFish(1, at: now.addingTimeInterval(47)), 0)
        var toddler = FishRound(startedAt: now, mode: .toddler)
        for index in 0..<3 { _ = toddler.catchFish(index, at: now) }
        XCTAssertTrue(toddler.finished)
        var older = FishRound(startedAt: now, mode: .older, level: 6)
        for index in 0..<6 { _ = older.catchFish(index, at: now) }
        XCTAssertFalse(older.finished)
        XCTAssertEqual(older.catchFish(6, at: now), 3)
        XCTAssertFalse(older.finished)
        older.tick(at: now.addingTimeInterval(2))
        for index in 0..<3 { _ = older.catchFish(index, at: now.addingTimeInterval(2)) }
        XCTAssertTrue(older.finished)
    }

    func testFishReturnsAndCloudTargetMovesOnTimeout() {
        let now = Date(timeIntervalSince1970: 1_000)
        var fish = FishRound(startedAt: now, mode: .older)
        _ = fish.catchFish(0, at: now)
        XCTAssertTrue(fish.caught.contains(0))
        fish.tick(at: now.addingTimeInterval(1.4))
        XCTAssertFalse(fish.caught.contains(0))
        var clouds = CloudRound(now: now, mode: .older, seed: 7)
        clouds.tick(at: now.addingTimeInterval(1.8))
        XCTAssertEqual(clouds.misses, 1)
        XCTAssertNotEqual(clouds.targetCloud, 1)
    }

    func testFishQuestsGrowAndRejectWrongFish() {
        let now = Date(timeIntervalSince1970: 1_000)
        var progress = PlayProgress()
        for level in 1...10 {
            let round = FishRound(startedAt: now, mode: .toddler, level: progress.fishLevel)
            XCTAssertEqual(round.targetCount, min(12, level + 2))
            progress.advanceFishLevel()
        }
        var blue = FishRound(startedAt: now, mode: .older, level: 2)
        XCTAssertEqual(blue.questRule, .only(.blue))
        XCTAssertEqual(blue.catchFish(1, at: now), 0)
        XCTAssertEqual(blue.caughtCount, 0)
        XCTAssertEqual(blue.mistakes, 1)
        XCTAssertEqual(blue.catchFish(0, at: now), 1)
        var noGold = FishRound(startedAt: now, mode: .older, level: 3)
        XCTAssertEqual(noGold.questRule, .avoidGold)
        XCTAssertEqual(noGold.catchFish(6, at: now), 0)
        XCTAssertEqual(noGold.penaltySeconds, 2)
        XCTAssertEqual(noGold.catchFish(0, at: now), 1)
    }

    func testCloudStarAndThreeMisses() {
        let now = Date(timeIntervalSince1970: 1_000)
        var won = CloudRound(now: now, mode: .older, seed: 5)
        for _ in 0..<8 { _ = won.tapCloud(won.targetCloud, at: now) }
        XCTAssertTrue(won.won)
        XCTAssertTrue(won.finished)
        XCTAssertEqual(won.coins, 13)
        var lost = CloudRound(now: now, mode: .older, seed: 5)
        for _ in 0..<3 { _ = lost.tapCloud((lost.targetCloud + 1) % 5, at: now) }
        XCTAssertTrue(lost.finished)
        XCTAssertFalse(lost.won)
    }
}
