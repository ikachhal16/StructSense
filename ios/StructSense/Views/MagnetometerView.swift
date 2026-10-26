import SwiftUI

/// Live field vector, a green-to-red indicator, and the anomaly log.
struct MagnetometerView: View {
    @EnvironmentObject private var session: TriageSession
    @StateObject private var service = MagnetometerService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerBanner()

                    ToolCard(title: "How to sweep") {
                        Text("Hold the phone flat on an empty part of the wall and tap Calibrate. Then slide it slowly across the surface. The indicator turns red when the field jumps, which usually means a steel stud, nail plate, screw line or iron pipe is behind the drywall.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }

                    StructureIndicator(zScore: service.zScore, isOverStructure: service.isOverStructure, isCalibrating: service.isCalibrating)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)

                    ToolCard(title: "Live field") {
                        HStack(spacing: 18) {
                            Metric(label: "x", value: String(format: "%.1f µT", service.latest.x))
                            Metric(label: "y", value: String(format: "%.1f µT", service.latest.y))
                            Metric(label: "z", value: String(format: "%.1f µT", service.latest.z))
                            Metric(label: "Magnitude", value: String(format: "%.1f µT", service.smoothedMagnitude))
                        }
                        Divider()
                        HStack(spacing: 18) {
                            Metric(label: "Baseline", value: String(format: "%.1f µT", service.baselineMagnitude))
                            Metric(label: "Noise", value: String(format: "±%.1f µT", service.baselineDeviation))
                            Metric(label: "Deviation", value: String(format: "%.1f σ", service.zScore))
                        }
                        Text(service.accuracyDescription)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }

                    HStack(spacing: 12) {
                        Button {
                            service.recalibrate()
                        } label: {
                            Label(service.isCalibrating ? "Calibrating…" : "Calibrate on empty wall", systemImage: "scope")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.clinical)

                        Button {
                            session.saveAnomalies(service.anomalies)
                        } label: {
                            Label("Save \(service.anomalies.count)", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(service.anomalies.isEmpty)
                    }

                    ToolCard(title: "Anomalies this sweep") {
                        if service.anomalies.isEmpty {
                            Text("None yet. Spikes above \(Int(MagnetometerService.zScoreThreshold)) standard deviations or \(Int(MagnetometerService.absoluteDeltaThreshold)) µT from the baseline are logged here.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                        } else {
                            ForEach(service.anomalies.suffix(8).reversed()) { anomaly in
                                HStack {
                                    Text(anomaly.at, style: .time)
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(Theme.muted)
                                    Spacer()
                                    Text(String(format: "%.1f µT  (%+.1f σ)", anomaly.magnitude, anomaly.zScore))
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(Theme.ink)
                                }
                            }
                            Button("Clear log", role: .destructive) { service.clearAnomalies() }
                                .font(.footnote)
                        }
                    }

                    if !service.isAvailable {
                        Text("This device does not expose a magnetometer, so the sweep cannot run here.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.danger)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Magnetic sweep")
        }
        .onAppear { service.start() }
        .onDisappear { service.stop() }
    }
}

/// Circle that blends from green to red as the field departs from baseline.
struct StructureIndicator: View {
    let zScore: Double
    let isOverStructure: Bool
    let isCalibrating: Bool

    private var intensity: Double {
        // 0 at baseline, 1 at the spike threshold and beyond.
        min(1, max(0, abs(zScore) / MagnetometerService.zScoreThreshold))
    }

    private var fill: Color {
        // Linear blend green -> amber -> red keeps the midpoint readable for colour-blind users.
        let green = (r: 21.0, g: 128.0, b: 61.0)
        let amber = (r: 245.0, g: 158.0, b: 11.0)
        let red = (r: 220.0, g: 38.0, b: 38.0)
        let t = intensity
        let (from, to, local) = t < 0.5 ? (green, amber, t * 2) : (amber, red, (t - 0.5) * 2)
        return Color(
            red: (from.r + (to.r - from.r) * local) / 255,
            green: (from.g + (to.g - from.g) * local) / 255,
            blue: (from.b + (to.b - from.b) * local) / 255
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fill.opacity(0.18))
                .scaleEffect(1 + intensity * 0.12)
            Circle()
                .fill(fill)
                .frame(width: 140, height: 140)
                .shadow(color: fill.opacity(0.5), radius: isOverStructure ? 24 : 6)
            VStack(spacing: 4) {
                Image(systemName: isCalibrating ? "scope" : (isOverStructure ? "exclamationmark.triangle.fill" : "checkmark"))
                    .font(.largeTitle.bold())
                Text(isCalibrating ? "Calibrating" : (isOverStructure ? "Metal detected" : "Clear"))
                    .font(.headline)
            }
            .foregroundStyle(.white)
        }
        .animation(.easeOut(duration: 0.15), value: intensity)
        .accessibilityLabel(isOverStructure ? "Metal detected behind wall" : "No metal detected")
    }
}
