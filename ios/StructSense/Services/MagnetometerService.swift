import Combine
import CoreMotion
import Foundation

/// Streams the calibrated magnetic field vector at 50 Hz and flags spikes against a rolling baseline.
///
/// Earth's field at the surface is roughly 25 to 65 microtesla. A steel stud, cast iron drain or
/// nail plate a few centimetres behind drywall distorts that field by several microtesla, which
/// the phone's magnetometer resolves easily. Copper and PVC do not show up, so a clean sweep is
/// not proof that a wall is empty.
final class MagnetometerService: ObservableObject {
    struct FieldSample {
        let x: Double
        let y: Double
        let z: Double
        var magnitude: Double { (x * x + y * y + z * z).squareRoot() }
    }

    @Published private(set) var latest = FieldSample(x: 0, y: 0, z: 0)
    @Published private(set) var smoothedMagnitude: Double = 0
    @Published private(set) var baselineMagnitude: Double = 0
    @Published private(set) var baselineDeviation: Double = 0
    @Published private(set) var zScore: Double = 0
    @Published private(set) var isOverStructure = false
    @Published private(set) var isCalibrating = false
    @Published private(set) var accuracyDescription = "Waiting for sensor"
    @Published private(set) var isAvailable = true
    @Published private(set) var anomalies: [MagneticAnomaly] = []

    /// Spike rule: either of these trips the indicator. The z-score catches subtle metal on a
    /// quiet baseline; the absolute delta catches big iron when the baseline itself is noisy.
    static let zScoreThreshold: Double = 4
    static let absoluteDeltaThreshold: Double = 8

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1 / 50
    private var baseline = RollingStatistics(capacity: 100)
    private var smoother = ExponentialSmoother(alpha: 0.25)
    private var samplesSinceCalibrationStart = 0
    private var lastAnomalyAt: Date?

    func start() {
        guard motionManager.isDeviceMotionAvailable || motionManager.isMagnetometerAvailable else {
            isAvailable = false
            accuracyDescription = "Magnetometer not available on this device"
            return
        }
        isAvailable = true
        recalibrate()

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = updateInterval
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, _ in
                guard let self, let motion else { return }
                let field = motion.magneticField
                self.accuracyDescription = Self.describe(field.accuracy)
                self.ingest(FieldSample(x: field.field.x, y: field.field.y, z: field.field.z))
            }
        } else {
            motionManager.magnetometerUpdateInterval = updateInterval
            motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.accuracyDescription = "Raw sensor, uncalibrated"
                self.ingest(FieldSample(x: data.magneticField.x, y: data.magneticField.y, z: data.magneticField.z))
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopMagnetometerUpdates()
    }

    /// Hold the phone against a known-empty section of wall, then call this. The next two
    /// seconds of samples become the baseline.
    func recalibrate() {
        baseline.reset()
        smoother.reset()
        samplesSinceCalibrationStart = 0
        isCalibrating = true
        isOverStructure = false
        zScore = 0
    }

    func clearAnomalies() {
        anomalies.removeAll()
    }

    private func ingest(_ sample: FieldSample) {
        latest = sample
        let magnitude = smoother.update(sample.magnitude)
        smoothedMagnitude = magnitude

        if isCalibrating {
            baseline.append(magnitude)
            samplesSinceCalibrationStart += 1
            if baseline.isFull {
                isCalibrating = false
            }
            baselineMagnitude = baseline.median
            baselineDeviation = baseline.standardDeviation
            return
        }

        let deviation = max(baseline.standardDeviation, 0.3)
        let delta = magnitude - baseline.median
        let score = delta / deviation
        zScore = score
        baselineMagnitude = baseline.median
        baselineDeviation = deviation

        let spike = abs(score) >= Self.zScoreThreshold || abs(delta) >= Self.absoluteDeltaThreshold
        if spike {
            if !isOverStructure {
                isOverStructure = true
                recordAnomaly(magnitude: magnitude, baseline: baseline.median, zScore: score)
            }
        } else {
            isOverStructure = false
            // Only quiet samples feed the baseline, so a long pass over a pipe does not become "normal".
            baseline.append(magnitude)
        }
    }

    private func recordAnomaly(magnitude: Double, baseline: Double, zScore: Double) {
        // Debounce: a single stud produces one anomaly, not fifty.
        if let last = lastAnomalyAt, Date().timeIntervalSince(last) < 0.5 { return }
        lastAnomalyAt = Date()
        anomalies.append(MagneticAnomaly(magnitude: magnitude, baseline: baseline, zScore: zScore))
        if anomalies.count > 200 {
            anomalies.removeFirst(anomalies.count - 200)
        }
    }

    private static func describe(_ accuracy: CMMagneticFieldCalibrationAccuracy) -> String {
        switch accuracy {
        case .uncalibrated: return "Calibrating, move the phone in a figure eight"
        case .low: return "Low accuracy"
        case .medium: return "Medium accuracy"
        case .high: return "High accuracy"
        @unknown default: return "Unknown accuracy"
        }
    }
}
