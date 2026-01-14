//
//  SleepBarChart.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Swift Charts Bar Chart with Status-Based Coloring
// Swift Charts 프레임워크를 사용한 수면 시간 바 차트 + 상태별 색상 구분
// 💡 Java 비교: Android의 MPAndroidChart, iOS Charts와 유사하지만 상태별 색상 구분 기능 포함

import SwiftUI
import Charts

// MARK: - SleepBarChart

/// 수면 시간을 표시하는 바 차트 컴포넌트
/// 📚 학습 포인트: Swift Charts Integration with Status Colors
/// - Swift Charts를 사용한 바 그래프
/// - 수면 상태별 색상 표시 (bad, soso, good, excellent, oversleep)
/// - 평균선 표시 지원
/// - 인터랙티브 선택 기능
/// - 빈 상태 처리
/// 💡 Java 비교: MPAndroidChart BarChart + Custom Colors와 유사하지만 더 선언적
struct SleepBarChart: View {

    // MARK: - Properties

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Data Input
    /// - FetchSleepStatsUseCase.SleepDataPoint 배열
    /// - 날짜 오름차순 정렬되어 있음
    let dataPoints: [FetchSleepStatsUseCase.SleepDataPoint]

    /// 평균 수면 시간 (분)
    /// 📚 학습 포인트: Optional Average Line
    /// - nil이면 평균선 표시 안 함
    /// - 값이 있으면 점선으로 표시
    let averageDuration: Int32?

    /// 선택된 통계 기간
    /// 📚 학습 포인트: Period Context
    /// - 차트 제목 및 X축 레이블 결정
    let period: FetchSleepStatsUseCase.StatsPeriod

    /// 인터랙션 활성화 여부
    /// 📚 학습 포인트: Interactive Feature Toggle
    /// - true: 탭하여 상세 정보 표시
    /// - false: 정적 차트
    let isInteractive: Bool

    /// 차트 높이
    /// 📚 학습 포인트: Customizable Height
    /// - 대시보드에서는 작게, 상세 화면에서는 크게
    let height: CGFloat

