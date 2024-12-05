//
//  SalahTimeRowView.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct SalahTimeRowView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    let imageName: String
    let salahTime: String
    let salahName: String
    
    var body: some View {
        HStack {
            leadingContent
            Spacer(minLength: 80)
            notificationButton
            Spacer()
            Text(salahTime)
        }
        .padding(.vertical, 5)
    }
    
    private var leadingContent: some View {
        HStack {
            Image(systemName: imageName)
                .frame(width: 30, alignment: .leading)
            Text(salahName)
        }
        .frame(width: 110, alignment: .leading)
    }
    
    private var notificationButton: some View {
        Button(action: toggleNotification) {
            Image(systemName: notificationManager.notificationSettings[salahName] ?? true ? "bell.fill" : "bell.slash")
                .foregroundColor(.primary)
        }
    }
    
    private func toggleNotification() {
        let currentSetting = notificationManager.notificationSettings[salahName] ?? true
        notificationManager.updateNotificationSettings(for: salahName, sendNotification: !currentSetting)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
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
