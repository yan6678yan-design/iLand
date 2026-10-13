import Foundation
import SwiftUI
import ActivityKit
import UIKit

// Kept shared so the app and extension decode exactly the same payload.
enum DesignKind: String, Codable, CaseIterable, Identifiable {
    case custom = "Custom", timer = "Timer", travel = "Reise", market = "Aktien"
    static var available: [Self] { allCases.filter { $0 != .market || DistributionFeatures.thirdPartyCatalogs } }
    var id: String { rawValue }
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if value == "Musik" { self = .custom }
        else if let kind = Self(rawValue: value) { self = kind }
        else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown design kind")) }
    }
    var symbol: String { switch self { case .custom: "sparkles"; case .timer: "timer"; case .travel: "airplane"; case .market: "chart.line.uptrend.xyaxis" } }
}
enum IconMode: String, Codable, CaseIterable, Identifiable {
    case symbol = "Icons", emoji = "Emoji", image = "Bild", brand = "Logos"
    static var available: [Self] { allCases.filter { $0 != .brand || DistributionFeatures.thirdPartyCatalogs } }
    var id: String { rawValue }
}
struct IslandTint: RawRepresentable, Codable, Hashable, Identifiable {
    var rawValue: String
    var id: String { rawValue }
    static let violet = Self(rawValue: "Violett")
    static let blue = Self(rawValue: "Blau")
    static let mint = Self(rawValue: "Mint")
    static let orange = Self(rawValue: "Orange")
    static let pink = Self(rawValue: "Pink")
    static let silver = Self(rawValue: "Silber")
    static let allCases: [Self] = [.violet, .blue, .mint, .orange, .pink, .silver]
    static let suggested: [Self] = [.violet, .blue, .mint, .orange]
    var color: Color {
        switch rawValue {
        case "Violett": Color(red: 0.61, green: 0.49, blue: 1)
        case "Blau": Color(red: 0.32, green: 0.76, blue: 1)
        case "Mint": Color(red: 0.24, green: 0.86, blue: 0.76)
        case "Orange": Color(red: 1, green: 0.62, blue: 0.16)
        case "Pink": Color(red: 1, green: 0.40, blue: 0.64)
        case "Silber": Color(red: 0.72, green: 0.74, blue: 0.80)
        default:
            if let rgb = UInt32(rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) {
                Color(red: Double((rgb >> 16) & 255) / 255, green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255)
            } else { .white }
        }
    }
    init(rawValue: String) { self.rawValue = rawValue }
    init(color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        rawValue = String(format: "#%02X%02X%02X", Int((min(1, max(0, r)) * 255).rounded()), Int((min(1, max(0, g)) * 255).rounded()), Int((min(1, max(0, b)) * 255).rounded()))
    }
    init(from decoder: Decoder) throws { rawValue = try decoder.singleValueContainer().decode(String.self) }
    func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}
enum IslandMotion: String, Codable, CaseIterable, Identifiable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if value == "Musikvisualisierung" { self = .none }
        else if let motion = Self(rawValue: value) { self = motion }
        else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown motion")) }
    }
    case none = "Keine", fade = "Fade", slide = "Slide", scale = "Scale", pulse = "Pulsieren", iconChange = "Icon-Wechsel", progress = "Fortschritt"
    var id: String { rawValue }
}
enum ActionKind: String, Codable, CaseIterable, Identifiable {
    case inApp = "Design in iLand", website = "Webseite", deepLink = "App / Deep Link"
    var id: String { rawValue }
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        if value == "Design in ILand" { self = .inApp }
        else if let action = Self(rawValue: value) { self = action }
        else { throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown action")) }
    }
}

