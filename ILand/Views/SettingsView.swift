import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: IslandStore
    @State private var addPlace = false
    @State private var reset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 16) {
                        Image(systemName: "capsule.fill")
                            .font(.system(size: 27)).foregroundStyle(.white)
                            .frame(width: 62, height: 62)
                            .background(Color.islandAccent.gradient, in: RoundedRectangle(cornerRadius: 19))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ganz dein iLand.").font(.title3.bold())
                            Text("Dein Look. Deine Einstellungen.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }.padding(.top, 8)

                    section("Erscheinungsbild") {
                        HStack(spacing: 10) {
                            appearance("System", icon: "circle.lefthalf.filled")
                            appearance("Hell", icon: "sun.max.fill")
                            appearance("Dunkel", icon: "moon.fill")
                        }
                    }

                    section("Dein Alltag") {
                        VStack(spacing: 0) {
                            NavigationLink { places } label: {
                                row("Meine Orte", detail: "\(store.places.count) gespeicherte Orte", icon: "mappin.and.ellipse", color: .orange)
                            }
                            Divider().padding(.leading, 66)
                            NavigationLink { permissions } label: {
                                row("Berechtigungen", detail: "Standort & Kalender", icon: "hand.raised.fill", color: .blue)
                            }
                            Divider().padding(.leading, 66)
                            NavigationLink { activities } label: {
                                row("Live Activities", detail: store.activitiesAllowed ? "In iOS aktiviert" : "In iOS deaktiviert", icon: "capsule.fill", color: .islandAccent)
                            }
                        }.background(Color.card, in: RoundedRectangle(cornerRadius: 24))
                    }

                    if DistributionFeatures.thirdPartyCatalogs {
                        section("Kursdaten") {
                            NavigationLink { MarketSettingsView() } label: {
                                row("Aktien & Krypto", detail: "Kursquellen & Aktualisierung", icon: "chart.line.uptrend.xyaxis", color: .mint)
                            }.background(Color.card, in: RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    section("Privatsphäre") {
                        VStack(alignment: .leading, spacing: 18) {
                            Label("Deine Daten bleiben bei dir.", systemImage: "checkmark.shield.fill")
                                .font(.headline).foregroundStyle(Color.islandAccent)
                            Text(DistributionFeatures.thirdPartyCatalogs ? "Kein Konto. Keine Werbung. Kein Tracking. Deine Designs und Regeln werden auf diesem Gerät gespeichert. Kursabfragen senden das gewählte Symbol an Coinbase bzw. Finnhub." : "Kein Konto. Keine Werbung. Kein Tracking. Deine Designs und Regeln werden auf diesem Gerät gespeichert.")
                                .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            NavigationLink { privacy } label: {
                                HStack { Text("Datenschutz & Daten"); Spacer(); Image(systemName: "arrow.up.right") }.font(.subheadline.weight(.semibold))
                            }
                        }.padding(20).background(Color.card, in: RoundedRectangle(cornerRadius: 24))
                    }
                    Link(destination: AppLinks.support) {
                        row("Support & Kontakt", detail: "Hilfe zu iLand", icon: "questionmark.circle.fill", color: .blue)
                    }.background(Color.card, in: RoundedRectangle(cornerRadius: 24))
                    VStack(spacing: 5) {
                        Text("iLand").font(.subheadline.weight(.semibold))
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.caption)
                    }.foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.bottom, 12)
                }.padding(.horizontal, 20).padding(.bottom, 20)
            }.background(Color.canvas).navigationTitle("Einstellungen")
                .buttonStyle(.plain)
                .sheet(isPresented: $addPlace) { PlaceEditor() }
        }
    }

    private func appearance(_ name: String, icon: String) -> some View {
        let selected = store.appearance == name
        return Button {
            store.appearance = name
            store.persist()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 24))
                    .foregroundStyle(selected ? Color.islandAccent : .secondary)
                    .frame(height: 34)
                Text(name).font(.subheadline.weight(.medium))
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Color.islandAccent : Color.secondary.opacity(0.3))
            }.frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 21))
                .overlay { RoundedRectangle(cornerRadius: 21).stroke(selected ? Color.islandAccent : .clear, lineWidth: 2) }
                .contentShape(RoundedRectangle(cornerRadius: 21))
        }.accessibilityIdentifier("appearance-\(name)").accessibilityLabel(name)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { Text(title).font(.headline); content() }
    }
    private func row(_ title: String, detail: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 18, weight: .medium))
                .foregroundStyle(color).frame(width: 38, height: 38)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
        }.padding(16).contentShape(Rectangle())
    }
    private var places: some View {
        List {
            Section {
                ForEach(store.places) { place in
                    HStack { Label(place.name, systemImage: "mappin.circle.fill"); Spacer(); Text("\(Int(place.radius)) m").foregroundStyle(.secondary) }
                }.onDelete { store.removePlaces(at: $0) }
                Button("Ort hinzufügen", systemImage: "plus") { addPlace = true }
            } footer: { Text("Orte und Radien bleiben auf diesem Gerät. iLand prüft deinen Standort nur bei geöffneter App und zeichnet keine Bewegungsverläufe auf.") }
        }.navigationTitle("Meine Orte").navigationBarTitleDisplayMode(.inline)
            .toolbar { EditButton() }
    }
    private var permissions: some View {
        Form {
            Section {
                LocationPermissionRow(location: store.location)
            } footer: { Text("Für ortsabhängige Regeln. Der Zugriff ist freiwillig und nur bei Verwendung der App nötig.") }
            Section {
                CalendarPermissionRow(calendar: store.calendar)
            } footer: { Text("Für Regeln mit Kalenderereignissen. Ereignisse werden nur während der Regelauswertung im Arbeitsspeicher verwendet.") }
            Section { systemSettings }
        }.navigationTitle("Berechtigungen").navigationBarTitleDisplayMode(.inline)
    }
    private var activities: some View {
        Form {
            Section {
                LabeledContent("Systemfreigabe", value: store.activitiesAllowed ? "Aktiviert" : "Deaktiviert")
                systemSettings
            }
            Section("So funktioniert’s") {
                Text("Eine lange Berührung erweitert die Dynamic Island. iOS entscheidet über Sichtbarkeit und Laufzeit der Live Activity.")
                Text("Kalender- und Ortsregeln werden bei geöffneter App geprüft.")
            }
            Section { Link("Mehr über Live Activities", destination: URL(string: "https://developer.apple.com/documentation/activitykit")!) }
        }.navigationTitle("Live Activities").navigationBarTitleDisplayMode(.inline)
    }
    private var privacy: some View {
        Form {
            Section("Lokal auf deinem Gerät") {
                Label("Kein Konto, keine Werbung, kein Tracking", systemImage: "checkmark.shield")
                Text("Designs, Bilder, Regeln und Orte werden lokal gespeichert. Beim Öffnen externer Links gelten die Datenschutzregeln des Ziels.")
            }
            if DistributionFeatures.thirdPartyCatalogs {
                Section("Optionale Kursabfragen") {
                    Text("Bei Aktien- und Krypto-Designs werden das ausgewählte Symbol und deine IP-Adresse an Finnhub bzw. Coinbase übertragen. Ein Finnhub-Schlüssel wird nur im Schlüsselbund gespeichert und direkt an Finnhub gesendet. Designs, Standort und Kalender werden nicht übertragen.")
                }
            }
            Section {
                Link("Datenschutzerklärung", destination: AppLinks.privacy)
                Link("Support & Kontakt", destination: AppLinks.support)
            }
            Section {
                Button("Alle lokalen Daten löschen", role: .destructive) { reset = true }
            } footer: { Text("Entfernt deine Designs, Regeln, Orte und Bilder. Dieser Schritt kann nicht rückgängig gemacht werden.") }
        }.navigationTitle("Datenschutz & Daten").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Alle Designs, Regeln, Orte und Bilder löschen?", isPresented: $reset, titleVisibility: .visible) {
                Button("Alles löschen", role: .destructive) { Task { await store.resetAll() } }
                Button("Abbrechen", role: .cancel) {}
            }
    }
    private var systemSettings: some View {
        Link("iOS-Einstellungen öffnen", destination: URL(string: UIApplication.openSettingsURLString)!)
    }
}

private struct LocationPermissionRow: View {
    @ObservedObject var location: LocationService
    var body: some View {
        LabeledContent("Standort", value: location.permissionLabel)
        if !location.allowed { Button("Standortzugriff erlauben") { location.requestPermission() } }
    }
}
private struct CalendarPermissionRow: View {
    @ObservedObject var calendar: CalendarService
    var body: some View {
        LabeledContent("Kalender", value: calendar.permissionLabel)
        if !calendar.allowed { Button("Kalenderzugriff erlauben") { Task { await calendar.requestPermission() } } }
    }
}
