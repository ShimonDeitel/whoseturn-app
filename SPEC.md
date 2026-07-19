# Whoseturn - Chore Wheel — SPEC

Batch 2, app #1. Native iOS 17+ SwiftUI app. Bundle id `com.shimondeitel.whoseturn`.

## What it does

Households create one or more "wheels" — named rotations like "Dishes", "Trash", "Who picks the
movie" — add participants to each, and spin a physical-feeling wheel to fairly decide whose turn
it is next.

## Fairness algorithm

Implemented in `iOS/Whoseturn/FairnessEngine.swift`, a pure Swift file (Foundation only — no
SwiftUI/UIKit imports) so it is fully unit-testable with plain values.

Each `Participant` tracks `spinsSinceTurn: Int` — how many completed spins have happened since
they last won. The engine has two rules:

1. **Never repeat immediately.** If more than one participant exists, whoever won the previous
   spin is excluded from the candidate pool for the next spin (`selectNext(lastPickedID:)`).
2. **Weight by wait time.** Among the remaining candidates, each participant's selection weight
   is:

   ```
   weight(p) = spinsSinceTurn(p) + 1
   ```

   The `+1` guarantees every participant always has a strictly positive weight — even someone who
   won last spin (whose `spinsSinceTurn` just reset to 0) still has weight 1, so they could
   theoretically be picked again once rule 1 stops excluding them (i.e. once someone else has won
   in between). A participant who has waited N spins since their last turn is N+1 times as likely
   to be picked as someone who won on the immediately preceding spin. This makes the wheel
   self-balancing over many spins — nobody can be perpetually unlucky — while preserving genuine
   randomness rather than hard-coded round robin, which would feel mechanical and defeats the
   point of "spinning a wheel."

   Selection itself is a standard weighted-random draw: candidate weights are summed, a caller-
   supplied `randomValue` in `[0, 1)` is scaled by the total, and the participant whose cumulative
   weight bucket contains that scaled value wins. Passing an explicit `randomValue` (rather than
   drawing internally) is what makes the engine deterministic and testable; the app's `WhoseturnStore.spin(wheel:)`
   defaults it to `Double.random(in: 0..<1)` at the call site.

3. **Applying a spin.** `applySpin(participants:winnerID:)` resets the winner's `spinsSinceTurn`
   to 0 and increments everyone else's by 1.

## Data model

`Models.swift`:

- `Participant` (in `FairnessEngine.swift`): `id`, `name`, `spinsSinceTurn`.
- `Wheel`: `id`, `name`, `participants: [Participant]`, `lastPickedID`, `iconSymbolName` (Pro
  customization), `spinHistory: [SpinRecord]` (Pro only — populated only when the user is Pro, so
  Free users never accumulate history data they can't see).
- `SpinRecord`: `id`, `participantID`, `participantName`, `date` — one row per completed spin,
  used for the Pro stats screen.
- `WhoseturnData`: top-level `{ wheels: [Wheel] }`, the entire persisted document.

## Persistence

`WhoseturnStore` (in `Services/WhoseturnStore.swift`) is a `@MainActor` `ObservableObject` that
holds `WhoseturnData` and writes it as JSON to a single file in the app's Documents directory via
`FileManager`, using `Codable`. No network calls, no CloudKit, no iCloud entitlements — the
`.entitlements` file is empty (`<dict/>`), matching the Handoff reference project's pattern.
Everything lives on-device only, which is also disclosed in the privacy policy.

## Monetization

StoreKit 2 auto-renewable monthly subscription, product id
`com.shimondeitel.whoseturn.pro.monthly`, managed by `EntitlementsStore`
(`Services/EntitlementsStore.swift`), following the same "derive Pro live from
`Transaction.currentEntitlements`, never persist it as truth" pattern used in the Vantage
reference project.

| | Free | Pro |
|---|---|---|
| Wheels | 1 | Unlimited |
| Participants per wheel | 4 | Unlimited |
| Custom wheel icon/category | No | Yes |
| Spin history & stats | No | Yes |

`FreeTierLimits` in `Models.swift` holds the free-tier caps; `WhoseturnStore.canAddWheel` /
`canAddParticipant(to:)` enforce them, and the UI routes blocked actions to `PaywallView`.

## Tech choices

- SwiftUI, iOS 17 deployment target, no third-party dependencies.
- `xcodegen` for project generation (`iOS/project.yml`).
- Wheel spin animation and haptics are driven by `Services/SpinAnimator.swift`, a small
  `@MainActor` `ObservableObject` that manually steps rotation each frame via `Timer` using a cubic
  ease-out curve (long deceleration tail), firing a light `UIImpactFeedbackGenerator` tick every
  time the pointer crosses a segment boundary and a `UINotificationFeedbackGenerator` success
  haptic when the wheel settles — chosen over a plain SwiftUI `.animation()` modifier because that
  API can't be queried mid-flight to detect segment-boundary crossings for the tick haptics.
- Keyboard dismissal on every text-entry screen (`AddWheelSheet`, `AddParticipantSheet`) is a real
  tap gesture: `KeyboardDismissBackground` (in `Design.swift`) sits behind the form content and
  calls `UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder)...)` on tap,
  independent of `.scrollDismissesKeyboard`.
- Bespoke warm/playful palette (marigold, coral, sage, plum, cream) defined in `Design.swift` —
  explicitly not the black/white/blue combo used by an earlier, deprecated app-factory template.
  Icons are SF Symbols or plain SwiftUI `Shape`s only; no emoji anywhere in code, UI, or copy.

## Deviations from the brief

- None of substance. The brief's "weighted-deceleration physics animation" is implemented as a
  manually time-stepped cubic ease-out rather than a full spring/physics simulation — this keeps
  the tick-haptic timing exactly synchronized with the visible rotation, which a physics engine
  black box would make harder to guarantee.
