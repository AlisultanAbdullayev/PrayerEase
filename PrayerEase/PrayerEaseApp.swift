//
//  PrayerEaseApp.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

@main
struct PrayerEaseApp: App {
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var prayerTimeManager = PrayerTimeManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            TabPageView()
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .environmentObject(prayerTimeManager)
                .task {
                    setupApp()
                }
        }
    }
    private func setupApp() {
         locationManager.requestLocation()
         notificationManager.syncNotifications()
     }
}

#if DEBUG
struct SalahTimeApp_Previews: PreviewProvider {
    static var previews: some View {
        TabPageView()
            .environmentObject(LocationManager())
            .environmentObject(NotificationManager.shared)
            .environmentObject(PrayerTimeManager.shared)
    }
}
#endif
