import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 30          // fire update every 30 m of movement
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    /// Call on first launch. Requests "When In Use" first; after grant we
    /// escalate to "Always" so background notifications work.
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Escalate to Always for background delivery
            manager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func startMonitoring() {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }

        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()

        // Significant-change monitoring keeps location alive even when the
        // OS suspends the app (requires Always authorization).
        if status == .authorizedAlways {
            manager.startMonitoringSignificantLocationChanges()
        }
    }

    func stopMonitoring() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse:
                // Got "When In Use" — ask to upgrade to Always
                manager.requestAlwaysAuthorization()
                self.startMonitoring()
            case .authorizedAlways:
                self.startMonitoring()
            default:
                self.stopMonitoring()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        DispatchQueue.main.async { self.location = loc }
    }
}
