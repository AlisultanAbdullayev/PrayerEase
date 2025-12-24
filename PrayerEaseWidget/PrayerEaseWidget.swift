//
//  PrayerEaseWidget.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit

// MARK: - Configuration

struct PrayerEaseWidget: Widget {
    let kind: String = "PrayerEaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            PrayerEaseWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    #if os(iOS)
                        Color(UIColor.systemBackground)
                    #else
                        Color.black
                    #endif
                }
        }
        .configurationDisplayName("Prayer Times")
        .description("Unified prayer times widget.")
        .supportedFamilies(supportedFamilies)
        .contentMarginsDisabled()
    }

    private var supportedFamilies: [WidgetFamily] {
        #if os(watchOS)
            return [
                .accessoryCircular,
                .accessoryRectangular,
                .accessoryInline,
                .accessoryCorner,
            ]
        #else
            return [
                .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
                .accessoryCircular, .accessoryRectangular, .accessoryInline,
            ]
        #endif
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) { PrayerEaseWidget() } timeline: {
    PrayerWidgetEntry.placeholder
}
#Preview("Medium", as: .systemMedium) { PrayerEaseWidget() } timeline: {
    PrayerWidgetEntry.placeholder
}
#Preview("Large", as: .systemLarge) { PrayerEaseWidget() } timeline: {
    PrayerWidgetEntry.placeholder
}
