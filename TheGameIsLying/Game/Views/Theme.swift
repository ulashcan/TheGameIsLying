import SwiftUI

enum Theme {
    static let bg = Color(red: 0.04, green: 0.04, blue: 0.045)
    static let red = Color(red: 1.0, green: 0.18, blue: 0.18)
    static let blue = Color(red: 0.16, green: 0.42, blue: 1.0)
    static let white = Color.white
    static let muted = Color.white.opacity(0.55)
    static let door = Color(red: 0.12, green: 0.12, blue: 0.13)

    static func fill(for hue: ButtonHue) -> Color {
        switch hue {
        case .red: return red
        case .blue: return blue
        case .green: return Color(red: 0.12, green: 0.78, blue: 0.36)
        case .white: return Color.white
        case .black: return Color.black
        case .gray: return Color(white: 0.28)
        }
    }

    static func foreground(for hue: ButtonHue) -> Color {
        switch hue {
        case .white: return bg
        default: return .white
        }
    }
}
