//
//  OnboardingProgressBar.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 진행 상태 바
/// 현재 진행률을 시각적으로 표시
struct OnboardingProgressBar: View {
    /// 진행률 (0.0 ~ 1.0)
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                // 진행 바
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geometry.size.width * CGFloat(min(max(progress, 0), 1)), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
            .clipShape(Capsule())
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("Progress 0%") {
    OnboardingProgressBar(progress: 0.0)
}

#Preview("Progress 50%") {
    OnboardingProgressBar(progress: 0.5)
}

#Preview("Progress 100%") {
    OnboardingProgressBar(progress: 1.0)
}