    /// 상태 범례 표시 여부
    /// 📚 학습 포인트: Optional Legend
    /// - true: 차트 하단에 상태별 색상 범례 표시
    /// - false: 범례 숨김
    let showStatusLegend: Bool

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
    private var selectedDataPoint: FetchSleepStatsUseCase.SleepDataPoint? {
        guard let date = selectedDate else { return nil }
        // 날짜가 가장 가까운 데이터 포인트 찾기
        return dataPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    private var isEmpty: Bool {
        dataPoints.isEmpty
    }

    /// Y축 최소값 (시간 단위)
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 최소 수면 시간보다 약간 작은 값 (여백)
    /// - 0시간 이하로는 내려가지 않음
    private var yAxisMinimum: Double {
        guard !isEmpty else { return 0 }
        let minDuration = dataPoints.map { $0.duration }.min() ?? 0
        // 분을 시간으로 변환하고 1시간 단위로 내림
        let minHours = Double(minDuration) / 60.0
        return max(0, floor(minHours / 1.0) * 1.0)
    }

    /// Y축 최대값 (시간 단위)
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 최대 수면 시간보다 약간 큰 값 (여백)
    /// - 평균 수면 시간도 고려
    private var yAxisMaximum: Double {
        guard !isEmpty else { return 10 }
        let maxDuration = dataPoints.map { $0.duration }.max() ?? 480
        let avgDuration = averageDuration ?? maxDuration
        let maximum = max(maxDuration, avgDuration)
        // 분을 시간으로 변환하고 1시간 단위로 올림
        let maxHours = Double(maximum) / 60.0
        return ceil(maxHours / 1.0) * 1.0
    }

    /// 수면 시간 변화량 (첫 기록 대비 마지막 기록)
    /// 📚 학습 포인트: Trend Calculation
    /// - 양수: 수면 시간 증가
    /// - 음수: 수면 시간 감소
    private var durationChange: Int32? {
        guard let first = dataPoints.first?.duration,
              let last = dataPoints.last?.duration else {
            return nil
        }
        return last - first
    }

    // MARK: - Initialization

    /// SleepBarChart 초기화
    /// 📚 학습 포인트: Flexible Initializer
    /// - 기본값을 제공하여 편리하게 사용
    ///
    /// - Parameters:
    ///   - dataPoints: 차트 데이터 포인트
    ///   - averageDuration: 평균 수면 시간 (기본값: nil)
    ///   - period: 선택된 기간 (기본값: .week)
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    ///   - showStatusLegend: 상태 범례 표시 여부 (기본값: true)
    init(
        dataPoints: [FetchSleepStatsUseCase.SleepDataPoint],
        averageDuration: Int32? = nil,
        period: FetchSleepStatsUseCase.StatsPeriod = .week,
        isInteractive: Bool = true,
        height: CGFloat = 300,
        showStatusLegend: Bool = true
    ) {
        self.dataPoints = dataPoints
        self.averageDuration = averageDuration
        self.period = period
        self.isInteractive = isInteractive
        self.height = height
        self.showStatusLegend = showStatusLegend
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
                if showStatusLegend {
                    chartLegend
                }

                // 선택된 데이터 포인트 상세 정보
                if let selected = selectedDataPoint {
                    selectedDataPointDetail(selected)
                }
            }
        }
    }

    // MARK: - Subviews

    /// 차트 헤더
    /// 📚 학습 포인트: Header with Statistics
    /// - 제목, 기간, 변화량 표시
    private var chartHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)

                    Text("수면 시간 트렌드")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                // 기간
                Text(period.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 변화량 표시
            if let change = durationChange {
                durationChangeBadge(change)
            }
        }
    }

    /// 수면 시간 변화량 뱃지
    /// 📚 학습 포인트: Visual Indicator
    /// - 증가는 초록 (긍정적), 감소는 주황 (부정적)
    ///
    /// - Parameter change: 수면 시간 변화량 (분)
    /// - Returns: 뱃지 뷰
    private func durationChangeBadge(_ change: Int32) -> some View {
        let isIncrease = change > 0
        let color: Color = isIncrease ? .green : .orange
        let icon = isIncrease ? "arrow.up.right" : "arrow.down.right"

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(formatDurationChange(change))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }

    /// 차트 뷰
    /// 📚 학습 포인트: Swift Charts Implementation with Bar Marks
    /// - Chart { } 블록 내에 Mark 정의
    /// - BarMark: 바 그래프
    /// - RuleMark: 평균선 표시
    private var chartView: some View {
        Chart {
            // 📚 학습 포인트: ForEach in Chart
            // 각 데이터 포인트를 BarMark로 변환
            ForEach(dataPoints) { dataPoint in
                // 바 그래프
                BarMark(
                    x: .value("날짜", dataPoint.date, unit: .day),
                    y: .value("수면 시간", Double(dataPoint.duration) / 60.0) // 분을 시간으로 변환
                )
                .foregroundStyle(dataPoint.status.color)
                .cornerRadius(4)
            }

            // 평균선 표시
            // 📚 학습 포인트: RuleMark for Average Line
            if let avg = averageDuration {
                RuleMark(
                    y: .value("평균", Double(avg) / 60.0) // 분을 시간으로 변환
                )
                .foregroundStyle(.gray)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5])) // 점선
                .annotation(position: .top, alignment: .trailing) {
                    Text("평균: \(formatDuration(avg))")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // 선택된 데이터 포인트 강조
            // 📚 학습 포인트: Selection Indicator
            if let selected = selectedDataPoint {
                RuleMark(
                    x: .value("날짜", selected.date)
                )
                .foregroundStyle(.gray.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [3, 3]))

                // 선택된 바 강조
                BarMark(
                    x: .value("날짜", selected.date, unit: .day),
                    y: .value("수면 시간", Double(selected.duration) / 60.0)
                )
                .foregroundStyle(selected.status.color.opacity(0.3))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(selected.status.color, lineWidth: 3)
                )
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
            // 수면 시간 레이블 표시 (시간 단위)
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))h")
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
    /// 📚 학습 포인트: Legend Component with Status Colors
    /// - 차트 요소 설명
    /// - 수면 상태별 색상 표시
    private var chartLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 20) {
                // 평균선
                if averageDuration != nil {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(.gray)
                            .frame(width: 20, height: 2)

                        Text("평균")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // 수면 상태 범례
            Divider()
                .padding(.vertical, 4)

            Text("수면 상태")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(SleepStatus.allCases) { status in
                    statusLegendItem(status)
                }
            }
        }
    }

    /// 수면 상태 범례 아이템
    /// 📚 학습 포인트: Reusable Legend Item
    ///
    /// - Parameter status: 수면 상태
    /// - Returns: 범례 아이템 뷰
    private func statusLegendItem(_ status: SleepStatus) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(status.color)
                .frame(width: 12, height: 12)

            Text(status.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 선택된 데이터 포인트 상세 정보
    /// 📚 학습 포인트: Selection Detail
    /// - 선택한 포인트의 정보를 카드로 표시
    ///
    /// - Parameter dataPoint: 선택된 데이터 포인트
    /// - Returns: 상세 정보 뷰
    private func selectedDataPointDetail(_ dataPoint: FetchSleepStatsUseCase.SleepDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 날짜
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.purple)

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
                // 수면 시간
                measurementItem(
                    icon: "moon.fill",
                    label: "수면 시간",
                    value: formatDuration(dataPoint.duration),
                    color: .purple
                )

                // 수면 상태
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: dataPoint.status.iconName)
                            .font(.caption2)
                            .foregroundStyle(dataPoint.status.color)

                        Text("수면 상태")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Text(dataPoint.status.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Circle()
                            .fill(dataPoint.status.color)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // 평균과의 비교
            if let avg = averageDuration {
                Divider()

                let diff = dataPoint.duration - avg
                let isAboveAverage = diff >= 0

                HStack(spacing: 6) {
                    Image(systemName: isAboveAverage ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(isAboveAverage ? .green : .orange)

                    Text("평균보다 \(formatDurationChange(diff)) \(isAboveAverage ? "많음" : "적음")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    /// 측정 값 아이템
    /// 📚 학습 포인트: Reusable Component Function
    /// - 반복되는 측정값 표시 패턴을 재사용
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘 이름
    ///   - label: 레이블 텍스트
    ///   - value: 측정 값
    ///   - color: 강조 색상
    /// - Returns: 측정 값 표시 뷰
    private func measurementItem(
        icon: String,
        label: String,
        value: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))

            VStack(spacing: 8) {
                Text("수면 데이터가 없습니다")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("수면 기록을 입력하면\n수면 시간 트렌드를 확인할 수 있습니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    /// - "2026년 1월 14일 (화)" 형식
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 수면 시간 포맷팅
    /// 📚 학습 포인트: Duration Formatting
    /// - 분 단위를 시간:분 형식으로 변환
    ///
    /// - Parameter minutes: 수면 시간 (분)
    /// - Returns: 포맷된 문자열 (예: "7시간 30분")
    private func formatDuration(_ minutes: Int32) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if mins == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(mins)분"
        }
    }

    /// 수면 시간 변화량 포맷팅
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량 (분)
    /// - Returns: 포맷된 문자열 (예: "+30분", "-1시간")
    private func formatDurationChange(_ change: Int32) -> String {
        let hours = abs(change) / 60
        let mins = abs(change) % 60
        let sign = change >= 0 ? "+" : "-"

        if hours == 0 {
            return "\(sign)\(mins)분"
        } else if mins == 0 {
            return "\(sign)\(hours)시간"
        } else {
            return "\(sign)\(hours)시간 \(mins)분"
        }
    }
}

// MARK: - Convenience Initializers

extension SleepBarChart {
    /// 📚 학습 포인트: Convenience Initializer with ViewModel
    /// - SleepTrendsViewModel에서 직접 값을 가져오는 편의 생성자
    /// - View에서 쉽게 사용 가능
    ///
    /// - Parameters:
    ///   - viewModel: SleepTrendsViewModel 인스턴스
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    ///   - showStatusLegend: 상태 범례 표시 여부 (기본값: true)
    init(
        viewModel: SleepTrendsViewModel,
        isInteractive: Bool = true,
        height: CGFloat = 300,
        showStatusLegend: Bool = true
    ) {
        self.dataPoints = viewModel.dataPoints
        self.averageDuration = viewModel.averageDurationMinutes
        self.period = viewModel.selectedPeriod
        self.isInteractive = isInteractive
        self.height = height
        self.showStatusLegend = showStatusLegend
    }
}

// MARK: - Preview

#Preview("7일 데이터") {
    ScrollView {
        SleepBarChart(
            dataPoints: FetchSleepStatsUseCase.sampleOutput().dataPoints,
            averageDuration: FetchSleepStatsUseCase.sampleOutput().averageDuration,
            period: .week
        )
        .padding()
    }
}

#Preview("7일 데이터 + 평균선") {
    ScrollView {
        SleepBarChart(
            dataPoints: FetchSleepStatsUseCase.sampleOutput().dataPoints,
            averageDuration: 420, // 7시간
            period: .week
        )
        .padding()
    }
}

#Preview("범례 숨김") {
    ScrollView {
        SleepBarChart(
            dataPoints: FetchSleepStatsUseCase.sampleOutput().dataPoints,
            averageDuration: FetchSleepStatsUseCase.sampleOutput().averageDuration,
            period: .week,
            showStatusLegend: false
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        SleepBarChart(
            dataPoints: [],
            period: .week
        )
        .padding()
    }
}

#Preview("인터랙션 비활성화") {
    ScrollView {
        SleepBarChart(
            dataPoints: FetchSleepStatsUseCase.sampleOutput().dataPoints,
            period: .week,
            isInteractive: false,
            height: 200,
            showStatusLegend: false
        )
        .padding()
    }
}

