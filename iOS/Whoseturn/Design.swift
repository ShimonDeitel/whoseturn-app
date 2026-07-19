import SwiftUI

/// Whoseturn's bespoke warm, playful palette. Deliberately avoids the black/white/blue combo
/// used elsewhere in the app factory — this app leans into marigold, coral, sage and plum
/// against a warm cream background.
enum WTColor {
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.92)
    static let ink = Color(red: 0.22, green: 0.17, blue: 0.14)
    static let marigold = Color(red: 0.96, green: 0.64, blue: 0.19)
    static let coral = Color(red: 0.95, green: 0.42, blue: 0.30)
    static let sage = Color(red: 0.44, green: 0.64, blue: 0.49)
    static let plum = Color(red: 0.55, green: 0.37, blue: 0.51)
    static let sand = Color(red: 0.93, green: 0.87, blue: 0.75)

    /// Cycled per-participant colors for wheel segments.
    static let wheelPalette: [Color] = [marigold, coral, sage, plum,
                                        Color(red: 0.85, green: 0.55, blue: 0.25),
                                        Color(red: 0.80, green: 0.33, blue: 0.42)]
}

enum WTFont {
    static func title(_ size: CGFloat = 28) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func heading(_ size: CGFloat = 20) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static func body(_ size: CGFloat = 16) -> Font { .system(size: size, weight: .regular, design: .rounded) }
}

/// Rounded, warm button style shared across the app.
struct WTButtonStyle: ButtonStyle {
    var background: Color = WTColor.coral
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WTFont.heading(17))
            .foregroundStyle(foreground)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A background view that dismisses the keyboard on tap-outside. Placed behind form content so
/// taps that land anywhere except an active control resign the responder.
struct KeyboardDismissBackground: View {
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}

extension View {
    /// Wraps the view with a full-size tap-to-dismiss-keyboard background. Use on any screen
    /// with a text field.
    func dismissesKeyboardOnTap() -> some View {
        self.background(KeyboardDismissBackground())
    }
}
