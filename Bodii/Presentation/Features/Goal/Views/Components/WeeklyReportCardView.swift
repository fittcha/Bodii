//
//  WeeklyReportCardView.swift
//  Bodii
//
//  목표 대시보드에 표시되는 주간 리포트 카드

import SwiftUI

/// 주간 리포트 카드
///
/// 최근 7일간의 체중 변화, 식단 준수, 운동 빈도를 요약합니다.
struct WeeklyReportCardView: View {

    @ObservedObject var viewModel: WeeklyReportViewModel
    let urgency: GoalUrgency

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(urgency.color)
                Text("이번 주 리포트")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("최근 7일")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 0) {
                    // 체중 변화
                    reportRow(
                        icon: "scalemass",
                        label: "체중 변화",
                        value: viewModel.weightChangeText,
                        trailingIcon: viewModel.weightChangeIcon,
                        color: weightChangeColor
                    )

                    Divider()
                        .padding(.vertical, 6)

                    // 식단 준수
                    reportRow(
                        icon: "fork.knife",
                        label: "식단 준수",
                        value: "\(viewModel.calorieComplianceDays)/\(viewModel.totalWeekDays)일",
                        trailingIcon: nil,
                        color: complianceColor
                    )

                    Divider()
                        .padding(.vertical, 6)

                    // 운동 빈도
                    reportRow(
                        icon: "figure.run",
                        label: "운동 빈도",
                        value: "\(viewModel.exerciseDays)/\(viewModel.totalWeekDays)일",
                        trailingIcon: nil,
                        color: exerciseColor
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Row Builder

    private func reportRow(
        icon: String,
        label: String,
        value: String,
        trailingIcon: String?,
        color: Color
    ) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)

                if let trailingIcon = trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.caption)
                        .foregroundStyle(color)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Colors

    private var weightChangeColor: Color {
        guard let change = viewModel.weeklyWeightChange else { return .secondary }
        // 감량 목표에서는 음수가 좋음, 증량에서는 양수가 좋음
        // 중립적으로 표시
        if change < 0 { return .blue }
        if change > 0 { return .orange }
        return .secondary
    }

    private var complianceColor: Color {
        let ratio = viewModel.totalWeekDays > 0
            ? Double(viewModel.calorieComplianceDays) / Double(viewModel.totalWeekDays)
            : 0
        if ratio >= 0.7 { return .green }
        if ratio >= 0.4 { return .orange }
        return .red
    }

    private var exerciseColor: Color {
        let ratio = viewModel.totalWeekDays > 0
            ? Double(viewModel.exerciseDays) / Double(viewModel.totalWeekDays)
            : 0
        if ratio >= 0.5 { return .green }
        if ratio >= 0.3 { return .orange }
        return .red
    }
}
