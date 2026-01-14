//
//  SleepTrendsViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Chart-Focused ViewModel Pattern
// 수면 차트 데이터 관리와 기간 선택을 위한 ViewModel
// 💡 Java 비교: Android의 ViewModel과 유사하지만 차트 전용 상태 관리

import Foundation
import SwiftUI
import Combine

// MARK: - SleepTrendsViewModel

/// 수면 트렌드 차트를 위한 ViewModel
/// 📚 학습 포인트: Chart Data Management
/// - 차트 표시를 위한 수면 통계 데이터 관리
/// - 기간 선택 및 네비게이션 처리
/// - 빈 상태 및 로딩 상태 관리
/// 💡 Java 비교: Android ViewModel + Chart data transformation
@MainActor
class SleepTrendsViewModel: ObservableObject {

    // MARK: - Published Properties (View State)

    /// 선택된 통계 기간
    /// 📚 학습 포인트: User Selection State
    /// - 사용자가 선택한 기간 (7일/30일/90일)
    /// - 변경 시 자동으로 데이터 다시 로드
    /// 💡 Java 비교: LiveData<StatsPeriod>와 유사
    @Published var selectedPeriod: FetchSleepStatsUseCase.StatsPeriod = .week

    /// 통계 데이터 출력
    /// 📚 학습 포인트: Optional State
    /// - nil이면 아직 데이터 로드 안 됨
    /// - 값이 있으면 차트에 표시
    @Published var statsOutput: FetchSleepStatsUseCase.Output?

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 데이터 조회 중 로딩 인디케이터 표시
    @Published var isLoading: Bool = false

    /// 에러 메시지
    /// 📚 학습 포인트: Error State
    /// - nil이면 에러 없음
    /// - 값이 있으면 에러 메시지 표시
    @Published var errorMessage: String?

    /// 커스텀 날짜 범위 사용 여부
    /// 📚 학습 포인트: Advanced Feature Toggle
    /// - false: StatsPeriod 사용
    /// - true: customStartDate/customEndDate 사용
    @Published var useCustomDateRange: Bool = false

    /// 커스텀 시작 날짜
    /// 📚 학습 포인트: Custom Date Range
    /// - useCustomDateRange가 true일 때만 사용
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

    /// 커스텀 종료 날짜
    @Published var customEndDate: Date = Date()

    // MARK: - Private Properties

    /// 수면 통계 조회 Use Case
    /// 📚 학습 포인트: Dependency Injection
    /// - Use Case를 외부에서 주입받아 사용
    /// - 테스트 시 Mock으로 교체 가능
    private let fetchSleepStatsUseCase: FetchSleepStatsUseCase

    /// 수면 데이터 저장소
    /// 📚 학습 포인트: Protocol-Oriented Programming
    /// - 직접 조회가 필요한 경우를 위해 Repository도 보유
    private let sleepRepository: SleepRepositoryProtocol

