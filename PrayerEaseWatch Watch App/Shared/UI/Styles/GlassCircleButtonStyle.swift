//
//  GlassCircleButtonStyle.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// A button style that applies glass effect with circular border shape
struct GlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassCircleButtonStyle {
    /// Glass circle button style for consistent watchOS buttons
    static var glassCircle: GlassCircleButtonStyle {
        GlassCircleButtonStyle()
    }
}