struct IslandDesign: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var kind: DesignKind = .custom
    var symbol = "sparkles"
    var iconMode: IconMode = .symbol
    var emoji = "✨"
    var imageName: String?
    var brandID: String?
    var personalization: IslandPersonalization?
    var iconBackground: Bool?
    var customLayout: IslandLayout?
    var marketAsset: MarketAsset?
    var showsIconBackground: Bool { iconBackground ?? true }
    var title = "Dein Moment"
    var subtitle = "Ganz nach deinem Stil"
    var status = "Zeit für dich"
    var tint: IslandTint = .violet
    var motion: IslandMotion = .fade
    var favorite = false
    var durationMinutes = 25
    var flightNumber = "LX 318"
    var gate = "A12"
    var departure = Date().addingTimeInterval(7200)
    var actionKind: ActionKind = .inApp
    var actionURL = ""
    var lastUsed: Date?
    static var blank: IslandDesign { IslandDesign(name: "Mein Design") }
    var validActionURL: URL? {
        if actionKind == .website { return WebsiteAddress.normalized(actionURL) }
        guard let url = URL(string: actionURL.trimmingCharacters(in: .whitespacesAndNewlines)), let scheme = url.scheme?.lowercased(), !["iland", "file", "data", "javascript", "about"].contains(scheme) else { return nil }
        return url
    }
    var validationError: String? {
        if kind == .market && !selectedAsset.isValid { return "Bitte wähle ein gültiges Börsen- oder Kryptosymbol." }
        if kind == .custom, let error = customLayout?.validationError { return error }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Der Designname darf nicht leer sein." }
        if iconMode == .symbol && UIImage(systemName: symbol) == nil { return "Wähle ein verfügbares System-Icon aus." }
        if let personalization {
            if (personalization.compactText?.count ?? 0) > 12 || (personalization.actionText?.count ?? 0) > 20 || (personalization.gateText?.count ?? 0) > 20 { return "Kompakttext: maximal 12 Zeichen. Beschriftungen: maximal 20 Zeichen." }
            for element in editableElements {
                let style = self.style(element)
                if !element.decorative && style.appearance == .hidden { return "Steuerelemente benötigen ein sichtbares Symbol." }
                if let error = style.error { return "\(element.title): \(error)" }
            }
        }
        if name.count > 60 || title.count > 60 || subtitle.count > 100 || status.count > 100 || emoji.count > 4 || flightNumber.count > 20 || gate.count > 20 { return "Bitte halte Inhalte kurz: Name/Titel max. 60, Untertitel/Status max. 100 Zeichen, bis zu 4 Emojis, Flugnummer/Gate max. 20 Zeichen." }
        if iconMode == .brand && !BrandCatalog.all.contains(where: { $0.id == brandID }) { return "Wähle zuerst ein Logo aus der Sammlung aus." }
        if iconMode == .image && imageName == nil { return "Wähle zuerst ein eigenes Bild aus." }
        if actionKind != .inApp && validActionURL == nil { return "Bitte gib eine gültige Domain ein, z. B. example.com. App-Links benötigen ihr dokumentiertes URL-Schema." }
        return nil
    }
    static var examples: [IslandDesign] {
        [IslandDesign(name: "Deep Focus", kind: .timer, symbol: "moon.stars.fill", title: "Deep Focus", subtitle: "Ein Moment nur für dich", status: "Nicht stören", tint: .violet, favorite: true),
         IslandDesign(name: "Next Stop", kind: .travel, symbol: "airplane", title: "Zürich → London", subtitle: "Deine nächste Reise", status: "Boarding", tint: .blue),
         IslandDesign(name: "Zuhause", symbol: "house.fill", title: "Zuhause", subtitle: "Dein Lieblingsort", status: "Endlich angekommen", tint: .mint),
         IslandDesign(name: "Unterwegs", symbol: "car.side.fill", title: "Auf dem Weg", subtitle: "Zeit für eine Ausfahrt", tint: .orange),
         IslandDesign(name: "Arbeit", symbol: "briefcase.fill", title: "Im Flow", subtitle: "Eins nach dem anderen", tint: .blue),
         IslandDesign(name: "Gaming", symbol: "gamecontroller.fill", title: "Level up", subtitle: "Deine nächste Session", tint: .violet),
         IslandDesign(name: "Minimal", symbol: "circle.dotted", title: "Hier. Jetzt.", subtitle: "Weniger ist mehr", tint: .silver)]
    }
}