    /// Combine 구독 저장소
    /// 📚 학습 포인트: Reactive Programming
    /// - selectedPeriod 변경 시 자동으로 데이터 다시 로드
    /// - 메모리 누수 방지를 위한 구독 관리
    /// 💡 Java 비교: RxJava의 CompositeDisposable과 유사
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// SleepTrendsViewModel 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - fetchSleepStatsUseCase: 수면 통계 조회 Use Case
    ///   - sleepRepository: 수면 데이터 저장소
    init(
        fetchSleepStatsUseCase: FetchSleepStatsUseCase,
        sleepRepository: SleepRepositoryProtocol
    ) {
        self.fetchSleepStatsUseCase = fetchSleepStatsUseCase
        self.sleepRepository = sleepRepository

        // 📚 학습 포인트: Reactive State Observation
        // selectedPeriod 변경 시 자동으로 데이터 다시 로드
        setupPeriodObserver()

        // 초기 데이터 로드
        Task {
            await loadStats()
        }
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    /// 📚 학습 포인트: Computed Property for Empty State
    /// - View에서 empty state UI 표시 여부 결정
    var isEmpty: Bool {
        statsOutput?.isEmpty ?? true
    }

    /// 데이터 포인트 개수
    /// 📚 학습 포인트: Quick Access Property
    /// - UI에서 바로 사용할 수 있는 편의 속성
    var dataPointCount: Int {
        statsOutput?.count ?? 0
    }

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Convenience Property
    /// - View에서 직접 접근 가능한 데이터 포인트 배열
    var dataPoints: [FetchSleepStatsUseCase.SleepDataPoint] {
        statsOutput?.dataPoints ?? []
    }

    /// 기간 표시 문자열
    /// 📚 학습 포인트: UI Helper Property
    /// - "2024.01.01 - 2024.01.07" 형식
    var periodDisplayString: String {
        guard let output = statsOutput else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")

        let startStr = formatter.string(from: output.startDate)
        let endStr = formatter.string(from: output.endDate)

        return "\(startStr) - \(endStr)"
    }

    /// 평균 수면 시간 문자열
    /// 📚 학습 포인트: UI Helper Property
    /// - 통계 표시를 위한 포맷팅된 문자열
    var averageDurationString: String {
        guard let avg = statsOutput?.averageDurationFormatted else {
            return "-"
        }
        if avg.minutes == 0 {
            return "\(avg.hours)시간"
        } else {
            return "\(avg.hours)시간 \(avg.minutes)분"
        }
    }

    /// 평균 수면 시간 (분)
    /// 📚 학습 포인트: Quick Access for Chart
    /// - 차트에 평균선 표시할 때 사용
    var averageDurationMinutes: Int32? {
        statsOutput?.averageDuration
    }

    /// 가장 많은 수면 상태 문자열
    /// 📚 학습 포인트: Statistics Display
    /// - 사용자의 주된 수면 패턴 표시
    var mostCommonStatusString: String {
        guard let status = statsOutput?.mostCommonStatus else {
            return "-"
        }
        return status.displayName
    }

    /// 좋은 수면 비율 문자열
    /// 📚 학습 포인트: Quality Metric Display
    /// - 수면 품질의 전반적인 평가 지표
    var goodSleepPercentageString: String {
        guard let output = statsOutput else { return "-" }
        let percentage = output.goodSleepPercentage * 100
        return String(format: "%.0f%%", percentage)
    }

    /// 수면 일관성 점수 문자열
    /// 📚 학습 포인트: Consistency Score Display
    /// - 수면 패턴의 규칙성 평가
    var consistencyScoreString: String {
        guard let score = statsOutput?.consistencyScore else {
            return "-"
        }
        let percentage = score * 100
        return String(format: "%.0f%%", percentage)
    }

    /// 상태별 통계
    /// 📚 학습 포인트: Detailed Statistics Access
    /// - UI에서 상태별 분포 차트 구성에 사용
    var statusStats: [FetchSleepStatsUseCase.StatusStats] {
        statsOutput?.statusStats ?? []
    }

    /// 추세 정보
    /// 📚 학습 포인트: Trend Analysis Access
    /// - 최근 vs 이전 기간 비교
    var trendInfo: (recent: Int32, previous: Int32, change: Int32)? {
        statsOutput?.recentTrend()
    }

    /// 추세 문자열
    /// 📚 학습 포인트: Trend Display Helper
    /// - "1시간 30분 증가" 또는 "30분 감소" 형식
    var trendString: String {
        guard let trend = trendInfo else { return "-" }

        let hours = abs(trend.change) / 60
        let minutes = abs(trend.change) % 60
        let direction = trend.change >= 0 ? "증가" : "감소"

        if hours == 0 {
            return "\(minutes)분 \(direction)"
        } else if minutes == 0 {
            return "\(hours)시간 \(direction)"
        } else {
            return "\(hours)시간 \(minutes)분 \(direction)"
        }
    }

    // MARK: - Public Methods

    /// 통계 데이터 로드
    /// 📚 학습 포인트: Async Data Loading
    /// - Use Case를 호출하여 데이터 조회
    /// - 로딩 상태 및 에러 처리
    /// 💡 Java 비교: Kotlin Coroutines의 suspend function과 유사
    func loadStats() async {
        isLoading = true
        errorMessage = nil

        do {
            // 📚 학습 포인트: Conditional Query Strategy
            // 커스텀 날짜 범위 사용 여부에 따라 다른 메서드 호출
            if useCustomDateRange {
                // 커스텀 날짜 범위로 조회
                let input = FetchSleepStatsUseCase.Input(
                    period: selectedPeriod,
                    endDate: customEndDate
                )
                statsOutput = try await fetchSleepStatsUseCase.execute(input: input)
            } else {
                // 표준 기간으로 조회
                statsOutput = try await fetchSleepStatsUseCase.execute(period: selectedPeriod)
            }

        } catch let error as FetchSleepStatsUseCase.StatsError {
            // 📚 학습 포인트: Specific Error Handling
            // Use Case의 도메인 에러를 사용자 친화적 메시지로 변환
            errorMessage = error.localizedDescription
            statsOutput = nil
        } catch {
            // 📚 학습 포인트: Generic Error Handling
            errorMessage = "통계 데이터 로드 실패: \(error.localizedDescription)"
            statsOutput = nil
        }

        isLoading = false
    }

    /// 기간 변경
    /// 📚 학습 포인트: State Update Method
    /// - 기간 변경 시 자동으로 데이터 다시 로드 (observer를 통해)
    ///
    /// - Parameter period: 새로운 기간
    func changePeriod(to period: FetchSleepStatsUseCase.StatsPeriod) {
        selectedPeriod = period
        useCustomDateRange = false
    }

    /// 이전 기간으로 이동
    /// 📚 학습 포인트: Date Range Navigation
    /// - 현재 기간만큼 과거로 이동
    /// - 예: 7일 기간이면 7일 전으로 이동
    func navigateToPreviousPeriod() async {
        // 📚 학습 포인트: Date Calculation
        // 현재 종료 날짜에서 기간만큼 이전으로 이동
        let days = selectedPeriod.days

        if useCustomDateRange {
            // 커스텀 날짜 범위 사용 중
            customEndDate = customStartDate
            customStartDate = Calendar.current.date(byAdding: .day, value: -days, to: customStartDate) ?? customStartDate
        } else {
            // 표준 기간 사용 중 → 커스텀 모드로 전환
            useCustomDateRange = true
            let now = Date()
            customEndDate = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            customStartDate = Calendar.current.date(byAdding: .day, value: -days*2, to: now) ?? now
        }

        await loadStats()
    }

    /// 다음 기간으로 이동
    /// 📚 학습 포인트: Date Range Navigation
    /// - 현재 기간만큼 미래로 이동 (최대 현재까지)
    func navigateToNextPeriod() async {
        let days = selectedPeriod.days

        if useCustomDateRange {
            // 커스텀 날짜 범위 사용 중
            let newEndDate = Calendar.current.date(byAdding: .day, value: days, to: customEndDate) ?? customEndDate

            // 📚 학습 포인트: Future Date Prevention
            // 미래 날짜는 현재 날짜로 제한
            let now = Date()
            if newEndDate > now {
                // 현재로 리셋
                useCustomDateRange = false
            } else {
                customStartDate = customEndDate
                customEndDate = newEndDate
            }
        }

        await loadStats()
    }

    /// 현재 날짜로 리셋
    /// 📚 학습 포인트: Reset to Default State
    /// - 커스텀 날짜 범위를 해제하고 현재 기준으로 조회
    func resetToCurrentPeriod() async {
        useCustomDateRange = false
        await loadStats()
    }

    /// 새로고침
    /// 📚 학습 포인트: Manual Refresh
    /// - Pull-to-refresh 등에서 사용
    func refresh() async {
        await loadStats()
    }

    // MARK: - Private Methods

    /// 기간 변경 감지 설정
    /// 📚 학습 포인트: Combine Publisher Observation
    /// - @Published 프로퍼티 변경을 감지하여 자동 동작 실행
    /// - debounce로 연속 변경 시 마지막만 처리
    /// 💡 Java 비교: RxJava의 Observable.debounce()와 유사
    private func setupPeriodObserver() {
        // selectedPeriod 변경 시 자동으로 데이터 다시 로드
        $selectedPeriod
            .dropFirst() // 초기값 무시
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main) // 300ms 딜레이
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.loadStats()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Helper Methods

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting Helper
    /// - 일관된 날짜 표시를 위한 헬퍼 메서드
    ///
    /// - Parameters:
    ///   - date: 포맷할 날짜
    ///   - style: 날짜 스타일 (기본값: .medium)
    /// - Returns: 포맷된 문자열
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 수면 시간 포맷팅
    /// 📚 학습 포인트: Duration Formatting Helper
    /// - 분 단위를 시간:분 형식으로 변환
    ///
    /// - Parameter minutes: 수면 시간 (분)
    /// - Returns: 포맷된 문자열 (예: "7시간 30분")
    func formatDuration(_ minutes: Int32) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if mins == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(mins)분"
        }
    }

    /// 수면 시간 변화량 포맷팅
    /// 📚 학습 포인트: Change Formatting with Sign
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량 (분)
    /// - Returns: 포맷된 문자열 (예: "+30분", "-1시간")
    func formatDurationChange(_ change: Int32?) -> String {
        guard let change = change else { return "-" }

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

    /// 에러 메시지 제거
    /// 📚 학습 포인트: State Cleanup
    /// - 사용자가 에러 확인 후 호출
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Preview Support

#if DEBUG
extension SleepTrendsViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview() -> SleepTrendsViewModel {
        // Mock Repository와 Use Case 필요 (실제로는 DIContainer에서 주입)
        fatalError("Preview support not yet implemented. Use DIContainer.shared.makeSleepTrendsViewModel() instead.")
    }

    /// 샘플 데이터가 있는 ViewModel
    /// 📚 학습 포인트: Sample Data for Preview
    /// - 차트 미리보기를 위한 샘플 데이터 포함
    static func makePreviewWithData(
        fetchSleepStatsUseCase: FetchSleepStatsUseCase,
        sleepRepository: SleepRepositoryProtocol
    ) -> SleepTrendsViewModel {
        let viewModel = SleepTrendsViewModel(
            fetchSleepStatsUseCase: fetchSleepStatsUseCase,
            sleepRepository: sleepRepository
        )

        // 샘플 데이터 설정
        viewModel.statsOutput = FetchSleepStatsUseCase.sampleOutput()

        return viewModel
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: Chart ViewModel Pattern 이해
///
/// SleepTrendsViewModel의 역할:
/// - 차트 데이터 관리: FetchSleepStatsUseCase를 통해 통계 데이터 조회
/// - 기간 선택: 7/30/90일 기간 또는 커스텀 날짜 범위
/// - 네비게이션: 이전/다음 기간으로 이동
/// - 빈 상태 처리: 데이터 없을 때 empty state 표시
/// - 로딩/에러 처리: 비동기 작업의 상태 관리
///
/// 주요 기능:
/// 1. 기간 선택 (7/30/90일)
/// 2. 날짜 범위 네비게이션 (이전/다음 기간)
/// 3. 통계 정보 제공 (평균, 추세, 일관성 등)
/// 4. 실시간 상태 반영 (@Published)
/// 5. 자동 리로드 (기간 변경 시)
///
/// 차트 최적화:
/// - 데이터는 이미 날짜순 정렬됨 (Use Case에서 처리)
/// - 통계는 computed properties로 자동 계산됨
/// - 빈 상태 체크 용이 (isEmpty computed property)
///
/// 상태 관리:
/// - @Published: 값 변경 시 자동으로 View 업데이트
/// - @MainActor: 모든 메서드가 메인 스레드에서 실행
/// - Combine: 기간 변경 감지 및 자동 리로드
///
/// 의존성:
/// - FetchSleepStatsUseCase: 통계 데이터 조회
/// - SleepRepositoryProtocol: 직접 조회가 필요한 경우
///
/// 제공하는 통계:
/// - 평균 수면 시간
/// - 가장 많은 수면 상태
/// - 좋은 수면 비율
/// - 일관성 점수
/// - 추세 분석 (최근 vs 이전)
/// - 상태별 분포
///
/// SleepHistoryViewModel과의 차이:
/// - SleepHistoryViewModel: 리스트 표시 및 편집/삭제
/// - SleepTrendsViewModel: 차트 및 통계 표시
/// - SleepHistoryViewModel: 기본 통계만 제공
/// - SleepTrendsViewModel: 고급 통계 및 추세 분석 제공
///
/// 사용 예시:
/// ```swift
/// struct SleepTrendsView: View {
///     @StateObject private var viewModel: SleepTrendsViewModel
///
///     var body: some View {
///         VStack {
///             // 기간 선택기
///             Picker("기간", selection: $viewModel.selectedPeriod) {
///                 ForEach(FetchSleepStatsUseCase.StatsPeriod.allCases, id: \.self) { period in
///                     Text(period.displayName).tag(period)
///                 }
///             }
///             .pickerStyle(.segmented)
///
///             // 통계 요약
///             VStack(alignment: .leading, spacing: 8) {
///                 HStack {
///                     Text("평균 수면")
///                     Spacer()
///                     Text(viewModel.averageDurationString)
///                 }
///                 HStack {
///                     Text("좋은 수면 비율")
///                     Spacer()
///                     Text(viewModel.goodSleepPercentageString)
///                 }
///                 HStack {
///                     Text("일관성 점수")
///                     Spacer()
///                     Text(viewModel.consistencyScoreString)
///                 }
///             }
///
///             // 차트
///             if viewModel.isEmpty {
///                 Text("데이터가 없습니다")
///             } else {
///                 Chart(viewModel.dataPoints) { dataPoint in
///                     BarMark(
///                         x: .value("날짜", dataPoint.date),
///                         y: .value("수면 시간", dataPoint.duration)
///                     )
///                     .foregroundStyle(by: .value("상태", dataPoint.status.displayName))
///                 }
///
///                 // 평균선 표시
///                 if let avg = viewModel.averageDurationMinutes {
///                     RuleMark(y: .value("평균", avg))
///                         .foregroundStyle(.gray)
///                         .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
///                 }
///             }
///
///             // 네비게이션
///             HStack {
///                 Button("이전") {
///                     Task { await viewModel.navigateToPreviousPeriod() }
///                 }
///                 Spacer()
///                 Text(viewModel.periodDisplayString)
///                     .font(.caption)
///                     .foregroundColor(.secondary)
///                 Spacer()
///                 Button("다음") {
///                     Task { await viewModel.navigateToNextPeriod() }
///                 }
///             }
///         }
///         .overlay {
///             if viewModel.isLoading {
///                 ProgressView()
///             }
///         }
///         .refreshable {
///             await viewModel.refresh()
///         }
///     }
/// }
/// ```
///
/// 💡 Android ViewModel과의 비교:
/// - Android: ViewModel + StateFlow + Chart data
/// - SwiftUI: ObservableObject + @Published + Chart data
/// - Android: Flow.collect로 상태 관찰
/// - SwiftUI: Combine sink로 상태 관찰
///
/// 💡 실무 팁:
/// - 기간 선택은 Picker 또는 SegmentedControl 사용
/// - 차트는 Swift Charts 사용 (BarMark 또는 LineMark)
/// - 평균선은 RuleMark로 표시
/// - 상태별 색상은 SleepStatus.color 사용
/// - Pull-to-refresh로 수동 새로고침 지원
/// - 네비게이션으로 과거 데이터 탐색 가능
///
/// FetchSleepStatsUseCase와의 협력:
/// - ViewModel: UI 상태 관리 및 사용자 액션 처리
/// - Use Case: 비즈니스 로직 (데이터 조회, 통계 계산)
/// - ViewModel은 Use Case의 결과만 받아서 UI 업데이트
///
