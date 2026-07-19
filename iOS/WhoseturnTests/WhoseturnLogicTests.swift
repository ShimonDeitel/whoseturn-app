import XCTest
@testable import Whoseturn

/// Deterministic core-logic tests for the fairness/rotation engine: no UI, no persistence, no
/// network — every expected value below was hand-verified against the weight formula
/// `weight(p) = spinsSinceTurn(p) + 1`. `randomValue` is supplied explicitly so results are
/// reproducible.
final class WhoseturnLogicTests: XCTestCase {

    private func participant(_ name: String, spinsSinceTurn: Int = 0) -> Participant {
        Participant(name: name, spinsSinceTurn: spinsSinceTurn)
    }

    // MARK: weight()

    func testWeightIsSpinsSinceTurnPlusOne() {
        XCTAssertEqual(FairnessEngine.weight(for: participant("A", spinsSinceTurn: 0)), 1)
        XCTAssertEqual(FairnessEngine.weight(for: participant("A", spinsSinceTurn: 4)), 5)
    }

    // MARK: selectNext — empty / single participant

    func testSelectNextReturnsNilForEmptyPool() {
        XCTAssertNil(FairnessEngine.selectNext(participants: [], lastPickedID: nil, randomValue: 0.5))
    }

    func testSelectNextReturnsOnlyParticipantWhenPoolHasOne() {
        let a = participant("A")
        let result = FairnessEngine.selectNext(participants: [a], lastPickedID: a.id, randomValue: 0.9)
        XCTAssertEqual(result?.id, a.id)
    }

    // MARK: selectNext — never repeat when others are available

    func testSelectNextExcludesLastPickedWhenOthersAvailable() {
        let a = participant("A")
        let b = participant("B")
        // Even with a randomValue that would land on A's bucket in the unfiltered pool, A must
        // be excluded because B is available and A won last time.
        let result = FairnessEngine.selectNext(participants: [a, b], lastPickedID: a.id, randomValue: 0.1)
        XCTAssertEqual(result?.id, b.id)
    }

    // MARK: selectNext — equal weights split the [0,1) range into even buckets

    func testSelectNextWithEqualWeightsSplitsRangeIntoThirds() {
        let a = participant("A")
        let b = participant("B")
        let c = participant("C")
        let pool = [a, b, c]
        // Equal weights (1,1,1), total 3: buckets are [0, 1/3), [1/3, 2/3), [2/3, 1).
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.0)?.id, a.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.3)?.id, a.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.4)?.id, b.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.6)?.id, b.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.7)?.id, c.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.99)?.id, c.id)
    }

    // MARK: selectNext — weighted by wait time

    func testSelectNextWeightsLongerWaitingParticipantMoreHeavily() {
        // A just had a turn (weight 1), B has waited 2 spins (weight 3). Total weight = 4.
        // A's bucket is [0, 0.25), B's bucket is [0.25, 1.0).
        let a = participant("A", spinsSinceTurn: 0)
        let b = participant("B", spinsSinceTurn: 2)
        let pool = [a, b]
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.0)?.id, a.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.24)?.id, a.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.25)?.id, b.id)
        XCTAssertEqual(FairnessEngine.selectNext(participants: pool, lastPickedID: nil, randomValue: 0.9)?.id, b.id)
    }

    // MARK: applySpin

    func testApplySpinResetsWinnerAndIncrementsEveryoneElse() {
        let a = participant("A", spinsSinceTurn: 3)
        let b = participant("B", spinsSinceTurn: 1)
        let c = participant("C", spinsSinceTurn: 0)
        let updated = FairnessEngine.applySpin(participants: [a, b, c], winnerID: b.id)

        XCTAssertEqual(updated[0].spinsSinceTurn, 4) // A did not win, increments
        XCTAssertEqual(updated[1].spinsSinceTurn, 0) // B won, resets
        XCTAssertEqual(updated[2].spinsSinceTurn, 1) // C did not win, increments
    }

    // MARK: Multi-spin fairness simulation

    func testRepeatedSpinsNeverPickSameWinnerTwiceInARowWithMultipleParticipants() {
        var participants = [participant("A"), participant("B"), participant("C")]
        var lastPicked: UUID?
        var randomSeed = 0.0

        for _ in 0..<50 {
            guard let winner = FairnessEngine.selectNext(
                participants: participants,
                lastPickedID: lastPicked,
                randomValue: randomSeed
            ) else {
                XCTFail("Expected a winner")
                return
            }
            if lastPicked != nil {
                XCTAssertNotEqual(winner.id, lastPicked, "Same participant should never win twice in a row")
            }
            participants = FairnessEngine.applySpin(participants: participants, winnerID: winner.id)
            lastPicked = winner.id
            // Walk the random seed through the [0, 1) range deterministically across iterations.
            randomSeed = (randomSeed + 0.137).truncatingRemainder(dividingBy: 1.0)
        }
    }

    func testEveryoneEventuallyGetsATurnOverManySpins() {
        var participants = [participant("A"), participant("B"), participant("C"), participant("D")]
        var lastPicked: UUID?
        var winCounts: [String: Int] = [:]
        var randomSeed = 0.05

        for _ in 0..<200 {
            guard let winner = FairnessEngine.selectNext(
                participants: participants,
                lastPickedID: lastPicked,
                randomValue: randomSeed
            ) else {
                XCTFail("Expected a winner")
                return
            }
            winCounts[winner.name, default: 0] += 1
            participants = FairnessEngine.applySpin(participants: participants, winnerID: winner.id)
            lastPicked = winner.id
            randomSeed = (randomSeed + 0.211).truncatingRemainder(dividingBy: 1.0)
        }

        for name in ["A", "B", "C", "D"] {
            XCTAssertGreaterThan(winCounts[name, default: 0], 0, "\(name) should have won at least once over 200 spins")
        }
    }
}
