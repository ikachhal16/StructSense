import Foundation

/// Text and thresholds that every screen shares.
enum StructSenseConstants {
    /// Required transparency disclaimer. Shown on the home tab, every tool and every exported report.
    static let disclaimer = "StructSense acts as a preliminary structural triage tool. It does not replace a licensed professional structural engineer."

    /// EPA guidance: keep indoor relative humidity below 60 percent, ideally 30 to 50 percent.
    static let humidityAlertPercent: Double = 60
    static let humidityIdealUpperPercent: Double = 50

    /// Duration of each acoustic capture window.
    static let acousticWindowSeconds: TimeInterval = 3
}

// MARK: - Acoustic triage

/// Outcome of comparing a suspect wall section against a known-dry reference spot.
enum MoistureVerdict: String, Codable {
    case likelyDry = "Dry or hollow cavity"
    case suspectSaturated = "Possible saturated drywall"
    case inconclusive = "Inconclusive, measure again"

    var guidance: String {
        switch self {
        case .likelyDry:
            return "The suspect spot reflects the tone about as well as your reference. No acoustic sign of trapped water."
        case .suspectSaturated:
            return "The suspect spot absorbs noticeably more of the tone than your reference. Wet drywall and insulation damp sound. Check it with a pin moisture meter or a licensed inspector."
        case .inconclusive:
            return "The difference is inside the noise band. Hold the phone flat against the wall, keep the room quiet and measure both spots again."
        }
    }
}

/// One three-second capture. Samples are average loudness per 100 ms bin, in dBFS.
struct AcousticMeasurement: Codable, Identifiable {
    let id: UUID
    let takenAt: Date
    let label: String
    let samples: [Float]

    init(label: String, samples: [Float]) {
        self.id = UUID()
        self.takenAt = Date()
        self.label = label
        self.samples = samples
    }

    /// Mean loudness after the first 300 ms, so the speaker ramp-up is excluded.
    var meanDecibels: Float {
        let settled = Array(samples.dropFirst(3))
        guard !settled.isEmpty else { return samples.isEmpty ? -120 : samples.reduce(0, +) / Float(samples.count) }
        return settled.reduce(0, +) / Float(settled.count)
    }

    /// Loudness spread. A large spread means room noise leaked into the capture.
    var standardDeviation: Float {
        let settled = Array(samples.dropFirst(3))
        guard settled.count > 1 else { return 0 }
        let mean = meanDecibels
        let variance = settled.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Float(settled.count - 1)
        return variance.squareRoot()
    }
}

/// Reference-versus-suspect comparison with a plain-language verdict.
struct AcousticComparison: Codable {
    let reference: AcousticMeasurement
    let suspect: AcousticMeasurement
    /// Suspect mean minus reference mean, in dB. Negative means the suspect spot absorbed more.
    let absorptionDelta: Float
    let verdict: MoistureVerdict
    /// 0 to 1. Grows with the size of the delta and shrinks with noisy captures.
    let confidence: Double
}

// MARK: - Magnetometer

/// A magnetic field spike that stood out from the rolling baseline.
struct MagneticAnomaly: Codable, Identifiable {
    let id: UUID
    let at: Date
    /// Field magnitude in microtesla at the spike.
    let magnitude: Double
    /// Rolling baseline magnitude in microtesla before the spike.
    let baseline: Double
    /// How many baseline standard deviations the spike reached.
    let zScore: Double

    init(magnitude: Double, baseline: Double, zScore: Double) {
        self.id = UUID()
        self.at = Date()
        self.magnitude = magnitude
        self.baseline = baseline
        self.zScore = zScore
    }
}

// MARK: - Humidity puck

/// One environmental reading from a Bluetooth puck or the simulated puck.
struct PuckReading: Codable, Identifiable {
    let id: UUID
    let at: Date
    let humidityPercent: Double
    let temperatureFahrenheit: Double
    /// Peripheral name, or "Simulated puck".
    let source: String

    init(humidityPercent: Double, temperatureFahrenheit: Double, source: String) {
        self.id = UUID()
        self.at = Date()
        self.humidityPercent = humidityPercent
        self.temperatureFahrenheit = temperatureFahrenheit
        self.source = source
    }

    var exceedsAlert: Bool { humidityPercent >= StructSenseConstants.humidityAlertPercent }
}

// MARK: - Report

/// Everything gathered in one triage session, ready to share with an inspector or insurer.
struct TriageReport: Codable {
    var createdAt: Date = Date()
    var roomLabel: String = ""
    var acoustic: AcousticComparison?
    var anomalies: [MagneticAnomaly] = []
    var puckReadings: [PuckReading] = []
    var notes: String = ""

    var isEmpty: Bool { acoustic == nil && anomalies.isEmpty && puckReadings.isEmpty && notes.isEmpty }

    /// Plain-text summary used by the share sheet.
    var summaryText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines: [String] = []
        lines.append("StructSense triage report")
        lines.append("Created: \(formatter.string(from: createdAt))")
        lines.append("Location: \(roomLabel.isEmpty ? "Not labelled" : roomLabel)")
        lines.append("")

        if let acoustic {
            lines.append("Acoustic check")
            lines.append(String(format: "  Reference mean: %.1f dBFS", acoustic.reference.meanDecibels))
            lines.append(String(format: "  Suspect mean:   %.1f dBFS", acoustic.suspect.meanDecibels))
            lines.append(String(format: "  Absorption delta: %+.1f dB", acoustic.absorptionDelta))
            lines.append("  Verdict: \(acoustic.verdict.rawValue) (confidence \(Int(acoustic.confidence * 100))%)")
            lines.append("")
        }

        lines.append("Magnetic anomalies: \(anomalies.count)")
        for anomaly in anomalies.prefix(20) {
            lines.append(String(format: "  %@  %.1f uT vs baseline %.1f uT (z = %.1f)", formatter.string(from: anomaly.at), anomaly.magnitude, anomaly.baseline, anomaly.zScore))
        }
        lines.append("")

        if let latest = puckReadings.last {
            let peak = puckReadings.map(\.humidityPercent).max() ?? latest.humidityPercent
            lines.append("Humidity puck (\(latest.source))")
            lines.append(String(format: "  Latest: %.0f%% RH, %.0f F", latest.humidityPercent, latest.temperatureFahrenheit))
            lines.append(String(format: "  Peak over session: %.0f%% RH", peak))
            lines.append(peak >= StructSenseConstants.humidityAlertPercent ? "  Above the 60% EPA alert line." : "  Within the EPA range.")
            lines.append("")
        }

        if !notes.isEmpty {
            lines.append("Notes")
            lines.append(notes)
            lines.append("")
        }

        lines.append(StructSenseConstants.disclaimer)
        return lines.joined(separator: "\n")
    }
}
