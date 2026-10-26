import SwiftUI

/// Bluetooth puck scanner with live humidity and temperature, a sparkline, and the 60 percent alert.
struct PuckScannerView: View {
    @EnvironmentObject private var session: TriageSession
    @StateObject private var scanner = PuckScannerService()

    private var isScanning: Bool {
        if case .scanning = scanner.state { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerBanner()

                    if let latest = scanner.latest {
                        LiveReadingCard(reading: latest)
                        ToolCard(title: "Humidity, last \(scanner.history.count) readings") {
                            HumiditySparkline(readings: scanner.history)
                                .frame(height: 140)
                        }
                    } else {
                        ToolCard(title: "No puck connected") {
                            Text("Scan for a Bluetooth sensor that uses the standard Environmental Sensing Service, or start the simulated puck to see how the alert works.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                        }
                    }

                    ToolCard(title: scanner.state.label) {
                        HStack(spacing: 12) {
                            Button {
                                isScanning ? scanner.stopScanning() : scanner.startScanning()
                            } label: {
                                Label(isScanning ? "Stop scan" : "Scan", systemImage: isScanning ? "stop.circle" : "antenna.radiowaves.left.and.right")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.clinical)

                            Button {
                                scanner.state == .simulated ? scanner.stopSimulation() : scanner.startSimulation()
                            } label: {
                                Label(scanner.state == .simulated ? "Stop simulation" : "Simulated puck", systemImage: "cpu")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        if scanner.state == .simulated {
                            Button {
                                scanner.triggerSimulatedStorm()
                            } label: {
                                Label("Simulate water intrusion", systemImage: "cloud.rain.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(Theme.alert)
                        }

                        if case .connected = scanner.state {
                            Button("Disconnect", role: .destructive) { scanner.disconnect() }
                        }

                        if let error = scanner.lastError {
                            Text(error).font(.footnote).foregroundStyle(Theme.danger)
                        }
                    }

                    if !scanner.discovered.isEmpty {
                        ToolCard(title: "Nearby devices") {
                            ForEach(scanner.discovered) { puck in
                                Button {
                                    scanner.connect(to: puck)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(puck.name).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                                            Text(puck.advertisesEnvironmentalSensing ? "Environmental Sensing Service" : "No sensor service advertised")
                                                .font(.caption)
                                                .foregroundStyle(Theme.muted)
                                        }
                                        Spacer()
                                        Text("\(puck.rssi) dBm")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(Theme.muted)
                                    }
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            session.savePuckReadings(scanner.history)
                        } label: {
                            Label("Save readings to report", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.clinicalDeep)
                        .disabled(scanner.history.isEmpty)

                        Button("Clear", role: .destructive) { scanner.clearHistory() }
                            .buttonStyle(.bordered)
                            .disabled(scanner.history.isEmpty)
                    }

                    if let message = session.lastSavedMessage {
                        Text(message).font(.footnote).foregroundStyle(Theme.ok)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Humidity puck")
        }
    }
}

private struct LiveReadingCard: View {
    let reading: PuckReading

    private var tint: Color { reading.exceedsAlert ? Theme.alert : Theme.ok }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Humidity").font(.caption).foregroundStyle(Theme.muted)
                    Text(String(format: "%.0f%%", reading.humidityPercent))
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Temperature").font(.caption).foregroundStyle(Theme.muted)
                    Text(String(format: "%.0f °F", reading.temperatureFahrenheit))
                        .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
            }
            Text(reading.exceedsAlert
                 ? "Above 60 percent. The EPA says mold can start on wet materials within 24 to 48 hours. Run a dehumidifier and find the water source."
                 : "Within the EPA range. Keep it under 60 percent, ideally 30 to 50.")
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
            Text("\(reading.source) · updated \(reading.at.formatted(date: .omitted, time: .standard))")
                .font(.caption)
                .foregroundStyle(Theme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(tint.opacity(0.5)))
        .animation(.easeInOut(duration: 0.3), value: reading.exceedsAlert)
    }
}

/// Humidity over the last readings with the 60 percent alert line drawn across it.
struct HumiditySparkline: View {
    let readings: [PuckReading]

    private let minimum: Double = 20
    private let maximum: Double = 100

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 6
            let plotWidth = size.width - inset * 2
            let plotHeight = size.height - inset * 2

            func y(_ value: Double) -> CGFloat {
                let clamped = min(max(value, minimum), maximum)
                return inset + plotHeight * CGFloat(1 - (clamped - minimum) / (maximum - minimum))
            }

            // Alert line at 60 percent.
            var alertLine = Path()
            alertLine.move(to: CGPoint(x: inset, y: y(StructSenseConstants.humidityAlertPercent)))
            alertLine.addLine(to: CGPoint(x: inset + plotWidth, y: y(StructSenseConstants.humidityAlertPercent)))
            context.stroke(alertLine, with: .color(Theme.alert), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

            guard readings.count > 1 else { return }
            var line = Path()
            for (index, reading) in readings.enumerated() {
                let x = inset + plotWidth * CGFloat(index) / CGFloat(readings.count - 1)
                let point = CGPoint(x: x, y: y(reading.humidityPercent))
                if index == 0 { line.move(to: point) } else { line.addLine(to: point) }
            }
            context.stroke(line, with: .color(Theme.clinical), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            // Fill the part of the trace that sits above the alert line.
            var fill = line
            fill.addLine(to: CGPoint(x: inset + plotWidth, y: y(StructSenseConstants.humidityAlertPercent)))
            fill.addLine(to: CGPoint(x: inset, y: y(StructSenseConstants.humidityAlertPercent)))
            fill.closeSubpath()
            context.clip(to: Path(CGRect(x: 0, y: 0, width: size.width, height: y(StructSenseConstants.humidityAlertPercent))))
            context.fill(fill, with: .color(Theme.alert.opacity(0.25)))
        }
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel("Humidity trend")
    }
}
