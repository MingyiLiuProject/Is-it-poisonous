import SwiftUI

enum AppMotion {
    static func responsive(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.16)
            : .spring(response: 0.34, dampingFraction: 1.0)
    }

    static func emphasized(reduceMotion: Bool) -> Animation {
        reduceMotion
            ? .easeOut(duration: 0.18)
            : .spring(response: 0.38, dampingFraction: 0.86)
    }
}

struct AppCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                AppTheme.paper,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.hairline)
            }
            .shadow(color: Color.black.opacity(0.055), radius: 14, y: 6)
    }
}

extension View {
    func appCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius))
    }
}

struct PressableCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(
                AppMotion.responsive(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}

struct PressableControlButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(
                AppMotion.responsive(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}
