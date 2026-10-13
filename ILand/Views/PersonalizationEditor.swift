import SwiftUI
import PhotosUI

struct PersonalizationEditor: View {
    @Binding var design: IslandDesign
    @State private var expanded = true
    @State private var selectedElement: IslandElement?
    @State private var reset = false
    var body: some View {
        Form {
            Section {
                PreviewStage(design: design, expanded: expanded)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                Picker("Vorschau", selection: $expanded) {
                    Text("Kompakt").tag(false); Text("Erweitert").tag(true)
                }.pickerStyle(.segmented)
            }
            Section {
                field("Titel", text: $design.title, limit: 60)
                field("Untertitel", text: $design.subtitle, limit: 100)
                field("Status", text: $design.status, limit: 100)

            } header: { Text("Deine Texte") } footer: {
                Text("Emojis sind in allen Textfeldern möglich. Leere Texte werden ausgeblendet. Den Namen deines Designs änderst du im Haupteditor.")
            }
            Section {
                Toggle("Eigenen Kompakttext verwenden", isOn: Binding(get: { design.customization.compactText != nil }, set: { enabled in
                    change { $0.compactText = enabled ? String(design.title.prefix(12)) : nil }
                })).accessibilityIdentifier("customCompactText")
                if design.customization.compactText != nil {
                    field("Kompakttext", text: textBinding(\.compactText, fallback: ""), limit: 12)
                        .accessibilityIdentifier("compactText")
                }
                ForEach(design.editableElements.filter { $0 != .compact || design.customization.compactText == nil }) { element in
                    Button { selectedElement = element } label: {
                        HStack(spacing: 12) {
                            IslandElementIcon(design: design, element: element, size: 28)
                                .frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(element.title).foregroundStyle(.primary)
                                Text(design.style(element).appearance.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 3)
                    }.accessibilityIdentifier("element-" + element.rawValue)
                }
            } header: { Text("Symbole & kompakte Island") } footer: {
                Text("Jedes Symbol kann ein Icon, Emoji, Logo oder eigenes Bild sein. Dekorative Symbole lassen sich auch ausblenden. Die Funktionen der Tasten bleiben erhalten.")
                if design.kind == .timer { Text("Ein eigener Kompakttext ersetzt die kleine Zeitanzeige. Der Countdown bleibt in der erweiterten Island sichtbar.") }
            }
            if design.kind == .custom || design.actionKind == .website || design.kind == .travel {
                Section("Beschriftungen") {
                    if design.kind == .custom || design.actionKind == .website {
                        field("Link-Beschriftung", text: textBinding(\.actionText, fallback: design.actionKind == .website ? "Webseite" : ""), limit: 20)
                            .accessibilityIdentifier("actionText")
                        Text("Leer lassen, um nur das Symbol anzuzeigen.").font(.caption).foregroundStyle(.secondary)
                    }
                    if design.kind == .travel {
                        field("Gate-Beschriftung", text: textBinding(\.gateText, fallback: "Gate"), limit: 20)
                    }
                }
            }
            Section {
                Button("Details auf Standard zurücksetzen", role: .destructive) { reset = true }
            } footer: { Text("Änderungen siehst du sofort in der Vorschau. Gespeichert wird erst mit „Sichern“ im Design-Studio.") }
        }
        .navigationTitle("Details personalisieren").navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedElement) { element in
            ElementEditor(design: design, element: element) { design.setStyle($0, for: element) }
        }
        .confirmationDialog("Zusätzliche Details zurücksetzen?", isPresented: $reset, titleVisibility: .visible) {
            Button("Details zurücksetzen", role: .destructive) { design.personalization = nil }
        } message: { Text("Titel, Untertitel, Status und Hauptsymbol bleiben erhalten.") }
    }
    private func field(_ title: String, text: Binding<String>, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text("\(text.wrappedValue.count)/\(limit)")
                    .foregroundStyle(text.wrappedValue.count > limit ? Color.red : Color.secondary)
            }.font(.caption).foregroundStyle(.secondary)
            TextField(title, text: text)
        }.padding(.vertical, 3)
    }
    private func change(_ update: (inout IslandPersonalization) -> Void) {
        var value = design.customization; update(&value); design.personalization = value
    }
    private func textBinding(_ key: WritableKeyPath<IslandPersonalization, String?>, fallback: String) -> Binding<String> {
        Binding(get: { design.customization[keyPath: key] ?? fallback }, set: { text in change { $0[keyPath: key] = text } })
    }
}

