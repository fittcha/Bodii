//
//  GoalMiniBannerView.swift
//  Bodii
//
//  목표 모드 활성 시 각 탭 상단에 표시되는 미니 배너

import SwiftUI

/// 목표 모드 활성 시 각 탭 상단에 표시되는 미니 배너
///
/// 체성분, 식단, 운동 탭 상단에 간략한 목표 컨텍스트를 표시합니다.
struct GoalMiniBannerView: View {

    let dDayText: String
    let message: String
    let urgency: GoalUrgency

    var body: some View {
        HStack(spacing: 8) {
            // D-Day 뱃지
            Text(dDayText)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(urgency.color)
                .clipShape(Capsule())

            // 메시지
            Text(message)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundStyle(urgency.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(urgency.color.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }
}
