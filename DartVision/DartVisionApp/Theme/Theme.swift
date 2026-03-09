import SwiftUI

/// Centralized design tokens for the app
enum Theme {
    // MARK: - Colors
    static let primary      = Color(hex: "#5C56BA")
    static let secondary    = Color(hex: "#836B6B")
    static let secondaryDark = Color(hex: "#614848")
    static let danger       = Color(hex: "#EE3D3D")
    static let textPrimary  = Color(hex: "#090C3B")
    static let textSecondary = Color(hex: "#999999")
    static let disabled     = Color(hex: "#CCCCCC")
    static let background   = Color.white
    static let surface      = Color(hex: "#F8F8FA")
    static let border       = Color(hex: "#E0E0E0")
}

// MARK: - Color from Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
