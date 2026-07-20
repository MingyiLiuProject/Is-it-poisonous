import SwiftUI
import UIKit

enum AppTheme {
    static let forest = adaptive(
        light: UIColor(red: 0.12, green: 0.31, blue: 0.24, alpha: 1),
        dark: UIColor(red: 0.55, green: 0.82, blue: 0.67, alpha: 1)
    )
    static let forestFill = Color(red: 0.12, green: 0.31, blue: 0.24)
    static let moss = adaptive(
        light: UIColor(red: 0.42, green: 0.57, blue: 0.36, alpha: 1),
        dark: UIColor(red: 0.57, green: 0.75, blue: 0.49, alpha: 1)
    )
    static let cream = adaptive(
        light: UIColor(red: 0.97, green: 0.96, blue: 0.91, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.075, blue: 0.065, alpha: 1)
    )
    static let paper = adaptive(
        light: UIColor(red: 1.00, green: 0.99, blue: 0.96, alpha: 1),
        dark: UIColor(red: 0.105, green: 0.13, blue: 0.115, alpha: 1)
    )
    static let elevated = adaptive(
        light: UIColor.white,
        dark: UIColor(red: 0.15, green: 0.18, blue: 0.16, alpha: 1)
    )
    static let hairline = adaptive(
        light: UIColor.black.withAlphaComponent(0.07),
        dark: UIColor.white.withAlphaComponent(0.12)
    )
    static let danger = adaptive(
        light: UIColor(red: 0.78, green: 0.22, blue: 0.18, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.43, blue: 0.38, alpha: 1)
    )
    static let warning = adaptive(
        light: UIColor(red: 0.82, green: 0.49, blue: 0.08, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.72, blue: 0.28, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}
