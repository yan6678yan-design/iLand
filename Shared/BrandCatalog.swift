import SwiftUI

struct BrandMark: Identifiable, Decodable {
    let id: String
    let name: String
    let category: String
    let source: String
    let credit: String
}

enum BrandCatalog {
    static let categories = ["Alle", "Autos", "Mode", "Uhren", "Tech", "Lifestyle"]
    static let all: [BrandMark] = {
        guard DistributionFeatures.thirdPartyCatalogs else { return [] }
        guard let file = Bundle.main.url(forResource: "Brands", withExtension: "json"),
              let data = try? Data(contentsOf: file),
              let brands = try? JSONDecoder().decode([BrandMark].self, from: data) else { return [] }
        return brands
    }()
}

struct BrandLogo: View {
    let id: String
    var size: CGFloat = 42
    var showsBackground = true
    var foreground: Color = .white
    var body: some View {
        (DistributionFeatures.thirdPartyCatalogs ? Image("brand_" + id) : Image(systemName: "sparkles"))
            .resizable().renderingMode(showsBackground ? .original : .template).scaledToFit()
            .padding(size * 0.12).frame(width: size, height: size)
            .foregroundStyle(foreground)
            .background(showsBackground ? Color.white : .clear, in: RoundedRectangle(cornerRadius: size * 0.23))
            .accessibilityLabel(BrandCatalog.all.first { $0.id == id }?.name ?? "Markenlogo")
    }
}
