import SwiftUI

extension View {
    @ViewBuilder func modify<Content: View>(@ViewBuilder transform: (Self) -> Content) -> some View {
        transform(self)
    }
}

struct AppTheme: Equatable, Hashable {
    let name: String
    let displayName: String
    let accent: Color
    /// Empty means no gradient override — let the system background show through.
    let playerGradientColors: [Color]
    /// When true, FullPlayerView forces dark color scheme (needed when playerGradient is dark).
    let forceDarkPlayer: Bool
    /// App-level preferred color scheme. nil means follow system.
    let preferredColorScheme: ColorScheme?
    let miniPlayerTint: Color

    static let system = AppTheme(
        name: "system",
        displayName: "System",
        accent: .accentColor,
        playerGradientColors: [],
        forceDarkPlayer: false,
        preferredColorScheme: nil,
        miniPlayerTint: Color.primary.opacity(0.05)
    )

    static let midnight = AppTheme(
        name: "midnight",
        displayName: "Midnight",
        accent: Color(hue: 0.11, saturation: 0.85, brightness: 0.95),   // warm amber
        playerGradientColors: [
            Color(hue: 0.62, saturation: 0.35, brightness: 0.14),       // deep navy
            Color(hue: 0.62, saturation: 0.40, brightness: 0.07)        // near-black
        ],
        forceDarkPlayer: true,
        preferredColorScheme: .dark,
        miniPlayerTint: Color(hue: 0.62, saturation: 0.35, brightness: 0.14)
    )

    static let all: [AppTheme] = [.system, .midnight]

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.name == rhs.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
