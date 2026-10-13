import SwiftUI

/// Logical coordinates shared by the editor, preview, Lock Screen and Dynamic Island.
enum LayoutItemKind: String, Codable {
    case mainIcon, badge, statusIcon, title, subtitle, status, text, decoration, action
    var name: String {
        switch self {
        case .mainIcon: "Hauptsymbol"
        case .badge: "Rechtes Symbol"
        case .statusIcon: "Statussymbol"
        case .title: "Titel"
        case .subtitle: "Untertitel"
        case .status: "Status"
        case .text: "Eigener Text"
        case .decoration: "Emoji / Icon"
        case .action: "Link-Schaltfläche"
        }
    }
    var isText: Bool { [.title, .subtitle, .status, .text].contains(self) }
}
struct LayoutItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: LayoutItemKind
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var scale: Double = 1
    var rotation: Double = 0
    var text: String?
    var glyph: ElementStyle?
    var hidden: Bool = false
    enum CodingKeys: String, CodingKey {
        case id = "i", kind = "k", x, y, width = "w", height = "h", scale = "s", rotation = "r", text = "t", glyph = "g", hidden = "v"
    }
    mutating func constrain(avoidingCamera: Bool = false) {
        // Keep the full rotated bounds away from the rounded corners.
        scale = min(2.5, max(0.5, scale.isFinite ? scale : 1))
        rotation = min(180, max(-180, rotation.isFinite ? rotation : 0))
        let radians = rotation * .pi / 180
        let rotatedWidth = abs(cos(radians)) * width + abs(sin(radians)) * height
        let rotatedHeight = abs(sin(radians)) * width + abs(cos(radians)) * height
        scale = min(scale, 292 / max(rotatedWidth, 1), 100 / max(rotatedHeight, 1))
        let halfW = rotatedWidth * scale / 2
        let halfH = rotatedHeight * scale / 2
        x = min(306 - halfW, max(14 + halfW, x.isFinite ? x : 160))
        y = min(112 - halfH, max(12 + halfH, y.isFinite ? y : 62))
        if avoidingCamera && x + halfW > 74 && x - halfW < 246 && y - halfH < 36 {
            // The camera occupies the upper middle. Fit rotated items below it.
            scale = min(scale, 76 / max(rotatedHeight, 1))
            let safeHalfH = rotatedHeight * scale / 2
            y = min(112 - safeHalfH, max(36 + safeHalfH, y))
        }
    }
}
struct IslandLayout: Codable, Hashable {
    var items: [LayoutItem]
    // Missing in existing saved layouts, which retain their below-camera coordinates.
    var cameraLayout: Bool? = nil
    static var standard: IslandLayout {
        IslandLayout(items: [
            LayoutItem(kind: .mainIcon, x: 36, y: 32, width: 32, height: 32),
            LayoutItem(kind: .title, x: 160, y: 49, width: 166, height: 23),
            LayoutItem(kind: .subtitle, x: 160, y: 69, width: 166, height: 18),
            LayoutItem(kind: .badge, x: 287, y: 32, width: 24, height: 24),
            LayoutItem(kind: .statusIcon, x: 25, y: 96, width: 14, height: 14),
            LayoutItem(kind: .status, x: 127, y: 96, width: 171, height: 20),
            LayoutItem(kind: .action, x: 263, y: 96, width: 86, height: 32)
        ], cameraLayout: true)
    }
    var validationError: String? {
        guard items.count <= 12, Set(items.map(\.id)).count == items.count else { return "Auf die Island passen bis zu 12 Elemente." }
        for item in items {
            guard [item.x, item.y, item.width, item.height, item.scale, item.rotation].allSatisfy(\.isFinite), item.width > 0, item.width <= 292, item.height > 0, item.height <= 100, item.scale > 0, item.scale <= 2.5, abs(item.rotation) <= 180 else { return "Ein Layout-Element hat ungültige Maße." }
            if (item.text?.count ?? 0) > 60 { return "Eigene Texte dürfen bis zu 60 Zeichen enthalten." }
            if let error = item.glyph?.error { return error }
            var clamped = item; clamped.constrain(avoidingCamera: cameraLayout == true)
            if abs(clamped.x - item.x) > 0.01 || abs(clamped.y - item.y) > 0.01 || abs(clamped.scale - item.scale) > 0.01 { return "Verschiebe das Element in den sichtbaren Bereich der Island." }
        }
        return nil
    }
}
struct LayoutItemContent: View {
    let design: IslandDesign
    let item: LayoutItem
    var body: some View {
        Group {
            switch item.kind {
            case .mainIcon: DesignIcon(design: design, size: item.width)
            case .badge: IslandElementIcon(design: design, element: .badge, size: item.width)
            case .statusIcon: IslandElementIcon(design: design, element: .status, size: item.width)
            case .title: text(design.title, size: 16, bold: true)
            case .subtitle: text(design.subtitle, size: 12).foregroundStyle(.white.opacity(0.6))
            case .status: text(design.status, size: 12)
            case .text: text(item.text ?? "", size: 14)
            case .decoration:
                IslandElementIcon(design: decorationDesign, element: .badge, size: item.width)
            case .action: IslandActionLabel(design: design, minimumHeight: item.height)
            }
        }.frame(width: item.width, height: item.height).foregroundStyle(.white)
    }
    private func text(_ value: String, size: Double, bold: Bool = false) -> some View {
        Text(value).font(.system(size: size, weight: bold ? .semibold : .regular))
            .lineLimit(2).minimumScaleFactor(0.65)
            .multilineTextAlignment(centeredTitle ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: centeredTitle ? .center : .leading)
    }
    private var centeredTitle: Bool {
        (design.customLayout?.cameraLayout == true || design.customLayout == nil) && [.title, .subtitle].contains(item.kind)
    }
    private var decorationDesign: IslandDesign {
        var copy = design
        copy.setStyle(item.glyph ?? ElementStyle(appearance: .emoji, value: "✨"), for: .badge)
        return copy
    }
}
enum IslandCanvasMetrics {
    static let logicalWidth: CGFloat = 320
    static let logicalHeight: CGFloat = 124
    static let headerHeight: CGFloat = 80
    static let sideWidth: CGFloat = 74
    static let cameraClearance: CGFloat = 36
    // Expanded islands have a 14-point system inset on each side of an iPhone.
    // App and extension use the same device reference, then previews scale uniformly.
    static var deviceWidth: CGFloat { max(320, min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 28) }
    static var ratio: CGFloat { deviceWidth / logicalWidth }
    static func isLegacy(_ design: IslandDesign) -> Bool {
        design.kind == .custom && design.customLayout != nil && design.customLayout?.cameraLayout != true
    }
    static func centerY(for design: IslandDesign) -> Double {
        62 - (isLegacy(design) ? cameraClearance / ratio / 2 : 0)
    }
    static func snapped(_ value: Double, to center: Double) -> Double {
        abs(value - center) < 4 ? center : value
    }
    static func height(for design: IslandDesign) -> CGFloat {
        logicalHeight * ratio + (isLegacy(design) ? cameraClearance : 0)
            + ((design.kind == .timer || design.kind == .travel) && design.actionKind == .website && design.style(.action).appearance != .hidden ? 24 * ratio : 0)
    }
}

