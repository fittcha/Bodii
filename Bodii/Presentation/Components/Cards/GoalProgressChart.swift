//
//  GoalProgressChart.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Swift Charts Goal Progress Visualization
// Swift Charts 프레임워크를 사용한 목표 진행 상황 차트
// 현재 진행 상황, 예상 궤적, 마일스톤을 시각화
// 💡 Java 비교: Android의 MPAndroidChart와 유사하지만 더 선언적

import SwiftUI
import Charts

// MARK: - GoalProgressChart

/// 목표 진행 상황을 표시하는 라인 차트 컴포넌트
/// 📚 학습 포인트: Swift Charts Integration for Goal Tracking
/// - Swift Charts를 사용한 목표 진행 그래프
/// - 실제 진행 라인 (시작 → 현재)
/// - 예상 궤적 라인 (현재 → 목표) - 점선
/// - 목표선 표시 (수평선)
/// - 마일스톤 마커 (25%, 50%, 75%, 100%)
/// - 시작 지점 표시
/// 💡 Java 비교: MPAndroidChart LineChart + LimitLines와 유사하지만 더 선언적
struct GoalProgressChart: View {

    // MARK: - Types

    /// 목표 지표 타입
    /// 📚 학습 포인트: Metric Type for Formatting
    /// - 각 지표마다 단위와 색상이 다름
    enum GoalMetric {
        case weight      // 체중 (kg)
        case bodyFat     // 체지방률 (%)
        case muscle      // 근육량 (kg)

        /// 지표 색상
        var color: Color {
            switch self {
            case .weight: return .blue
            case .bodyFat: return .orange
            case .muscle: return .green
            }
        }

        /// 지표 아이콘
        var icon: String {
            switch self {
            case .weight: return "scalemass"
            case .bodyFat: return "percent"
            case .muscle: return "figure.strengthtraining.traditional"
            }
        }

        /// 지표 이름
        var displayName: String {
            switch self {
            case .weight: return "체중"
            case .bodyFat: return "체지방률"
            case .muscle: return "근육량"
            }
        }

        /// 지표 단위
        var unit: String {
            switch self {
            case .weight: return "kg"
            case .bodyFat: return "%"
            case .muscle: return "kg"
            }
        }
    }

    // MARK: - Properties

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Data Input
    /// - 3개의 데이터 포인트: 시작, 현재, 목표
    /// - 날짜순으로 정렬되어 있음 (시작 → 현재 → 목표)
    let dataPoints: [ChartDataPoint]

    /// 목표 지표 타입
    /// 📚 학습 포인트: Metric Context
    /// - 색상, 단위, 레이블 결정
    let metric: GoalMetric

    /// 달성한 마일스톤 목록
    /// 📚 학습 포인트: Milestone Indicators
    /// - 25%, 50%, 75%, 100% 마일스톤 표시
    let achievedMilestones: [Milestone]

    /// 인터랙션 활성화 여부
    /// 📚 학습 포인트: Interactive Feature Toggle
    /// - true: 탭하여 상세 정보 표시
    /// - false: 정적 차트
    let isInteractive: Bool

    /// 차트 높이
    /// 📚 학습 포인트: Customizable Height
    /// - 대시보드에서는 작게, 상세 화면에서는 크게
    let height: CGFloat

    // MARK: - State

    /// 선택된 날짜
    /// 📚 학습 포인트: Chart Selection State
    /// - 사용자가 탭한 데이터 포인트의 날짜
    /// - nil이면 선택 없음
    /// 💡 Java 비교: selectedEntry in MPAndroidChart
    @State private var selectedDate: Date?