struct ElementEditor: View {
    let design: IslandDesign
    let element: IslandElement
    let apply: (ElementStyle) -> Void
    let titleOverride: String?
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ElementStyle
    @State private var category = "Alle"
    @State private var showBrands = false
    @State private var photo: PhotosPickerItem?
    @State private var importing = false
    @State private var error: String?
    init(design: IslandDesign, element: IslandElement, title: String? = nil, apply: @escaping (ElementStyle) -> Void) {
        self.design = design; self.element = element; self.apply = apply; self.titleOverride = title
        _draft = State(initialValue: design.style(element))
    }
    private var preview: IslandDesign { var copy = design; copy.setStyle(draft, for: element); return copy }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack { Spacer(); IslandElementIcon(design: preview, element: element, size: 56); Spacer() }
                        .padding(20).listRowBackground(Color.black)
                    Picker("Darstellung", selection: $draft.appearance) {
                        ForEach(ElementAppearance.available.filter { element.decorative || $0 != .hidden }) { Text($0.rawValue).tag($0) }
                    }.accessibilityIdentifier("elementAppearance")
                    if draft.appearance == .emoji {
                        TextField("Dein Emoji", text: $draft.value).accessibilityIdentifier("elementEmoji")
                        Text("Nutze die Emoji-Tastatur. Bis zu vier Zeichen.").font(.caption).foregroundStyle(.secondary)
                    } else if draft.appearance == .symbol {
                        Picker("Kategorie", selection: $category) { ForEach(SymbolLibrary.categories, id: \.self) { Text($0).tag($0) } }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(SymbolLibrary.symbols(category), id: \.self) { symbol in
                                Button { draft.value = symbol } label: {
                                    Image(systemName: symbol).frame(maxWidth: .infinity).frame(height: 44)
                                        .background(draft.value == symbol ? Color.islandAccent.opacity(0.18) : Color.canvas, in: RoundedRectangle(cornerRadius: 12))
                                }.buttonStyle(.plain).accessibilityLabel(symbol)
                            }
                        }
                        DisclosureGroup("Weitere System-Icons") {
                            TextField("SF-Symbol-Name", text: $draft.value).textInputAutocapitalization(.never).autocorrectionDisabled()
                            Text("Du kannst auch den Namen eines beliebigen auf diesem iPhone verfügbaren SF Symbols eingeben.").font(.caption).foregroundStyle(.secondary)
                        }
                    } else if draft.appearance == .brand {
                        Button("Logo auswählen") { showBrands = true }
                    } else if draft.appearance == .image {
                        PhotosPicker(selection: $photo, matching: .images) { Label("Eigenes Bild auswählen", systemImage: "photo") }
                        if importing { ProgressView("Bild wird vorbereitet …") }
                    }
                } footer: {
                    if let validation = draft.error { Text(validation).foregroundStyle(.secondary) }
                    else if !element.decorative { Text("Die Taste führt weiterhin „\(element.title)“ aus — auch mit einem anderen Symbol.") }
                }
            }.navigationTitle(titleOverride ?? element.title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Übernehmen") { apply(draft); dismiss() }.disabled(draft.error != nil || importing) }
                }
                .onChange(of: draft.appearance) { _, mode in
                    if mode == .symbol { draft.value = element.symbol(for: design) }
                    else if mode == .emoji { draft.value = "✨" }
                    else { draft.value = "" }
                }
                .sheet(isPresented: $showBrands) {
                    BrandPicker(selectedID: Binding(get: { draft.value.isEmpty ? nil : draft.value }, set: { draft.value = $0 ?? "" }))
                }
                .onChange(of: photo) { _, item in
                    Task {
                        importing = true; defer { importing = false }
                        do { if let data = try await item?.loadTransferable(type: Data.self) { draft.value = try SharedAssets.save(data) } }
                        catch { self.error = error.localizedDescription }
                    }
                }
                .alert("Bild konnte nicht geladen werden", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) { Button("OK") { error = nil } } message: { Text(error ?? "") }
        }
    }
}
