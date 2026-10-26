import SwiftUI

/// Tab shell. Each tool lives on its own tab; the report tab collects what the tools saved.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Triage", systemImage: "house.fill") }
            AcousticTriageView()
                .tabItem { Label("Acoustic", systemImage: "waveform") }
            MagnetometerView()
                .tabItem { Label("Magnetic", systemImage: "dot.radiowaves.left.and.right") }
            PuckScannerView()
                .tabItem { Label("Puck", systemImage: "humidity.fill") }
            ReportView()
                .tabItem { Label("Report", systemImage: "doc.text.fill") }
        }
        .tint(Theme.clinical)
    }
}

/// Shared palette, matching the web app.
enum Theme {
    static let clinical = Color(red: 2 / 255, green: 132 / 255, blue: 199 / 255)
    static let clinicalDeep = Color(red: 7 / 255, green: 89 / 255, blue: 133 / 255)
    static let clinicalSoft = Color(red: 224 / 255, green: 242 / 255, blue: 254 / 255)
    static let alert = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    static let alertSoft = Color(red: 254 / 255, green: 243 / 255, blue: 199 / 255)
    static let danger = Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
    static let ok = Color(red: 21 / 255, green: 128 / 255, blue: 61 / 255)
    static let ink = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
    static let muted = Color(red: 71 / 255, green: 85 / 255, blue: 105 / 255)
}

/// The transparency disclaimer, used on every tab.
struct DisclaimerBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.alert)
                .accessibilityHidden(true)
            Text(StructSenseConstants.disclaimer)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.alertSoft, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.alert.opacity(0.6)))
    }
}

/// Card wrapper used across the tools.
struct ToolCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.ink)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