struct IslandAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var subtitle: String
        var status: String
        var endDate: Date
        var paused = false
        var remaining: TimeInterval
        var progress: Double = 0
        var isPlaying = false
        var revision = 0
        var playbackStart: Date?
        var marketQuote: MarketQuote?
        var marketError: String?
    }
    var design: IslandDesign
    var startedAt: Date
    var deepLink: URL { URL(string: "iland://design/\(design.id.uuidString)")! }
}

struct DesignIcon: View {
    var design: IslandDesign
    var size: CGFloat = 32
    var body: some View {
        Group {
            if design.iconMode == .brand, let brandID = design.brandID {
                BrandLogo(id: brandID, size: size, showsBackground: design.showsIconBackground, foreground: design.tint.color)
            }
            else if design.iconMode == .emoji { Text(String(design.emoji.prefix(4))).font(.system(size: size * 0.72)) }
            else if design.iconMode == .image, let name = design.imageName, let image = SharedAssets.image(name) { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: design.symbol).font(.system(size: size * 0.55, weight: .semibold)).foregroundStyle(design.tint.color) }
        }.frame(width: size, height: size).background(design.showsIconBackground ? design.tint.color.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: size * 0.27)).clipShape(RoundedRectangle(cornerRadius: size * 0.27))
    }
}

enum SharedAssets {
    static var directory: URL? { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ch.yannis.ILand")?.appendingPathComponent("Images", isDirectory: true) }
    static func image(_ name: String) -> UIImage? {
        guard name == URL(fileURLWithPath: name).lastPathComponent, let directory else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(name).path)
    }
    static func save(_ data: Data) throws -> String {
        guard let image = UIImage(data: data), let directory else { throw AssetError.unavailable }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let size = CGSize(width: 96, height: 96)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let ratio = max(size.width / image.size.width, size.height / image.size.height)
            let drawSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            image.draw(in: CGRect(x: (96 - drawSize.width) / 2, y: (96 - drawSize.height) / 2, width: drawSize.width, height: drawSize.height))
        }
        guard let compressed = rendered.pngData() else { throw AssetError.unavailable }
        let name = UUID().uuidString + ".png"
        try compressed.write(to: directory.appendingPathComponent(name), options: .atomic)
        return name
    }
    enum AssetError: LocalizedError { case unavailable; var errorDescription: String? { "Das Bild konnte nicht gespeichert werden. Prüfe die App-Group-Konfiguration in Xcode." } }
}

enum SymbolLibrary {
    static let categories = ["Alle", "Alltag", "Mobilität", "Sport", "Tech", "Wetter", "Welt"]
    static let groups: [String: [String]] = [
        "Alltag": ["sparkles", "house.fill", "heart.fill", "moon.stars.fill", "music.note", "cup.and.saucer.fill", "book.fill", "briefcase.fill", "leaf.fill", "pawprint.fill", "gift.fill", "camera.fill"],
        "Mobilität": ["car.side.fill", "airplane", "tram.fill", "bicycle", "sailboat.fill", "bus.fill"],
        "Sport": ["figure.run", "basketball.fill", "soccerball", "tennisball.fill", "dumbbell.fill", "medal.fill"],
        "Tech": ["laptopcomputer", "iphone", "gamecontroller.fill", "headphones", "bolt.fill", "cpu.fill"],
        "Wetter": ["sun.max.fill", "cloud.sun.fill", "cloud.rain.fill", "snowflake", "wind", "cloud.bolt.fill"],
        "Welt": ["globe.europe.africa.fill", "globe.americas.fill", "globe.asia.australia.fill", "flag.fill", "mountain.2.fill", "map.fill"]]
    static func symbols(_ category: String) -> [String] { category == "Alle" ? categories.dropFirst().flatMap { groups[$0] ?? [] } : groups[category] ?? [] }
}
