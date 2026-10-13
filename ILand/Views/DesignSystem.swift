import SwiftUI

extension Color {
    static let islandAccent = Color(red: 0.46, green: 0.34, blue: 0.96)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

struct Surface: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20).background(Color.card, in: RoundedRectangle(cornerRadius: 26))
    }
}
extension View { func surface() -> some View { modifier(Surface()) } }

struct PrimaryButton: View {
    var title: String
    var icon = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) { Text(title); Image(systemName: icon) }
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 17)
        }.buttonStyle(.plain).foregroundStyle(.white)
            .background(Color.islandAccent, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct SectionHeading: View {
    var title: String
    var caption: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.bold())
            Spacer()
            if let caption { Text(caption).font(.caption.weight(.medium)).foregroundStyle(.secondary) }
        }
    }
}

struct IslandPreview: View {
    var design: IslandDesign
    var expanded = true
    var simulation = false
    var liveState: IslandAttributes.ContentState?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    var body: some View {
        if expanded {
            IslandPreviewSurface(design: design) {
                ExpandedIslandContent(design: design, state: liveState)
            }.frame(maxWidth: 350)
                .shadow(color: .black.opacity(0.18), radius: 20, y: 12)
        } else {
        VStack(spacing: 18) {
            HStack(spacing: 10) {
                DesignIcon(design: animatedDesign, size: expanded ? 39 : 24)
                    .scaleEffect(pulse && (design.motion == .pulse || design.motion == .scale) ? 1.08 : 1)
                    .opacity(pulse && design.motion == .fade ? 0.5 : 1)
                    .offset(y: pulse && design.motion == .slide ? -4 : 0)
                if expanded {
                    VStack(alignment: .leading, spacing: 3) {
                        if !(liveState?.title ?? design.title).isEmpty { Text(liveState?.title ?? design.title).font(.subheadline.bold()).lineLimit(1) }
                        if !(liveState?.subtitle ?? design.subtitle).isEmpty { Text(liveState?.subtitle ?? design.subtitle).font(.caption).foregroundStyle(.white.opacity(0.55)).lineLimit(1) }
                    }
                    Spacer(minLength: 3)
                    IslandElementIcon(design: design, element: .badge)
                } else {
                    Spacer(minLength: 44)
                    IslandCompactContent(design: design, paused: liveState?.paused ?? false, endDate: liveState?.endDate)
                }
            }
            if expanded {
                if design.kind == .timer {
                    HStack { timerLabel.font(.system(.title2, design: .rounded).bold()).monospacedDigit().foregroundStyle(design.tint.color); Spacer(); IslandElementIcon(design: design, element: liveState?.paused == true ? .play : .pause); IslandElementIcon(design: design, element: .reset) }
                } else if design.kind == .travel {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(design.flightNumber) · \(design.gateCaption) \(design.gate)").font(.caption.bold())
                            Text(design.status).font(.caption2)
                        }
                        Spacer()
                        Text(design.departure, style: .time).font(.caption.bold())
                    }.foregroundStyle(design.tint.color)
                } else {
                    HStack(spacing: 10) {
                        IslandElementIcon(design: design, element: .status, size: 16)
                        Text(design.status).font(.caption).lineLimit(2).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
                        IslandActionLabel(design: design)
                    }.foregroundStyle(.white.opacity(0.85)).frame(minHeight: 34)
                }
                if design.kind != .custom && design.actionKind == .website {
                    HStack { Spacer(); IslandActionLabel(design: design) }
                }
            }
        }
        .padding(expanded ? 22 : 12).foregroundStyle(.white)
        .frame(maxWidth: expanded ? 350 : 240)
        .background(.black, in: RoundedRectangle(cornerRadius: expanded ? 34 : 40))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 12)
        .task(id: "\(simulation)-\(design.motion.rawValue)-\(reduceMotion)") {
            pulse = false
            guard simulation && !reduceMotion && design.motion != .none else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(0.9)) } catch { return }
                withAnimation(.easeInOut(duration: 0.25)) { pulse.toggle() }
            }
        }
        .accessibilityElement(children: .combine)
        }
    }
    private var animatedDesign: IslandDesign {
        var result = design
        if pulse && design.motion == .iconChange && design.iconMode == .symbol && design.style(.badge).appearance == .symbol { result.symbol = design.style(.badge).value }
        return result
    }
    @ViewBuilder private var timerLabel: some View {
        if let liveState {
            if liveState.paused { Text(Duration.seconds(liveState.remaining).formatted(.time(pattern: .minuteSecond))) }
            else { Text(timerInterval: Date()...max(Date(), liveState.endDate), countsDown: true).frame(maxWidth: 110) }
        } else { Text("\(design.durationMinutes):00") }
    }
}

struct PreviewStage: View {
    var design: IslandDesign
    var expanded = true
    var simulation = false
    var liveState: IslandAttributes.ContentState?
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("9:41").font(.caption.bold())
                Spacer()
                Image(systemName: "cellularbars"); Image(systemName: "wifi"); Image(systemName: "battery.100percent")
            }.font(.caption2).foregroundStyle(.secondary)
            IslandPreview(design: design, expanded: expanded, simulation: simulation, liveState: liveState)
                .frame(maxWidth: .infinity).frame(minHeight: 145)
            Text(expanded ? "EXPANDED ISLAND" : "COMPACT ISLAND")
                .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2.5).foregroundStyle(.secondary)
        }.padding(22)
        .background {
            RoundedRectangle(cornerRadius: 28).fill(Color.islandAccent.opacity(0.08))
                .overlay { RoundedRectangle(cornerRadius: 28).fill(RadialGradient(colors: [design.tint.color.opacity(0.15), .clear], center: .center, startRadius: 10, endRadius: 220)) }
        }
    }
}

struct DesignTile: View {
    var design: IslandDesign
    var isActive = false
    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack { DesignIcon(design: design, size: 34); Spacer(); if design.favorite { Image(systemName: "heart.fill").font(.caption).foregroundStyle(design.tint.color) } }
            HStack(spacing: 5) {
                DesignIcon(design: design, size: 16)
                Capsule().fill(design.tint.color.opacity(0.7)).frame(width: 22, height: 3)
                Spacer(minLength: 4)
                Circle().fill(design.tint.color).frame(width: 4, height: 4)
            }.foregroundStyle(design.tint.color).padding(12).background(.black, in: Capsule())
            VStack(alignment: .leading, spacing: 4) {
                Text(design.name).font(.headline).foregroundStyle(.primary)
                if isActive {
                    Label("Läuft gerade", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.semibold)).foregroundStyle(.green)
                } else { Text(design.kind.rawValue).font(.caption).foregroundStyle(.secondary) }
            }
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(isActive ? Color.green : .clear, lineWidth: 2) }
            .accessibilityValue(isActive ? "Live Activity läuft" : "")
    }
}


@MainActor
enum MessagePresenter {
    static func show(_ message: String, dismissed: @escaping () -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              var controller = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = controller.presentedViewController, !presented.isBeingDismissed { controller = presented }
        guard !(controller is UIAlertController) else { return }
        let alert = UIAlertController(title: "iLand", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in dismissed() })
        controller.present(alert, animated: true)
    }
}
