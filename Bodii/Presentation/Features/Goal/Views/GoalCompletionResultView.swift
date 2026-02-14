//
//  GoalCompletionResultView.swift
//  Bodii
//
//  목표 기간 만료 시 결과 요약을 표시하는 뷰

import SwiftUI

/// 목표 기간 만료 시 결과 요약 뷰
///
/// 목표 달성률을 보여주고 "일상 모드로 전환합니다" 메시지를 표시합니다.
struct GoalCompletionResultView: View {

    let goal: Goal
    let overallProgress: Decimal
    let onDismiss: () -> Void

    // MARK: - Computed

    private var goalType: GoalType {
        GoalType(rawValue: goal.goalType) ?? .maintain
    }

    private var isAchieved: Bool {
        overallProgress >= 100
    }

    private var headerEmoji: String {
        if overallProgress >= 100 { return "🎉" }
        if overallProgress >= 75 { return "💪" }
        if overallProgress >= 50 { return "👏" }
        return "📊"
    }

    private var headerText: String {
        if overallProgress >= 100 { return "목표 달성!" }
        if overallProgress >= 75 { return "거의 다 왔어요!" }
        if overallProgress >= 50 { return "절반 이상 달성!" }
        return "목표 기간 종료"
    }

    private var descriptionText: String {
        if overallProgress >= 100 {
            return "축하합니다! 설정한 목표를 달성했습니다."
        }
        return "목표 기간이 종료되었습니다. 새로운 목표를 설정해보세요."
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 헤더
            VStack(spacing: 12) {
                Text(headerEmoji)
                    .font(.system(size: 64))

                Text(headerText)
                    .font(.title)
                    .fontWeight(.bold)

                Text(descriptionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 전체 달성률 원형 프로그레스
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: min(CGFloat(truncating: NSDecimalNumber(decimal: overallProgress)) / 100.0, 1.0))
                    .stroke(
                        isAchieved ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(NSDecimalNumber(decimal: overallProgress).intValue)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(isAchieved ? .green : .blue)

                    Text("달성률")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 목표 요약 정보
            VStack(spacing: 8) {
                goalDetailRow(label: "목표 유형", value: goalType.displayName)

                if let start = goal.goalPeriodStart, let end = goal.goalPeriodEnd {
                    goalDetailRow(
                        label: "목표 기간",
                        value: GoalModeService.periodText(start: start, end: end)
                    )
                }

                if let weight = goal.targetWeight?.decimalValue {
                    goalDetailRow(label: "목표 체중", value: "\(weight) kg")
                }

                if let fat = goal.targetBodyFatPct?.decimalValue {
                    goalDetailRow(label: "목표 체지방률", value: "\(fat)%")
                }

                if let muscle = goal.targetMuscleMass?.decimalValue {
                    goalDetailRow(label: "목표 근육량", value: "\(muscle) kg")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

            Spacer()

            // 닫기 버튼
            Button(action: onDismiss) {
                Text("확인")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Components

    private func goalDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Sheet Wrapper

/// Sheet에서 사용되는 래퍼 - GoalProgressViewModel로 진행률을 로드합니다.
struct GoalCompletionResultSheet: View {

    let goal: Goal
    @StateObject private var progressViewModel: GoalProgressViewModel
    let onDismiss: () -> Void

    init(goal: Goal, progressViewModel: GoalProgressViewModel, onDismiss: @escaping () -> Void) {
        self.goal = goal
        self._progressViewModel = StateObject(wrappedValue: progressViewModel)
        self.onDismiss = onDismiss
    }

    var body: some View {
        GoalCompletionResultView(
            goal: goal,
            overallProgress: progressViewModel.overallProgress,
            onDismiss: onDismiss
        )
        .task {
            await progressViewModel.loadProgress()
        }
    }
}
