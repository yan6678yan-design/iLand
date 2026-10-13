import SwiftUI
import CoreLocation

struct RulesView: View {
    @EnvironmentObject private var store: IslandStore
    @State private var editing: IslandRule?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: "bolt.horizontal.circle.fill").font(.largeTitle).foregroundStyle(Color.islandAccent)
                        Text("Der richtige Look.\nIm richtigen Moment.").font(.title2.bold())
                        Text("Verbinde Orte, Zeiten und Aktivitäten mit deinen Designs.").font(.subheadline).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).surface()
                    Label("Regeln werden bei geöffneter App geprüft. Bei mehreren Treffern gilt die erste Regel in der Liste.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
                    ForEach(store.rules) { rule in
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Button { editing = rule } label: { Text(rule.name).font(.headline).foregroundStyle(.primary) }
                                Spacer()
                                Toggle("Aktivieren", isOn: Binding(get: { rule.enabled }, set: { store.setRuleEnabled(rule.id, $0) })).labelsHidden()
                            }
                            ForEach(Array(rule.conditions.enumerated()), id: \.element.id) { index, condition in
                                HStack { Text(index == 0 ? "WENN" : rule.matchAll ? "UND" : "ODER").font(.system(size: 9, weight: .bold)).foregroundStyle(Color.islandAccent).frame(width: 40, alignment: .leading); Text(condition.summary(places: store.places)).font(.subheadline) }
                            }
                            Divider()
                            HStack { Text("DANN").font(.system(size: 9, weight: .bold)).foregroundStyle(Color.islandAccent).frame(width: 40, alignment: .leading); Text(store.designs.first { $0.id == rule.designID }?.name ?? "Design wählen").font(.subheadline.bold()); Spacer(); Button { editing = rule } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("Regel bearbeiten") }
                        }.surface()
                    }
                    if store.rules.isEmpty { ContentUnavailableView("Dein Alltag, deine Regeln", systemImage: "bolt", description: Text("Füge eine erste Regel hinzu.")) }
                    PrimaryButton(title: "Neue Regel erstellen", icon: "plus") { editing = IslandRule(designID: store.designs.first?.id ?? UUID()) }
                    Button("Regeln jetzt prüfen") { Task { await store.evaluateRules(report: true) } }.frame(maxWidth: .infinity)
                    if let evaluation = store.lastEvaluation { Text(evaluation).font(.caption).foregroundStyle(.secondary) }
                }.padding(20)
            }.background(Color.canvas).navigationTitle("Regeln")
                .sheet(item: $editing) { RuleEditor(rule: $0) }
        }
    }
}

