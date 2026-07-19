import SwiftUI

/// Pro-only spin history and fairness stats for a single wheel.
struct SpinHistoryView: View {
    let wheel: Wheel
    @Environment(\.dismiss) private var dismiss

    private var counts: [(name: String, count: Int)] {
        var tally: [UUID: Int] = [:]
        for record in wheel.spinHistory {
            tally[record.participantID, default: 0] += 1
        }
        return wheel.participants
            .map { (name: $0.name, count: tally[$0.id] ?? 0) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WTColor.cream.ignoresSafeArea()
                List {
                    Section("Turns taken") {
                        if counts.isEmpty {
                            Text("No spins yet.")
                                .foregroundStyle(WTColor.ink.opacity(0.6))
                        } else {
                            ForEach(counts, id: \.name) { entry in
                                HStack {
                                    Text(entry.name)
                                        .foregroundStyle(WTColor.ink)
                                    Spacer()
                                    Text("\(entry.count)")
                                        .foregroundStyle(WTColor.plum)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }

                    Section("Recent spins") {
                        ForEach(wheel.spinHistory.sorted(by: { $0.date > $1.date }).prefix(20)) { record in
                            HStack {
                                Text(record.participantName)
                                    .foregroundStyle(WTColor.ink)
                                Spacer()
                                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(WTFont.body(12))
                                    .foregroundStyle(WTColor.ink.opacity(0.55))
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("\(wheel.name) Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
