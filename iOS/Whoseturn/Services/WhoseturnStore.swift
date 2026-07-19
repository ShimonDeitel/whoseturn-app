import Foundation
import Combine

/// Local-only persistence for Whoseturn: Codable JSON written to the app's Documents directory
/// via FileManager. No network calls, no CloudKit, no iCloud entitlements — everything lives on
/// this device only.
@MainActor
final class WhoseturnStore: ObservableObject {
    @Published private(set) var data: WhoseturnData

    private let fileURL: URL
    private let entitlements: EntitlementsStore

    init(entitlements: EntitlementsStore, fileURL: URL? = nil) {
        self.entitlements = entitlements
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = documents.appendingPathComponent("whoseturn_data.json")
        }
        self.data = WhoseturnStore.load(from: self.fileURL) ?? WhoseturnData()
    }

    // MARK: Loading / saving

    private static func load(from url: URL) -> WhoseturnData? {
        guard let raw = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WhoseturnData.self, from: raw)
    }

    private func persist() {
        guard let raw = try? JSONEncoder().encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }

    // MARK: Limits

    var canAddWheel: Bool {
        entitlements.isPro || data.wheels.count < FreeTierLimits.maxWheels
    }

    func canAddParticipant(to wheel: Wheel) -> Bool {
        entitlements.isPro || wheel.participants.count < FreeTierLimits.maxParticipantsPerWheel
    }

    // MARK: Wheels

    @discardableResult
    func addWheel(name: String) -> Bool {
        guard canAddWheel else { return false }
        let wheel = Wheel(name: name)
        data.wheels.append(wheel)
        persist()
        return true
    }

    func deleteWheel(_ wheel: Wheel) {
        data.wheels.removeAll { $0.id == wheel.id }
        persist()
    }

    func updateWheel(_ wheel: Wheel) {
        guard let index = data.wheels.firstIndex(where: { $0.id == wheel.id }) else { return }
        data.wheels[index] = wheel
        persist()
    }

    // MARK: Participants

    @discardableResult
    func addParticipant(name: String, to wheel: Wheel) -> Bool {
        guard let index = data.wheels.firstIndex(where: { $0.id == wheel.id }) else { return false }
        guard canAddParticipant(to: data.wheels[index]) else { return false }
        data.wheels[index].participants.append(Participant(name: name))
        persist()
        return true
    }

    func removeParticipant(_ participant: Participant, from wheel: Wheel) {
        guard let index = data.wheels.firstIndex(where: { $0.id == wheel.id }) else { return }
        data.wheels[index].participants.removeAll { $0.id == participant.id }
        if data.wheels[index].lastPickedID == participant.id {
            data.wheels[index].lastPickedID = nil
        }
        persist()
    }

    // MARK: Spinning

    /// Runs the fairness engine against the given wheel, records the winner, and persists.
    /// Returns the winning participant, if any.
    @discardableResult
    func spin(wheel: Wheel, randomValue: Double = Double.random(in: 0..<1)) -> Participant? {
        guard let index = data.wheels.firstIndex(where: { $0.id == wheel.id }) else { return nil }
        var current = data.wheels[index]
        guard let winner = FairnessEngine.selectNext(
            participants: current.participants,
            lastPickedID: current.lastPickedID,
            randomValue: randomValue
        ) else { return nil }

        current.participants = FairnessEngine.applySpin(participants: current.participants, winnerID: winner.id)
        current.lastPickedID = winner.id
        if entitlements.isPro {
            current.spinHistory.append(SpinRecord(participantID: winner.id, participantName: winner.name))
        }
        data.wheels[index] = current
        persist()
        return winner
    }
}
