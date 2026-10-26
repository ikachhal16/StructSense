import SwiftUI

/// Collects everything the tools saved and hands it to the share sheet as plain text.
struct ReportView: View {
    @EnvironmentObject private var session: TriageSession

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerBanner()

                    if session.report.isEmpty {
                        ToolCard(title: "Nothing saved yet") {
                            Text("Run the magnetic sweep, acoustic check and humidity puck, then tap Save on each. Everything lands here as one report you can send to an inspector, your insurer or FEMA.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                        }
                    }

                    ToolCard(title: "Notes") {
                        TextEditor(text: $session.report.notes)
                            .frame(minHeight: 90)
                            .font(.body)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                        Text("Where the water line was, what it smells like, what you have already removed.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }

                    ToolCard(title: "Report preview") {
                        Text(session.report.summaryText)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(Theme.ink)
                            .textSelection(.enabled)
                    }

                    HStack(spacing: 12) {
                        ShareLink(item: session.report.summaryText, subject: Text("StructSense triage report"), message: Text("Preliminary triage from StructSense")) {
                            Label("Share report", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.clinical)

                        Button(role: .destructive) {
                            session.reset()
                        } label: {
                            Label("New session", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Report")
        }
    }
}
