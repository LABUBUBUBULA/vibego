import UIKit

enum Theme {
    // MARK: - Colors (深青冷酷风)
    enum Colors {
        static let primaryPurple = UIColor(hex: "#00E5A0")
        static let accentCyan = UIColor(hex: "#00BCD4")
        static let darkBackground = UIColor(hex: "#0B1A1A")
        static let darkerBackground = UIColor(hex: "#071212")
        static let cardBackground = UIColor(hex: "#122626")
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(hex: "#8AABAB")
        static let separator = UIColor(hex: "#1E3838")
        static let tabBarBackground = UIColor(hex: "#071212")
        static let splashBackground = UIColor(hex: "#050E0E")
        static let profileBackground = UIColor(hex: "#0E2020")
        static let textFieldBorder = UIColor(hex: "#1E3838")

        // 兼容旧引用
        static let primaryYellow = primaryPurple
        static let primaryGreen = accentCyan
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
