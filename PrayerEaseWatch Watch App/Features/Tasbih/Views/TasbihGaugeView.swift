//
//  TasbihGaugeView.swift
//  PrayerEaseWatch Watch App
//
//  Created by Antigravity on 12/23/25.
//

import SwiftUI

/// Circular gauge component showing Tasbih progress
struct TasbihGaugeView: View {
    let currentCount: Int
    let targetCount: Int
    let totalCount: Int

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Circular progress gauge
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 10)
                    .frame(width: 120, height: 120)

                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                // Count display
                VStack(spacing: 2) {
                    Text("\(currentCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    Text("of \(targetCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Total count
            Text("Total: \(totalCount)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TasbihGaugeView(currentCount: 15, targetCount: 33, totalCount: 150)
}
