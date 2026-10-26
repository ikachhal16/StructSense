import Foundation

/// Fixed-capacity sample window with the summary statistics the sensor services need.
/// Cheap enough to update at 50 Hz on the main thread.
struct RollingStatistics {
    private(set) var values: [Double] = []
    let capacity: Int

    init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    var count: Int { values.count }
    var isFull: Bool { values.count >= capacity }

    mutating func append(_ value: Double) {
        values.append(value)
        if values.count > capacity {
            values.removeFirst(values.count - capacity)
        }
    }

    mutating func reset() {
        values.removeAll(keepingCapacity: true)
    }

    var mean: Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Median resists the short spikes we are trying to detect, so it makes a better baseline than the mean.
    var median: Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    var standardDeviation: Double {
        guard values.count > 1 else { return 0 }
        let mean = self.mean
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count - 1)
        return variance.squareRoot()
    }
}

/// Exponential moving average. `alpha` near 1 follows the signal closely; near 0 smooths heavily.
struct ExponentialSmoother {
    let alpha: Double
    private(set) var value: Double?

    init(alpha: Double) {
        self.alpha = min(max(alpha, 0.01), 1)
    }

    mutating func update(_ sample: Double) -> Double {
        if let current = value {
            value = current + alpha * (sample - current)
        } else {
            value = sample
        }
        return value ?? sample
    }

    mutating func reset() {
        value = nil
    }
}
