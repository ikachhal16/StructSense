import Combine
import CoreBluetooth
import Foundation

/// Finds Bluetooth Low Energy humidity and temperature pucks and streams their readings.
///
/// Real hardware: any peripheral that advertises the Bluetooth SIG Environmental Sensing
/// Service (0x181A) with the standard Temperature (0x2A6E) and Humidity (0x2A6F)
/// characteristics. Many hobby sensors (ESP32 and nRF52 boards running the standard
/// profile) and some commercial hygrometers expose exactly this.
///
/// Simulated hardware: when no puck is nearby, a simulated crawlspace puck produces a
/// realistic drifting signal so the whole workflow can be demonstrated and tested.
final class PuckScannerService: NSObject, ObservableObject {
    enum ConnectionState: Equatable {
        case bluetoothOff
        case unauthorized
        case idle
        case scanning
        case connecting(String)
        case connected(String)
        case simulated

        var label: String {
            switch self {
            case .bluetoothOff: return "Bluetooth is off"
            case .unauthorized: return "Bluetooth permission needed"
            case .idle: return "Not scanning"
            case .scanning: return "Scanning for pucks"
            case .connecting(let name): return "Connecting to \(name)"
            case .connected(let name): return "Streaming from \(name)"
            case .simulated: return "Streaming from simulated puck"
            }
        }
    }

    struct DiscoveredPuck: Identifiable, Equatable {
        let id: UUID
        let name: String
        var rssi: Int
        let advertisesEnvironmentalSensing: Bool
    }

    static let environmentalSensingService = CBUUID(string: "181A")
    static let temperatureCharacteristic = CBUUID(string: "2A6E")
    static let humidityCharacteristic = CBUUID(string: "2A6F")

    @Published private(set) var state: ConnectionState = .idle
    @Published private(set) var discovered: [DiscoveredPuck] = []
    @Published private(set) var latest: PuckReading?
    @Published private(set) var history: [PuckReading] = []
    @Published private(set) var lastError: String?

    private var central: CBCentralManager!
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var pendingTemperatureC: Double?
    private var pendingHumidity: Double?

    private var simulationTimer: Timer?
    private var simulatedHumidity: Double = 54
    private var simulatedTemperatureF: Double = 79
    private var simulatedStormPhase: Double = 0

