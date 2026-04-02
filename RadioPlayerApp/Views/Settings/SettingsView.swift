import SwiftUI

struct SettingsView: View {
    @Binding var currentTheme: AppTheme

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    Picker("Theme", selection: $currentTheme) {
                        ForEach(AppTheme.all, id: \.name) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Credits") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("All audio is hosted by the Internet Archive, a non-profit digital library preserving millions of free cultural works.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Link("Visit archive.org", destination: URL(string: "https://archive.org")!)
                            .font(.footnote)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Show catalogues are curated by the Old Time Radio Researchers Group (OTRR), who have painstakingly identified, dated, and restored thousands of classic radio episodes.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Link("Visit otrr.org", destination: URL(string: "https://otrr.org")!)
                            .font(.footnote)
                    }
                    .padding(.vertical, 4)
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
