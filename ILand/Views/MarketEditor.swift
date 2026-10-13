import SwiftUI

struct MarketEditor: View {
    @Binding var design: IslandDesign
    @State private var search = ""
    @State private var kind: MarketAsset.Kind = .crypto
    @Binding var quote: MarketQuote?
    @State private var error: String?
    @State private var loading = false
    @State private var symbol = ""
    @State private var requestID = UUID()
    private var assets: [MarketAsset] {
        MarketAsset.examples.filter { $0.kind == kind && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) || $0.symbol.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Aktien & Krypto")
            Picker("Markt", selection: $kind) { ForEach(MarketAsset.Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            TextField("Bitcoin, Apple oder Symbol suchen", text: $search).textFieldStyle(.roundedBorder)
            ForEach(assets) { asset in
                Button { choose(asset) } label: {
                    HStack {
                        VStack(alignment: .leading) { Text(asset.name).font(.subheadline.weight(.medium)); Text(asset.symbol + " · USD").font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Image(systemName: asset == design.selectedAsset ? "checkmark.circle.fill" : "circle").foregroundStyle(Color.islandAccent)
                    }.padding(.vertical, 3)
                }.buttonStyle(.plain).accessibilityIdentifier("asset-" + asset.symbol)
            }
            DisclosureGroup("Anderes Börsen- oder Kryptosymbol") {
                TextField(kind == .crypto ? "Coinbase-Symbol, z. B. LTC" : "Finnhub-Symbol, z. B. NFLX", text: $symbol)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                Button("Symbol verwenden") {
                    let value = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    choose(MarketAsset(kind: kind, symbol: value, name: value))
                }.disabled(symbol.isEmpty)
            }
            Divider()
            HStack {
                Text(design.selectedAsset.name).font(.headline)
                Spacer()
                if loading { ProgressView() }
                else { Button("Kurs laden", systemImage: "arrow.clockwise") { Task { await load() } }.accessibilityIdentifier("loadMarketQuote") }
            }
            if let quote {
                Text(quote.priceText).font(.title2.bold()).monospacedDigit().contentTransition(.numericText())
                Text("\(quote.source) · Stand \(quote.timeText)").font(.caption).foregroundStyle(.secondary)
            }
            if let error { Text(error).font(.caption).foregroundStyle(.orange) }
            if design.selectedAsset.kind == .stock {
                NavigationLink("Aktien-Kursquelle einrichten") { MarketSettingsView() }
            }
            Text("Kurse in USD. Bei geöffneter App wird die aktive Island alle 30 Sekunden aktualisiert. Außerhalb der App nutzt du die Aktualisieren-Taste in der erweiterten Island. Der Zeitstempel zeigt den letzten Handel; Aktienkurse können je nach Börse und Datenzugang verzögert sein.")
                .font(.caption).foregroundStyle(.secondary)
        }.surface()
            .onAppear { kind = design.selectedAsset.kind }
            .task(id: design.selectedAsset) { await load() }
    }
    private func choose(_ asset: MarketAsset) {
        guard asset != design.selectedAsset else { return }
        requestID = UUID(); design.selectAsset(asset); quote = nil; error = nil; loading = false
    }
    private func load() async {
        let id = UUID(); requestID = id; loading = true; error = nil
        let asset = design.selectedAsset
        do {
            let result = try await MarketClient.shared.quote(for: asset)
            guard requestID == id else { return }
            withAnimation { quote = result }
        } catch { if requestID == id { self.error = error.localizedDescription } }
        if requestID == id { loading = false }
    }
}

struct MarketSettingsView: View {
    @State private var key = ""
    @State private var saved = false
    @State private var error: String?
    var body: some View {
        Form {
            Section("Krypto") {
                Label("Coinbase · ohne API-Schlüssel", systemImage: "bitcoinsign.circle")
                Text("Nur das ausgewählte Handelspaar wird an Coinbase gesendet. Keine Wallet-Verbindung und keine Handelsfunktion.").font(.caption).foregroundStyle(.secondary)
            }
            Section {
                SecureField("Finnhub-API-Schlüssel", text: $key).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button(saved ? "Gespeichert ✓" : "Schlüssel speichern") {
                    do { try MarketCredentials.save(key); saved = true; error = nil }
                    catch { self.error = error.localizedDescription }
                }
                Link("API-Schlüssel bei Finnhub erhalten", destination: URL(string: "https://finnhub.io/register")!)
                Button("Schlüssel löschen", role: .destructive) {
                    do { try MarketCredentials.save(""); key = ""; saved = false }
                    catch { self.error = error.localizedDescription }
                }
                if let error { Text(error).foregroundStyle(.red) }
            } header: { Text("Aktien · Finnhub") } footer: {
                Text("Der Schlüssel bleibt im Schlüsselbund dieses iPhones und wird nur an Finnhub gesendet. Verfügbare Märkte, Verzögerungen und Nutzungsrechte hängen von deinem Datenzugang ab.")
            }
            Section("Aktualisierung") {
                Text("Automatisch alle 30 Sekunden bei aktiver App. In der Island kannst du manuell aktualisieren. Ohne Push-Server gibt es keine dauernden automatischen Hintergrundupdates.")
                Text("Kurswerte werden unverändert von der Quelle übernommen. Bei Fehlern bleibt der letzte Wert mit Zeitstempel sichtbar.")
            }
        }.navigationTitle("Kursdaten").navigationBarTitleDisplayMode(.inline)
            .onAppear { key = MarketCredentials.read() ?? "" }
            .onChange(of: key) { _, _ in saved = false }
    }
}
