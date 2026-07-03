import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var timeoutTask: Task<Void, Never>?
    private var isFetching = false

    // Accept the first fix at least this accurate; otherwise keep listening until timeout
    private let goodEnoughAccuracy: CLLocationAccuracy = 50
    private let fetchTimeoutSeconds: UInt64 = 10

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    /// One-shot location fetch. Listens for updates until an accurate fix arrives,
    /// then stops. Falls back to the best fix seen (or last known) after a timeout.
    func fetchCurrentLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return nil }
        guard !isFetching else { return location }
        isFetching = true

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: (self?.fetchTimeoutSeconds ?? 10) * 1_000_000_000)
                guard !Task.isCancelled else { return }
                DispatchQueue.main.async {
                    self?.finishFetch(with: self?.location)
                }
            }
            manager.startUpdatingLocation()
        }
    }

    /// Must be called on the main thread.
    private func finishFetch(with loc: CLLocation?) {
        guard isFetching else { return }
        manager.stopUpdatingLocation()
        timeoutTask?.cancel()
        timeoutTask = nil
        isFetching = false
        locationContinuation?.resume(returning: loc)
        locationContinuation = nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async {
            self.location = loc
            // Keep listening for a better fix unless this one is accurate enough
            if loc.horizontalAccuracy > 0 && loc.horizontalAccuracy <= self.goodEnoughAccuracy {
                self.finishFetch(with: loc)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient — CoreLocation keeps trying; the timeout is our backstop
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        DispatchQueue.main.async {
            self.finishFetch(with: self.location)
        }
    }
}