/// The same uniformly scaled surface is used in the editor, preview and widget.
struct IslandLayoutCanvas: View {
    let design: IslandDesign
    var linksEnabled = false
    var body: some View {
        GeometryReader { geometry in
            let ratio = geometry.size.width / IslandCanvasMetrics.logicalWidth
            ZStack(alignment: .topLeading) {
                ForEach((design.customLayout ?? .standard).items.filter { !$0.hidden && ($0.kind != .action || design.style(.action).appearance != .hidden) }) { item in
                    Group {
                        if linksEnabled && item.kind == .action {
                            Link(destination: design.actionKind == .website ? IslandRoute.website(design.id).url : IslandRoute.design(design.id).url) {
                                LayoutItemContent(design: design, item: item)
                            }.buttonStyle(.plain).accessibilityLabel(design.actionKind == .website ? "Webseite öffnen" : "Design öffnen")
                        } else { LayoutItemContent(design: design, item: item) }
                    }
                    .scaleEffect(item.scale * ratio)
                    .rotationEffect(.degrees(item.rotation))
                    .position(x: item.x * ratio, y: item.y * ratio)
                }
            }
        }.aspectRatio(IslandCanvasMetrics.logicalWidth / IslandCanvasMetrics.logicalHeight, contentMode: .fit)
            .environment(\.colorScheme, .dark).dynamicTypeSize(.medium)
    }
}

/// Matches the widget's reference frame even when a card or sheet is narrower.
struct IslandPreviewSurface<Content: View>: View {
    let design: IslandDesign
    @ViewBuilder var content: () -> Content
    var body: some View {
        let width = IslandCanvasMetrics.deviceWidth
        let height = IslandCanvasMetrics.height(for: design)
        GeometryReader { geometry in
            content().frame(width: width, height: height)
                .background(.black, in: RoundedRectangle(cornerRadius: 44))
                .scaleEffect(geometry.size.width / width, anchor: .topLeading)
        }.aspectRatio(width / height, contentMode: .fit)
            .environment(\.colorScheme, .dark).dynamicTypeSize(.medium)
    }
}
