import Combine
import Foundation

/// Drives the two-capture acoustic workflow: reference spot first, suspect spot second.
@MainActor
final class AcousticViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case capturingReference
        case capturingSuspect
        case complete
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var reference: AcousticMeasurement?
    @Published private(set) var suspect: AcousticMeasurement?
    @Published private(set) var comparison: AcousticComparison?
    @Published private(set) var liveSamples: [Float] = []
    @Published private(set) var liveLevel: Float = -120
    @Published var errorMessage: String?

    private let service = AcousticTriageService()

    var isCapturing: Bool { phase == .capturingReference || phase == .capturingSuspect }
    var canCaptureSuspect: Bool { reference != nil && !isCapturing }

    func captureReference() {
        Task { await capture(asReference: true) }
    }

    func captureSuspect() {
        Task { await capture(asReference: false) }
    }

    func reset() {
        phase = .idle
        reference = nil
        suspect = nil
        comparison = nil
        liveSamples = []
        liveLevel = -120
        errorMessage = nil
    }

    private func capture(asReference: Bool) async {
        guard !isCapturing else { return }
        errorMessage = nil
        liveSamples = []
        phase = asReference ? .capturingReference : .capturingSuspect

        do {
            let samples = try await service.capture(duration: StructSenseConstants.acousticWindowSeconds) { [weak self] level in
                guard let self else { return }
                self.liveLevel = level
                self.liveSamples.append(level)
            }
            let measurement = AcousticMeasurement(label: asReference ? "Reference" : "Suspect", samples: samples)
            if asReference {
                reference = measurement
                suspect = nil
                comparison = nil
                phase = .idle
            } else {
                suspect = measurement
                if let reference {
                    comparison = AcousticAnalyzer.compare(reference: reference, suspect: measurement)
                }
                phase = .complete
            }
        } catch {
            errorMessage = error.localizedDescription
            phase = .idle
        }
    }
}
