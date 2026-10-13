import SwiftUI

@main
struct ILandApp: App {
    @StateObject private var store: IslandStore
    init() {
        #if DEBUG
        if let value = ProcessInfo.processInfo.environment["ILAND_UI_TEST_STORE"], let id = UUID(uuidString: value) {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("UITests/\(id.uuidString)/state.json")
            _store = StateObject(wrappedValue: IslandStore(fileURL: file))
        } else { _store = StateObject(wrappedValue: IslandStore()) }
        #else
        _store = StateObject(wrappedValue: IslandStore())
        #endif
    }
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store) }
    }
}
