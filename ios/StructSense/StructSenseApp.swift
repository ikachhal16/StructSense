import SwiftUI

/// Entry point. A single `TriageSession` is shared across every tab so that
/// readings from the acoustic, magnetic and puck tools accumulate into one report.
@main
struct StructSenseApp: App {
    @StateObject private var session = TriageSession()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}
