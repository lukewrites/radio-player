import SwiftUI

/// Generates a deterministic programmatic cover art from a show title.
/// Used as fallback when no archive.org thumbnail is available.
struct StylizedCoverView: View {
    let title: String
    var size: CGFloat = 120

    private var gradient: LinearGradient {
        let hue = Double(abs(title.hashValue) % 360) / 360.0
        let color1 = Color(hue: hue, saturation: 0.6, brightness: 0.7)
        let color2 = Color(hue: (hue + 0.15).truncatingRemainder(dividingBy: 1.0),
                           saturation: 0.7, brightness: 0.5)
        return LinearGradient(colors: [color1, color2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var initials: String {
        let words = title.split(separator: " ").prefix(2)
        return words.compactMap { $0.first.map(String.init) }.joined()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(gradient)

            VStack(spacing: size * 0.06) {
                Image(systemName: "radio")
                    .font(.system(size: size * 0.28, weight: .light))
                    .foregroundStyle(.white.opacity(0.6))

                Text(initials.uppercased())
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 16) {
        StylizedCoverView(title: "Dragnet", size: 120)
        StylizedCoverView(title: "The Shadow", size: 120)
        StylizedCoverView(title: "Suspense", size: 120)
    }
    .padding()
}
