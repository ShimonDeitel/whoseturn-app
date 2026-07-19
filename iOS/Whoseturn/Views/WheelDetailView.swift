import SwiftUI

struct WheelDetailView: View {
    let wheelID: UUID
    @EnvironmentObject private var store: WhoseturnStore
    @EnvironmentObject private var entitlements: EntitlementsStore
    @StateObject private var animator = SpinAnimator()
    @State private var showAddParticipant = false
    @State private var showPaywall = false
    @State private var showHistory = false
    @State private var winnerName: String?

    private var wheel: Wheel? {
        store.data.wheels.first { $0.id == wheelID }
    }

    var body: some View {
        ZStack {
            WTColor.cream.ignoresSafeArea()

            if let wheel {
                VStack(spacing: 24) {
                    if wheel.participants.isEmpty {
                        emptyParticipants
                    } else {
                        wheelDial(wheel)
                        resultBanner
                        spinButton(wheel)
                    }

                    participantList(wheel)
                }
                .padding()
            }
        }
        .navigationTitle(wheel?.name ?? "Wheel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if entitlements.isPro {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    .foregroundStyle(WTColor.plum)
                }
            }
        }
        .sheet(isPresented: $showAddParticipant) {
            AddParticipantSheet(wheelID: wheelID)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showHistory) {
            if let wheel { SpinHistoryView(wheel: wheel) }
        }
    }

    // MARK: Wheel dial

    private func wheelDial(_ wheel: Wheel) -> some View {
        ZStack {
            SpinWheelShape(participants: wheel.participants)
                .rotationEffect(.degrees(animator.rotationDegrees))

            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 28))
                .foregroundStyle(WTColor.ink)
                .offset(y: -150)
        }
        .frame(width: 280, height: 280)
        .padding(.top, 8)
    }

    private var resultBanner: some View {
        Group {
            if let winnerName {
                Text("\(winnerName)'s turn!")
                    .font(WTFont.title(22))
                    .foregroundStyle(WTColor.plum)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: winnerName)
    }

    private func spinButton(_ wheel: Wheel) -> some View {
        Button {
            spin(wheel)
        } label: {
            Label(animator.isSpinning ? "Spinning..." : "Spin the Wheel", systemImage: "dice.fill")
        }
        .buttonStyle(WTButtonStyle(background: WTColor.coral))
        .disabled(animator.isSpinning || wheel.participants.count < 2)
    }

    private func spin(_ wheel: Wheel) {
        winnerName = nil
        guard let winner = store.spin(wheel: wheel) else { return }
        guard let index = wheel.participants.firstIndex(where: { $0.id == winner.id }) else { return }
        animator.spin(winnerIndex: index, segmentCount: wheel.participants.count) {
            winnerName = winner.name
        }
    }

    // MARK: Participants

    private func participantList(_ wheel: Wheel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Participants")
                    .font(WTFont.heading(16))
                    .foregroundStyle(WTColor.ink)
                Spacer()
                Button {
                    if store.canAddParticipant(to: wheel) {
                        showAddParticipant = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(WTColor.sage)
                }
            }

            ForEach(Array(wheel.participants.enumerated()), id: \.element.id) { index, participant in
                HStack {
                    Circle()
                        .fill(WTColor.wheelPalette[index % WTColor.wheelPalette.count])
                        .frame(width: 10, height: 10)
                    Text(participant.name)
                        .font(WTFont.body(15))
                        .foregroundStyle(WTColor.ink)
                    Spacer()
                    Text(wheel.lastPickedID == participant.id ? "last turn" : "waiting \(participant.spinsSinceTurn)")
                        .font(WTFont.body(12))
                        .foregroundStyle(WTColor.ink.opacity(0.55))
                }
                .swipeActions {
                    Button(role: .destructive) {
                        store.removeParticipant(participant, from: wheel)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyParticipants: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(WTColor.sage)
            Text("Add at least two participants to spin this wheel.")
                .font(WTFont.body(15))
                .foregroundStyle(WTColor.ink.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

/// The colored pie-segment wheel itself, drawn with plain SwiftUI shapes (no images, no emoji).
private struct SpinWheelShape: View {
    let participants: [Participant]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                    segment(index: index, size: size)
                }
                Circle()
                    .fill(WTColor.cream)
                    .frame(width: size * 0.16, height: size * 0.16)
                Circle()
                    .stroke(WTColor.ink.opacity(0.15), lineWidth: 3)
            }
            .frame(width: size, height: size)
        }
    }

    private func segment(index: Int, size: CGFloat) -> some View {
        let count = max(participants.count, 1)
        let anglePerSegment = 360.0 / Double(count)
        let startAngle = Angle(degrees: Double(index) * anglePerSegment - 90)
        let endAngle = Angle(degrees: Double(index + 1) * anglePerSegment - 90)
        let color = WTColor.wheelPalette[index % WTColor.wheelPalette.count]
        let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)

        return ZStack {
            PieSlice(startAngle: startAngle, endAngle: endAngle)
                .fill(color)
            Text(participants[index].name)
                .font(WTFont.body(12))
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .offset(x: cos(midAngle.radians) * size * 0.32, y: sin(midAngle.radians) * size * 0.32)
        }
    }
}

private struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
