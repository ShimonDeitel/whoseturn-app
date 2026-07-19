import Foundation

/// A single named rotation (e.g. "Dishes", "Trash", "Family Movie Pick").
public struct Wheel: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var participants: [Participant]
    public var lastPickedID: UUID?
    /// Pro feature: a custom SF Symbol name shown as the wheel's icon.
    public var iconSymbolName: String
    public var spinHistory: [SpinRecord]

    public init(
        id: UUID = UUID(),
        name: String,
        participants: [Participant] = [],
        lastPickedID: UUID? = nil,
        iconSymbolName: String = "circle.grid.cross",
        spinHistory: [SpinRecord] = []
    ) {
        self.id = id
        self.name = name
        self.participants = participants
        self.lastPickedID = lastPickedID
        self.iconSymbolName = iconSymbolName
        self.spinHistory = spinHistory
    }
}

/// A record of one completed spin, kept for Pro spin-history stats.
public struct SpinRecord: Identifiable, Codable, Equatable {
    public let id: UUID
    public let participantID: UUID
    public let participantName: String
    public let date: Date

    public init(id: UUID = UUID(), participantID: UUID, participantName: String, date: Date = Date()) {
        self.id = id
        self.participantID = participantID
        self.participantName = participantName
        self.date = date
    }
}

/// Top-level persisted document.
public struct WhoseturnData: Codable, Equatable {
    public var wheels: [Wheel]

    public init(wheels: [Wheel] = []) {
        self.wheels = wheels
    }
}

public enum FreeTierLimits {
    public static let maxWheels = 1
    public static let maxParticipantsPerWheel = 4
}
