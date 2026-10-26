import AVFoundation
import Foundation

/// Plays a 40 to 100 Hz sweep through the speaker while measuring the microphone level,
/// then bins the level into 100 ms loudness samples.
///
/// The physics in one line: a dry, hollow wall cavity reflects and resonates with low
/// frequency sound; drywall and insulation that are holding water are heavier and damp the
/// same tone. A single absolute reading means little, because every phone, case and wall is
/// different. So the app always compares a suspect spot against a dry reference spot on the
/// same wall, and `AcousticAnalyzer` judges the difference.
final class AcousticTriageService {
    enum ServiceError: LocalizedError {
        case microphoneDenied
        case engineFailed(String)

        var errorDescription: String? {
            switch self {
            case .microphoneDenied: return "Microphone access is required for the acoustic check. Enable it in Settings."
            case .engineFailed(let detail): return "Audio engine could not start: \(detail)"
            }
        }
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let processingQueue = DispatchQueue(label: "app.structsense.acoustic", qos: .userInitiated)

    /// Sweep parameters. 40 to 100 Hz is low enough to couple into a wall cavity while still
    /// being reproducible by a phone speaker (most roll off hard below about 200 Hz, which is
    /// why the measurement is comparative, not absolute).
    private let sweepStartHz: Double = 40
    private let sweepEndHz: Double = 100
    private let sweepAmplitude: Float = 0.85

    private var sampleRate: Double = 44_100
    private var phase: Double = 0
    private var sweepTime: Double = 0

    /// Microphone level accumulation.
    private var binDurationSeconds: Double = 0.1
    private var currentBinSumOfSquares: Double = 0
    private var currentBinFrames: Int = 0
    private var bins: [Float] = []

    /// Requests microphone access and resolves to true when granted.
    func requestMicrophone() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    /// Runs one capture window and returns loudness bins in dBFS (0 is full scale, quieter is more negative).
    /// `onLevel` is called on the main thread with the latest bin so the UI can animate a live meter.
    func capture(duration: TimeInterval, onLevel: @escaping (Float) -> Void) async throws -> [Float] {
        guard await requestMicrophone() else { throw ServiceError.microphoneDenied }

        try configureSession()
        try startEngine(onLevel: onLevel)

        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

        stopEngine()
        return processingQueue.sync { bins }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.measurement` turns off the system's automatic gain and voice processing,
            // which would otherwise erase the differences we are trying to measure.
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            throw ServiceError.engineFailed(error.localizedDescription)
        }
    }

    private func startEngine(onLevel: @escaping (Float) -> Void) throws {
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        sampleRate = inputFormat.sampleRate > 0 ? inputFormat.sampleRate : 44_100

        processingQueue.sync {
            bins.removeAll()
            currentBinSumOfSquares = 0
            currentBinFrames = 0
        }
        phase = 0
        sweepTime = 0

        // Tone generator: a linear chirp from 40 Hz to 100 Hz that repeats every second.
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let source = AVAudioSourceNode(format: outputFormat) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sweepLength = 1.0
            for frame in 0..<Int(frameCount) {
                let progress = (self.sweepTime.truncatingRemainder(dividingBy: sweepLength)) / sweepLength
                let frequency = self.sweepStartHz + (self.sweepEndHz - self.sweepStartHz) * progress
                self.phase += 2 * Double.pi * frequency / self.sampleRate
                if self.phase > 2 * Double.pi { self.phase -= 2 * Double.pi }
                self.sweepTime += 1 / self.sampleRate
                let sample = Float(sin(self.phase)) * self.sweepAmplitude
                for buffer in buffers {
                    let pointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                    pointer?[frame] = sample
                }
            }
            return noErr
        }
        sourceNode = source
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: outputFormat)

        // Microphone tap: root-mean-square level per buffer, accumulated into 100 ms bins.
        let framesPerBin = Int(sampleRate * binDurationSeconds)
        engine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            guard let self, let channel = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            self.processingQueue.async {
                for frame in 0..<frameLength {
                    let value = Double(channel[frame])
                    self.currentBinSumOfSquares += value * value
                    self.currentBinFrames += 1
                    if self.currentBinFrames >= framesPerBin {
                        let rms = (self.currentBinSumOfSquares / Double(self.currentBinFrames)).squareRoot()
                        let decibels = Float(20 * log10(max(rms, 1e-7)))
                        self.bins.append(decibels)
                        self.currentBinSumOfSquares = 0
                        self.currentBinFrames = 0
                        DispatchQueue.main.async { onLevel(decibels) }
                    }
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            throw ServiceError.engineFailed(error.localizedDescription)
        }
    }

    private func stopEngine() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        if let sourceNode {
            engine.detach(sourceNode)
        }
        sourceNode = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// Turns two captures into a verdict. Pure functions, easy to unit test.
enum AcousticAnalyzer {
    /// Suspect must be at least this much quieter than reference to be called saturated.
    static let saturatedThresholdDecibels: Float = -3
    /// Differences above this are treated as no meaningful absorption.
    static let dryThresholdDecibels: Float = -1

    /// Smooths a bin series with an exponential moving average so a door slam does not decide the verdict.
    static func smooth(_ samples: [Float], alpha: Float = 0.35) -> [Float] {
        var output: [Float] = []
        output.reserveCapacity(samples.count)
        var current: Float?
        for sample in samples {
            if let value = current {
                current = value + alpha * (sample - value)
            } else {
                current = sample
            }
            output.append(current ?? sample)
        }
        return output
    }

    static func compare(reference: AcousticMeasurement, suspect: AcousticMeasurement) -> AcousticComparison {
        let smoothedReference = AcousticMeasurement(label: reference.label, samples: smooth(reference.samples))
        let smoothedSuspect = AcousticMeasurement(label: suspect.label, samples: smooth(suspect.samples))

        let delta = smoothedSuspect.meanDecibels - smoothedReference.meanDecibels

        let verdict: MoistureVerdict
        if delta <= saturatedThresholdDecibels {
            verdict = .suspectSaturated
        } else if delta >= dryThresholdDecibels {
            verdict = .likelyDry
        } else {
            verdict = .inconclusive
        }

        // Confidence: how far the delta sits outside the noise of both captures.
        let noise = max(Float(0.5), (smoothedReference.standardDeviation + smoothedSuspect.standardDeviation) / 2)
        let signalToNoise = abs(delta) / noise
        let confidence = min(1, max(0, Double(signalToNoise) / 4))

        return AcousticComparison(
            reference: smoothedReference,
            suspect: smoothedSuspect,
            absorptionDelta: delta,
            verdict: verdict,
            confidence: verdict == .inconclusive ? min(confidence, 0.35) : confidence
        )
    }
}
