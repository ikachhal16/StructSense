import Combine
import Foundation

/// Shared session that the three tools write into and the report tab reads from.
@MainActor
final class TriageSession: ObservableObject {
    @Published var report = TriageReport()
    @Published var lastSavedMessage: String?

    func saveAcoustic(_ comparison: AcousticComparison) {
        report.acoustic = comparison
        lastSavedMessage = "Acoustic verdict saved to report"
    }

    func saveAnomalies(_ anomalies: [MagneticAnomaly]) {
        report.anomalies = anomalies
        lastSavedMessage = "\(anomalies.count) magnetic anomalies saved to report"
    }

    func savePuckReadings(_ readings: [PuckReading]) {
        report.puckReadings = readings
        lastSavedMessage = "\(readings.count) puck readings saved to report"
    }

    func reset() {
        report = TriageReport()
        lastSavedMessage = nil
    }
}
