import UIKit

struct AppColors {
    static let primary = UIColor(red: 0.07, green: 0.30, blue: 0.22, alpha: 1)
    static let primaryDark = UIColor(red: 0.04, green: 0.20, blue: 0.15, alpha: 1)
    static let sidebarBg = UIColor(red: 0.05, green: 0.22, blue: 0.18, alpha: 1)
    static let accent = UIColor(red: 0.95, green: 0.78, blue: 0.22, alpha: 1)
    static let accentLight = UIColor(red: 0.98, green: 0.90, blue: 0.55, alpha: 1)
    static let success = UIColor(red: 0.18, green: 0.60, blue: 0.35, alpha: 1)
    static let danger = UIColor.systemRed
    static let cardBg = UIColor.secondarySystemGroupedBackground
    static let background = UIColor.systemBackground
    static let textPrimary = UIColor.label
    static let textSecondary = UIColor.secondaryLabel
    static let textTertiary = UIColor.tertiaryLabel
    static let shadowColor = UIColor.black.cgColor
    static let shadowOpacity: Float = 0.06
    static let cardCornerRadius: CGFloat = 14
    static let buttonCornerRadius: CGFloat = 12
}

struct AppFonts {
    static func title() -> UIFont { .systemFont(ofSize: 28, weight: .bold) }
    static func heading() -> UIFont { .systemFont(ofSize: 17, weight: .semibold) }
    static func body() -> UIFont { .systemFont(ofSize: 14, weight: .regular) }
    static func caption() -> UIFont { .systemFont(ofSize: 12, weight: .regular) }
    static func small() -> UIFont { .systemFont(ofSize: 10, weight: .medium) }
    static func value() -> UIFont { .systemFont(ofSize: 22, weight: .bold) }
}
