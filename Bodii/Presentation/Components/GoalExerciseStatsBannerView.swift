//
//  GoalExerciseStatsBannerView.swift
//  Bodii
//
//  목표 모드 활성 시 운동 탭 상단에 표시되는 통계 배너

import SwiftUI

/// 목표 모드 운동 탭 통계 배너
///
/// 목표 기간 내 운동 종류별 횟수와 운동일 퍼센트를 표시합니다.
struct GoalExerciseStatsBannerView: View {

    let dDayText: String
    let urgency: GoalUrgency
    @ObservedObject var viewModel: GoalExerciseStatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 상단: D-Day + 운동 종류별 횟수
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

                Text(viewModel.exerciseTypeSummary)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()
            }

            // 하단: 운동일 퍼센트
            HStack(spacing: 6) {
                // 미니 프로그레스 바
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(urgency.color)
                            .frame(
                                width: geometry.size.width * CGFloat(viewModel.exerciseDaysPercent) / 100.0,
                                height: 4
                            )
                    }
                }
                .frame(width: 60, height: 4)

                Text("운동한 일수 \(viewModel.exerciseDays)/\(viewModel.totalDaysElapsed)일 (\(viewModel.exerciseDaysPercent)%)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(urgency.color)
            }
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
