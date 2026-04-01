import Foundation

final class ThemeStore {
    private static let key = "appTheme"

    var theme: AppTheme {
        get {
            let stored = UserDefaults.standard.string(forKey: Self.key)
            return AppTheme.all.first { $0.name == stored } ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.name, forKey: Self.key)
        }
    }
}
