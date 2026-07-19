import Foundation

/// A participant in a wheel's rotation. Pure data — no UI, no persistence framework beyond
/// Codable, so this type (and the engine below) can be unit tested with plain Swift values.
public struct Participant: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    /// Number of completed spins since this participant was last selected (0 = selected on the
    /// most recent spin, or never spun if the wheel is brand new).
    public var spinsSinceTurn: Int

    public init(id: UUID = UUID(), name: String, spinsSinceTurn: Int = 0) {
        self.id = id
        self.name = name
        self.spinsSinceTurn = spinsSinceTurn
    }
}

/// Standalone, UI-independent fairness/rotation logic for Whoseturn's chore wheel.
///
/// Rules implemented:
/// 1. Never pick the same person twice in a row if another participant is available.
/// 2. Among the eligible candidates, weight selection by how long it has been since each
///    participant last had a turn, so the longer someone waits the more likely they are to be
///    picked next. This self-balances fairness over many spins without ever hard-guaranteeing
///    strict round-robin order (which would make the wheel feel deterministic/rigged).
///
/// Weighting formula: weight(p) = spinsSinceTurn(p) + 1
/// Adding 1 guarantees every participant always has a strictly positive weight (even someone
/// selected on the very last spin, whose spinsSinceTurn resets to 0, still has weight 1 and can
/// theoretically be picked again once others are excluded by rule 1). Someone who has waited N
/// spins is N+1 times more likely to be picked than someone selected last spin (weight 1),
/// biasing the wheel toward whoever is "most overdue" while still leaving genuine randomness.
public enum FairnessEngine {

    public static func weight(for participant: Participant) -> Double {
        Double(participant.spinsSinceTurn + 1)
    }

    /// Picks the next participant.
    /// - Parameters:
    ///   - participants: the full candidate pool (must be non-empty to get a result).
    ///   - lastPickedID: whoever won the previous spin on this wheel, or nil if this is the
    ///     wheel's first-ever spin.
    ///   - randomValue: a value in [0, 1) driving the weighted pick. Callers pass a real random
    ///     draw at runtime; tests pass fixed values for deterministic, hand-verifiable results.
    /// - Returns: the selected participant, or nil if `participants` is empty.
    public static func selectNext(
        participants: [Participant],
        lastPickedID: UUID?,
        randomValue: Double
    ) -> Participant? {
        guard !participants.isEmpty else { return nil }

        var pool = participants
        if participants.count > 1, let lastPickedID {
            let eligible = participants.filter { $0.id != lastPickedID }
            if !eligible.isEmpty {
                pool = eligible
            }
        }

        let weights = pool.map(weight(for:))
        let total = weights.reduce(0, +)
        guard total > 0 else { return pool.first }

        let clampedRandom = min(max(randomValue, 0), 0.999_999_999)
        let target = clampedRandom * total
        var cumulative = 0.0
        for (index, w) in weights.enumerated() {
            cumulative += w
            if target < cumulative {
                return pool[index]
            }
        }
        return pool.last
    }

    /// Updates every participant's `spinsSinceTurn` after a spin resolves: the winner resets to
    /// 0, everyone else increments by 1.
    public static func applySpin(participants: [Participant], winnerID: UUID) -> [Participant] {
        participants.map { participant in
            var updated = participant
            updated.spinsSinceTurn = (participant.id == winnerID) ? 0 : participant.spinsSinceTurn + 1
            return updated
        }
    }
}
