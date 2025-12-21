//
//  PrayerEaseWidgetBundle.swift
//  PrayerEaseWidget
//
//  Created by Alisultan Abdullah on 12/21/25.
//

import WidgetKit
import SwiftUI

@main
struct PrayerEaseWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerEaseWidget()
        PrayerEaseWidgetControl()
        PrayerEaseWidgetLiveActivity()
    }
}
