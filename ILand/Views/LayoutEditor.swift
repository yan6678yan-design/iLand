import SwiftUI

struct LayoutEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: IslandDesign
    let apply: (IslandDesign) -> Void
    @State private var selectedID: UUID?
    @State private var editingID: UUID?
    @FocusState private var focusedID: UUID?
    @State private var dragOrigin: LayoutItem?
    @State private var history: [IslandDesign] = []
    @State private var future: [IslandDesign] = []
    @State private var showSymbols = false
    @State private var confirmReset = false
    init(design: IslandDesign, apply: @escaping (IslandDesign) -> Void) {
        var copy = design
        if copy.customLayout == nil { copy.customLayout = .standard }
        _draft = State(initialValue: copy)
        self.apply = apply
    }
    private var items: [LayoutItem] { draft.customLayout?.items ?? [] }
    private var selected: LayoutItem? { items.first { $0.id == selectedID } }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Deine erweiterte Island").font(.headline)
                        Spacer()
                        Button { undo() } label: { Image(systemName: "arrow.uturn.backward") }.disabled(history.isEmpty).accessibilityLabel("Rückgängig")
                        Button { redo() } label: { Image(systemName: "arrow.uturn.forward") }.disabled(future.isEmpty).accessibilityLabel("Wiederholen")
                    }
                    artboard
                    Text(editingID == nil ? "Antippen zum Auswählen · Ziehen zum Verschieben\nText doppelt antippen zum Bearbeiten" : "Text direkt ändern und mit „Fertig“ bestätigen.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(20).background(Color.canvas)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(items) { item in
                                    Button { finishText(); selectedID = item.id } label: {
                                        Text(item.kind.name).font(.caption.weight(.medium)).padding(10)
                                            .background(selectedID == item.id ? Color.islandAccent : Color.card, in: Capsule())
                                            .foregroundStyle(selectedID == item.id ? .white : .primary)
                                    }.accessibilityIdentifier("select-layout-" + item.kind.rawValue)
                                }
                            }
                        }
                        if let item = selected {
                            inspector(item)
                        } else {
                            Label("Wähle oben ein Element aus.", systemImage: "hand.tap").foregroundStyle(.secondary).padding(.vertical, 8)
                        }
                        HStack(spacing: 12) {
                            Button { add(.text) } label: { Label("Text hinzufügen", systemImage: "text.badge.plus") }
                                .accessibilityIdentifier("addCanvasText")
                            Spacer()
                            Button { add(.decoration) } label: { Label("Emoji / Icon", systemImage: "face.smiling") }
                        }.font(.subheadline).disabled(items.count >= 12)
                        Text("Bis zu 12 Elemente. Der schwarze Bereich entspricht deinem Custom-Layout. Elemente bleiben innerhalb der sichtbaren Fläche.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Layout zurücksetzen", role: .destructive) { confirmReset = true }
                        if let error = draft.customLayout?.validationError { Text(error).font(.caption).foregroundStyle(.red) }
                    }.padding(20)
                }.background(Color.canvas)
            }.navigationTitle("Layout bearbeiten").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Übernehmen") { finishText(); apply(draft); dismiss() }.disabled(draft.customLayout?.validationError != nil) }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Fertig") { finishText() } }
                }
                .sheet(isPresented: $showSymbols) {
                    if let item = selected {
                        ElementEditor(design: symbolDesign(item), element: item.kind == .action ? .action : item.kind == .statusIcon ? .status : .badge, title: item.kind.name) { style in
                            checkpoint()
                            if item.kind == .decoration { update(item.id) { $0.glyph = style } }
                            else if item.kind == .mainIcon { setMain(style) }
                            else { draft.setStyle(style, for: item.kind == .statusIcon ? .status : item.kind == .action ? .action : .badge) }
                        }
                    }
                }
                .confirmationDialog("Layout zurücksetzen?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("Zurücksetzen", role: .destructive) { checkpoint(); draft.customLayout = .standard; selectedID = nil; finishText() }
                } message: { Text("Positionen und Größen werden zurückgesetzt, zusätzlich platzierte Elemente entfernt. Haupttexte und Symbole bleiben erhalten.") }
        }.interactiveDismissDisabled(!history.isEmpty)
    }
    private var artboard: some View {
        IslandPreviewSurface(design: draft) {
        GeometryReader { geometry in
            let ratio = IslandCanvasMetrics.ratio
            let horizontalRatio = ratio
            let verticalRatio = ratio
            ZStack(alignment: .topLeading) {
                ForEach(items.filter { !$0.hidden }) { item in
                    Group {
                        if editingID == item.id && item.kind.isText {
                            TextField("Dein Text", text: contentBinding(item), axis: .vertical)
                                .font(.system(size: item.kind == .title ? 16 : item.kind == .text ? 14 : 12, weight: item.kind == .title ? .semibold : .regular))
                                .multilineTextAlignment(draft.customLayout?.cameraLayout == true && [.title, .subtitle].contains(item.kind) ? .center : .leading)
                                .foregroundStyle(.white).tint(.white)
                                .focused($focusedID, equals: item.id)
                                .accessibilityIdentifier("canvasInlineText")
                        } else { LayoutItemContent(design: draft, item: item) }
                    }.frame(width: item.width, height: item.height)
                        .overlay {
                            if selectedID == item.id {
                                RoundedRectangle(cornerRadius: 5).stroke(Color.islandAccent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])).padding(-3)
                                    .allowsHitTesting(false)
                            }
                        }
                        .contentShape(Rectangle())
                        .scaleEffect(item.scale * ratio).rotationEffect(.degrees(item.rotation))
                        .position(x: item.x * horizontalRatio, y: item.y * verticalRatio)
                        .onTapGesture(count: 2) { selectedID = item.id; if item.kind.isText { beginText(item) } else { showSymbols = true } }
                        .onTapGesture { if editingID != item.id { finishText(); selectedID = item.id } }
                        .gesture(DragGesture(minimumDistance: 4, coordinateSpace: .named("layoutCanvas")).onChanged { value in
                            guard editingID == nil else { return }
                            if dragOrigin == nil { checkpoint(); dragOrigin = item; selectedID = item.id }
                            guard let origin = dragOrigin else { return }
                            update(item.id) { $0.x = origin.x + value.translation.width / horizontalRatio; $0.y = origin.y + value.translation.height / verticalRatio; $0.constrain() }
                        }.onEnded { _ in dragOrigin = nil })
                        .accessibilityLabel(item.kind.name)
                        .accessibilityIdentifier(editingID == item.id ? "canvasInlineText" : "canvas-" + item.kind.rawValue)
                        .accessibilityAddTraits(editingID == item.id ? [] : .isButton)
                        .accessibilityRemoveTraits(editingID == item.id ? .isButton : [])
                        .accessibilityAction(named: "Bearbeiten") { selectedID = item.id; if item.kind.isText { beginText(item) } else { showSymbols = true } }
                }
            }
        }.coordinateSpace(name: "layoutCanvas")
            .frame(height: IslandCanvasMetrics.logicalHeight * IslandCanvasMetrics.ratio)
            .padding(.top, IslandCanvasMetrics.isLegacy(draft) ? IslandCanvasMetrics.cameraClearance : 0)
        }.frame(maxWidth: 350).frame(maxWidth: .infinity)
    }
    @ViewBuilder private func inspector(_ item: LayoutItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(item.kind.name).font(.headline)
                Spacer()
                if item.kind.isText { Button("Text bearbeiten") { beginText(item) } }
                else { Button("Symbol ändern") { finishText(); showSymbols = true } }
            }
            slider("Größe", value: numberBinding(item, \.scale), range: 0.5...2.5, display: "\(Int(item.scale * 100)) %")
            slider("Drehung", value: numberBinding(item, \.rotation), range: -180...180, display: "\(Int(item.rotation))°", center: 0)
            DisclosureGroup("Position & Reihenfolge") {
                slider("Horizontal", value: numberBinding(item, \.x), range: 14...306, display: "\(Int(item.x))", center: 160)
                slider("Vertikal", value: numberBinding(item, \.y), range: 12...112, display: "\(Int(item.y))", center: canvasCenterY)
                HStack {
                    Button("Nach vorne") { checkpoint(); reorder(item.id, front: true) }
                    Spacer(); Button("Nach hinten") { checkpoint(); reorder(item.id, front: false) }
                }.font(.caption)
            }
            if item.kind == .mainIcon {
                Toggle("Symbolhintergrund", isOn: Binding(get: { draft.showsIconBackground }, set: { value in checkpoint(); draft.iconBackground = value })).accessibilityIdentifier("layoutIconBackground")
            }
            HStack {
                Button(role: .destructive) {
                    checkpoint(); draft.customLayout?.items.removeAll { $0.id == item.id }; selectedID = nil; finishText()
                } label: { Label("Löschen", systemImage: "trash") }
                .accessibilityIdentifier("deleteCanvasElement")
                Spacer()
                Button("Position zurücksetzen") {
                    checkpoint()
                    update(item.id) { value in
                        let original = IslandLayout.standard.items.first { $0.kind == value.kind }
                        value.x = original?.x ?? 160; value.y = original?.y ?? 62; value.scale = 1; value.rotation = 0; value.constrain()
                    }
                }.font(.caption)
            }
        }.surface()
    }
    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, display: String, center: Double? = nil) -> some View {
        VStack(spacing: 4) {
            HStack { Text(title); Spacer(); Text(display).monospacedDigit().foregroundStyle(.secondary) }.font(.caption)
            ZStack {
                if center != nil {
                    GeometryReader { geometry in
                        Capsule().fill(Color.islandAccent.opacity(0.65)).frame(width: 3, height: 16)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }.allowsHitTesting(false)
                }
                Slider(value: sliderValue(value, range: range, center: center), in: center == nil ? range : 0...1, onEditingChanged: { editing in if editing { finishText(); checkpoint() } })
                    .accessibilityLabel(title).accessibilityIdentifier("layout-" + title)
            }.frame(height: 32)

        }
    }
    // For older canvases the camera area makes the usable range asymmetric.
    // Map both halves separately so the real island center is still the slider midpoint.
    private func sliderValue(_ value: Binding<Double>, range: ClosedRange<Double>, center: Double?) -> Binding<Double> {
        guard let center else { return value }
        return Binding(get: {
            let current = value.wrappedValue
            return current <= center ? 0.5 * (current - range.lowerBound) / (center - range.lowerBound)
                : 0.5 + 0.5 * (current - center) / (range.upperBound - center)
        }, set: { fraction in
            value.wrappedValue = fraction <= 0.5 ? range.lowerBound + fraction * 2 * (center - range.lowerBound)
                : center + (fraction - 0.5) * 2 * (range.upperBound - center)
        })
    }
    private var canvasCenterY: Double {
        IslandCanvasMetrics.centerY(for: draft)
    }
    private func numberBinding(_ item: LayoutItem, _ key: WritableKeyPath<LayoutItem, Double>) -> Binding<Double> {
        Binding(get: { items.first { $0.id == item.id }?[keyPath: key] ?? item[keyPath: key] }, set: { value in
            let center: Double? = key == \.x ? 160 : key == \.y ? canvasCenterY : key == \.rotation ? 0 : nil
            let snapped = center.map { IslandCanvasMetrics.snapped(value, to: $0) } ?? value
            if let center, snapped == center, items.first(where: { $0.id == item.id })?[keyPath: key] != center {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            update(item.id) { $0[keyPath: key] = snapped; $0.constrain() }
        })
    }
    private func contentBinding(_ item: LayoutItem) -> Binding<String> {
        Binding(get: {
            switch item.kind {
            case .title: return draft.title
            case .subtitle: return draft.subtitle
            case .status: return draft.status
            default: return items.first { $0.id == item.id }?.text ?? ""
            }
        }, set: { value in
            switch item.kind {
            case .title: draft.title = String(value.prefix(60))
            case .subtitle: draft.subtitle = String(value.prefix(100))
            case .status: draft.status = String(value.prefix(100))
            default: update(item.id) { $0.text = String(value.prefix(60)) }
            }
        })
    }
    private func beginText(_ item: LayoutItem) { checkpoint(); selectedID = item.id; editingID = item.id; focusedID = item.id }
    private func finishText() { focusedID = nil; editingID = nil }
    private func update(_ id: UUID, _ change: (inout LayoutItem) -> Void) {
        guard let index = draft.customLayout?.items.firstIndex(where: { $0.id == id }) else { return }
        let avoidsCamera = draft.customLayout?.cameraLayout == true
        change(&draft.customLayout!.items[index])
        draft.customLayout!.items[index].constrain(avoidingCamera: avoidsCamera)
    }
    private func add(_ kind: LayoutItemKind) {
        guard items.count < 12 else { return }
        finishText(); checkpoint()
        let item = LayoutItem(kind: kind, x: 160, y: 66, width: kind == .text ? 150 : 30, height: kind == .text ? 24 : 30, text: kind == .text ? "Dein Text" : nil, glyph: kind == .decoration ? ElementStyle(appearance: .emoji, value: "✨") : nil)
        draft.customLayout?.items.append(item); selectedID = item.id
        if kind == .text { editingID = item.id; focusedID = item.id }
        else { showSymbols = true }
    }
    private func reorder(_ id: UUID, front: Bool) {
        guard let index = draft.customLayout?.items.firstIndex(where: { $0.id == id }), let item = draft.customLayout?.items.remove(at: index) else { return }
        if front { draft.customLayout?.items.append(item) } else { draft.customLayout?.items.insert(item, at: 0) }
    }
    private func checkpoint() { history.append(draft); if history.count > 30 { history.removeFirst() }; future.removeAll() }
    private func undo() { guard let previous = history.popLast() else { return }; finishText(); future.append(draft); draft = previous; if !items.contains(where: { $0.id == selectedID }) { selectedID = nil } }
    private func redo() { guard let next = future.popLast() else { return }; finishText(); history.append(draft); draft = next }
    private func symbolDesign(_ item: LayoutItem) -> IslandDesign {
        var value = draft
        let style: ElementStyle
        switch item.kind {
        case .mainIcon:
            switch draft.iconMode {
            case .symbol: style = ElementStyle(appearance: .symbol, value: draft.symbol)
            case .emoji: style = ElementStyle(appearance: .emoji, value: draft.emoji)
            case .brand: style = ElementStyle(appearance: .brand, value: draft.brandID ?? "")
            case .image: style = ElementStyle(appearance: .image, value: draft.imageName ?? "")
            }
        case .decoration: style = item.glyph ?? ElementStyle(appearance: .emoji, value: "✨")
        default: style = draft.style(item.kind == .statusIcon ? .status : item.kind == .action ? .action : .badge)
        }
        value.setStyle(style, for: .badge); return value
    }
    private func setMain(_ style: ElementStyle) {
        switch style.appearance {
        case .symbol: draft.iconMode = .symbol; draft.symbol = style.value
        case .emoji: draft.iconMode = .emoji; draft.emoji = style.value
        case .brand: draft.iconMode = .brand; draft.brandID = style.value
        case .image: draft.iconMode = .image; draft.imageName = style.value
        case .hidden: if let id = selectedID { update(id) { $0.hidden = true } }
        case .automatic: draft.iconMode = .symbol; draft.symbol = "sparkles"
        }
    }
}
