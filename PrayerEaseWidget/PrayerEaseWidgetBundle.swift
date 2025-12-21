//
//  PrayerEaseWidgetBundle.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import SwiftUI
import WidgetKit

@main
struct PrayerEaseWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen & Lock Screen Widgets
        PrayerEaseWidget()
        
        // Live Activity for Dynamic Island & Lock Screen
        PrayerEaseWidgetLiveActivity()
        
        // Control Center Widget
        PrayerEaseWidgetControl()
    }
}
