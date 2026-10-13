import SwiftUI
import UIKit

// Optional overrides keep existing saved designs and ActivityKit payloads compatible.
enum IslandElement: String, CaseIterable, Identifiable {
    case badge, compact, status, action, play, pause, previous, next, reset
    var id: String { rawValue }
    var title: String {
        switch self {
        case .badge: "Symbol oben rechts"
        case .compact: "Symbol rechts · Kompakt"
        case .status: "Symbol neben dem Status"
        case .action: "Symbol auf der Link-Schaltfläche"
        case .play: "Wiedergabe / Fortsetzen"
        case .pause: "Pause"
        case .previous: "Vorheriger Titel"
        case .next: "Nächster Titel"
        case .reset: "Timer zurücksetzen"
        }
    }
    var decorative: Bool { [.badge, .compact, .status, .action].contains(self) }
    func symbol(for design: IslandDesign) -> String {
        switch self {
        case .badge, .compact: design.kind.symbol
        case .status: "circle.fill"
        case .action: "arrow.up.right"
        case .play: "play.fill"
        case .pause: "pause.fill"
        case .previous: "backward.end.fill"
        case .next: "forward.end.fill"
        case .reset: "arrow.counterclockwise"
        }
    }
}

enum ElementAppearance: String, Codable, CaseIterable, Identifiable {
    case automatic = "Standard", symbol = "Icon", emoji = "Emoji", brand = "Logo", image = "Bild", hidden = "Ausblenden"
    static var available: [Self] { allCases.filter { $0 != .brand || DistributionFeatures.thirdPartyCatalogs } }
    var id: String { rawValue }
}
struct ElementStyle: Codable, Hashable {
    var appearance: ElementAppearance = .automatic
    var value: String = ""
    var error: String? {
        switch appearance {
        case .symbol: return UIImage(systemName: value) == nil ? "Dieses System-Icon ist nicht verfügbar." : nil
        case .emoji: return value.isEmpty || value.count > 4 ? "Gib ein bis vier Emojis oder Zeichen ein." : nil
        case .brand: return BrandCatalog.all.contains(where: { $0.id == value }) ? nil : "Wähle ein Logo aus."
        case .image: return SharedAssets.image(value) == nil ? "Wähle ein verfügbares Bild aus." : nil
        default: return nil
        }
    }
}
struct IslandPersonalization: Codable, Hashable {
    var elements: [String: ElementStyle] = [:]
    var compactText: String?
    var actionText: String?
    var gateText: String?
}
extension IslandDesign {
    var customization: IslandPersonalization { personalization ?? IslandPersonalization() }
    func style(_ element: IslandElement) -> ElementStyle { customization.elements[element.rawValue] ?? ElementStyle() }
    mutating func setStyle(_ style: ElementStyle, for element: IslandElement) {
        var value = customization
        if style.appearance == .automatic { value.elements.removeValue(forKey: element.rawValue) }
        else { value.elements[element.rawValue] = style }
        if element == .compact { value.compactText = nil }
        personalization = value
        // A style selected outside the canvas also restores a previously hidden node.
        if let index = customLayout?.items.firstIndex(where: { item in
            (element == .badge && item.kind == .badge) || (element == .action && item.kind == .action) || (element == .status && item.kind == .statusIcon)
        }) { customLayout?.items[index].hidden = false }
    }
    var actionCaption: String { customization.actionText ?? (actionKind == .website ? "Webseite" : "") }
    var gateCaption: String { customization.gateText ?? "Gate" }
    var editableElements: [IslandElement] {
        var result: [IslandElement] = [.badge, .compact]
        if kind == .custom { result += [.status] }
        if kind == .custom || actionKind == .website { result += [.action] }
        if kind == .timer { result += [.play, .pause, .reset] }
        return result
    }
}
struct IslandElementIcon: View {
    var design: IslandDesign
    var element: IslandElement
    var size: CGFloat = 20
    private var style: ElementStyle { design.style(element) }
    var body: some View {
        Group {
            switch style.appearance {
            case .hidden: EmptyView()
            case .emoji: Text(style.value).font(.system(size: size * 0.8)).minimumScaleFactor(0.5).lineLimit(1).frame(width: size, height: size)
            case .brand: BrandLogo(id: style.value, size: size)
            case .image:
                if let image = SharedAssets.image(style.value) {
                    Image(uiImage: image).resizable().scaledToFill().frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                }
            case .automatic, .symbol:
                Image(systemName: style.appearance == .automatic ? element.symbol(for: design) : style.value)
                    .font(.system(size: element == .status && style.appearance == .automatic ? 6 : size * 0.8, weight: .semibold))
                    .frame(width: size, height: size)
            }
        }.foregroundStyle(design.tint.color)
    }
}
struct IslandActionLabel: View {
    var design: IslandDesign
    var minimumHeight: CGFloat = 34
    var showsBackground = true
    var body: some View {
        if design.style(.action).appearance != .hidden {
        HStack(spacing: 6) {
            IslandElementIcon(design: design, element: .action, size: 18)
            if !design.actionCaption.isEmpty { Text(design.actionCaption).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7) }
        }.padding(.horizontal, design.actionCaption.isEmpty ? 8 : 12).frame(minHeight: minimumHeight)
            .background(.white.opacity(showsBackground ? 0.14 : 0), in: Capsule())
        }
    }
}
struct IslandCompactContent: View {
    var design: IslandDesign
    var paused = false
    var endDate: Date?
    var body: some View {
        if let text = design.customization.compactText {
            if !text.isEmpty { Text(text).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: 64).foregroundStyle(design.tint.color) }
        } else if design.kind == .timer && design.style(.compact).appearance == .automatic && !paused {
            if let endDate { Text(timerInterval: Date()...max(Date(), endDate), countsDown: true).monospacedDigit().font(.caption).frame(maxWidth: 52).foregroundStyle(design.tint.color) }
            else { Text("\(design.durationMinutes):00").font(.caption).monospacedDigit().foregroundStyle(design.tint.color) }
        } else { IslandElementIcon(design: design, element: paused && design.style(.compact).appearance == .automatic ? .pause : .compact, size: 20) }
    }
}
