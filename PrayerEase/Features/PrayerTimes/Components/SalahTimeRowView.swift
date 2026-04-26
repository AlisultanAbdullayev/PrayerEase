//
//  SalahTimeRowView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct SalahTimeRowView: View {
    @Environment(NotificationManager.self) private var notificationManager

    let imageName: String
    let salahTime: String
    let salahName: String

    var body: some View {
        HStack {
            SalahLeadingContentView(imageName: imageName, salahName: salahName)
            Spacer()
            SalahNotificationButton(
                salahName: salahName,
                notificationManager: notificationManager
            )
            Spacer()
            Text(salahTime)
        }
    }
}

private struct SalahLeadingContentView: View {
    let imageName: String
    let salahName: String

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .font(.body)
            Text(salahName)
        }
        .frame(width: 100, alignment: .leading)
    }
}

private struct SalahNotificationButton: View {
    let salahName: String
    let notificationManager: NotificationManager

    var body: some View {
        let isEnabled = notificationManager.notificationSettings[salahName] ?? true
        Button(action: {
            toggleNotification()
        }, label: {
            Image(systemName: isEnabled ? "bell.fill" : "bell.slash")
        })
        .buttonStyle(.glass)
        .sensoryFeedback(
            .selection, trigger: notificationManager.notificationSettings[salahName] ?? false)
        .accessibilityLabel(
            isEnabled
                ? "Disable \(salahName) notification"
                : "Enable \(salahName) notification"
        )
    }

    private func toggleNotification() {
        let currentSetting = notificationManager.notificationSettings[salahName] ?? true
        notificationManager.updateNotificationSettings(
            for: salahName, sendNotification: !currentSetting)
    }
}

struct SalahTimeRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SalahTimeRowView(imageName: "sun", salahTime: "12:30", salahName: "Fajr")
                .previewLayout(.sizeThatFits)
                .padding()

            SalahTimeRowView(imageName: "moon", salahTime: "19:45", salahName: "Maghrib")
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