    /// 선택된 데이터 포인트
    /// 📚 학습 포인트: Computed Property for Selection
    /// - selectedDate를 기반으로 실제 데이터 포인트 조회
    private var selectedDataPoint: ChartDataPoint? {
        guard let date = selectedDate else { return nil }
        // 날짜가 가장 가까운 데이터 포인트 찾기
        return dataPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    private var isEmpty: Bool {
        dataPoints.count < 2 // 최소 2개 (시작, 목표)
    }

    /// 시작 데이터 포인트
    private var startPoint: ChartDataPoint? {
        dataPoints.first
    }

    /// 현재 데이터 포인트
    private var currentPoint: ChartDataPoint? {
        guard dataPoints.count >= 2 else { return nil }
        return dataPoints.count >= 3 ? dataPoints[1] : nil
    }

    /// 목표 데이터 포인트
    private var goalPoint: ChartDataPoint? {
        dataPoints.last
    }

    /// 실제 진행 데이터 (시작 → 현재)
    /// 📚 학습 포인트: Actual Progress Points
    /// - 현재까지의 실제 진행 상황
    private var actualProgressPoints: [ChartDataPoint] {
        guard let start = startPoint else { return [] }
        if let current = currentPoint {
            return [start, current]
        } else {
            // 현재 데이터가 없으면 시작점만
            return [start]
        }
    }

    /// 예상 궤적 데이터 (현재 → 목표)
    /// 📚 학습 포인트: Projected Trajectory
    /// - 현재 상태에서 목표까지의 예상 경로
    private var projectedPoints: [ChartDataPoint] {
        guard let current = currentPoint ?? startPoint,
              let goal = goalPoint else {
            return []
        }
        return [current, goal]
    }

    /// Y축 최소값
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 모든 값 중 최소값보다 약간 작은 값 (여백)
    private var yAxisMinimum: Double {
        let allValues = dataPoints.map { $0.value }
        let minValue = allValues.min() ?? Decimal(0)

        // 10% 여백 추가
        let minDouble = NSDecimalNumber(decimal: minValue).doubleValue
        return minDouble * 0.9
    }

    /// Y축 최대값
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 모든 값 중 최대값보다 약간 큰 값 (여백)
    private var yAxisMaximum: Double {
        let allValues = dataPoints.map { $0.value }
        let maxValue = allValues.max() ?? Decimal(100)

        // 10% 여백 추가
        let maxDouble = NSDecimalNumber(decimal: maxValue).doubleValue
        return maxDouble * 1.1
    }

    /// 목표 방향 (감량 vs 증량)
    /// 📚 학습 포인트: Goal Direction
    /// - 시작값과 목표값 비교
    private var isDecreasing: Bool {
        guard let start = startPoint?.value,
              let goal = goalPoint?.value else {
            return false
        }
        return goal < start
    }

    // MARK: - Initialization

    /// GoalProgressChart 초기화
    /// 📚 학습 포인트: Flexible Initializer
    /// - 기본값을 제공하여 편리하게 사용
    ///
    /// - Parameters:
    ///   - dataPoints: 차트 데이터 포인트 (시작, 현재, 목표)
    ///   - metric: 목표 지표 타입
    ///   - achievedMilestones: 달성한 마일스톤 (기본값: 빈 배열)
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    init(
        dataPoints: [ChartDataPoint],
        metric: GoalMetric,
        achievedMilestones: [Milestone] = [],
        isInteractive: Bool = true,
        height: CGFloat = 300
    ) {
        self.dataPoints = dataPoints
        self.metric = metric
        self.achievedMilestones = achievedMilestones
        self.isInteractive = isInteractive
        self.height = height
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 차트 헤더
            chartHeader

            if isEmpty {
                // 빈 상태
                emptyStateView
            } else {
                // 차트
                chartView

                // 범례
                chartLegend

                // 선택된 데이터 포인트 상세 정보
                if let selected = selectedDataPoint {
                    selectedDataPointDetail(selected)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 차트 헤더
    /// 📚 학습 포인트: Header with Goal Info
    /// - 제목, 지표명 표시
    private var chartHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(metric.color)

                    Text("\(metric.displayName) 목표 진행")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                // 부제목
                if let start = startPoint, let goal = goalPoint {
                    Text("\(formatValue(start.value)) → \(formatValue(goal.value))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 달성한 마일스톤 표시
            if let latestMilestone = achievedMilestones.last {
                milestoneBadge(latestMilestone)
            }
        }
    }

    /// 마일스톤 뱃지
    /// 📚 학습 포인트: Milestone Indicator
    /// - 가장 최근에 달성한 마일스톤 표시
    ///
    /// - Parameter milestone: 마일스톤
    /// - Returns: 뱃지 뷰
    private func milestoneBadge(_ milestone: Milestone) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.caption2)

            Text(milestone.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.purple)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.15))
        .cornerRadius(8)
    }

