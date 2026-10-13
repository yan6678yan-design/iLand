import ActivityKit
import WidgetKit
import SwiftUI

@main
struct ILandWidgetBundle: WidgetBundle {
    var body: some Widget { ILandLiveActivity() }
}
struct ILandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IslandAttributes.self) { context in
            IslandPreviewSurface(design: context.attributes.design) {
                ExpandedIslandContent(design: context.attributes.design, state: context.state, activityID: context.activityID)
            }
            .activityBackgroundTint(.black)
            .activitySystemActionForegroundColor(.white)
            .widgetURL(context.attributes.deepLink)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if !IslandCanvasMetrics.isLegacy(context.attributes.design) {
                        ExpandedIslandRegionContent(design: context.attributes.design, state: context.state, activityID: context.activityID, region: .leading)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !IslandCanvasMetrics.isLegacy(context.attributes.design) {
                        ExpandedIslandRegionContent(design: context.attributes.design, state: context.state, activityID: context.activityID, region: .trailing)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if !IslandCanvasMetrics.isLegacy(context.attributes.design) {
                        ExpandedIslandRegionContent(design: context.attributes.design, state: context.state, activityID: context.activityID, region: .center)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedIslandRegionContent(design: context.attributes.design, state: context.state, activityID: context.activityID, region: .bottom)
                }
            } compactLeading: {
                DesignIcon(design: context.attributes.design, size: 23)
            } compactTrailing: {
                IslandCompactContent(design: context.attributes.design, paused: context.state.paused, endDate: context.state.endDate)
            } minimal: {
                DesignIcon(design: context.attributes.design, size: 22)
            }.contentMargins(.all, 0, for: .expanded)
                .widgetURL(context.attributes.deepLink).keylineTint(context.attributes.design.tint.color)
        }.contentMarginsDisabled()
    }
}
