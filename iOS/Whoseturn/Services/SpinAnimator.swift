import Foundation
import Combine
import UIKit

/// Drives the wheel's spin animation frame-by-frame so we can fire a haptic "tick" every time the
/// pointer crosses a segment boundary, and a heavier "clunk" when it finally settles. Kept
/// separate from the view so the physics/timing logic isn't tangled with SwiftUI layout.
@MainActor
final class SpinAnimator: ObservableObject {
    @Published private(set) var rotationDegrees: Double = 0
    @Published private(set) var isSpinning = false

    private var displayTimer: Timer?
    private var startRotation: Double = 0
    private var endRotation: Double = 0
    private var startTime: CFTimeInterval = 0
    private var duration: CFTimeInterval = 3.2
    private var lastSegmentIndex: Int = -1
    private var segmentCount: Int = 0

    private let tickGenerator = UIImpactFeedbackGenerator(style: .light)
    private let settleGenerator = UINotificationFeedbackGenerator()

    /// Starts a weighted-deceleration spin that ends with `winnerIndex`'s segment centered under
    /// the top pointer. `onSettle` fires once the animation completes.
    func spin(winnerIndex: Int, segmentCount: Int, onSettle: @escaping () -> Void) {
        guard segmentCount > 0 else { onSettle(); return }
        self.segmentCount = segmentCount
        let anglePerSegment = 360.0 / Double(segmentCount)
        let segmentCenter = Double(winnerIndex) * anglePerSegment + anglePerSegment / 2
        // Rotation needed so that segmentCenter lands at the top (0 degrees).
        let targetOffset = (360 - segmentCenter).truncatingRemainder(dividingBy: 360)

        let currentBase = rotationDegrees.truncatingRemainder(dividingBy: 360)
        let extraFullSpins = 5.0
        var target = rotationDegrees - currentBase + extraFullSpins * 360 + targetOffset
        while target <= rotationDegrees {
            target += 360
        }

        startRotation = rotationDegrees
        endRotation = target
        startTime = CACurrentMediaTime()
        duration = 3.2
        lastSegmentIndex = currentSegmentIndex(for: rotationDegrees, anglePerSegment: anglePerSegment)
        isSpinning = true
        tickGenerator.prepare()

        displayTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(anglePerSegment: anglePerSegment, onSettle: onSettle)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        displayTimer = timer
    }

    private func tick(anglePerSegment: Double, onSettle: @escaping () -> Void) {
        let elapsed = CACurrentMediaTime() - startTime
        let t = min(elapsed / duration, 1.0)
        // Cubic ease-out: fast start, long deceleration tail, like a real wheel losing momentum.
        let eased = 1 - pow(1 - t, 3)
        rotationDegrees = startRotation + (endRotation - startRotation) * eased

        let segment = currentSegmentIndex(for: rotationDegrees, anglePerSegment: anglePerSegment)
        if segment != lastSegmentIndex {
            lastSegmentIndex = segment
            tickGenerator.impactOccurred(intensity: max(0.3, 1 - t))
        }

        if t >= 1.0 {
            displayTimer?.invalidate()
            displayTimer = nil
            isSpinning = false
            settleGenerator.notificationOccurred(.success)
            onSettle()
        }
    }

    private func currentSegmentIndex(for rotation: Double, anglePerSegment: Double) -> Int {
        guard segmentCount > 0, anglePerSegment > 0 else { return 0 }
        // The pointer is fixed at the top; as the wheel rotates clockwise by `rotation` degrees,
        // the segment currently under the pointer is the one at angle -rotation (mod 360).
        let pointerAngleOnWheel = (360 - rotation.truncatingRemainder(dividingBy: 360))
            .truncatingRemainder(dividingBy: 360)
        return Int(pointerAngleOnWheel / anglePerSegment) % max(segmentCount, 1)
    }
}
