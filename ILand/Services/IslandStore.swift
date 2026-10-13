import SwiftUI
import ActivityKit
import Combine

@MainActor
final class IslandStore: ObservableObject {
    @Published var designs: [IslandDesign] = []
    @Published var rules: [IslandRule] = []
    @Published var places: [SavedPlace] = []
    @Published var appearance = "System"
    @Published var message: String?
    @Published var activeDesign: IslandDesign?
    @Published var activeState: IslandAttributes.ContentState?
    @Published var busy = false
    @Published var lastEvaluation: String?
    @Published var activitiesAllowed = ActivityAuthorizationInfo().areActivitiesEnabled
    let location = LocationService()
    let calendar = CalendarService()
    private var subscriptions = Set<AnyCancellable>()
    private var matchingRuleID: UUID?
    private var evaluating = false
    private var observation: Task<Void, Never>?
    private var contentObservation: Task<Void, Never>?
    private var observedID: String?
    private var endingIDs = Set<String>()
    private let fileURL: URL
    private var persistenceAvailable = true
    var orderedDesigns: [IslandDesign] {
        guard let activeID = activeDesign?.id else { return designs }
        return designs.filter { $0.id == activeID } + designs.filter { $0.id != activeID }
    }
    var recentDesigns: [IslandDesign] { designs.filter { $0.lastUsed != nil }.sorted { $0.lastUsed! > $1.lastUsed! } }
    struct Snapshot: Codable { var version = 1; var designs: [IslandDesign]; var rules: [IslandRule]; var places: [SavedPlace]; var appearance: String }
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("ILand/state.json")
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            do {
                let snapshot = try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: self.fileURL))
                guard snapshot.version == 1 else { throw CocoaError(.coderReadCorrupt) }
                designs = snapshot.designs; rules = snapshot.rules
                for index in rules.indices where rules[index].conditions.contains(where: { $0.kind == .music }) {
                    rules[index].enabled = false
                    rules[index].conditions.removeAll { $0.kind == .music }
                }
                places = snapshot.places; appearance = snapshot.appearance
            } catch {
                persistenceAvailable = false
                message = "Die gespeicherten Daten konnten nicht gelesen werden. Die Originaldatei bleibt erhalten. Du kannst die Daten in Einstellungen bewusst zurücksetzen."
            }
        } else {
            designs = IslandDesign.examples
            rules = [IslandRule(name: "Zeit für Fokus", conditions: [RuleCondition(kind: .time, startMinute: 18 * 60, endMinute: 23 * 60)], designID: designs[0].id)]
            persist()
        }
        location.objectWillChange.merge(with: calendar.objectWillChange)
            .receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        location.$current.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in Task { await self?.evaluateRules() } }.store(in: &subscriptions)
        reconcile()
    }
    @discardableResult func persist() -> Bool {
        guard persistenceAvailable else { message = "Speichern ist gesperrt, damit deine vorhandene Datendatei erhalten bleibt. Setze sie bei Bedarf in Einstellungen zurück."; return false }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let snapshot = Snapshot(designs: designs, rules: rules, places: places, appearance: appearance)
            try JSONEncoder().encode(snapshot).write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch { message = "Deine Änderung konnte nicht gespeichert werden: \(error.localizedDescription)"; return false }
    }
    @discardableResult func save(_ design: IslandDesign) -> Bool {
        if let error = design.validationError { message = error; return false }
        let old = designs
        if let index = designs.firstIndex(where: { $0.id == design.id }) { designs[index] = design } else { designs.append(design) }
        guard persist() else { designs = old; return false }
        return true
    }
    func duplicate(_ design: IslandDesign) { var copy = design; copy.id = UUID(); copy.name = String(design.name.prefix(52)) + " Kopie"; copy.lastUsed = nil; _ = save(copy) }
    func toggleFavorite(_ design: IslandDesign) { var copy = design; copy.favorite.toggle(); _ = save(copy) }
    func delete(_ design: IslandDesign) async { if activeDesign?.id == design.id { await stop() }; designs.removeAll { $0.id == design.id }; rules.removeAll { $0.designID == design.id }; persist() }
    @discardableResult func saveRule(_ rule: IslandRule) -> Bool {
        guard !rule.name.trimmingCharacters(in: .whitespaces).isEmpty, !rule.conditions.isEmpty, designs.contains(where: { $0.id == rule.designID }) else { message = "Bitte gib einen Namen, mindestens eine Bedingung und ein vorhandenes Design an."; return false }
        for condition in rule.conditions {
            if condition.kind == .location && !places.contains(where: { $0.id == condition.placeID }) { message = "Wähle für jede Standortbedingung einen gespeicherten Ort."; return false }
            if condition.kind == .calendar && condition.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { message = "Bitte gib einen Suchbegriff für den Kalender ein."; return false }
        }
        if let index = rules.firstIndex(where: { $0.id == rule.id }) { rules[index] = rule } else { rules.append(rule) }
        matchingRuleID = nil; return persist()
    }
    func removeRule(_ id: UUID) { rules.removeAll { $0.id == id }; matchingRuleID = nil; persist() }
    func setRuleEnabled(_ id: UUID, _ enabled: Bool) { guard let index = rules.firstIndex(where: { $0.id == id }) else { return }; rules[index].enabled = enabled; matchingRuleID = nil; persist(); Task { await evaluateRules() } }
    func removePlaces(at offsets: IndexSet) {
        let ids = Set(offsets.map { places[$0].id }); places.remove(atOffsets: offsets)
        for index in rules.indices where rules[index].conditions.contains(where: { $0.placeID.map(ids.contains) ?? false }) { rules[index].enabled = false }
        persist()
    }
    func reconcile() {
        activitiesAllowed = ActivityAuthorizationInfo().areActivitiesEnabled
        let current = Activity<IslandAttributes>.activities.first { !endingIDs.contains($0.id) && ($0.activityState == .active || $0.activityState == .stale) }
        activeDesign = current?.attributes.design
        activeState = current?.content.state
        if observedID != current?.id {
            observation?.cancel(); contentObservation?.cancel(); observedID = current?.id
            if let current {
                observation = Task { [weak self] in
                    for await _ in current.activityStateUpdates { guard !Task.isCancelled else { return }; self?.reconcile() }
                }
                contentObservation = Task { [weak self] in
                    for await content in current.contentUpdates {
                        guard !Task.isCancelled, self?.observedID == current.id else { return }
                        self?.activeState = content.state
                    }
                }
            }
        }
    }
    func refresh() async {
        reconcile()
        for activity in Activity<IslandAttributes>.activities where activity.attributes.design.kind == .timer && !activity.content.state.paused && activity.content.state.endDate <= Date() {
            endingIDs.insert(activity.id)
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        reconcile()
        if rules.contains(where: { $0.enabled && $0.conditions.contains { $0.kind == .location } }), location.allowed { location.requestLocation() }
        await evaluateRules()
    }
    func start(_ design: IslandDesign) async {
        guard !busy else { return }
        guard UIApplication.shared.applicationState == .active else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { message = "Live Activities sind deaktiviert. Erlaube sie in den iOS-Einstellungen für iLand."; return }
        if design.kind == .travel && design.departure <= Date() { message = "Der Abflug liegt in der Vergangenheit. Passe die Reise zuerst im Editor an."; return }
        busy = true; defer { busy = false }
        let now = Date()
        var state = IslandAttributes.ContentState(title: design.title, subtitle: design.subtitle, status: design.status, endDate: now.addingTimeInterval(Double(design.durationMinutes * 60)), remaining: Double(design.durationMinutes * 60))
        if design.kind == .travel { state.endDate = design.departure }
        if design.kind == .market {
            do { state.marketQuote = try await MarketClient.shared.quote(for: design.selectedAsset) }
            catch { message = error.localizedDescription; return }
            guard UIApplication.shared.applicationState == .active else { return }
        }
        // Keep attributes bounded: URLs stay in app storage, never in the 4 KB activity payload.
        var payload = design; payload.actionURL = ""; payload.lastUsed = nil
        if design.kind != .custom { payload.customLayout = nil }
        let attributes = IslandAttributes(design: payload, startedAt: now)
        guard let attributeData = try? JSONEncoder().encode(attributes), let stateData = try? JSONEncoder().encode(state), attributeData.count + stateData.count < 3900 else {
            message = "Dieses Design enthält zu viele Inhalte für eine Live Activity. Kürze einige Texte oder setze einzelne Details auf Standard zurück."
            return
        }
        let previous = Activity<IslandAttributes>.activities
        do {
            let activity = try Activity.request(attributes: IslandAttributes(design: payload, startedAt: now), content: ActivityContent(state: state, staleDate: design.kind == .market ? now.addingTimeInterval(60) : design.kind == .custom ? now.addingTimeInterval(3600) : state.endDate), pushType: nil)
            activeDesign = activity.attributes.design
            for old in previous { endingIDs.insert(old.id); await old.end(nil, dismissalPolicy: .immediate) }
            if let index = designs.firstIndex(where: { $0.id == design.id }) { designs[index].lastUsed = now; persist() }
            reconcile()
        } catch { message = "Live Activity konnte nicht gestartet werden: \(error.localizedDescription)" }
    }
    func stop() async {
        let activities = Activity<IslandAttributes>.activities
        endingIDs.formUnion(activities.map(\.id))
        observation?.cancel(); contentObservation?.cancel(); observedID = nil
        activeDesign = nil; activeState = nil
        for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
        reconcile()
    }
    func refreshMarket() async {
        guard UIApplication.shared.applicationState == .active else { return }
        for activity in Activity<IslandAttributes>.activities where activity.attributes.design.kind == .market {
            await MarketActivityUpdates.refresh(id: activity.id)
        }
        reconcile()
    }
    private var runningTimer: Activity<IslandAttributes>? {
        Activity<IslandAttributes>.activities.first {
            $0.attributes.design.id == activeDesign?.id && $0.attributes.design.kind == .timer
                && ($0.activityState == .active || $0.activityState == .stale)
        }
    }
    func toggleTimer() async { if let activity = runningTimer { await ActivityControls.timer(id: activity.id); reconcile() } }
    func resetTimer() async { if let activity = runningTimer { await ActivityControls.timer(id: activity.id, reset: true); reconcile() } }
    func evaluateRules(report: Bool = false) async {
        guard !evaluating, UIApplication.shared.applicationState == .active else { return }
        evaluating = true; defer { evaluating = false }
        let now = Date()
        reconcile()
        if location.allowed, rules.contains(where: { $0.enabled && $0.conditions.contains { $0.kind == .location } }), location.current.map({ now.timeIntervalSince($0.timestamp) > 120 }) ?? true { location.requestLocation() }
        let needsCalendar = rules.contains { $0.enabled && $0.conditions.contains { $0.kind == .calendar } }
        let context = RuleContext(now: now, appActive: true, location: location.allowed ? location.current : nil, places: places, eventTitles: needsCalendar ? calendar.currentTitles(at: now) : [])
        let rule = rules.first { RuleEngine.matches($0, context: context) }
        lastEvaluation = "Zuletzt geprüft: \(now.formatted(date: .omitted, time: .shortened)) · \(rule?.name ?? "Keine passende Regel")"
        if let rule, let design = designs.first(where: { $0.id == rule.designID }), matchingRuleID != rule.id {
            matchingRuleID = rule.id
            if activeDesign?.id != design.id { await start(design) }
        } else if rule == nil { matchingRuleID = nil }
        if report { message = lastEvaluation }
    }
    func resetAll() async {
        UserDefaults.standard.removeObject(forKey: RecentIslandColors.key)
        do { try MarketCredentials.save("") }
        catch { message = "Der gespeicherte Kursdaten-Schlüssel konnte nicht gelöscht werden. Bitte versuche das Zurücksetzen erneut."; return }
        await stop(); location.clear(); designs = []; rules = []; places = []; appearance = "System"; matchingRuleID = nil
        if let directory = SharedAssets.directory, FileManager.default.fileExists(atPath: directory.path) {
            do { try FileManager.default.removeItem(at: directory) }
            catch { message = "Einige gespeicherte Bilder konnten nicht gelöscht werden. Bitte versuche das Zurücksetzen erneut." }
        }
        persistenceAvailable = true; persist()
    }
}
