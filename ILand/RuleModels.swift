import Foundation
import CoreLocation

struct SavedPlace: Identifiable, Codable {
    var id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double
    func contains(_ location: CLLocation) -> Bool {
        location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= radius && abs(location.timestamp.timeIntervalSinceNow) < 300 && location.distance(from: CLLocation(latitude: latitude, longitude: longitude)) <= radius
    }
}
enum ConditionKind: String, CaseIterable, Codable, Identifiable {
    case appActive = "App ist aktiv", location = "Standort", time = "Zeitfenster", music = "Musik läuft", calendar = "Kalenderereignis"
    static var allCases: [Self] { [.appActive, .location, .time, .calendar] }
    var id: String { rawValue }
}
struct RuleCondition: Identifiable, Codable {
    var id = UUID()
    var kind: ConditionKind = .appActive
    var placeID: UUID?
    var startMinute = 18 * 60
    var endMinute = 23 * 60
    var query = "Flug"
    func summary(places: [SavedPlace]) -> String {
        switch kind {
        case .appActive: "iLand ist geöffnet"
        case .location: "Bei \(places.first { $0.id == placeID }?.name ?? "Ort auswählen")"
        case .time: "\(Self.format(startMinute)) – \(Self.format(endMinute)) Uhr"
        case .music: "Entfernte Bedingung"
        case .calendar: "Termin enthält „\(query)“"
        }
    }
    static func format(_ minute: Int) -> String { String(format: "%02d:%02d", minute / 60, minute % 60) }
    static func includes(minute: Int, start: Int, end: Int) -> Bool { start == end || (start < end ? minute >= start && minute < end : minute >= start || minute < end) }
}
struct IslandRule: Identifiable, Codable {
    var id = UUID()
    var name = "Meine Regel"
    var enabled = false
    var matchAll = true
    var conditions = [RuleCondition()]
    var designID: UUID
}
struct RuleContext {
    var now: Date
    var appActive: Bool
    var location: CLLocation?
    var places: [SavedPlace]
    var eventTitles: [String]
}
enum RuleEngine {
    static func matches(_ rule: IslandRule, context: RuleContext) -> Bool {
        guard rule.enabled, !rule.conditions.isEmpty else { return false }
        let results = rule.conditions.map { condition in
            switch condition.kind {
            case .appActive: return context.appActive
            case .location:
                guard let location = context.location, let place = context.places.first(where: { $0.id == condition.placeID }) else { return false }
                return place.contains(location)
            case .time:
                let parts = Calendar.current.dateComponents([.hour, .minute], from: context.now)
                return RuleCondition.includes(minute: (parts.hour ?? 0) * 60 + (parts.minute ?? 0), start: condition.startMinute, end: condition.endMinute)
            case .music: return false
            case .calendar:
                let query = condition.query.trimmingCharacters(in: .whitespacesAndNewlines)
                return !query.isEmpty && context.eventTitles.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        return rule.matchAll ? results.allSatisfy { $0 } : results.contains(true)
    }
}
