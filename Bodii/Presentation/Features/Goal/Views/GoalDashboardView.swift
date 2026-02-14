//
//  GoalDashboardView.swift
//  Bodii
//
//  목표 모드 활성 시 홈 탭을 대체하는 대시보드
//

import SwiftUI

// MARK: - Goal Dashboard View

/// 목표 모드 활성 시 홈 탭을 대체하는 대시보드 뷰
///
/// **구성**:
/// 1. D-Day 배너 (긴박도 색상 반영)
/// 2. 오늘의 칼로리 + 스트릭
/// 3. 목표 진행 현황
/// 4. 스와이프 카드 (주간 캘린더 | 체성분 그래프) - 재사용
/// 5. AI 코칭 (목표 모드 톤)
struct GoalDashboardView: View {

    // MARK: - Properties

    @StateObject private var viewModel: HomeViewModel
    @StateObject private var goalProgressViewModel: GoalProgressViewModel
    @StateObject private var goalModeViewModel: GoalModeSettingsViewModel
    @StateObject private var weeklyReportViewModel: WeeklyReportViewModel

    /// 현재 선택된 카드 인덱스
    @State private var selectedCardIndex: Int = 0

    /// 목표 진행상황 상세 표시 여부
    @State private var showGoalProgress = false

    // MARK: - Initialization

