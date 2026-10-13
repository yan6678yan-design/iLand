import SwiftUI
import PhotosUI

struct DesignEditor: View {
    @EnvironmentObject private var store: IslandStore
    @Environment(\.dismiss) private var dismiss
    @State var design: IslandDesign
    @State private var expanded = true
    @State private var showLayout = false
    @State private var showLeftSymbol = false
    @State private var editingRight = false
    @State private var photo: PhotosPickerItem?
    @State private var category = "Alle"
    @State private var showBrands = false
    @State private var saved = false
    @State private var saving = false
    @State private var importingPhoto = false
    @State private var marketQuote: MarketQuote?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    PreviewStage(design: design, expanded: expanded, simulation: true, liveState: marketPreviewState)
                    Picker("Darstellung", selection: $expanded) { Text("Kompakt").tag(false); Text("Erweitert").tag(true) }.pickerStyle(.segmented)
                    if design.kind == .custom && expanded {
                        Button { showLayout = true } label: {
                            Label("Layout direkt bearbeiten", systemImage: "hand.draw").font(.headline).frame(maxWidth: .infinity).padding(14)
                        }.buttonStyle(.borderedProminent).accessibilityIdentifier("editCanvas")
                        if design.customLayout != nil {
                            Button("Standardlayout verwenden") { design.customLayout = nil }.font(.caption)
                        }
                    }
                    NavigationLink {
                        PersonalizationEditor(design: $design)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3").font(.title2)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Details personalisieren").font(.headline)
                                Text("Jedes Symbol, kurze Texte und Beschriftungen").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(); Image(systemName: "chevron.right").font(.caption)
                        }.surface()
                    }.accessibilityIdentifier("personalizeDetails")
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeading(title: "Dein Design")
                        entry("Name", text: $design.name)
                        Picker("Aktivität", selection: $design.kind) { ForEach(DesignKind.available) { Text($0.rawValue).tag($0) } }.accessibilityIdentifier("designKind")
                    }.surface()
                    if design.kind == .market && DistributionFeatures.thirdPartyCatalogs { MarketEditor(design: $design, quote: $marketQuote) }
                    VStack(alignment: .leading, spacing: 17) {
                        SectionHeading(title: "Symbol & Farbe")
                        HStack(spacing: 12) {
                            Button { withAnimation(.easeInOut(duration: 0.2)) { showLeftSymbol = !showLeftSymbol || editingRight; editingRight = false } } label: {
                                Label("Symbol links", systemImage: "square.dashed").frame(maxWidth: .infinity)
                            }.accessibilityIdentifier("editLeftSymbol")
                            Button { withAnimation(.easeInOut(duration: 0.2)) { showLeftSymbol = !showLeftSymbol || !editingRight; editingRight = true } } label: {
                                Label("Symbol rechts", systemImage: "face.smiling").frame(maxWidth: .infinity)
                            }.accessibilityIdentifier("editRightSymbol")
                        }.buttonStyle(.bordered).font(.subheadline).lineLimit(1).minimumScaleFactor(0.8)
                        if showLeftSymbol {

                        Picker("Symbolart", selection: symbolModeBinding) { ForEach(IconMode.available) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                        if symbolMode == .symbol {
                            Picker("Kategorie", selection: $category) { ForEach(SymbolLibrary.categories, id: \.self) { Text($0).tag($0) } }
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(SymbolLibrary.symbols(category), id: \.self) { symbol in
                                    Button { symbolText(\.symbol, mode: .symbol).wrappedValue = symbol } label: { Image(systemName: symbol).font(.title3).frame(maxWidth: .infinity).frame(height: 42).background(symbolText(\.symbol, mode: .symbol).wrappedValue == symbol ? design.tint.color.opacity(0.2) : Color.canvas, in: RoundedRectangle(cornerRadius: 12)) }.buttonStyle(.plain).accessibilityLabel(symbol).accessibilityAddTraits(symbolText(\.symbol, mode: .symbol).wrappedValue == symbol ? .isSelected : [])
                                }
                            }
                            DisclosureGroup("Weitere System-Icons") {
                                entry("SF-Symbol-Name", text: symbolText(\.symbol, mode: .symbol)).textInputAutocapitalization(.never).autocorrectionDisabled()
                            }
                        } else if symbolMode == .emoji {
                            entry("Emoji", text: symbolText(\.emoji, mode: .emoji))
                            Text("Wähle ein Emoji über die iPhone-Tastatur.").font(.caption).foregroundStyle(.secondary)
                        } else if symbolMode == .brand {
                            Button { showBrands = true } label: {
                                HStack(spacing: 14) {
                                    if let id = brandSelection.wrappedValue, !id.isEmpty { BrandLogo(id: id, size: 42) }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(BrandCatalog.all.first { $0.id == brandSelection.wrappedValue }?.name ?? "Logo auswählen").font(.headline)
                                        Text("100 Markenlogos").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer(); Image(systemName: "chevron.right")
                                }.padding(.vertical, 8)
                            }.accessibilityIdentifier("chooseBrand")
                        } else {
                            PhotosPicker(selection: $photo, matching: .images) { Label("Eigenes Bild auswählen", systemImage: "photo.badge.plus") }
                            Text("Verwende nur Bilder und Markenlogos, für die du die erforderlichen Rechte hast. Bilder werden lokal gespeichert.").font(.caption).foregroundStyle(.secondary)
                        }
                        if editingRight {
                            HStack {
                                Button("Standard") { design.setStyle(ElementStyle(), for: rightElement) }
                                Spacer()
                                Button(role: .destructive) { design.setStyle(ElementStyle(appearance: .hidden), for: rightElement); showLeftSymbol = false } label: { Label("Löschen", systemImage: "trash") }
                            }.font(.subheadline)
                        } else {
                        Toggle("Symbolhintergrund", isOn: Binding(get: { design.showsIconBackground }, set: { design.iconBackground = $0 }))
                            .accessibilityIdentifier("iconBackground")
                        }
                        }
                        Divider()
                        DesignColors(tint: $design.tint)
                    }.surface()
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "Inhalte")
                        entry("Titel", text: $design.title)
                        entry("Untertitel", text: $design.subtitle)
                        entry("Status", text: $design.status)
                        if design.kind == .timer { Stepper("Dauer: \(design.durationMinutes) Minuten", value: $design.durationMinutes, in: 1...480) }
                        if design.kind == .travel {
                            entry("Flugnummer", text: $design.flightNumber); entry("Gate", text: $design.gate)
                            DatePicker("Abflug", selection: $design.departure)
                            Text("Reisedaten werden von dir gepflegt; keine automatische Flugdatenabfrage.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.surface()
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "Bewegung")
                        Picker("Animation", selection: $design.motion) { ForEach(IslandMotion.allCases) { Text($0.rawValue).tag($0) } }
                        Text("Vorschau in iLand. Live Activities animieren nur unterstützte Inhaltswechsel; iOS bestimmt Dauer und Darstellung.").font(.caption).foregroundStyle(.secondary)
                    }.surface()
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "Webseite & Aktionen")
                        Picker("Aktion", selection: $design.actionKind) { ForEach(ActionKind.allCases) { Text($0.rawValue).tag($0) } }.accessibilityIdentifier("actionKind")
                        if design.actionKind != .inApp {
                            entry(design.actionKind == .website ? "Domain oder Webseite" : "App-URL / Deep Link", text: $design.actionURL)
                                .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                                .accessibilityIdentifier("actionAddress")
                        }
                        if design.actionKind == .website {
                            Text("Zum Beispiel example.com. Halte die Dynamic Island gedrückt und tippe auf „Webseite“. iLand übergibt den Link an deinen Standardbrowser.").font(.caption).foregroundStyle(.secondary)
                            if let url = design.validActionURL { Label(url.absoluteString, systemImage: "checkmark.circle").font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                        } else {
                            Text("Mit „Webseite“ fügst du einen direkt erreichbaren Link hinzu. Andere App-Aktionen öffnest du aus der Detailansicht.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.surface()
                    PrimaryButton(title: "Design speichern", icon: "checkmark") { save() }
                }.padding(20)
            }.disabled(saving || importingPhoto)
                .overlay { if saved { SaveConfirmation(needsRestart: store.activeDesign?.id == design.id).transition(.opacity.combined(with: .scale(scale: 0.96))) } }
                .background(Color.canvas).navigationTitle("Design-Studio").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() }.disabled(saving) }; ToolbarItem(placement: .confirmationAction) { Button("Sichern") { save() }.bold().disabled(saving || importingPhoto) } }
                .interactiveDismissDisabled(saving)
                .onChange(of: expanded) { _, _ in showLeftSymbol = false }
                .onChange(of: design.kind) { _, kind in if kind == .market { design.selectAsset(design.selectedAsset) } }
                .sheet(isPresented: $showLayout) { LayoutEditor(design: design) { design = $0 } }
                .sheet(isPresented: $showBrands) { BrandPicker(selectedID: brandSelection) }
                .onChange(of: photo) { _, item in
                    let target: IslandElement? = editingRight ? rightElement : nil
                    Task {
                        importingPhoto = true
                        defer { importingPhoto = false }
                        do {
                            guard let data = try await item?.loadTransferable(type: Data.self) else { return }
                            let name = try SharedAssets.save(data)
                            if let target { design.setStyle(ElementStyle(appearance: .image, value: name), for: target) }
                            else { design.imageName = name }
                        } catch { store.message = error.localizedDescription }
                    }
                }
        }
    }
    private var marketPreviewState: IslandAttributes.ContentState? {
        guard design.kind == .market, let marketQuote else { return nil }
        var state = IslandAttributes.ContentState(title: design.title, subtitle: design.subtitle, status: design.status, endDate: Date(), remaining: 0)
        state.marketQuote = marketQuote
        return state
    }
    private var rightElement: IslandElement { expanded ? .badge : .compact }
    private var symbolMode: IconMode {
        guard editingRight else { return design.iconMode }
        switch design.style(rightElement).appearance {
        case .emoji: return .emoji
        case .brand: return .brand
        case .image: return .image
        default: return .symbol
        }
    }
    private var symbolModeBinding: Binding<IconMode> {
        Binding(get: { symbolMode }, set: { mode in
            if !editingRight { design.iconMode = mode; return }
            let appearance: ElementAppearance = mode == .emoji ? .emoji : mode == .brand ? .brand : mode == .image ? .image : .symbol
            design.setStyle(ElementStyle(appearance: appearance, value: mode == .emoji ? "✨" : mode == .symbol ? rightElement.symbol(for: design) : ""), for: rightElement)
        })
    }
    private func symbolText(_ key: WritableKeyPath<IslandDesign, String>, mode: IconMode) -> Binding<String> {
        Binding(get: {
            if !editingRight { return design[keyPath: key] }
            let style = design.style(rightElement)
            return style.appearance == .automatic ? rightElement.symbol(for: design) : style.value
        }, set: { value in
            if editingRight { design.setStyle(ElementStyle(appearance: mode == .emoji ? .emoji : .symbol, value: value), for: rightElement) }
            else { design[keyPath: key] = value }
        })
    }
    private var brandSelection: Binding<String?> {
        Binding(get: { editingRight ? design.style(rightElement).value : design.brandID }, set: { value in
            if editingRight { design.setStyle(ElementStyle(appearance: .brand, value: value ?? ""), for: rightElement) }
            else { design.brandID = value }
        })
    }
    private func entry(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 7) { Text(title).font(.caption).foregroundStyle(.secondary); TextField(title, text: text).padding(12).background(Color.canvas, in: RoundedRectangle(cornerRadius: 12)) }
    }
    private func save() {
        guard !saving && !importingPhoto else { return }
        if let error = design.validationError { store.message = error; return }
        if design.actionKind == .website { design.actionURL = design.validActionURL?.absoluteString ?? design.actionURL }
        guard store.save(design) else { return }
        RecentIslandColors.record(design.tint)
        saving = true
        withAnimation(.easeOut(duration: 0.18)) { saved = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Task { try? await Task.sleep(for: .milliseconds(1800)); dismiss() }
    }
}

