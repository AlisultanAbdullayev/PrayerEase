//
//  TabPageView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct TabPageView: View {

    @State private var selectedTab: Tab = .time

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ContentView()
            }
            .tabItem {
                Label(Tab.time.title, systemImage: Tab.time.imageName)
            }
            .tag(Tab.time)

            NavigationStack {
                QiblaView()
            }
            .tabItem {
                Label(Tab.qibla.title, systemImage: Tab.qibla.imageName)
            }
            .tag(Tab.qibla)

            // NavigationStack {
            //     ChatView()
            // }
            // .tabItem {
            //     Label(Tab.chat.title, systemImage: Tab.chat.imageName)
            // }
            // .tag(Tab.qibla)

            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label(Tab.calendar.title, systemImage: Tab.calendar.imageName)
            }
            .tag(Tab.calendar)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(Tab.settings.title, systemImage: Tab.settings.imageName)
            }
            .tag(Tab.settings)
        }
    }
}

extension TabPageView {

    private enum Tab: String, Equatable {
        case time
        case qibla
        case chat
        case calendar
        case settings

        fileprivate var imageName: String {
            switch self {
            case .time:
                return "clock"
            case .qibla:
                return "safari.fill"
            case .chat:
                return "apple.intelligence"
            case .calendar:
                return "calendar"
            case .settings:
                return "gear"
            }
        }

        fileprivate var title: String {
            self.rawValue.capitalized
        }
    }
}

#Preview {
    TabPageView()
}
