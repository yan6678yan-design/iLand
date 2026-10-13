import ActivityKit
import AppIntents
import Foundation

@MainActor
enum ActivityControls {
    static func timer(id: String, reset: Bool = false) async {
        guard let activity = Activity<IslandAttributes>.activities.first(where: { $0.id == id }), activity.attributes.design.kind == .timer else { return }
        var state = activity.content.state
        if reset {
            state.remaining = Double(activity.attributes.design.durationMinutes * 60)
            state.endDate = Date().addingTimeInterval(state.remaining); state.paused = false
        } else if state.paused {
            state.endDate = Date().addingTimeInterval(state.remaining); state.paused = false
        } else {
            state.remaining = max(0, state.endDate.timeIntervalSinceNow); state.paused = true
        }
        state.revision += 1
        await activity.update(ActivityContent(state: state, staleDate: state.paused ? nil : state.endDate))
    }
}

struct TimerToggleIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Timer pausieren oder fortsetzen"
    @Parameter(title: "Aktivität") var activityID: String
    init() {}
    init(activityID: String) { self.activityID = activityID }
    @MainActor func perform() async throws -> some IntentResult { await ActivityControls.timer(id: activityID); return .result() }
}
struct TimerResetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Timer zurücksetzen"
    @Parameter(title: "Aktivität") var activityID: String
    init() {}
    init(activityID: String) { self.activityID = activityID }
    @MainActor func perform() async throws -> some IntentResult { await ActivityControls.timer(id: activityID, reset: true); return .result() }
}


struct MarketRefreshIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Kurs aktualisieren"
    @Parameter(title: "Aktivität") var activityID: String
    init() {}
    init(activityID: String) { self.activityID = activityID }
    @MainActor func perform() async throws -> some IntentResult {
        await MarketActivityUpdates.refresh(id: activityID, force: true)
        return .result()
    }
}
@MainActor enum MarketActivityUpdates {
    private static var loading = Set<String>()
    static func refresh(id: String, force: Bool = false) async {
        guard !loading.contains(id), let activity = Activity<IslandAttributes>.activities.first(where: { $0.id == id && $0.attributes.design.kind == .market }), activity.activityState == .active || activity.activityState == .stale else { return }
        loading.insert(id); defer { loading.remove(id) }
        var state = activity.content.state
        do {
            state.marketQuote = try await MarketClient.shared.quote(for: activity.attributes.design.selectedAsset, force: force)
            state.marketError = nil
        } catch { state.marketError = "Kurs konnte nicht aktualisiert werden." }
        guard activity.activityState == .active || activity.activityState == .stale else { return }
        state.revision += 1
        await activity.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(state.marketError == nil ? 60 : 0)))
    }
}