struct DesignDetail: View {
    let designID: UUID
    @EnvironmentObject private var store: IslandStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var edit = false
    @State private var expanded = false
    @State private var delete = false
    private var design: IslandDesign { store.designs.first { $0.id == designID } ?? .blank }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 23) {
                    PreviewStage(design: design, expanded: expanded, liveState: store.activeDesign?.id == design.id ? store.activeState : nil)
                    Picker("Vorschau", selection: $expanded) { Text("Kompakt").tag(false); Text("Erweitert").tag(true) }.pickerStyle(.segmented)
                    HStack { VStack(alignment: .leading, spacing: 5) { Text(design.name).font(.largeTitle.bold()); Text(design.kind.rawValue).foregroundStyle(.secondary) }; Spacer(); Button { store.toggleFavorite(design) } label: { Image(systemName: design.favorite ? "heart.fill" : "heart").font(.title2) }.accessibilityLabel("Favorit umschalten") }
                    if design.kind == .market && DistributionFeatures.thirdPartyCatalogs {
                        Text("Automatische Kurse bei geöffneter App · in der Island über ↻ aktualisieren. Aktien benötigen einen Finnhub-Schlüssel unter Einstellungen → Kursdaten.").font(.caption).foregroundStyle(.secondary)
                        if store.activeDesign?.id == designID { Button("Kurs aktualisieren") { Task { await store.refreshMarket() } } }
                    }
                    if store.activeDesign?.id == designID && design.kind == .timer {
                        VStack(alignment: .leading, spacing: 15) {
                            if let state = store.activeState {
                                HStack {
                                    Text(state.paused ? "Pausiert" : "Timer läuft").font(.subheadline.bold())
                                    Spacer()
                                    if state.paused { Text(Duration.seconds(state.remaining).formatted(.time(pattern: .minuteSecond))).monospacedDigit() }
                                    else { Text(timerInterval: Date()...max(Date(), state.endDate), countsDown: true).monospacedDigit().frame(maxWidth: 90) }
                                }
                            }
                            HStack { Button("Pause / Fortsetzen") { Task { await store.toggleTimer() } }; Spacer(); Button("Zurücksetzen") { Task { await store.resetTimer() } } }
                        }.surface()
                    }
                    Button { edit = true } label: { Label("Bearbeiten", systemImage: "pencil").frame(maxWidth: .infinity).padding(16) }.buttonStyle(.bordered).accessibilityIdentifier("editDesign")
                    if store.activeDesign?.id == designID {
                        PrimaryButton(title: "Live Activity beenden", icon: "stop.fill") { Task { await store.stop() } }
                    } else {
                        PrimaryButton(title: "Als Live Activity aktivieren", icon: "dot.radiowaves.left.and.right") { Task { await store.start(design) } }.disabled(store.busy)
                    }
                    if design.actionKind != .inApp, let url = design.validActionURL {
                        Button { openURL(url) { accepted in if !accepted { store.message = "Der Link konnte nicht geöffnet werden. Prüfe, ob die zugehörige App installiert ist." } } } label: { Label("Verknüpfte Aktion öffnen", systemImage: "arrow.up.right.square").frame(maxWidth: .infinity) }
                    }
                    Text("Live Activities begleiten eine zeitlich begrenzte Aktivität. iOS bestimmt die Sichtbarkeit und beendet sie spätestens nach 8 Stunden. Auf iPhones ohne Dynamic Island erscheint die Aktivität auf dem Sperrbildschirm.").font(.caption).foregroundStyle(.secondary)
                }.padding(22)
            }.background(Color.canvas).navigationTitle("Deine Island").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Fertig") { dismiss() } }
                    ToolbarItem(placement: .primaryAction) { Menu {
                        Button("Bearbeiten", systemImage: "pencil") { edit = true }
                        Button("Duplizieren", systemImage: "square.on.square") { store.duplicate(design) }
                        Button("Löschen", systemImage: "trash", role: .destructive) { delete = true }
                    } label: { Image(systemName: "ellipsis.circle") } }
                }
                .sheet(isPresented: $edit) { DesignEditor(design: design) }
                .confirmationDialog("Design und zugehörige Regeln löschen?", isPresented: $delete, titleVisibility: .visible) { Button("Design löschen", role: .destructive) { Task { await store.delete(design); dismiss() } } }
        }
    }
}