struct RuleEditor: View {
    @EnvironmentObject private var store: IslandStore
    @Environment(\.dismiss) private var dismiss
    @State var rule: IslandRule
    var body: some View {
        NavigationStack {
            Form {
                Section("Deine Regel") { TextField("Name", text: $rule.name); Toggle("Regel aktivieren", isOn: $rule.enabled) }
                Section {
                    Picker("Verknüpfung", selection: $rule.matchAll) { Text("Alle Bedingungen (UND)").tag(true); Text("Eine Bedingung (ODER)").tag(false) }
                    ForEach($rule.conditions) { $condition in
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Wenn", selection: $condition.kind) { ForEach(ConditionKind.allCases) { Text($0.rawValue).tag($0) } }
                            switch condition.kind {
                            case .location:
                                Picker("Ort", selection: $condition.placeID) {
                                    Text("Ort auswählen").tag(Optional<UUID>.none)
                                    ForEach(store.places) { Text($0.name).tag(Optional($0.id)) }
                                }
                                if store.places.isEmpty { Text("Lege zuerst unter Einstellungen einen Ort an.").font(.caption).foregroundStyle(.secondary) }
                            case .time:
                                DatePicker("Von", selection: timeBinding($condition.startMinute), displayedComponents: .hourAndMinute)
                                DatePicker("Bis", selection: timeBinding($condition.endMinute), displayedComponents: .hourAndMinute)
                            case .calendar:
                                TextField("Termintitel enthält …", text: $condition.query)
                                Text("Prüft gerade laufende Kalenderereignisse nach deiner Zustimmung.").font(.caption).foregroundStyle(.secondary)
                            case .music:
                                Text("Diese Bedingung wird nicht mehr unterstützt.").font(.caption).foregroundStyle(.secondary)
                            case .appActive:
                                Text("Während iLand im Vordergrund geöffnet ist.").font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 5)
                    }.onDelete { rule.conditions.remove(atOffsets: $0) }
                    Button("Bedingung hinzufügen", systemImage: "plus") { rule.conditions.append(RuleCondition()) }.disabled(rule.conditions.count >= 8)
                } header: { Text("Wenn") } footer: { Text("Zeitfenster über Mitternacht sind möglich. Gleiche Start- und Endzeit bedeutet ganztägig. Wische eine Bedingung nach links, um sie zu entfernen.") }
                Section("Dann anzeigen") { Picker("Design", selection: $rule.designID) { ForEach(store.designs) { Text($0.name).tag($0.id) } } }
                Section { Text("Die App startet eine Live Activity beim Eintritt in eine passende Regel. Sie startet dieselbe Regel nicht fortlaufend neu. Außerhalb der App gibt es keine garantierte automatische Ausführung.").font(.caption).foregroundStyle(.secondary) }
                if store.rules.contains(where: { $0.id == rule.id }) { Section { Button("Regel löschen", role: .destructive) { store.removeRule(rule.id); dismiss() } } }
            }.navigationTitle("Regel-Builder").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Sichern") { if store.saveRule(rule) { dismiss() } }.bold() } }
        }
    }
    private func timeBinding(_ minute: Binding<Int>) -> Binding<Date> {
        Binding(get: { Calendar.current.startOfDay(for: Date()).addingTimeInterval(Double(minute.wrappedValue * 60)) }, set: { let c = Calendar.current.dateComponents([.hour, .minute], from: $0); minute.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0) })
    }
}

struct PlaceEditor: View {
    @EnvironmentObject private var store: IslandStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = "Zuhause"
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var radius = 150.0
    var body: some View {
        NavigationStack {
            Form {
                Section("Dein Ort") { TextField("Name", text: $name); TextField("Breitengrad", text: $latitude).keyboardType(.numbersAndPunctuation); TextField("Längengrad", text: $longitude).keyboardType(.numbersAndPunctuation); Button("Aktuellen Standort übernehmen") { store.location.requestLocation() }; if let fix = store.location.current { Button("Gefundenen Standort verwenden") { latitude = String(fix.coordinate.latitude); longitude = String(fix.coordinate.longitude) } }; if let issue = store.location.issue { Text(issue).font(.caption).foregroundStyle(.secondary) } }
                Section("Umkreis: \(Int(radius)) Meter") { Slider(value: $radius, in: 100...2000, step: 50) }
                Section { Text("Die Koordinaten kannst du auch manuell eingeben. Zum Prüfen einer Standortregel ist deine Standortfreigabe erforderlich.").font(.caption).foregroundStyle(.secondary) }
            }.navigationTitle("Ort hinzufügen").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Sichern") {
                    guard let lat = Double(latitude.replacingOccurrences(of: ",", with: ".")), let lon = Double(longitude.replacingOccurrences(of: ",", with: ".")), (-90...90).contains(lat), (-180...180).contains(lon), !name.trimmingCharacters(in: .whitespaces).isEmpty else { store.message = "Bitte gib einen Namen und gültige Koordinaten ein."; return }
                    store.places.append(SavedPlace(name: name, latitude: lat, longitude: lon, radius: radius)); store.persist(); dismiss()
                } } }
        }
    }
}
