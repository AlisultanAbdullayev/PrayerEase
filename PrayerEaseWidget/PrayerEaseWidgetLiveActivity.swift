//
//  PrayerEaseWidgetLiveActivity.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget

struct PrayerEaseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerEaseWidgetAttributes.self) { context in
            // Lock Screen / Banner View
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(state: context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(state: context.state)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(state: context.state)
                }

                DynamicIslandExpandedRegion(.center) {
                    EmptyView()
                }
            } compactLeading: {
                CompactLeadingView(state: context.state)
            } compactTrailing: {
                CompactTrailingView(state: context.state)
            } minimal: {
                MinimalView(state: context.state)
            }
            .widgetURL(
                URL(string: "prayerease://prayer/\(context.state.nextPrayerName.lowercased())")
            )
            .keylineTint(.accent)
        }
    }
}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: PrayerEaseWidgetAttributes.preview) {
    PrayerEaseWidgetLiveActivity()
} contentStates: {
    PrayerEaseWidgetAttributes.ContentState.previewFajr
}
