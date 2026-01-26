//
//  TabPageView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct TabPageView: View {
    @State private var selectedTab: AppTab = .time

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: AppTab.time) {
                NavigationStack {
                    PrayerTimesView()
                }
            } label: {
                Label(AppTab.time.title, systemImage: AppTab.time.imageName)
            }

            Tab(value: AppTab.qibla) {
                NavigationStack {
                    QiblaView()
                }
            } label: {
                Label(AppTab.qibla.title, systemImage: AppTab.qibla.imageName)
            }

            // Tab(value: AppTab.chat) {
            //     NavigationStack {
            //         ChatView()
            //     }
            // } label: {
            //     Label(AppTab.chat.title, systemImage: AppTab.chat.imageName)
            // }

            Tab(value: AppTab.calendar) {
                NavigationStack {
                    EventsView()
                }
            } label: {
                Label(AppTab.calendar.title, systemImage: AppTab.calendar.imageName)
            }

            Tab(value: AppTab.settings) {
                NavigationStack {
                    SettingsView()
                }
            } label: {
                Label(AppTab.settings.title, systemImage: AppTab.settings.imageName)
            }
        }
    }
}

extension TabPageView {

    private enum AppTab: String, Hashable {
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
