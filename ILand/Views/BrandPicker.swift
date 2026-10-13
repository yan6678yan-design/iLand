import SwiftUI

struct BrandPicker: View {
    @Binding var selectedID: String?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var category = "Alle"
    private var brands: [BrandMark] {
        BrandCatalog.all.sorted { a, b in
            let featured = ["porsche", "rolex", "bmw", "audi", "ferrari", "gucci", "prada", "omega", "tagheuer", "apple"]
            return (featured.firstIndex(of: a.id) ?? 1000) < (featured.firstIndex(of: b.id) ?? 1000)
        }.filter { (category == "Alle" || $0.category == category) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Deine Marken.\nDeine Island.").font(.title2.bold())
                        Spacer()
                        Text("\(BrandCatalog.all.count) LOGOS").font(.caption2.bold()).padding(10).background(Color.islandAccent.opacity(0.12), in: Capsule()).foregroundStyle(Color.islandAccent)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BrandCatalog.categories, id: \.self) { item in
                                Button { category = item } label: {
                                    Text(item).font(.subheadline.weight(.medium)).padding(.horizontal, 14).padding(.vertical, 10)
                                        .background(category == item ? Color.islandAccent : Color.card, in: Capsule())
                                        .foregroundStyle(category == item ? .white : .primary)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                        ForEach(brands) { brand in
                            Button {
                                selectedID = brand.id
                                UISelectionFeedbackGenerator().selectionChanged()
                                dismiss()
                            } label: {
                                VStack(spacing: 12) {
                                    BrandLogo(id: brand.id, size: 54)
                                    Text(brand.name).font(.caption.weight(.medium)).lineLimit(2).frame(height: 30)
                                }.frame(maxWidth: .infinity).padding(.vertical, 15)
                                    .background(Color.card, in: RoundedRectangle(cornerRadius: 20))
                                    .overlay(alignment: .topTrailing) {
                                        if selectedID == brand.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.islandAccent).padding(6) }
                                    }
                            }.buttonStyle(.plain).accessibilityLabel(brand.name)
                                .accessibilityIdentifier("brand-" + brand.id)
                        }
                    }
                    if BrandCatalog.all.isEmpty { ContentUnavailableView("Logos nicht geladen", systemImage: "photo.on.rectangle", description: Text("Der Logo-Katalog fehlt in diesem Build. Bitte die aktuelle iLand-Version installieren.")) }
                    else if brands.isEmpty { ContentUnavailableView.search(text: search) }
                    Text("Alle Logos sind ohne In-App-Kauf und offline verfügbar.").font(.caption).foregroundStyle(.secondary)
                    NavigationLink("Quellen & Markenhinweise") { BrandCreditsView() }.font(.caption)
                }.padding(20)
            }.background(Color.canvas)
                .navigationTitle("Logos").navigationBarTitleDisplayMode(.inline)
                .searchable(text: $search, prompt: "Marke suchen")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fertig") { dismiss() } } }
        }
    }
}

struct BrandCreditsView: View {
    var body: some View {
        List {
            Section {
                Text("Die Sammlung enthält Vektorgrafiken aus Simple Icons und Wikimedia Commons. Sie ist kostenlos verfügbar. Marken und Logos gehören den jeweiligen Inhabern; iLand steht mit ihnen nicht in Verbindung.")
                Text("Die Lizenz der Sammlung ersetzt keine Markenrechte. Beachte bei einer Weiterverwendung die jeweiligen Markenrichtlinien.")
            }.font(.footnote)
            Section("Sammlungen") {
                Link("Simple Icons · Lizenz und Hinweise", destination: URL(string: "https://github.com/simple-icons/simple-icons/blob/develop/DISCLAIMER.md")!)
                Link("Wikimedia Commons", destination: URL(string: "https://commons.wikimedia.org")!)
            }
            Section("Quellen pro Logo") {
                ForEach(BrandCatalog.all) { brand in
                    if let url = URL(string: brand.source) {
                        Link(destination: url) {
                            HStack(spacing: 12) { BrandLogo(id: brand.id, size: 32); VStack(alignment: .leading) { Text(brand.name); Text(brand.credit).font(.caption).foregroundStyle(.secondary) } }
                        }
                    }
                }
            }
        }.navigationTitle("Logoquellen")
    }
}
