import SwiftUI
import Combine

struct RootView: View {
    @EnvironmentObject private var store: IslandStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    @State private var destination: IslandDesign?
    @State private var pendingWebsite: URL?
    @Environment(\.openURL) private var openURL
    private let tick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    var body: some View {
        TabView(selection: $tab) {
            HomeView().tabItem { Label("Home", systemImage: "square.grid.2x2.fill") }.tag(0)
            DesignsView().tabItem { Label("Designs", systemImage: "square.stack.3d.up") }.tag(1)
            RulesView().tabItem { Label("Regeln", systemImage: "bolt.horizontal") }.tag(2)
            SettingsView().tabItem { Label("Einstellungen", systemImage: "slider.horizontal.3") }.tag(3)
        }.tint(.islandAccent)
            .preferredColorScheme(store.appearance == "Dunkel" ? .dark : store.appearance == "Hell" ? .light : nil)
            .task { await store.refresh() }
            .onChange(of: scenePhase) { _, phase in if phase == .active { openPendingWebsite(); Task { await store.refresh(); await store.refreshMarket() } } }
            .onReceive(tick) { _ in if scenePhase == .active { Task { await store.evaluateRules(); await store.refreshMarket() } } }
            .onOpenURL { url in
                guard let route = IslandRoute(url: url) else { return }
                switch route {
                case .design(let id): destination = store.designs.first { $0.id == id }
                case .website(let id):
                    guard let design = store.designs.first(where: { $0.id == id }), design.actionKind == .website, let website = design.validActionURL else {
                        store.message = "Für dieses Design ist keine gültige Webseite mehr gespeichert."
                        return
                    }
                    pendingWebsite = website
                    if scenePhase == .active { openPendingWebsite() }
                }
            }
            .sheet(item: $destination) { DesignDetail(designID: $0.id) }
            .onChange(of: store.message, initial: true) { _, message in
                guard let message else { return }
                // Present above the current sheet, preserving unsaved editor state.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    guard store.message == message else { return }
                    MessagePresenter.show(message) { store.message = nil }
                }
            }
    }
    private func openPendingWebsite() {
        guard let website = pendingWebsite else { return }
        pendingWebsite = nil
        openURL(website) { accepted in
            if !accepted { store.message = "Die Webseite konnte nicht geöffnet werden." }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: IslandStore
    @State private var editor: IslandDesign?
    @State private var detail: IslandDesign?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack {
                        HStack(spacing: 9) {
                            Capsule().fill(.primary).frame(width: 29, height: 13).overlay(alignment: .trailing) { Circle().fill(Color.islandAccent).frame(width: 5, height: 5).padding(4) }
                            Text("iLand").font(.title2.bold())
                        }
                        Spacer()
                        Text("DEINE ISLAND. DEIN STIL.").font(.system(size: 8, weight: .bold)).tracking(1.4).foregroundStyle(.secondary)
                    }.padding(.top, 12)
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Kleine Island.\nGroße Möglichkeiten.").font(.system(size: 34, weight: .bold, design: .rounded)).tracking(-1)
                        Text("Mach sie zu einem Teil von dir.").font(.subheadline).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Label(store.activeDesign == nil ? "DEINE NÄCHSTE ISLAND" : "AKTIVE DYNAMIC ISLAND", systemImage: store.activeDesign == nil ? "sparkles" : "dot.radiowaves.left.and.right")
                                .font(.system(size: 10, weight: .bold)).tracking(1)
                            Spacer()
                            Text(store.activeDesign == nil ? "VORSCHAU" : "LIVE").font(.system(size: 9, weight: .heavy)).padding(.horizontal, 9).padding(.vertical, 5).background(.white.opacity(0.16), in: Capsule())
                        }.foregroundStyle(.white.opacity(0.75))
                        IslandPreview(design: featured, expanded: true, liveState: store.activeState).frame(maxWidth: .infinity).padding(.vertical, 5)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(featured.name).font(.headline)
                                Text(store.activeDesign == nil ? "Ein Design, das zu deinem Moment passt." : "Auf deiner Island und dem Sperrbildschirm.").font(.caption).foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            Button { detail = featured } label: { Image(systemName: "arrow.up.right").font(.headline).frame(width: 42, height: 42).background(.white.opacity(0.15), in: Circle()) }.accessibilityLabel("Design öffnen")
                        }.foregroundStyle(.white)
                    }.padding(22).background(LinearGradient(colors: [Color(red: 0.24, green: 0.19, blue: 0.4), Color(red: 0.12, green: 0.11, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 30))
                    Button { editor = .blank } label: {
                        HStack(spacing: 15) {
                            Image(systemName: "plus").font(.title3.weight(.medium)).frame(width: 44, height: 44).background(Color.islandAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) { Text("Neues Design erstellen").font(.headline); Text("Deine Idee. Ein ganz eigener Look.").font(.caption).foregroundStyle(Color(uiColor: .secondaryLabel)) }
                            Spacer(); Image(systemName: "arrow.right").font(.subheadline)
                        }.foregroundStyle(Color.islandAccent).surface()
                    }.buttonStyle(.plain).accessibilityIdentifier("createDesign")
                    SectionHeading(title: "Meine Designs", caption: "\(store.designs.count) Designs")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(store.orderedDesigns.prefix(4)) { design in Button { detail = design } label: { DesignTile(design: design, isActive: store.activeDesign?.id == design.id) }.buttonStyle(.plain) }
                    }
                    if !store.recentDesigns.isEmpty {
                        SectionHeading(title: "Zuletzt verwendet")
                        ForEach(store.recentDesigns.prefix(3)) { design in designRow(design) }
                    }
                    if store.designs.contains(where: \.favorite) {
                        SectionHeading(title: "Deine Favoriten", caption: "IMMER GRIFFBEREIT")
                        ForEach(store.designs.filter(\.favorite)) { design in designRow(design) }
                    }
                    Label("Für deine Momente. Mit Apple Live Activities.", systemImage: "checkmark.shield").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.bottom, 16)
                }.padding(.horizontal, 22)
            }.background(Color.canvas).toolbar(.hidden, for: .navigationBar)
                .sheet(item: $editor) { DesignEditor(design: $0) }
                .sheet(item: $detail) { DesignDetail(designID: $0.id) }
        }
    }
    private var featured: IslandDesign { store.activeDesign ?? store.designs.first ?? .blank }
    private func designRow(_ design: IslandDesign) -> some View {
        Button { detail = design } label: {
            HStack(spacing: 13) { DesignIcon(design: design, size: 34); VStack(alignment: .leading, spacing: 3) { Text(design.name).font(.subheadline.bold()); Text(design.subtitle).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary) }.surface()
        }.buttonStyle(.plain)
    }
}