#Preview("다크 모드") {
    ScrollView {
        SleepBarChart(
            dataPoints: FetchSleepStatsUseCase.sampleOutput().dataPoints,
            averageDuration: 420,
            period: .month
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("대시보드 크기 (작게)") {
    ScrollView {
        VStack(spacing: 16) {
            Text("대시보드 카드 크기 예시")
                .font(.headline)

            SleepBarChart(
                dataPoints: FetchSleepStatsUseCase.sampleOutput().dataPoints,
                period: .week,
                isInteractive: false,
                height: 180,
                showStatusLegend: false
            )
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8)
            )
        }
        .padding()
    }
}

#Preview("30일 데이터 - 다양한 상태") {
    ScrollView {
        let now = Date()
        let dataPoints = stride(from: -29, through: 0, by: 3).map { dayOffset in
            // 다양한 수면 시간과 상태 표시
            let progress = Double(dayOffset + 29) / 29.0
            let duration = Int32(300 + progress * 180) // 5시간 → 8시간으로 점진적 증가

            return FetchSleepStatsUseCase.SleepDataPoint(
                id: UUID(),
                date: Calendar.current.date(byAdding: .day, value: dayOffset, to: now)!,
                duration: duration,
                status: SleepStatus.from(durationMinutes: duration)
            )
        }

        SleepBarChart(
            dataPoints: dataPoints,
            averageDuration: 420, // 7시간
            period: .month
        )
        .padding()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepBarChart 사용법
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct SleepTrendsView: View {
///     @StateObject private var viewModel: SleepTrendsViewModel
///
///     var body: some View {
///         SleepBarChart(
///             viewModel: viewModel,
///             height: 300,
///             showStatusLegend: true
///         )
///     }
/// }
/// ```
///
/// 데이터 직접 전달:
/// ```swift
/// struct MyView: View {
///     let dataPoints: [FetchSleepStatsUseCase.SleepDataPoint]
///
///     var body: some View {
///         SleepBarChart(
///             dataPoints: dataPoints,
///             averageDuration: 420,
///             period: .month,
///             isInteractive: true,
///             height: 300,
///             showStatusLegend: true
///         )
///     }
/// }
/// ```
///
/// 대시보드 크기 (범례 숨김):
/// ```swift
/// SleepBarChart(
///     dataPoints: dataPoints,
///     period: .week,
///     isInteractive: false,
///     height: 180,
///     showStatusLegend: false
/// )
/// ```
///
/// 주요 기능:
/// - Swift Charts 기반 바 차트
/// - 수면 상태별 색상 구분 (bad=빨강, soso=노랑, good=초록, excellent=파랑, oversleep=주황)
/// - 평균선 표시 (점선)
/// - 인터랙티브 선택 (탭하여 상세 정보 표시)
/// - 수면 시간 변화량 뱃지
/// - 상태별 범례 표시 (선택적)
/// - 빈 상태 처리
/// - 라이트/다크 모드 자동 대응
/// - 커스터마이즈 가능한 높이
///
/// 차트 구성 요소:
/// - BarMark: 일별 수면 시간 바 (상태별 색상)
/// - RuleMark: 평균선 및 선택 인디케이터
///
/// 수면 상태와 색상:
/// - bad (나쁨): 빨강 - 5시간 30분 미만
/// - soso (보통): 노랑 - 5시간 30분 ~ 6시간 30분
/// - good (좋음): 초록 - 6시간 30분 ~ 7시간 30분
/// - excellent (매우 좋음): 파랑 - 7시간 30분 ~ 9시간
/// - oversleep (과다 수면): 주황 - 9시간 초과
///
/// 인터랙션 기능:
/// - 바 탭하여 선택
/// - 선택한 날짜의 상세 정보 표시 (수면 시간, 상태, 평균과의 비교)
/// - 선택 해제 버튼
///
/// 💡 Android 비교:
/// - Android: MPAndroidChart BarChart + Custom Colors
/// - SwiftUI: Swift Charts BarMark + status.color
/// - Android: BarDataSet + custom colors
/// - SwiftUI: ForEach + BarMark (선언적)
/// - Android: setOnChartValueSelectedListener
/// - SwiftUI: @State + chartXSelection
///
/// 성능 최적화:
/// - 최대 90일 데이터 권장 (StatsPeriod.quarter)
/// - 범례 표시는 선택적 (showStatusLegend)
/// - 인터랙션 비활성화 시 더 가볍게 렌더링
/// - 날짜순 정렬된 데이터 사용 (Use Case에서 처리)
///
/// WeightTrendChart와의 차이:
/// - WeightTrendChart: LineMark (라인 차트)
/// - SleepBarChart: BarMark (바 차트)
/// - WeightTrendChart: 단일 색상 (파랑)
/// - SleepBarChart: 상태별 색상 (5가지)
/// - WeightTrendChart: 체중 데이터 (연속적)
/// - SleepBarChart: 수면 데이터 (일별 독립적)
///
