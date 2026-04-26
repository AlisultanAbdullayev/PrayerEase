//
//  GlassStyle.swift
//  PrayerEase
//

import SwiftUI

struct CustomGlassModifier<S: InsettableShape>: ViewModifier {
    var glassType: Glass = .regular
    var shape: S

    func body(content: Content) -> some View {
        content
            .padding()
            .glassEffect(glassType, in: shape)
    }
}

extension View {
    func customGlassContainer<S: InsettableShape>(
        glassType: Glass = .regular,
        shape: S = ContainerRelativeShape()
    ) -> some View {
        modifier(CustomGlassModifier(glassType: glassType, shape: shape))
    }
}

