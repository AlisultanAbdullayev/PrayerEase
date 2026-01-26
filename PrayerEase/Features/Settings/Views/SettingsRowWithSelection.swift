//
//  SettingsRowWithSelection.swift
//  PrayerEase
//
//  Created by Alisultan Abdullah on 10/30/24.
//

import SwiftUI

struct SettingsRowWithSelection<Content: View>: View {
    let text: Text?
    let content: Content
    let systemImage: String?
    
    init(
        text: Text? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.text = text
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        HStack {
            SettingsRowLeadingContent(text: text, systemImage: systemImage)
            Spacer()
            content
        }
    }
}

private struct SettingsRowLeadingContent: View {
    let text: Text?
    let systemImage: String?

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.accent)
            }
            text
        }
    }
}

struct SettingsRowWithSelection_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsRowWithSelection(text: Text("Setting"), systemImage: "gear") {
                Text("Value")
            }
            
            SettingsRowWithSelection(text: Text("Another Setting")) {
                Toggle("", isOn: .constant(true))
            }
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
