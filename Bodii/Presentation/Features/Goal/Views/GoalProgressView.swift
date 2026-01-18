//
//  GoalProgressView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Progress Dashboard View Pattern
// 목표 진행 상황을 시각화하여 표시하는 대시보드 UI
// 💡 Java 비교: Android의 Fragment with Dashboard Layout과 유사

import SwiftUI

// MARK: - Goal Progress View

/// 목표 진행 상황 대시보드
///
/// 현재 활성 목표의 진행 상황을 시각적으로 표시합니다.
///
/// **주요 기능:**
/// - 전체 진행률 표시 (원형 프로그레스)
/// - 각 목표별 진행 상황 (체중, 체지방률, 근육량)
/// - 마일스톤 달성 현황 (25%, 50%, 75%, 100%)
/// - 예상 달성일 표시 (14일 트렌드 기반)
/// - 목표별 탭 전환
/// - 목표 수정 기능
///
/// **상태별 UI:**
/// - 로딩 중: ProgressView
/// - 활성 목표 없음: EmptyStateView (목표 설정 유도)
/// - 데이터 있음: 진행 상황 대시보드
/// - 에러: Alert
///
/// - Example:
/// ```swift
/// GoalProgressView(
///     viewModel: goalProgressViewModel,
///     onEditGoal: {
///         // 목표 수정 화면으로 이동
///     }
/// )
/// ```
struct GoalProgressView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @StateObject ViewModel
    // ViewModel을 View가 소유하도록 하여 생명주기 관리
    // 💡 Java 비교: ViewModel + ViewModelProvider와 유사

    /// 뷰 모델
    @StateObject var viewModel: GoalProgressViewModel

    /// 목표 수정 버튼 클릭 시 실행할 콜백
    let onEditGoal: (() -> Void)?

    // MARK: - State

    /// 선택된 탭 (목표 유형별)
    @State private var selectedTab: GoalTab = .weight

    // MARK: - Initialization

    /// GoalProgressView 초기화
    ///
    /// - Parameters:
    ///   - viewModel: 목표 진행 상황 뷰 모델
    ///   - onEditGoal: 목표 수정 버튼 클릭 시 실행할 콜백 (옵셔널)
    init(
        viewModel: GoalProgressViewModel,
        onEditGoal: (() -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onEditGoal = onEditGoal
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경색
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // 📚 학습 포인트: Conditional Content Rendering
                // 상태에 따라 다른 UI 표시
                if viewModel.isLoading {
                    // 로딩 중
                    loadingView
                } else if viewModel.hasNoActiveGoal {
                    // 활성 목표 없음
                    emptyStateView
                } else if viewModel.hasGoal {
                    // 진행 상황 대시보드
                    progressDashboard
                }
            }
            .navigationTitle("목표 진행 상황")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    editButton
                }
            }
            // 📚 학습 포인트: Pull-to-Refresh
            // refreshable modifier로 새로고침 지원
            .refreshable {
                await viewModel.refresh()
            }
            // 📚 학습 포인트: Alert for Errors
            // errorMessage가 nil이 아니면 알림 표시
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            // 📚 학습 포인트: Celebration Sheet
            // 마일스톤 달성 시 축하 화면 표시
            .sheet(isPresented: $viewModel.showCelebration) {
                celebrationView
            }
        }
    }

    // MARK: - View Components

    // 📚 학습 포인트: Loading State View
    // 데이터 로딩 중 표시되는 뷰

    /// 로딩 뷰
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)

            Text("목표 진행 상황 로드 중...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// 빈 상태 뷰 (활성 목표 없음)
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 아이콘
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundStyle(.gray)

            // 제목
            Text("설정된 목표가 없습니다")
                .font(.title2)
                .fontWeight(.semibold)

            // 설명
            Text("먼저 목표를 설정하여 진행 상황을 추적하세요")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // 목표 설정 버튼
            Button(action: {
                onEditGoal?()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("목표 설정하기")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }

    /// 진행 상황 대시보드
    @ViewBuilder
    private var progressDashboard: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 전체 진행률 카드
                overallProgressCard

                // 목표별 탭 전환
                if hasMultipleGoals {
                    goalTabPicker
                }

                // 선택된 목표의 상세 진행 상황
                selectedGoalProgressCard

                // 마일스톤 진행 바
                milestonesProgressCard

                // 예상 달성일 카드
                projectedCompletionCard

                // 트렌드 정보 카드
                trendInfoCard
            }
            .padding()
        }
    }

    /// 수정 버튼
    @ViewBuilder
    private var editButton: some View {
        Button(action: {
            onEditGoal?()
        }) {
            Image(systemName: "pencil")
                .font(.headline)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Dashboard Cards

    /// 전체 진행률 카드
    @ViewBuilder
    private var overallProgressCard: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(.blue)

                Text("전체 진행률")
                    .font(.headline)

                Spacer()
            }

            // 📚 학습 포인트: Circular Progress Indicator
            // ZStack으로 원형 프로그레스 구현
            ZStack {
                // 배경 원
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)

                // 진행률 원
                Circle()
                    .trim(from: 0, to: CGFloat(min(Double(truncating: viewModel.overallProgress as NSNumber) / 100.0, 1.0)))
                    .stroke(
                        progressColor(viewModel.overallProgress),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.overallProgress)

                // 진행률 텍스트
                VStack(spacing: 4) {
                    Text(viewModel.formatProgress(viewModel.overallProgress))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(progressColor(viewModel.overallProgress))

                    Text(progressStatusText(viewModel.overallProgress))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)

            // 온트랙 상태
            if viewModel.hasSufficientTrendData {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isOnTrack ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(viewModel.isOnTrack ? .green : .orange)

                    Text(viewModel.isOnTrack ? "계획대로 진행 중" : "계획보다 느립니다")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(viewModel.isOnTrack ? .green : .orange)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((viewModel.isOnTrack ? Color.green : Color.orange).opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 목표별 탭 선택기
    @ViewBuilder
    private var goalTabPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("목표별 진행 상황")
                .font(.headline)
                .padding(.horizontal)

            // 📚 학습 포인트: Segmented Picker for Tab Switching
            // 목표 유형별로 탭 전환
            Picker("목표 선택", selection: $selectedTab) {
                if viewModel.weightProgress != nil {
                    Text("체중").tag(GoalTab.weight)
                }
                if viewModel.bodyFatProgress != nil {
                    Text("체지방률").tag(GoalTab.bodyFat)
                }
                if viewModel.muscleProgress != nil {
                    Text("근육량").tag(GoalTab.muscle)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    /// 선택된 목표의 상세 진행 카드
    @ViewBuilder
    private var selectedGoalProgressCard: some View {
        let goal = viewModel.currentGoal
        let body = viewModel.currentBody

        VStack(spacing: 20) {
            // 📚 학습 포인트: Tab Content Switching
            // selectedTab에 따라 다른 콘텐츠 표시
            switch selectedTab {
            case .weight:
                if let progress = viewModel.weightProgress,
                   let startWeight = goal?.startWeight,
                   let targetWeight = goal?.targetWeight,
                   let currentWeight = body?.weight {
                    goalDetailCard(
                        title: "체중 목표",
                        icon: "scalemass",
                        progress: progress,
                        start: startWeight,
                        current: currentWeight,
                        target: targetWeight,
                        unit: "kg",
                        color: .blue
                    )
                }

            case .bodyFat:
                if let progress = viewModel.bodyFatProgress,
                   let startBodyFat = goal?.startBodyFatPct,
                   let targetBodyFat = goal?.targetBodyFatPct,
                   let currentBodyFat = body?.bodyFatPercent {
                    goalDetailCard(
                        title: "체지방률 목표",
                        icon: "percent",
                        progress: progress,
                        start: startBodyFat,
                        current: currentBodyFat,
                        target: targetBodyFat,
                        unit: "%",
                        color: .orange
                    )
                }

            case .muscle:
                if let progress = viewModel.muscleProgress,
                   let startMuscle = goal?.startMuscleMass,
                   let targetMuscle = goal?.targetMuscleMass,
                   let currentMuscle = body?.muscleMass {
                    goalDetailCard(
                        title: "근육량 목표",
                        icon: "figure.strengthtraining.traditional",
                        progress: progress,
                        start: startMuscle,
                        current: currentMuscle,
                        target: targetMuscle,
                        unit: "kg",
                        color: .green
                    )
                }
            }
        }
    }

    /// 목표 상세 카드
    ///
    /// 시작값, 현재값, 목표값을 표시하고 프로그레스 바를 보여줍니다.
    @ViewBuilder
    private func goalDetailCard(
        title: String,
        icon: String,
        progress: ProgressResult,
        start: Decimal,
        current: Decimal,
        target: Decimal,
        unit: String,
        color: Color
    ) -> some View {
        VStack(spacing: 20) {
            // 헤더
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)

                Text(title)
                    .font(.headline)

                Spacer()

                // 진행률 배지
                Text(viewModel.formatProgress(progress.percentage))
                    .font(.headline)
                    .foregroundStyle(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.1))
                    )
            }

            // 프로그레스 바
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 배경 바
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)

                        // 진행률 바
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(
                                width: geometry.size.width * CGFloat(min(Double(truncating: progress.percentage as NSNumber) / 100.0, 1.0)),
                                height: 12
                            )
                            .animation(.easeInOut, value: progress.percentage)
                    }
                }
                .frame(height: 12)
            }

            // 시작, 현재, 목표 값 표시
            HStack(spacing: 0) {
                // 시작
                VStack(spacing: 4) {
                    Text("시작")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatValue(start, unit: unit))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)

                // 현재
                VStack(spacing: 4) {
                    Text("현재")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatValue(current, unit: unit))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
                .frame(maxWidth: .infinity)

                // 목표
                VStack(spacing: 4) {
                    Text("목표")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formatValue(target, unit: unit))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }

            // 남은 값
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.secondary)

                Text("남은 \(title.replacingOccurrences(of: " 목표", with: "")): ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(formatValue(progress.remaining, unit: unit))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 마일스톤 진행 카드
    @ViewBuilder
    private var milestonesProgressCard: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: "rosette")
                    .font(.title3)
                    .foregroundStyle(.purple)

                Text("마일스톤")
                    .font(.headline)

                Spacer()
            }

            // 📚 학습 포인트: Milestone Progress Bar
            // 25%, 50%, 75%, 100% 마일스톤을 시각적으로 표시
            VStack(spacing: 12) {
                // 프로그레스 바 with 마일스톤 마커
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 배경 바
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)

                        // 진행률 바
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * CGFloat(min(Double(truncating: viewModel.overallProgress as NSNumber) / 100.0, 1.0)),
                                height: 16
                            )
                            .animation(.easeInOut, value: viewModel.overallProgress)

                        // 마일스톤 마커
                        HStack(spacing: 0) {
                            ForEach([Milestone.quarter, .half, .threeQuarters, .complete], id: \.self) { milestone in
                                Spacer()

                                VStack(spacing: 0) {
                                    // 마커
                                    Circle()
                                        .fill(viewModel.achievedMilestones.contains(milestone) ? Color.purple : Color.gray.opacity(0.5))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: viewModel.achievedMilestones.contains(milestone) ? "checkmark" : "")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        )
                                }
                                .offset(y: -4)

                                if milestone != .complete {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .frame(height: 24)

                // 마일스톤 레이블
                HStack(spacing: 0) {
                    ForEach([Milestone.quarter, .half, .threeQuarters, .complete], id: \.self) { milestone in
                        Spacer()

                        Text(milestone.displayName)
                            .font(.caption2)
                            .foregroundStyle(viewModel.achievedMilestones.contains(milestone) ? .purple : .secondary)
                            .fontWeight(viewModel.achievedMilestones.contains(milestone) ? .semibold : .regular)

                        if milestone != .complete {
                            Spacer()
                        }
                    }
                }
            }

            // 달성한 마일스톤 목록
            if !viewModel.achievedMilestones.isEmpty {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)

                    Text("달성한 마일스톤: ")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(viewModel.achievedMilestones.map { $0.displayName }.joined(separator: ", "))
                        .font(.caption)
                        .fontWeight(.semibold)

                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 예상 달성일 카드
    @ViewBuilder
    private var projectedCompletionCard: some View {
        VStack(spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(.green)

                Text("예상 달성일")
                    .font(.headline)

                Spacer()
            }

            // 📚 학습 포인트: Conditional Display Based on Data Availability
            // 트렌드 데이터가 충분한 경우에만 예상 달성일 표시
            if viewModel.hasSufficientTrendData {
                if let completionDate = viewModel.earliestCompletionDate {
                    VStack(spacing: 12) {
                        // 날짜 표시
                        Text(completionDate, format: .dateTime.year().month().day())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)

                        // 남은 일수
                        Text(viewModel.formatDaysRemaining(to: completionDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // 목표별 달성일
                        VStack(alignment: .leading, spacing: 8) {
                            if let weightDate = viewModel.weightCompletionDate {
                                projectedDateRow(
                                    icon: "scalemass",
                                    title: "체중",
                                    date: weightDate,
                                    color: .blue
                                )
                            }

                            if let bodyFatDate = viewModel.bodyFatCompletionDate {
                                projectedDateRow(
                                    icon: "percent",
                                    title: "체지방률",
                                    date: bodyFatDate,
                                    color: .orange
                                )
                            }

                            if let muscleDate = viewModel.muscleCompletionDate {
                                projectedDateRow(
                                    icon: "figure.strengthtraining.traditional",
                                    title: "근육량",
                                    date: muscleDate,
                                    color: .green
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                } else {
                    // 예상 달성일 계산 불가
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)

                        Text("현재 추세로는 목표 달성이 어렵습니다")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text("목표를 조정하거나 노력을 배가해주세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                // 데이터 부족
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)

                    Text("트렌드 데이터 수집 중")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("데이터 포인트: \(viewModel.dataPointsCount) / 5")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("정확한 예측을 위해 최소 5회 이상의 체성분 기록이 필요합니다")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 예상 달성일 행
    @ViewBuilder
    private func projectedDateRow(
        icon: String,
        title: String,
        date: Date,
        color: Color
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(date, format: .dateTime.month().day())
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }

    /// 트렌드 정보 카드
    @ViewBuilder
    private var trendInfoCard: some View {
        if viewModel.hasSufficientTrendData {
            VStack(spacing: 12) {
                // 헤더
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    Text("14일 트렌드")
                        .font(.headline)

                    Spacer()
                }

                // 안내 메시지
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)

                    Text("최근 14일간의 체성분 기록을 바탕으로 현재 추세를 분석했습니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    /// 축하 뷰
    @ViewBuilder
    private var celebrationView: some View {
        VStack(spacing: 24) {
            // 축하 아이콘
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)

            // 제목
            Text("축하합니다! 🎉")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 달성한 마일스톤 표시
            if !viewModel.newMilestones.isEmpty {
                VStack(spacing: 8) {
                    Text("새로운 마일스톤 달성")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.newMilestones, id: \.self) { milestone in
                        Text(milestone.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.purple)
                    }
                }
            }

            // 격려 메시지
            Text("계속 노력하고 있군요! 멋집니다!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // 닫기 버튼
            Button(action: {
                viewModel.clearCelebration()
            }) {
                Text("확인")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple)
                    )
            }
            .padding(.horizontal, 32)
        }
        .padding(32)
        .presentationDetents([.medium])
    }

    // MARK: - Helper Methods

    /// 여러 목표가 설정되어 있는지 확인
    private var hasMultipleGoals: Bool {
        let activeGoalsCount = [
            viewModel.weightProgress != nil,
            viewModel.bodyFatProgress != nil,
            viewModel.muscleProgress != nil
        ].filter { $0 }.count

        return activeGoalsCount > 1
    }

    /// 진행률에 따른 색상 반환
    ///
    /// - Parameter progress: 진행률 (%)
    /// - Returns: 진행률에 적합한 색상
    private func progressColor(_ progress: Decimal) -> Color {
        let value = Double(truncating: progress as NSNumber)

        switch value {
        case 0..<25:
            return .red
        case 25..<50:
            return .orange
        case 50..<75:
            return .yellow
        case 75..<100:
            return .blue
        case 100...:
            return .green
        default:
            return .gray
        }
    }

    /// 진행률 상태 텍스트 반환
    ///
    /// - Parameter progress: 진행률 (%)
    /// - Returns: 상태 텍스트
    private func progressStatusText(_ progress: Decimal) -> String {
        let value = Double(truncating: progress as NSNumber)

        switch value {
        case 0..<25:
            return "시작 단계"
        case 25..<50:
            return "1/4 달성"
        case 50..<75:
            return "절반 달성"
        case 75..<100:
            return "거의 다 왔어요!"
        case 100...:
            return "목표 달성!"
        default:
            return ""
        }
    }

    /// 값 포맷팅
    ///
    /// - Parameters:
    ///   - value: 포맷팅할 값
    ///   - unit: 단위
    /// - Returns: 포맷된 문자열
    private func formatValue(_ value: Decimal, unit: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: value)
        return (formatter.string(from: number) ?? "\(value)") + " " + unit
    }
}

// MARK: - Supporting Types

/// 목표 탭 유형
///
/// 여러 목표가 설정된 경우 탭으로 전환
enum GoalTab {
    /// 체중 목표
    case weight

    /// 체지방률 목표
    case bodyFat

    /// 근육량 목표
    case muscle
}

// MARK: - Preview

#Preview("Goal Progress - Weight Loss") {
    // 📚 학습 포인트: Preview with Mock Data
    // Mock UseCase를 사용한 Preview

    struct MockGetGoalProgressUseCase: GetGoalProgressUseCase {
        func execute(previousProgress: Decimal?) async throws -> GoalProgressData {
            // Mock 데이터 생성
            let goal = Goal(
                id: UUID(),
                userId: UUID(),
                goalType: .lose,
                targetWeight: Decimal(65.0),
                targetBodyFatPct: Decimal(18.0),
                targetMuscleMass: nil,
                weeklyWeightRate: Decimal(-0.5),
                weeklyFatPctRate: Decimal(-0.5),
                weeklyMuscleRate: nil,
                dailyCalorieTarget: 2000,
                startWeight: Decimal(70.0),
                startBodyFatPct: Decimal(22.0),
                startMuscleMass: Decimal(30.0),
                startBMR: Decimal(1650),
                startTDEE: Decimal(2310),
                isActive: true,
                createdAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30일 전
                updatedAt: Date()
            )

            let currentBody = BodyCompositionEntry(
                id: UUID(),
                userId: UUID(),
                weight: Decimal(67.0),
                bodyFatPercent: Decimal(20.0),
                muscleMass: Decimal(30.5),
                measuredAt: Date(),
                createdAt: Date()
            )

            let weightProgress = ProgressResult(
                percentage: Decimal(60.0),
                remaining: Decimal(2.0),
                direction: .loss
            )

            let bodyFatProgress = ProgressResult(
                percentage: Decimal(50.0),
                remaining: Decimal(2.0),
                direction: .loss
            )

            let weightProjection = ProjectionResult(
                estimatedCompletionDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                daysToCompletion: 30,
                isOnTrack: true
            )

            return GoalProgressData(
                goal: goal,
                currentBody: currentBody,
                overallProgress: Decimal(55.0),
                weightProgress: weightProgress,
                bodyFatProgress: bodyFatProgress,
                muscleProgress: nil,
                achievedMilestones: [.quarter, .half],
                newlyAchievedMilestones: [],
                weightTrend: nil,
                bodyFatTrend: nil,
                muscleTrend: nil,
                weightProjection: weightProjection,
                bodyFatProjection: nil,
                muscleProjection: nil,
                dataPointsCount: 10
            )
        }
    }

    let mockUseCase = MockGetGoalProgressUseCase()
    let viewModel = GoalProgressViewModel(getGoalProgressUseCase: mockUseCase)

    return GoalProgressView(
        viewModel: viewModel,
        onEditGoal: {
            print("목표 수정")
        }
    )
}

#Preview("Goal Progress - Empty State") {
    struct MockGetGoalProgressUseCase: GetGoalProgressUseCase {
        func execute(previousProgress: Decimal?) async throws -> GoalProgressData {
            throw GetGoalProgressError.noActiveGoal
        }
    }

    let mockUseCase = MockGetGoalProgressUseCase()
    let viewModel = GoalProgressViewModel(getGoalProgressUseCase: mockUseCase)

    return GoalProgressView(
        viewModel: viewModel,
        onEditGoal: {
            print("목표 설정")
        }
    )
}

// MARK: - Learning Notes

/// ## Goal Progress Dashboard Pattern
///
/// 목표 진행 상황을 시각화하여 표시하는 대시보드 UI 구현 패턴입니다.
///
/// ### 주요 구성 요소
///
/// 1. **Overall Progress Circle**:
///    - ZStack으로 원형 프로그레스 구현
///    - Circle().trim()으로 진행률 표시
///    - 색상은 진행률에 따라 동적 변경
///
/// 2. **Goal Tabs**:
///    - Picker with Segmented Style
///    - 여러 목표 (체중, 체지방률, 근육량) 간 전환
///    - @State로 선택된 탭 관리
///
/// 3. **Progress Bars**:
///    - GeometryReader로 반응형 너비 계산
///    - RoundedRectangle로 프로그레스 바 구현
///    - Animation으로 부드러운 전환
///
/// 4. **Milestone Markers**:
///    - 25%, 50%, 75%, 100% 마커 표시
///    - 달성한 마일스톤은 강조 표시
///    - HStack + Spacer로 균등 배치
///
/// 5. **Projected Completion Date**:
///    - 14일 트렌드 기반 예상 달성일 계산
///    - 데이터 충분성 검증
///    - D-Day 형식으로 남은 일수 표시
///
/// 6. **Empty State**:
///    - 활성 목표가 없을 때 표시
///    - 목표 설정 유도 UI
///    - CTA 버튼 제공
///
/// 7. **Celebration Sheet**:
///    - 새 마일스톤 달성 시 자동 표시
///    - .sheet modifier 사용
///    - presentationDetents로 높이 조절
///
/// ### Circular Progress Pattern
///
/// **ZStack으로 원형 프로그레스 구현**:
/// ```swift
/// ZStack {
///     // 배경 원
///     Circle()
///         .stroke(Color.gray.opacity(0.2), lineWidth: 20)
///
///     // 진행률 원
///     Circle()
///         .trim(from: 0, to: progress / 100.0)
///         .stroke(color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
///         .rotationEffect(.degrees(-90))  // 12시 방향부터 시작
///         .animation(.easeInOut, value: progress)
///
///     // 중앙 텍스트
///     VStack {
///         Text("\(progress)%")
///             .font(.system(size: 48, weight: .bold))
///     }
/// }
/// .frame(width: 200, height: 200)
/// ```
///
/// ### Progress Bar with Markers Pattern
///
/// **마일스톤 마커가 있는 프로그레스 바**:
/// ```swift
/// GeometryReader { geometry in
///     ZStack(alignment: .leading) {
///         // 배경 바
///         RoundedRectangle(cornerRadius: 8)
///             .fill(Color.gray.opacity(0.2))
///
///         // 진행률 바
///         RoundedRectangle(cornerRadius: 8)
///             .fill(color)
///             .frame(width: geometry.size.width * progress / 100.0)
///
///         // 마일스톤 마커
///         HStack(spacing: 0) {
///             ForEach([25, 50, 75, 100], id: \.self) { milestone in
///                 Spacer()
///                 Circle()
///                     .fill(achieved.contains(milestone) ? .purple : .gray)
///                     .frame(width: 24, height: 24)
///                 if milestone != 100 { Spacer() }
///             }
///         }
///     }
/// }
/// ```
///
/// ### Tab Switching Pattern
///
/// **목표별 탭 전환**:
/// ```swift
/// @State private var selectedTab: GoalTab = .weight
///
/// Picker("목표 선택", selection: $selectedTab) {
///     if viewModel.weightProgress != nil {
///         Text("체중").tag(GoalTab.weight)
///     }
///     // 다른 탭들...
/// }
/// .pickerStyle(.segmented)
///
/// switch selectedTab {
/// case .weight:
///     WeightProgressView()
/// case .bodyFat:
///     BodyFatProgressView()
/// case .muscle:
///     MuscleProgressView()
/// }
/// ```
///
/// ### Empty State Pattern
///
/// **활성 목표가 없을 때**:
/// ```swift
/// VStack(spacing: 24) {
///     Image(systemName: "target")
///         .font(.system(size: 80))
///         .foregroundStyle(.gray)
///
///     Text("설정된 목표가 없습니다")
///         .font(.title2)
///
///     Button("목표 설정하기") {
///         onEditGoal?()
///     }
/// }
/// ```
///
/// ### Celebration Sheet Pattern
///
/// **마일스톤 달성 축하**:
/// ```swift
/// .sheet(isPresented: $viewModel.showCelebration) {
///     VStack {
///         Image(systemName: "party.popper.fill")
///         Text("축하합니다! 🎉")
///         ForEach(viewModel.newMilestones) { milestone in
///             Text(milestone.displayName)
///         }
///         Button("확인") { viewModel.clearCelebration() }
///     }
///     .presentationDetents([.medium])
/// }
/// ```
///
/// ### Best Practices
///
/// 1. **Visual Hierarchy**:
///    - 전체 진행률을 가장 눈에 띄게 표시
///    - 상세 정보는 아래로 배치
///
/// 2. **Color Coding**:
///    - 진행률에 따라 색상 변경 (빨강 → 주황 → 노랑 → 파랑 → 초록)
///    - 목표별로 고유 색상 사용
///
/// 3. **Data Sufficiency Check**:
///    - 데이터가 충분한지 확인 후 표시
///    - 부족하면 안내 메시지 제공
///
/// 4. **Responsive Layout**:
///    - GeometryReader로 화면 크기에 맞게 조정
///    - ScrollView로 작은 화면 대응
///
/// 5. **Animation**:
///    - 진행률 변경 시 부드러운 애니메이션
///    - .easeInOut으로 자연스러운 전환
///
/// 6. **Pull-to-Refresh**:
///    - .refreshable modifier로 새로고침 지원
///    - 최신 데이터 업데이트
///
/// 7. **Error Handling**:
///    - Alert로 에러 표시
///    - Empty state로 안내
///