struct DesignsView: View {
    @EnvironmentObject private var store: IslandStore
    @State private var search = ""
    @State private var favorites = false
    @State private var editor: IslandDesign?
    @State private var detail: IslandDesign?
    var filtered: [IslandDesign] { store.orderedDesigns.filter { (!favorites || $0.favorite) && (search.isEmpty || "\($0.name) \($0.title)".localizedCaseInsensitiveContains(search)) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Filter", selection: $favorites) { Text("Alle Designs").tag(false); Text("Favoriten").tag(true) }.pickerStyle(.segmented)
                    if filtered.isEmpty { ContentUnavailableView("Noch kein Design", systemImage: "square.stack", description: Text("Erstelle ein Design oder passe den Filter an.")) }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(filtered) { design in
                            Button { detail = design } label: { DesignTile(design: design, isActive: store.activeDesign?.id == design.id) }.buttonStyle(.plain)
                                .contextMenu {
                                    Button("Bearbeiten", systemImage: "pencil") { editor = design }
                                    Button("Duplizieren", systemImage: "plus.square.on.square") { store.duplicate(design) }
                                    Button(design.favorite ? "Favorit entfernen" : "Als Favorit", systemImage: "heart") { store.toggleFavorite(design) }
                                }
                        }
                    }
                }.padding(20)
            }.background(Color.canvas).navigationTitle("Meine Designs")
                .searchable(text: $search, prompt: "Design suchen")
                .toolbar { Button { editor = .blank } label: { Image(systemName: "plus") }.accessibilityLabel("Neues Design") }
                .sheet(item: $editor) { DesignEditor(design: $0) }
                .sheet(item: $detail) { DesignDetail(designID: $0.id) }
        }
    }
}
