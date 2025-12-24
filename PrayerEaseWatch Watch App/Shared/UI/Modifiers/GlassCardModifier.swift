//
//  GlassCardModifier.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// A view modifier that applies a glass effect with rounded corners
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .glassEffect(.clear, in: .rect(cornerRadius: 12))
    }
}

extension View {
    /// Applies a glass card effect to the view
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
