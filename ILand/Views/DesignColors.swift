import SwiftUI

/// Store only colors that were actually saved, not intermediate picker drags.
enum RecentIslandColors {
    static let key = "iLand.recentColors"
    static func record(_ tint: IslandTint, defaults: UserDefaults = .standard) {
        var colors = (defaults.stringArray(forKey: key) ?? []).filter { $0 != tint.rawValue }
        colors.insert(tint.rawValue, at: 0)
        defaults.set(Array(colors.prefix(4)), forKey: key)
    }
}
struct DesignColors: View {
    @Binding var tint: IslandTint
    var recent: [IslandTint] {
        (UserDefaults.standard.stringArray(forKey: RecentIslandColors.key) ?? [])
            .prefix(3).map { IslandTint(rawValue: $0) }
    }
    var body: some View {
        HStack(spacing: 12) {
            if !recent.isEmpty { swatches(recent) }
            ColorPicker("Farbe auswählen", selection: Binding(get: { tint.color }, set: { tint = IslandTint(color: $0) }), supportsOpacity: false)
                .labelsHidden()
                .frame(width: 44, height: 44)
                .accessibilityLabel("Farbe auswählen")
                .accessibilityIdentifier("moreColors")
        }
    }
    private func swatches(_ colors: [IslandTint]) -> some View {
        HStack(spacing: 12) {
            ForEach(colors) { color in
                Button { tint = color } label: {
                    Circle().fill(color.color).frame(width: 32, height: 32)
                        .overlay { Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 1) }
                        .overlay { if tint == color { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.black).padding(3).background(.white, in: Circle()) } }
                        .frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel(color.rawValue)
                    .accessibilityAddTraits(tint == color ? .isSelected : [])
            }
        }
    }
}
