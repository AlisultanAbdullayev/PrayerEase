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
                    Color(UIColor.systemBackground)
                }
        }
        .configurationDisplayName("Prayer Times")
        .description("Unified prayer times widget.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular,
            .accessoryRectangular, .accessoryInline,
        ])
        .contentMarginsDisabled()
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
