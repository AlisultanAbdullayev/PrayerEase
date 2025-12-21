//
//  PrayerEaseWidgetLiveActivity.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct PrayerEaseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct PrayerEaseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerEaseWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension PrayerEaseWidgetAttributes {
    fileprivate static var preview: PrayerEaseWidgetAttributes {
        PrayerEaseWidgetAttributes(name: "World")
    }
}

extension PrayerEaseWidgetAttributes.ContentState {
    fileprivate static var smiley: PrayerEaseWidgetAttributes.ContentState {
        PrayerEaseWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: PrayerEaseWidgetAttributes.ContentState {
         PrayerEaseWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: PrayerEaseWidgetAttributes.preview) {
   PrayerEaseWidgetLiveActivity()
} contentStates: {
    PrayerEaseWidgetAttributes.ContentState.smiley
    PrayerEaseWidgetAttributes.ContentState.starEyes
}
