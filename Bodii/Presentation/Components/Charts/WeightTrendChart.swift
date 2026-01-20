//
//  WeightTrendChart.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Swift Charts Line Chart Component
// Swift Charts 프레임워크를 사용한 체중 트렌드 라인 차트
// 💡 Java 비교: Android의 MPAndroidChart, iOS Charts와 유사

import SwiftUI
import Charts

// MARK: - WeightTrendChart

/// 체중 트렌드를 표시하는 라인 차트 컴포넌트
/// 📚 학습 포인트: Swift Charts Integration
/// - Swift Charts를 사용한 라인 그래프
/// - 목표선 표시 지원
/// - 인터랙티브 선택 기능
/// - 빈 상태 처리
/// 💡 Java 비교: MPAndroidChart LineChart와 유사하지만 더 선언적
struct WeightTrendChart: View {

    // MARK: - Properties

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Data Input
    /// - FetchBodyTrendsUseCase.TrendDataPoint 배열
    /// - 날짜 오름차순 정렬되어 있음
    let dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint]

    /// 목표 체중 (kg)
    /// 📚 학습 포인트: Optional Goal Line
    /// - nil이면 목표선 표시 안 함
    /// - 값이 있으면 점선으로 표시
    let goalWeight: Decimal?

    /// 선택된 트렌드 기간
    /// 📚 학습 포인트: Period Context
    /// - 차트 제목 및 X축 레이블 결정
    let period: FetchBodyTrendsUseCase.TrendPeriod

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
    private var selectedDataPoint: FetchBodyTrendsUseCase.TrendDataPoint? {
        guard let date = selectedDate else { return nil }
        // 날짜가 가장 가까운 데이터 포인트 찾기
        return dataPoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    private var isEmpty: Bool {
        dataPoints.isEmpty
    }

    /// Y축 최소값
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 최소 체중보다 약간 작은 값 (여백)
    /// - 목표 체중도 고려
    private var yAxisMinimum: Double {
        let minWeight = dataPoints.map { $0.weight }.min() ?? Decimal(50)
        let goalWeightValue = goalWeight ?? minWeight
        let minimum = min(minWeight, goalWeightValue)

        // 5kg 단위로 내림
        let minDouble = NSDecimalNumber(decimal: minimum).doubleValue
        return floor(minDouble / 5.0) * 5.0
    }

    /// Y축 최대값
    /// 📚 학습 포인트: Chart Scale Calculation
    /// - 최대 체중보다 약간 큰 값 (여백)
    /// - 목표 체중도 고려
    private var yAxisMaximum: Double {
        let maxWeight = dataPoints.map { $0.weight }.max() ?? Decimal(100)
        let goalWeightValue = goalWeight ?? maxWeight
        let maximum = max(maxWeight, goalWeightValue)

        // 5kg 단위로 올림
        let maxDouble = NSDecimalNumber(decimal: maximum).doubleValue
        return ceil(maxDouble / 5.0) * 5.0
    }

    /// 체중 변화량 (첫 기록 대비 마지막 기록)
    /// 📚 학습 포인트: Trend Calculation
    /// - 양수: 체중 증가
    /// - 음수: 체중 감소
    private var weightChange: Decimal? {
        guard let first = dataPoints.first?.weight,
              let last = dataPoints.last?.weight else {
            return nil
        }
        return last - first
    }

    // MARK: - Initialization

    /// WeightTrendChart 초기화
    /// 📚 학습 포인트: Flexible Initializer
    /// - 기본값을 제공하여 편리하게 사용
    ///
    /// - Parameters:
    ///   - dataPoints: 차트 데이터 포인트
    ///   - goalWeight: 목표 체중 (기본값: nil)
    ///   - period: 선택된 기간 (기본값: .week)
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    init(
        dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint],
        goalWeight: Decimal? = nil,
        period: FetchBodyTrendsUseCase.TrendPeriod = .week,
        isInteractive: Bool = true,
        height: CGFloat = 300
    ) {
        self.dataPoints = dataPoints
        self.goalWeight = goalWeight
        self.period = period
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
    /// 📚 학습 포인트: Header with Statistics
    /// - 제목, 기간, 변화량 표시
    private var chartHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // 제목
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    Text("체중 트렌드")
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
            if let change = weightChange {
                weightChangeBadge(change)
            }
        }
    }

    /// 체중 변화량 뱃지
    /// 📚 학습 포인트: Visual Indicator
    /// - 증가는 빨강, 감소는 파랑
    ///
    /// - Parameter change: 체중 변화량
    /// - Returns: 뱃지 뷰
    private func weightChangeBadge(_ change: Decimal) -> some View {
        let isIncrease = change > 0
        let color: Color = isIncrease ? .orange : .blue
        let icon = isIncrease ? "arrow.up.right" : "arrow.down.right"

        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)

            Text(formatWeightChange(change))
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
    /// 📚 학습 포인트: Swift Charts Implementation
    /// - Chart { } 블록 내에 Mark 정의
    /// - LineMark: 라인 그래프
    /// - PointMark: 데이터 포인트 표시
    /// - RuleMark: 목표선 표시
    private var chartView: some View {
        Chart {
            // 📚 학습 포인트: ForEach in Chart
            // 각 데이터 포인트를 LineMark로 변환
            ForEach(dataPoints) { dataPoint in
                // 라인 그래프
                LineMark(
                    x: .value("날짜", dataPoint.date),
                    y: .value("체중", NSDecimalNumber(decimal: dataPoint.weight).doubleValue)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom) // 부드러운 곡선

                // 데이터 포인트 표시
                PointMark(
                    x: .value("날짜", dataPoint.date),
                    y: .value("체중", NSDecimalNumber(decimal: dataPoint.weight).doubleValue)
                )
                .foregroundStyle(.blue)
                .symbolSize(60)

                // 영역 채우기 (선 아래 부분)
                // 📚 학습 포인트: Area Chart
                // AreaMark를 추가하여 라인 아래를 그라데이션으로 채움
                AreaMark(
                    x: .value("날짜", dataPoint.date),
                    y: .value("체중", NSDecimalNumber(decimal: dataPoint.weight).doubleValue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // 목표선 표시
            // 📚 학습 포인트: RuleMark for Goal Line
            if let goal = goalWeight {
                RuleMark(
                    y: .value("목표", NSDecimalNumber(decimal: goal).doubleValue)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5])) // 점선
                .annotation(position: .top, alignment: .trailing) {
                    Text("목표: \(formatWeight(goal))")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
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
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                PointMark(
                    x: .value("날짜", selected.date),
                    y: .value("체중", NSDecimalNumber(decimal: selected.weight).doubleValue)
                )
                .foregroundStyle(.white)
                .symbolSize(120)
                .symbol {
                    Circle()
                        .fill(.blue)
                        .strokeBorder(.white, lineWidth: 3)
                        .shadow(color: .blue.opacity(0.3), radius: 4)
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
            // 체중 레이블 표시 (kg 단위)
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text("\(Int(doubleValue))")
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
            // 체중 라인
            HStack(spacing: 6) {
                Circle()
                    .fill(.blue)
                    .frame(width: 10, height: 10)

                Text("체중")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 목표선
            if goalWeight != nil {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(.green)
                        .frame(width: 20, height: 2)

                    Text("목표")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// 선택된 데이터 포인트 상세 정보
    /// 📚 학습 포인트: Selection Detail
    /// - 선택한 포인트의 정보를 카드로 표시
    ///
    /// - Parameter dataPoint: 선택된 데이터 포인트
    /// - Returns: 상세 정보 뷰
    private func selectedDataPointDetail(_ dataPoint: FetchBodyTrendsUseCase.TrendDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 날짜
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.blue)

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
                // 체중
                measurementItem(
                    icon: "scalemass",
                    label: "체중",
                    value: formatWeight(dataPoint.weight),
                    color: .blue
                )

                // 체지방률
                measurementItem(
                    icon: "percent",
                    label: "체지방률",
                    value: formatBodyFat(dataPoint.bodyFatPercent),
                    color: .orange
                )

                // 근육량 (있는 경우)
                if let muscleMass = dataPoint.muscleMass {
                    measurementItem(
                        icon: "figure.strengthtraining.traditional",
                        label: "근육량",
                        value: formatWeight(muscleMass),
                        color: .purple
                    )
                }
            }

            // 대사율 정보 (있는 경우)
            if let bmr = dataPoint.bmr, let tdee = dataPoint.tdee {
                Divider()

                HStack(spacing: 24) {
                    measurementItem(
                        icon: "flame",
                        label: "BMR",
                        value: formatCalories(bmr),
                        color: .red
                    )

                    measurementItem(
                        icon: "figure.walk",
                        label: "TDEE",
                        value: formatCalories(tdee),
                        color: .green
                    )
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
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.3))

            VStack(spacing: 8) {
                Text("체중 데이터가 없습니다")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("신체 구성 데이터를 입력하면\n체중 트렌드를 확인할 수 있습니다")
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

    /// 체중 포맷팅
    /// 📚 학습 포인트: Weight Formatting
    /// - 소수점 1자리 + "kg" 단위
    ///
    /// - Parameter weight: 체중
    /// - Returns: 포맷된 문자열 (예: "70.5 kg")
    private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: weight)
        return (formatter.string(from: number) ?? "\(weight)") + " kg"
    }

    /// 체중 변화량 포맷팅
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+1.5 kg", "-0.8 kg")
    private func formatWeightChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + " kg"
    }

    /// 체지방률 포맷팅
    /// 📚 학습 포인트: Percentage Formatting
    /// - 소수점 1자리 + "%" 기호
    ///
    /// - Parameter bodyFat: 체지방률
    /// - Returns: 포맷된 문자열 (예: "18.5%")
    private func formatBodyFat(_ bodyFat: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: bodyFat)
        return (formatter.string(from: number) ?? "\(bodyFat)") + "%"
    }

    /// 칼로리 포맷팅
    /// 📚 학습 포인트: Calorie Formatting
    /// - 정수 + "kcal" 단위
    ///
    /// - Parameter calories: 칼로리 값
    /// - Returns: 포맷된 문자열 (예: "1,650 kcal")
    private func formatCalories(_ calories: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        let number = NSDecimalNumber(decimal: calories)
        return (formatter.string(from: number) ?? "\(calories)") + " kcal"
    }
}

// MARK: - Convenience Initializers

extension WeightTrendChart {
    /// 📚 학습 포인트: Convenience Initializer with ViewModel
    /// - BodyTrendsViewModel에서 직접 값을 가져오는 편의 생성자
    /// - View에서 쉽게 사용 가능
    ///
    /// - Parameters:
    ///   - viewModel: BodyTrendsViewModel 인스턴스
    ///   - goalWeight: 목표 체중 (기본값: nil)
    ///   - isInteractive: 인터랙션 활성화 (기본값: true)
    ///   - height: 차트 높이 (기본값: 300)
    init(
        viewModel: BodyTrendsViewModel,
        goalWeight: Decimal? = nil,
        isInteractive: Bool = true,
        height: CGFloat = 300
    ) {
        self.dataPoints = viewModel.dataPoints
        self.goalWeight = goalWeight
        self.period = viewModel.selectedPeriod
        self.isInteractive = isInteractive
        self.height = height
    }
}

// MARK: - Preview

#Preview("7일 데이터") {
    ScrollView {
        WeightTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week
        )
        .padding()
    }
}

#Preview("7일 데이터 + 목표선") {
    ScrollView {
        WeightTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            goalWeight: Decimal(68.0),
            period: .week
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        WeightTrendChart(
            dataPoints: [],
            period: .week
        )
        .padding()
    }
}

