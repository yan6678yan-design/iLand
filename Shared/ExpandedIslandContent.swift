import SwiftUI
import AppIntents

/// One composition for the in-app preview and the expanded Live Activity.
/// WidgetKit regions reassemble this surface around the system camera area.
struct ExpandedIslandContent: View {
    var design: IslandDesign
    var state: IslandAttributes.ContentState?
    var activityID: String?
    var accessibleRegion: IslandRegion?

    private var hasWebsiteFooter: Bool {
        (design.kind == .timer || design.kind == .travel) && design.actionKind == .website && design.style(.action).appearance != .hidden
    }

    private var renderedDesign: IslandDesign {
        var value = design
        if let state { value.title = state.title; value.subtitle = state.subtitle; value.status = state.status }
        if design.kind != .custom {
            value.customLayout = .standard
            value.customLayout?.items.removeAll { [.status, .statusIcon, .action].contains($0.kind) }
        }
        return value
    }
    var body: some View {
        let ratio = IslandCanvasMetrics.ratio
        Group {
        if design.kind == .market { MarketIslandContent(design: design, state: state, activityID: activityID, refreshAccessible: accessibleRegion == nil || accessibleRegion == .trailing) }
        else {
        VStack(spacing: 0) {
            if IslandCanvasMetrics.isLegacy(design) { Color.clear.frame(height: IslandCanvasMetrics.cameraClearance) }
            ZStack(alignment: .topLeading) {
                IslandLayoutCanvas(design: renderedDesign, linksEnabled: activityID != nil)
                if design.kind != .custom {
                    content.frame(width: 280, height: 40)
                        .scaleEffect(ratio, anchor: .topLeading)
                        .offset(x: 20 * ratio, y: 80 * ratio)
                }
            }.frame(width: IslandCanvasMetrics.deviceWidth, height: 124 * ratio)
            if hasWebsiteFooter {
                HStack { Spacer(); action }.frame(width: 280, height: 24)
                    .scaleEffect(ratio).frame(height: 24 * ratio)
            }
        }
        .frame(width: IslandCanvasMetrics.deviceWidth, height: IslandCanvasMetrics.height(for: design), alignment: .top)
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .dynamicTypeSize(.medium)
        }
        }
    }
    @ViewBuilder private var content: some View {
        switch design.kind {
        case .custom:
            HStack(spacing: 8) {
                IslandElementIcon(design: design, element: .status, size: 16)
                Text(state?.status ?? design.status).font(.system(size: 12)).lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                action
            }
        case .timer:
            HStack {
                Group {
                    if let state, !state.paused {
                        Text(timerInterval: Date()...max(Date(), state.endDate), countsDown: true)
                    } else if let state {
                        Text(Duration.seconds(state.remaining).formatted(.time(pattern: .minuteSecond)))
                    } else { Text("\(design.durationMinutes):00") }
                }.font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let activityID {
                    Button(intent: TimerToggleIntent(activityID: activityID)) { IslandElementIcon(design: design, element: state?.paused == true ? .play : .pause) }
                        .accessibilityLabel(state?.paused == true ? "Fortsetzen" : "Pausieren")
                    Button(intent: TimerResetIntent(activityID: activityID)) { IslandElementIcon(design: design, element: .reset) }.accessibilityLabel("Timer zurücksetzen")
                } else {
                    IslandElementIcon(design: design, element: .pause)
                    IslandElementIcon(design: design, element: .reset)
                }
            }.buttonStyle(.plain).foregroundStyle(design.tint.color)
        case .market: EmptyView()
        case .travel:
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(design.flightNumber) · \(design.gateCaption) \(design.gate)").font(.system(size: 12, weight: .semibold))
                    Text(state?.status ?? design.status).font(.system(size: 11))
                }.lineLimit(1)
                Spacer(minLength: 4)
                Text(design.departure, style: .time).font(.system(size: 12, weight: .semibold))
            }.foregroundStyle(design.tint.color)
        }
    }
    @ViewBuilder private var action: some View {
        if design.style(.action).appearance != .hidden {
            if activityID != nil {
                Link(destination: design.actionKind == .website ? IslandRoute.website(design.id).url : IslandRoute.design(design.id).url) {
                    IslandActionLabel(design: design, minimumHeight: design.kind == .custom ? 34 : 22, showsBackground: design.kind != .custom)
                }.buttonStyle(.plain).accessibilityLabel(design.actionKind == .website ? "Webseite öffnen" : "Design öffnen")
            } else { IslandActionLabel(design: design, minimumHeight: design.kind == .custom ? 34 : 22, showsBackground: design.kind != .custom) }
        }
    }
}

/// Slices one composition into Apple's camera-safe regions; it never resizes items.
enum IslandRegion { case leading, trailing, center, bottom }
struct ExpandedIslandRegionContent: View {
    var design: IslandDesign
    var state: IslandAttributes.ContentState
    var activityID: String
    var region: IslandRegion
    private var viewport: CGRect {
        let width = IslandCanvasMetrics.deviceWidth
        let side = IslandCanvasMetrics.sideWidth * IslandCanvasMetrics.ratio
        let header = IslandCanvasMetrics.headerHeight * IslandCanvasMetrics.ratio
        let height = IslandCanvasMetrics.height(for: design)
        switch region {
        case .leading: return CGRect(x: 0, y: 0, width: side, height: header)
        case .trailing: return CGRect(x: width - side, y: 0, width: side, height: header)
        case .center: return CGRect(x: side, y: 0, width: width - side * 2, height: header)
        case .bottom:
            let top = IslandCanvasMetrics.isLegacy(design) ? IslandCanvasMetrics.cameraClearance : header
            return CGRect(x: 0, y: top, width: width, height: height - top)
        }
    }
    var body: some View {
        if region == .center {
            // The camera clearance is supplied by WidgetKit and differs by device/iOS.
            // Align to the bottom of the header instead of assuming a 36-point origin.
            GeometryReader { geometry in
                ExpandedIslandContent(design: design, state: state, activityID: activityID, accessibleRegion: region)
                    .offset(x: -viewport.minX, y: -(IslandCanvasMetrics.headerHeight * IslandCanvasMetrics.ratio - geometry.size.height))
            }
            .frame(width: viewport.width)
            .frame(maxHeight: .infinity)
            .clipped()
        } else {
            ExpandedIslandContent(design: design, state: state, activityID: activityID, accessibleRegion: region)
                .offset(x: -viewport.minX, y: -viewport.minY)
                .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
                .clipped()
                .padding(.top, region == .bottom && !IslandCanvasMetrics.isLegacy(design) ? -8 : 0)
        }
    }
}