    private let maxHistory = 180

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    }

    // MARK: Scanning

    func startScanning() {
        stopSimulation()
        guard central.state == .poweredOn else {
            refreshStateFromCentral()
            return
        }
        discovered.removeAll()
        lastError = nil
        state = .scanning
        // Scan broadly so pucks that advertise without a service UUID still appear; the list
        // marks the ones that declare the Environmental Sensing Service.
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    func stopScanning() {
        if central.state == .poweredOn {
            central.stopScan()
        }
        if case .scanning = state {
            state = .idle
        }
    }

    func connect(to puck: DiscoveredPuck) {
        guard let peripheral = peripherals[puck.id] else { return }
        stopSimulation()
        central.stopScan()
        state = .connecting(puck.name)
        connectedPeripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        stopSimulation()
        state = central.state == .poweredOn ? .idle : state
    }

    func clearHistory() {
        history.removeAll()
        latest = nil
    }

    // MARK: Simulation

    /// Starts the simulated crawlspace puck. Readings drift slowly around a damp South Florida
    /// baseline with sensor noise; `triggerSimulatedStorm` pushes humidity past the alert line.
    func startSimulation() {
        disconnectPeripheralOnly()
        stopScanning()
        stopSimulation()
        state = .simulated
        simulatedHumidity = 54
        simulatedTemperatureF = 79
        simulatedStormPhase = 0
        publishSimulatedReading()
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.advanceSimulation()
        }
    }

    func triggerSimulatedStorm() {
        guard state == .simulated else { return }
        simulatedStormPhase = 1
    }

    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        if state == .simulated {
            state = central.state == .poweredOn ? .idle : state
        }
    }

    private func advanceSimulation() {
        // Slow random walk bounded to a plausible range.
        simulatedHumidity += Double.random(in: -0.6...0.6)
        simulatedTemperatureF += Double.random(in: -0.15...0.15)

        if simulatedStormPhase > 0 {
            // Water intrusion: humidity climbs about 1.2 points a second toward saturation,
            // temperature drops slightly as evaporation starts, then the storm phase decays.
            simulatedHumidity += 1.2 * simulatedStormPhase
            simulatedTemperatureF -= 0.05 * simulatedStormPhase
            simulatedStormPhase = max(0, simulatedStormPhase - 0.02)
        } else if simulatedHumidity > 56 {
            // Dehumidifier running: slow recovery toward the baseline.
            simulatedHumidity -= 0.25
        }

        simulatedHumidity = min(max(simulatedHumidity, 35), 98)
        simulatedTemperatureF = min(max(simulatedTemperatureF, 68), 92)
        publishSimulatedReading()
    }

    private func publishSimulatedReading() {
        let reading = PuckReading(humidityPercent: simulatedHumidity, temperatureFahrenheit: simulatedTemperatureF, source: "Simulated puck")
        publish(reading)
    }

    private func publish(_ reading: PuckReading) {
        latest = reading
        history.append(reading)
        if history.count > maxHistory {
            history.removeFirst(history.count - maxHistory)
        }
    }

    private func disconnectPeripheralOnly() {
        if let peripheral = connectedPeripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
    }

    private func refreshStateFromCentral() {
        switch central.state {
        case .poweredOn:
            if case .simulated = state { return }
            if case .connected = state { return }
            state = .idle
        case .unauthorized:
            state = .unauthorized
        case .poweredOff, .resetting, .unsupported, .unknown:
            if state != .simulated { state = .bluetoothOff }
        @unknown default:
            if state != .simulated { state = .bluetoothOff }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension PuckScannerService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        refreshStateFromCentral()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let advertisedServices = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? "Unnamed device"
        let advertisesESS = advertisedServices.contains(Self.environmentalSensingService)

        peripherals[peripheral.identifier] = peripheral
        if let index = discovered.firstIndex(where: { $0.id == peripheral.identifier }) {
            discovered[index].rssi = RSSI.intValue
        } else {
            discovered.append(DiscoveredPuck(id: peripheral.identifier, name: name, rssi: RSSI.intValue, advertisesEnvironmentalSensing: advertisesESS))
            discovered.sort { ($0.advertisesEnvironmentalSensing ? 1 : 0, $0.rssi) > ($1.advertisesEnvironmentalSensing ? 1 : 0, $1.rssi) }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        state = .connected(peripheral.name ?? "puck")
        peripheral.discoverServices([Self.environmentalSensingService])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        lastError = error?.localizedDescription ?? "Could not connect"
        connectedPeripheral = nil
        state = .idle
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error { lastError = error.localizedDescription }
        connectedPeripheral = nil
        if state != .simulated { state = .idle }
    }
}

// MARK: - CBPeripheralDelegate

extension PuckScannerService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            lastError = error?.localizedDescription ?? "No services found"
            return
        }
        for service in services where service.uuid == Self.environmentalSensingService {
            peripheral.discoverCharacteristics([Self.temperatureCharacteristic, Self.humidityCharacteristic], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil, let characteristics = service.characteristics else {
            lastError = error?.localizedDescription ?? "No characteristics found"
            return
        }
        for characteristic in characteristics {
            peripheral.readValue(for: characteristic)
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value, data.count >= 2 else { return }
        // Both standard characteristics are little-endian 16-bit values in hundredths.
        let raw = UInt16(data[0]) | (UInt16(data[1]) << 8)

        switch characteristic.uuid {
        case Self.temperatureCharacteristic:
            pendingTemperatureC = Double(Int16(bitPattern: raw)) / 100
        case Self.humidityCharacteristic:
            pendingHumidity = Double(raw) / 100
        default:
            return
        }

        guard let humidity = pendingHumidity else { return }
        let temperatureF = (pendingTemperatureC ?? 25) * 9 / 5 + 32
        publish(PuckReading(humidityPercent: humidity, temperatureFahrenheit: temperatureF, source: peripheral.name ?? "puck"))
    }
}