    init(
        viewModel: HomeViewModel,
        goalProgressViewModel: GoalProgressViewModel,
        goalModeViewModel: GoalModeSettingsViewModel,
        weeklyReportViewModel: WeeklyReportViewModel
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._goalProgressViewModel = StateObject(wrappedValue: goalProgressViewModel)
        self._goalModeViewModel = StateObject(wrappedValue: goalModeViewModel)
        self._weeklyReportViewModel = StateObject(wrappedValue: weeklyReportViewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // D-Day 배너
                dDayBanner

                // 오늘의 칼로리 + 스트릭
                dailyCalorieSection

                // 목표 진행 현황
                goalProgressSection

                // 주간 리포트
                weeklyReportSection

                // 스와이프 카드 (주간 캘린더 | 체성분 그래프)
                swipeCardSection

                // AI 코칭
                aiCoachingSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await viewModel.loadData()
            await goalProgressViewModel.loadProgress()
            await goalModeViewModel.loadActiveGoal()
            await loadWeeklyReport()
        }
        .refreshable {
            await viewModel.loadData()
            await goalProgressViewModel.loadProgress()
            await goalModeViewModel.loadActiveGoal()
            await loadWeeklyReport()
        }
        .sheet(isPresented: $showGoalProgress) {
            let goalProgressVM = DIContainer.shared.makeGoalProgressViewModel()
            GoalProgressView(viewModel: goalProgressVM, onEditGoal: nil)
        }
        .overlay {
            if goalProgressViewModel.showCelebration,
               !goalProgressViewModel.newMilestones.isEmpty {
                MilestoneCelebrationView(
                    milestones: goalProgressViewModel.newMilestones,
                    onDismiss: { goalProgressViewModel.clearCelebration() }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - D-Day Banner

    private var dDayBanner: some View {
        let urgency = goalModeViewModel.urgencyLevel ?? .relaxed
        let dDayText = goalModeViewModel.dDayText ?? "D-?"
        let summary = goalModeViewModel.goalSummaryText ?? ""
        let periodText = goalModeViewModel.goalPeriodText ?? ""

        return VStack(spacing: 8) {
            // D-Day 큰 텍스트
            Text(dDayText)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(urgency.color)

            // 목표 요약
            if !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            // 기간 프로그레스 바
            if let goal = goalModeViewModel.activeGoal,
               let start = goal.goalPeriodStart,
               let end = goal.goalPeriodEnd {
                let progress = GoalModeService.periodProgress(start: start, end: end)

                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: urgency.gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 6)
                        }
                    }
                    .frame(height: 6)

                    HStack {
                        Text("\(Int(progress * 100))% 경과")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(periodText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: urgency.gradientColors + [Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .shadow(color: urgency.color.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    // MARK: - Daily Calorie Section

    private var dailyCalorieSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.orange)
                    Text("오늘의 칼로리")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                // 목표 칼로리 기준 안내
                if viewModel.dailyCalorieTarget > 0 {
                    Text("목표 \(viewModel.dailyCalorieTarget) kcal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

            // 칼로리 카드
            HStack(spacing: 0) {
                calorieMetric(
                    title: "섭취",
                    value: viewModel.intakeCalories,
                    icon: "fork.knife",
                    color: viewModel.isIntakeNearTarget ? .green : .orange
                )

                Rectangle()
                    .fill(Color(.separator))
                    .frame(width: 1)
                    .padding(.vertical, 12)

                calorieMetric(
                    title: "소모",
                    value: viewModel.burnCalories,
                    icon: "flame.fill",
                    color: .red
                )
            }

            // 프로그레스 바
            calorieProgressView
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func calorieMetric(title: String, value: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text("/ \(viewModel.effectiveTarget) kcal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var calorieProgressView: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let barWidth = geometry.size.width
                let target = Double(viewModel.effectiveTarget)
                let intake = Double(viewModel.intakeCalories)
                let barMax = max(target * 1.2, 1.0)
                let intakeWidth = min(CGFloat(intake / barMax) * barWidth, barWidth)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.isIntakeNearTarget ? Color.green : Color.orange)
                        .frame(width: max(0, intakeWidth), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                let remaining = viewModel.remainingCalories
                Text(remaining >= 0
                    ? "남은 칼로리: \(remaining.formatted()) kcal"
                    : "\(abs(remaining).formatted()) kcal 초과")
                    .font(.caption)
                    .foregroundColor(remaining >= 0 ? .secondary : .red)

                Spacer()
            }
        }
    }

    // MARK: - Goal Progress Section

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .foregroundStyle(.blue)
                    Text("목표 진행 현황")
                        .font(.headline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button {
                    showGoalProgress = true
                } label: {
                    HStack(spacing: 4) {
                        Text("상세 보기")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(.blue)
                }
            }

            if goalProgressViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    // 전체 진행률
                    let overallProgress = goalProgressViewModel.overallProgress
                    let progressValue = min(NSDecimalNumber(decimal: overallProgress).doubleValue / 100.0, 1.0)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemGray5))
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(progressGradient(for: overallProgress))
                                .frame(width: geometry.size.width * progressValue, height: 10)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("전체 달성률")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(NSDecimalNumber(decimal: overallProgress).intValue)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // 목표별 진행률
                    if let wp = goalProgressViewModel.weightProgress {
                        let goal = goalProgressViewModel.currentGoal
                        let body = goalProgressViewModel.currentBody
                        goalMetricRow(
                            icon: "scalemass",
                            label: "체중",
                            startValue: formatOptionalDecimal(goal?.startWeight?.decimalValue),
                            currentValue: formatOptionalDecimal(body?.weight),
                            targetValue: formatOptionalDecimal(goal?.targetWeight?.decimalValue),
                            unit: "kg",
                            progress: wp.percentage,
                            color: .blue
                        )
                    }

                    if let bfp = goalProgressViewModel.bodyFatProgress {
                        let goal = goalProgressViewModel.currentGoal
                        let body = goalProgressViewModel.currentBody
                        goalMetricRow(
                            icon: "percent",
                            label: "체지방",
                            startValue: formatOptionalDecimal(goal?.startBodyFatPct?.decimalValue),
                            currentValue: formatOptionalDecimal(body?.bodyFatPercent),
                            targetValue: formatOptionalDecimal(goal?.targetBodyFatPct?.decimalValue),
                            unit: "%",
                            progress: bfp.percentage,
                            color: .orange
                        )
                    }

                    if let mp = goalProgressViewModel.muscleProgress {
                        let goal = goalProgressViewModel.currentGoal
                        let body = goalProgressViewModel.currentBody
                        goalMetricRow(
                            icon: "figure.strengthtraining.traditional",
                            label: "근육량",
                            startValue: formatOptionalDecimal(goal?.startMuscleMass?.decimalValue),
                            currentValue: formatOptionalDecimal(body?.muscleMass),
                            targetValue: formatOptionalDecimal(goal?.targetMuscleMass?.decimalValue),
                            unit: "kg",
                            progress: mp.percentage,
                            color: .green
                        )
                    }
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

    /// 목표 지표 행
    private func goalMetricRow(
        icon: String,
        label: String,
        startValue: String,
        currentValue: String,
        targetValue: String,
        unit: String,
        progress: Decimal,
        color: Color
    ) -> some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                Spacer()

                Text("현재: \(currentValue)\(unit)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            HStack {
                Text("\(startValue)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                GeometryReader { geometry in
                    let progressValue = min(max(NSDecimalNumber(decimal: progress).doubleValue / 100.0, 0), 1.0)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geometry.size.width * progressValue, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(targetValue)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Swipe Card Section

    private var swipeCardSection: some View {
        VStack(spacing: 12) {
            // 탭 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(index == selectedCardIndex ? Color.blue : Color(.systemGray4))
                        .frame(width: index == selectedCardIndex ? 20 : 8, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: selectedCardIndex)
                }
            }

            // 스와이프 가능한 카드 (HomeView와 동일)
            TabView(selection: $selectedCardIndex) {
                WeeklyCalendarView(
                    weekData: viewModel.weekData,
                    today: Date()
                )
                .tag(0)

                BodyCompositionChartView(
                    data: viewModel.bodyChartData,
                    gender: viewModel.userGender
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
        }
    }

    // MARK: - AI Coaching Section

    private var aiCoachingSection: some View {
        let urgency = goalModeViewModel.urgencyLevel ?? .relaxed

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(urgency.color)

                Text("AI 코칭")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(urgency.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(urgency.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(urgency.color.opacity(0.1))
                    .cornerRadius(8)
            }

            if let comment = viewModel.aiComment {
                Text(comment)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(urgency.color.opacity(0.08))
                    )
            } else {
                Text("오늘의 데이터를 분석 중입니다...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
        }
    }

    // MARK: - Weekly Report Section

    private var weeklyReportSection: some View {
        WeeklyReportCardView(
            viewModel: weeklyReportViewModel,
            urgency: goalModeViewModel.urgencyLevel ?? .relaxed
        )
    }

    /// 주간 리포트 데이터 로드
    private func loadWeeklyReport() async {
        let userId = viewModel.userId
        let target = goalModeViewModel.activeGoal?.dailyCalorieTarget ?? 0
        await weeklyReportViewModel.loadWeeklyData(
            userId: userId,
            dailyCalorieTarget: target
        )
    }

    // MARK: - Helpers

    private func progressGradient(for progress: Decimal) -> LinearGradient {
        let value = NSDecimalNumber(decimal: progress).doubleValue
        let startColor: Color
        let endColor: Color

        if value < 33 {
            startColor = .red
            endColor = .orange
        } else if value < 66 {
            startColor = .orange
            endColor = .yellow
        } else {
            startColor = .yellow
            endColor = .green
        }

        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: number) ?? "\(value)"
    }

    private func formatOptionalDecimal(_ value: Decimal?) -> String {
        guard let value = value else { return "-" }
        return formatDecimal(value)
    }
}
