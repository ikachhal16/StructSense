import SwiftUI

/// Two-capture acoustic workflow with a live loudness graph drawn in a Canvas.
struct AcousticTriageView: View {
    @EnvironmentObject private var session: TriageSession
    @StateObject private var viewModel = AcousticViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerBanner()

                    ToolCard(title: "How to measure") {
                        Text("Hold the phone flat against the wall with the speaker and microphone touching the surface. Capture a reference spot you know is dry on the same wall, then the suspect spot. Each capture plays a 40 to 100 Hz sweep for three seconds.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }

                    ToolCard(title: "Loudness over time") {
                        AcousticGraph(reference: viewModel.reference?.samples ?? [], suspect: viewModel.suspect?.samples ?? [], live: viewModel.isCapturing ? viewModel.liveSamples : [], livePhase: viewModel.phase)
                            .frame(height: 200)
                        HStack(spacing: 16) {
                            LegendSwatch(color: Theme.clinical, label: "Reference")
                            LegendSwatch(color: Theme.alert, label: "Suspect")
                            Spacer()
                            Text(viewModel.isCapturing ? String(format: "%.0f dBFS", viewModel.liveLevel) : " ")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.muted)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            viewModel.captureReference()
                        } label: {
                            Label(viewModel.phase == .capturingReference ? "Listening…" : "Capture reference", systemImage: "1.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.clinical)
                        .disabled(viewModel.isCapturing)

                        Button {
                            viewModel.captureSuspect()
                        } label: {
                            Label(viewModel.phase == .capturingSuspect ? "Listening…" : "Capture suspect", systemImage: "2.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.alert)
                        .disabled(!viewModel.canCaptureSuspect)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Theme.danger)
                    }

                    if let comparison = viewModel.comparison {
                        VerdictCard(comparison: comparison)
                        HStack {
                            Button("Save to report") {
                                session.saveAcoustic(comparison)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.clinicalDeep)
                            Button("Start over", role: .destructive) {
                                viewModel.reset()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let message = session.lastSavedMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Theme.ok)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Acoustic check")
        }
    }
}

private struct LegendSwatch: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(.caption).foregroundStyle(Theme.muted)
        }
    }
}

/// Draws reference and suspect loudness as two lines on a shared dB axis.
struct AcousticGraph: View {
    let reference: [Float]
    let suspect: [Float]
    let live: [Float]
    let livePhase: AcousticViewModel.Phase

    private let minDecibels: Float = -70
    private let maxDecibels: Float = 0
    private let expectedBins = Int(StructSenseConstants.acousticWindowSeconds * 10)

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 8
            let plotWidth = size.width - inset * 2
            let plotHeight = size.height - inset * 2

            // Gridlines every 10 dB.
            var gridline = minDecibels
            while gridline <= maxDecibels {
                let y = yPosition(for: gridline, plotHeight: plotHeight, inset: inset)
                var path = Path()
                path.move(to: CGPoint(x: inset, y: y))
                path.addLine(to: CGPoint(x: inset + plotWidth, y: y))
                context.stroke(path, with: .color(Color.secondary.opacity(0.18)), lineWidth: 1)
                gridline += 10
            }

            func draw(_ samples: [Float], color: Color, dashed: Bool) {
                guard samples.count > 1 else { return }
                var path = Path()
                for (index, sample) in samples.enumerated() {
                    let x = inset + plotWidth * CGFloat(index) / CGFloat(max(expectedBins - 1, 1))
                    let y = yPosition(for: sample, plotHeight: plotHeight, inset: inset)
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                let style = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: dashed ? [5, 4] : [])
                context.stroke(path, with: .color(color), style: style)
            }

            draw(reference, color: Theme.clinical, dashed: false)
            draw(suspect, color: Theme.alert, dashed: false)
            if !live.isEmpty {
                draw(live, color: livePhase == .capturingReference ? Theme.clinical : Theme.alert, dashed: true)
            }

            if reference.isEmpty && suspect.isEmpty && live.isEmpty {
                let text = Text("Capture a reference spot to begin").font(.subheadline).foregroundColor(.secondary)
                context.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
            }
        }
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Loudness graph")
    }

    private func yPosition(for decibels: Float, plotHeight: CGFloat, inset: CGFloat) -> CGFloat {
        let clamped = min(max(decibels, minDecibels), maxDecibels)
        let fraction = CGFloat((clamped - minDecibels) / (maxDecibels - minDecibels))
        return inset + plotHeight * (1 - fraction)
    }
}

private struct VerdictCard: View {
    let comparison: AcousticComparison

    private var tint: Color {
        switch comparison.verdict {
        case .likelyDry: return Theme.ok
        case .suspectSaturated: return Theme.alert
        case .inconclusive: return Theme.muted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(comparison.verdict.rawValue)
                    .font(.title3.bold())
                    .foregroundStyle(tint)
                Spacer()
                Text("\(Int(comparison.confidence * 100))% confidence")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            Text(comparison.verdict.guidance)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 18) {
                Metric(label: "Reference", value: String(format: "%.1f dBFS", comparison.reference.meanDecibels))
                Metric(label: "Suspect", value: String(format: "%.1f dBFS", comparison.suspect.meanDecibels))
                Metric(label: "Delta", value: String(format: "%+.1f dB", comparison.absorptionDelta))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.5)))
    }
}

struct Metric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Theme.muted)
            Text(value).font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(Theme.ink)
        }
    }
}
