import CoreLocation
import EventKit
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var current: CLLocation?
    @Published private(set) var status: CLAuthorizationStatus = .notDetermined
    @Published var issue: String?
    private let manager = CLLocationManager()
    private var lastRequest = Date.distantPast
    var allowed: Bool { status == .authorizedAlways || status == .authorizedWhenInUse }
    var permissionLabel: String { switch status { case .authorizedAlways, .authorizedWhenInUse: "Bei Verwendung"; case .denied, .restricted: "Nicht erlaubt"; default: "Nicht angefragt" } }
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyHundredMeters; status = manager.authorizationStatus }
    func requestPermission() { manager.requestWhenInUseAuthorization() }
    func requestLocation() { guard Date().timeIntervalSince(lastRequest) > 30 else { return }; lastRequest = Date(); issue = nil; if allowed { manager.requestLocation() } else if status == .notDetermined { requestPermission() } else { issue = "Standort ist nicht freigegeben. Du kannst die Berechtigung in den iOS-Einstellungen ändern." } }
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        Task { @MainActor in status = newStatus; if allowed { self.manager.requestLocation() } else { current = nil } }
    }
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { Task { @MainActor in current = locations.last; issue = nil } }
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { Task { @MainActor in current = nil; issue = "Standort momentan nicht verfügbar. Versuche es erneut." } }
    func clear() { current = nil }
}

@MainActor
final class CalendarService: ObservableObject {
    private let events = EKEventStore()
    @Published private(set) var allowed = EKEventStore.authorizationStatus(for: .event) == .fullAccess
    var permissionLabel: String { allowed ? "Erlaubt" : "Nicht freigegeben" }
    func requestPermission() async { do { allowed = try await events.requestFullAccessToEvents() } catch { allowed = false } }
    func currentTitles(at now: Date) -> [String] {
        allowed = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        guard allowed else { return [] }
        let predicate = events.predicateForEvents(withStart: now.addingTimeInterval(-86400), end: now.addingTimeInterval(1), calendars: nil)
        return events.events(matching: predicate).filter { $0.startDate <= now && $0.endDate > now }.compactMap(\.title)
    }
}