    /// 차트 뷰
    /// 📚 학습 포인트: Swift Charts Implementation with Goal Progress
    /// - Chart { } 블록 내에 Mark 정의
    /// - LineMark: 실제 진행 및 예상 궤적
    /// - PointMark: 데이터 포인트 표시
    /// - RuleMark: 목표선 및 마일스톤 표시
    private var chartView: some View {
        Chart {
            // 1. 목표선 (수평선)
            // 📚 학습 포인트: RuleMark for Goal Line
            if let goal = goalPoint {
                RuleMark(
                    y: .value("목표", NSDecimalNumber(decimal: goal.value).doubleValue)
                )
                .foregroundStyle(metric.color.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4])) // 긴 점선
                .annotation(position: .top, alignment: .trailing) {
                    Text("목표: \(formatValue(goal.value))")
                        .font(.caption2)
                        .foregroundStyle(metric.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(metric.color.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // 2. 마일스톤 수평선
            // 📚 학습 포인트: Milestone Lines
            if let start = startPoint?.value, let goal = goalPoint?.value {
                ForEach(Milestone.allCases, id: \.self) { milestone in
                    let milestoneValue = calculateMilestoneValue(
                        start: start,
                        goal: goal,
                        percentage: milestone.percentage
                    )

                    RuleMark(
                        y: .value("Milestone", NSDecimalNumber(decimal: milestoneValue).doubleValue)
                    )
                    .foregroundStyle(achievedMilestones.contains(milestone) ? Color.purple.opacity(0.3) : Color.gray.opacity(0.1))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    .annotation(position: .leading, alignment: .leading) {
                        if achievedMilestones.contains(milestone) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    }
                }
            }

            // 3. 실제 진행 라인 (시작 → 현재)
            // 📚 학습 포인트: Actual Progress Line
            ForEach(actualProgressPoints) { point in
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value(metric.displayName, NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(metric.color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.linear)

                // 영역 채우기 (라인 아래 부분)
                AreaMark(
                    x: .value("날짜", point.date),
                    y: .value(metric.displayName, NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [metric.color.opacity(0.3), metric.color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.linear)
            }

            // 4. 예상 궤적 라인 (현재 → 목표)
            // 📚 학습 포인트: Projected Trajectory Line (Dashed)
            ForEach(projectedPoints) { point in
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value(metric.displayName, NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(metric.color.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])) // 점선
                .interpolationMethod(.linear)
            }

            // 5. 데이터 포인트 마커
            // 📚 학습 포인트: Point Markers
            ForEach(dataPoints) { point in
                PointMark(
                    x: .value("날짜", point.date),
                    y: .value(metric.displayName, NSDecimalNumber(decimal: point.value).doubleValue)
                )
                .foregroundStyle(metric.color)
                .symbolSize(point == startPoint ? 100 : 60) // 시작점은 크게
                .symbol {
                    if point == startPoint {
                        // 시작 지점 특별 표시
                        Circle()
                            .fill(metric.color)
                            .strokeBorder(.white, lineWidth: 2)
                            .overlay {
                                Image(systemName: "flag.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            }
                    } else {
                        Circle()
                            .fill(metric.color)
                    }
                }
                .annotation(position: .top, alignment: .center) {
                    Text(point.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 6. 선택된 데이터 포인트 강조
            // 📚 학습 포인트: Selection Indicator
            if let selected = selectedDataPoint {
                RuleMark(
                    x: .value("날짜", selected.date)
                )
                .foregroundStyle(.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("날짜", selected.date),
                    y: .value(metric.displayName, NSDecimalNumber(decimal: selected.value).doubleValue)
                )
                .foregroundStyle(.white)
                .symbolSize(120)
                .symbol {
                    Circle()
                        .fill(metric.color)
                        .strokeBorder(.white, lineWidth: 3)
                        .shadow(color: metric.color.opacity(0.3), radius: 4)
                }
            }
        }
        .chartXAxis {
            // 📚 학습 포인트: Custom X Axis
            // 날짜 레이블 표시
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            // 📚 학습 포인트: Custom Y Axis
            // 값 레이블 표시 (단위 포함)
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(formatAxisValue(doubleValue))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisMinimum...yAxisMaximum)
        .chartXSelection(value: $selectedDate)
        .frame(height: height)
        .padding(.vertical, 8)
        .disabled(!isInteractive) // 인터랙션 비활성화 시 탭 불가
    }

    /// 범례
    /// 📚 학습 포인트: Legend Component
    /// - 차트 요소 설명
    private var chartLegend: some View {
        HStack(spacing: 20) {
            // 실제 진행
            HStack(spacing: 6) {
                Circle()
                    .fill(metric.color)
                    .frame(width: 10, height: 10)

                Text("실제 진행")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 예상 궤적
            HStack(spacing: 6) {
                Rectangle()
                    .fill(metric.color.opacity(0.5))
                    .frame(width: 20, height: 2)

                Text("예상 궤적")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 목표
            HStack(spacing: 6) {
                Rectangle()
                    .fill(metric.color.opacity(0.5))
                    .frame(width: 20, height: 2)

                Text("목표")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 선택된 데이터 포인트 상세 정보
    /// 📚 학습 포인트: Selection Detail
    /// - 선택한 포인트의 정보를 카드로 표시
    ///
    /// - Parameter dataPoint: 선택된 데이터 포인트
    /// - Returns: 상세 정보 뷰
    private func selectedDataPointDetail(_ dataPoint: ChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(metric.color)

                Text(formatDate(dataPoint.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Spacer()

                // 선택 해제 버튼
                Button(action: {
                    selectedDate = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Divider()

            // 측정 값
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: metric.icon)
                            .font(.caption2)
                            .foregroundStyle(metric.color)

                        Text(dataPoint.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(formatValue(dataPoint.value))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeInOut(duration: 0.2), value: selectedDate)
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))

            VStack(spacing: 8) {
                Text("목표 데이터가 없습니다")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("목표를 설정하면\n진행 상황을 확인할 수 있습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    /// 마일스톤 값 계산
    /// 📚 학습 포인트: Milestone Value Calculation
    /// - 시작값과 목표값 사이의 특정 백분율 지점 값 계산
    ///
    /// - Parameters:
    ///   - start: 시작값
    ///   - goal: 목표값
    ///   - percentage: 백분율 (0-100)
    /// - Returns: 마일스톤 값
    private func calculateMilestoneValue(start: Decimal, goal: Decimal, percentage: Decimal) -> Decimal {
        let range = goal - start
        let offset = range * (percentage / 100)
        return start + offset
    }

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    /// - "2024년 1월 15일 (월)" 형식
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 값 포맷팅
    /// 📚 학습 포인트: Value Formatting with Unit
    /// - 지표에 따라 적절한 단위 추가
    ///
    /// - Parameter value: 값
    /// - Returns: 포맷된 문자열 (예: "70.5 kg", "18.5%")
    private func formatValue(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: value)
        let formattedNumber = formatter.string(from: number) ?? "\(value)"
        return formattedNumber + " " + metric.unit
    }

    /// 축 값 포맷팅
    /// 📚 학습 포인트: Axis Label Formatting
    /// - Y축 레이블용 간단한 포맷
    ///
    /// - Parameter value: 값
    /// - Returns: 포맷된 문자열
    private func formatAxisValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0

        return (formatter.string(from: NSNumber(value: value)) ?? "\(value)")
    }
}

// MARK: - Preview

#Preview("체중 목표 - 진행 중") {
    ScrollView {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let goal = Calendar.current.date(byAdding: .day, value: 60, to: now)!

        let dataPoints = [
            ChartDataPoint(date: start, value: Decimal(70.0), label: "시작"),
            ChartDataPoint(date: now, value: Decimal(67.0), label: "현재"),
            ChartDataPoint(date: goal, value: Decimal(65.0), label: "목표")
        ]

        GoalProgressChart(
            dataPoints: dataPoints,
            metric: .weight,
            achievedMilestones: [.quarter, .half]
        )
        .padding()
    }
}

#Preview("체지방률 목표 - 초반") {
    ScrollView {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let goal = Calendar.current.date(byAdding: .day, value: 80, to: now)!

        let dataPoints = [
            ChartDataPoint(date: start, value: Decimal(22.0), label: "시작"),
            ChartDataPoint(date: now, value: Decimal(21.0), label: "현재"),
            ChartDataPoint(date: goal, value: Decimal(15.0), label: "목표")
        ]

        GoalProgressChart(
            dataPoints: dataPoints,
            metric: .bodyFat,
            achievedMilestones: []
        )
        .padding()
    }
}

#Preview("근육량 목표 - 거의 완료") {
    ScrollView {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -80, to: now)!
        let goal = Calendar.current.date(byAdding: .day, value: 10, to: now)!

        let dataPoints = [
            ChartDataPoint(date: start, value: Decimal(30.0), label: "시작"),
            ChartDataPoint(date: now, value: Decimal(34.5), label: "현재"),
            ChartDataPoint(date: goal, value: Decimal(35.0), label: "목표")
        ]

        GoalProgressChart(
            dataPoints: dataPoints,
            metric: .muscle,
            achievedMilestones: [.quarter, .half, .threeQuarters]
        )
        .padding()
    }
}

#Preview("인터랙션 비활성화") {
    ScrollView {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let goal = Calendar.current.date(byAdding: .day, value: 60, to: now)!

        let dataPoints = [
            ChartDataPoint(date: start, value: Decimal(70.0), label: "시작"),
            ChartDataPoint(date: now, value: Decimal(67.0), label: "현재"),
            ChartDataPoint(date: goal, value: Decimal(65.0), label: "목표")
        ]

        GoalProgressChart(
            dataPoints: dataPoints,
            metric: .weight,
            achievedMilestones: [.quarter],
            isInteractive: false,
            height: 200
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        GoalProgressChart(
            dataPoints: [],
            metric: .weight
        )
        .padding()
    }
}

#Preview("다크 모드") {
    ScrollView {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let goal = Calendar.current.date(byAdding: .day, value: 60, to: now)!

        let dataPoints = [
            ChartDataPoint(date: start, value: Decimal(70.0), label: "시작"),
            ChartDataPoint(date: now, value: Decimal(67.0), label: "현재"),
            ChartDataPoint(date: goal, value: Decimal(65.0), label: "목표")
        ]

        GoalProgressChart(
            dataPoints: dataPoints,
            metric: .weight,
            achievedMilestones: [.quarter, .half]
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: GoalProgressChart 사용법
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct GoalProgressView: View {
///     @StateObject private var viewModel: GoalProgressViewModel
///
///     var body: some View {
///         if let chartData = viewModel.getWeightChartData() {
///             GoalProgressChart(
///                 dataPoints: chartData,
///                 metric: .weight,
///                 achievedMilestones: viewModel.achievedMilestones
///             )
///         }
///     }
/// }
/// ```
///
/// 데이터 직접 전달:
/// ```swift
/// struct MyView: View {
///     let dataPoints: [ChartDataPoint]
///
///     var body: some View {
///         GoalProgressChart(
///             dataPoints: dataPoints,
///             metric: .bodyFat,
///             achievedMilestones: [.quarter, .half],
///             isInteractive: true,
///             height: 300
///         )
///     }
/// }
/// ```
///
/// 대시보드 크기 (작게):
/// ```swift
/// GoalProgressChart(
///     dataPoints: dataPoints,
///     metric: .muscle,
///     isInteractive: false,
///     height: 180
/// )
/// ```
///
/// 주요 기능:
/// - Swift Charts 기반 목표 진행 그래프
/// - 실제 진행 라인 (시작 → 현재, 실선)
/// - 예상 궤적 라인 (현재 → 목표, 점선)
/// - 목표 수평선 (점선)
/// - 마일스톤 수평선 (25%, 50%, 75%, 100%)
/// - 시작 지점 특별 표시 (플래그 아이콘)
/// - 달성한 마일스톤 체크 표시
/// - 인터랙티브 선택 (탭하여 상세 정보 표시)
/// - 빈 상태 처리
/// - 라이트/다크 모드 자동 대응
/// - 커스터마이즈 가능한 높이
///
/// 차트 구성 요소:
/// - LineMark: 실제 진행 및 예상 궤적
/// - AreaMark: 실제 진행 영역 채우기
/// - PointMark: 데이터 포인트 마커
/// - RuleMark: 목표선 및 마일스톤 선
///
/// 지표 타입:
/// - weight: 체중 (kg, 파랑)
/// - bodyFat: 체지방률 (%, 주황)
/// - muscle: 근육량 (kg, 초록)
///
/// 인터랙션 기능:
/// - 데이터 포인트 탭하여 선택
/// - 선택한 포인트의 상세 정보 표시 (날짜, 값)
/// - 선택 해제 버튼
///
/// 💡 Android 비교:
/// - Android: MPAndroidChart LineChart + custom markers
/// - SwiftUI: Swift Charts LineMark + PointMark
/// - Android: LineDataSet + dashed lines
/// - SwiftUI: lineStyle with dash patterns (선언적)
/// - Android: setOnChartValueSelectedListener
/// - SwiftUI: @State + chartXSelection
///
/// 성능 최적화:
/// - 3개의 데이터 포인트만 사용 (시작, 현재, 목표)
/// - 인터랙션 비활성화 시 더 가볍게 렌더링
/// - 날짜순 정렬된 데이터 사용
///