#Preview("인터랙션 비활성화") {
    ScrollView {
        WeightTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            period: .week,
            isInteractive: false,
            height: 200
        )
        .padding()
    }
}

#Preview("다크 모드") {
    ScrollView {
        WeightTrendChart(
            dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
            goalWeight: Decimal(68.0),
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

            WeightTrendChart(
                dataPoints: FetchBodyTrendsUseCase.sampleOutput().dataPoints,
                period: .week,
                isInteractive: false,
                height: 180
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

// Preview는 복잡한 표현식으로 인해 임시 비활성화
// TODO: 표현식을 분리하여 Preview 구현 필요

#Preview("Weight Trend Chart") {
    Text("WeightTrendChart Preview")
        .font(.title)
        .foregroundColor(.secondary)
}

// MARK: - Documentation

/// 📚 학습 포인트: WeightTrendChart 사용법
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct BodyTrendsView: View {
///     @StateObject private var viewModel: BodyTrendsViewModel
///
///     var body: some View {
///         WeightTrendChart(
///             viewModel: viewModel,
///             goalWeight: Decimal(70.0)
///         )
///     }
/// }
/// ```
///
/// 데이터 직접 전달:
/// ```swift
/// struct MyView: View {
///     let dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint]
///
///     var body: some View {
///         WeightTrendChart(
///             dataPoints: dataPoints,
///             goalWeight: Decimal(68.0),
///             period: .month,
///             isInteractive: true,
///             height: 300
///         )
///     }
/// }
/// ```
///
/// 대시보드 크기 (작게):
/// ```swift
/// WeightTrendChart(
///     dataPoints: dataPoints,
///     period: .week,
///     isInteractive: false,
///     height: 180
/// )
/// ```
///
/// 주요 기능:
/// - Swift Charts 기반 라인 차트
/// - 부드러운 곡선 (Catmull-Rom interpolation)
/// - 그라데이션 영역 채우기
/// - 목표선 표시 (점선)
/// - 인터랙티브 선택 (탭하여 상세 정보 표시)
/// - 체중 변화량 뱃지
/// - 빈 상태 처리
/// - 라이트/다크 모드 자동 대응
/// - 커스터마이즈 가능한 높이
///
/// 차트 구성 요소:
/// - LineMark: 체중 트렌드 라인
/// - PointMark: 데이터 포인트 표시
/// - AreaMark: 라인 아래 영역 채우기
/// - RuleMark: 목표선 및 선택 인디케이터
///
/// 인터랙션 기능:
/// - 데이터 포인트 탭하여 선택
/// - 선택한 포인트의 상세 정보 표시 (체중, 체지방률, 근육량, BMR, TDEE)
/// - 선택 해제 버튼
///
/// 💡 Android 비교:
/// - Android: MPAndroidChart LineChart
/// - SwiftUI: Swift Charts LineMark
/// - Android: LineDataSet + LineData
/// - SwiftUI: ForEach + LineMark (선언적)
/// - Android: setOnChartValueSelectedListener
/// - SwiftUI: @State + chartXSelection
///
/// 성능 최적화:
/// - 최대 90일 데이터 권장 (TrendPeriod.quarter)
/// - 인터랙션 비활성화 시 더 가볍게 렌더링
/// - 날짜순 정렬된 데이터 사용 (Use Case에서 처리)
///
