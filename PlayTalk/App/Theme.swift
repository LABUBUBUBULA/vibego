import UIKit

enum Theme {
    // MARK: - Colors (matching GameMic Android dark theme)
    enum Colors {
        static let primaryYellow = UIColor(hex: "#FFD500")
        static let primaryGreen = UIColor(hex: "#4CAF50")
        static let darkBackground = UIColor(hex: "#1C1C28")
        static let darkerBackground = UIColor(hex: "#16161E")
        static let cardBackground = UIColor(hex: "#21222E")
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(hex: "#999999")
        static let separator = UIColor(hex: "#2A2A3A")
        static let tabBarBackground = UIColor(hex: "#16161E")
    }

    // MARK: - Fonts
    enum Fonts {
        static func bold(_ size: CGFloat) -> UIFont {
            return UIFont.boldSystemFont(ofSize: size)
        }

        static func regular(_ size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size)
        }

        static func medium(_ size: CGFloat) -> UIFont {
            return UIFont.systemFont(ofSize: size, weight: .medium)
        }
    }

    // MARK: - Dimensions
    enum Dimensions {
        static let cornerRadius: CGFloat = 12
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let avatarSize: CGFloat = 48
        static let tabBarHeight: CGFloat = 83
    }
}

// MARK: - UIColor Hex Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
