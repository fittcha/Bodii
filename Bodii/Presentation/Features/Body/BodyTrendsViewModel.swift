//
//  BodyTrendsViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Chart-Focused ViewModel Pattern
// 차트 데이터 관리와 기간 선택을 위한 ViewModel
// 💡 Java 비교: Android의 ViewModel과 유사하지만 차트 전용 상태 관리

import Foundation
import SwiftUI
import Combine

// MARK: - BodyTrendsViewModel

/// 신체 구성 트렌드 차트를 위한 ViewModel
/// 📚 학습 포인트: Chart Data Management
/// - 차트 표시를 위한 트렌드 데이터 관리
/// - 기간 선택 및 네비게이션 처리
/// - 빈 상태 및 로딩 상태 관리
/// 💡 Java 비교: Android ViewModel + Chart data transformation
@MainActor
class BodyTrendsViewModel: ObservableObject {

    // MARK: - Published Properties (View State)

    /// 선택된 트렌드 기간
    /// 📚 학습 포인트: User Selection State
    /// - 사용자가 선택한 기간 (7일/30일/90일)
    /// - 변경 시 자동으로 데이터 다시 로드
    /// 💡 Java 비교: LiveData<TrendPeriod>와 유사
    @Published var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week

    /// 트렌드 데이터 출력
    /// 📚 학습 포인트: Optional State
    /// - nil이면 아직 데이터 로드 안 됨
    /// - 값이 있으면 차트에 표시
    @Published var trendsOutput: FetchBodyTrendsUseCase.Output?

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 데이터 조회 중 로딩 인디케이터 표시
    @Published var isLoading: Bool = false

    /// 에러 메시지
    /// 📚 학습 포인트: Error State
    /// - nil이면 에러 없음
    /// - 값이 있으면 에러 메시지 표시
    @Published var errorMessage: String?

    /// 대사율 데이터 포함 여부
    /// 📚 학습 포인트: Toggle State
    /// - 차트에 BMR/TDEE 정보 표시 여부
    /// - 성능 최적화를 위해 선택적 로딩
    @Published var includeMetabolismData: Bool = false

    /// 커스텀 날짜 범위 사용 여부
    /// 📚 학습 포인트: Advanced Feature Toggle
    /// - false: TrendPeriod 사용
    /// - true: customStartDate/customEndDate 사용
    @Published var useCustomDateRange: Bool = false

    /// 커스텀 시작 날짜
    /// 📚 학습 포인트: Custom Date Range
    /// - useCustomDateRange가 true일 때만 사용
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

    /// 커스텀 종료 날짜
    @Published var customEndDate: Date = Date()

    // MARK: - Private Properties

    /// 신체 트렌드 조회 Use Case
    /// 📚 학습 포인트: Dependency Injection
    /// - Use Case를 외부에서 주입받아 사용
    /// - 테스트 시 Mock으로 교체 가능
    private let fetchBodyTrendsUseCase: FetchBodyTrendsUseCase

    /// 신체 데이터 저장소
    /// 📚 학습 포인트: Protocol-Oriented Programming
    /// - 직접 조회가 필요한 경우를 위해 Repository도 보유
    private let bodyRepository: BodyRepositoryProtocol

    /// Combine 구독 저장소
    /// 📚 학습 포인트: Reactive Programming
    /// - selectedPeriod 변경 시 자동으로 데이터 다시 로드
    /// - 메모리 누수 방지를 위한 구독 관리
    /// 💡 Java 비교: RxJava의 CompositeDisposable과 유사
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// BodyTrendsViewModel 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - fetchBodyTrendsUseCase: 신체 트렌드 조회 Use Case
    ///   - bodyRepository: 신체 데이터 저장소
    init(
        fetchBodyTrendsUseCase: FetchBodyTrendsUseCase,
        bodyRepository: BodyRepositoryProtocol
    ) {
        self.fetchBodyTrendsUseCase = fetchBodyTrendsUseCase
        self.bodyRepository = bodyRepository

        // 📚 학습 포인트: Reactive State Observation
        // selectedPeriod 변경 시 자동으로 데이터 다시 로드
        setupPeriodObserver()

        // 초기 데이터 로드
        Task {
            await loadTrends()
        }
    }

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 확인
    /// 📚 학습 포인트: Computed Property for Empty State
    /// - View에서 empty state UI 표시 여부 결정
    var isEmpty: Bool {
        trendsOutput?.isEmpty ?? true
    }

    /// 데이터 포인트 개수
    /// 📚 학습 포인트: Quick Access Property
    /// - UI에서 바로 사용할 수 있는 편의 속성
    var dataPointCount: Int {
        trendsOutput?.count ?? 0
    }

    /// 차트 데이터 포인트
    /// 📚 학습 포인트: Convenience Property
    /// - View에서 직접 접근 가능한 데이터 포인트 배열
    var dataPoints: [FetchBodyTrendsUseCase.TrendDataPoint] {
        trendsOutput?.dataPoints ?? []
    }

    /// 기간 표시 문자열
    /// 📚 학습 포인트: UI Helper Property
    /// - "2024.01.01 - 2024.01.07" 형식
    var periodDisplayString: String {
        guard let output = trendsOutput else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")

        let startStr = formatter.string(from: output.startDate)
        let endStr = formatter.string(from: output.endDate)

        return "\(startStr) - \(endStr)"
    }

    // MARK: - Public Methods

    /// 트렌드 데이터 로드
    /// 📚 학습 포인트: Async Data Loading
    /// - Use Case를 호출하여 데이터 조회
    /// - 로딩 상태 및 에러 처리
    /// 💡 Java 비교: Kotlin Coroutines의 suspend function과 유사
    func loadTrends() async {
        isLoading = true
        errorMessage = nil

        do {
            // 📚 학습 포인트: Conditional Query Strategy
            // 커스텀 날짜 범위 사용 여부에 따라 다른 메서드 호출
            if useCustomDateRange {
                // 커스텀 날짜 범위로 조회
                let input = FetchBodyTrendsUseCase.Input(
                    period: selectedPeriod,
                    endDate: customEndDate,
                    includeMetabolismData: includeMetabolismData
                )
                trendsOutput = try await fetchBodyTrendsUseCase.execute(input: input)
            } else {
                // 표준 기간으로 조회
                let input = FetchBodyTrendsUseCase.Input(
                    period: selectedPeriod,
                    includeMetabolismData: includeMetabolismData
                )
                trendsOutput = try await fetchBodyTrendsUseCase.execute(input: input)
            }

        } catch let error as FetchBodyTrendsUseCase.TrendsError {
            // 📚 학습 포인트: Specific Error Handling
            // Use Case의 도메인 에러를 사용자 친화적 메시지로 변환
            errorMessage = error.localizedDescription
            trendsOutput = nil
        } catch {
            // 📚 학습 포인트: Generic Error Handling
            errorMessage = "트렌드 데이터 로드 실패: \(error.localizedDescription)"
            trendsOutput = nil
        }

        isLoading = false
    }

    /// 기간 변경
    /// 📚 학습 포인트: State Update Method
    /// - 기간 변경 시 자동으로 데이터 다시 로드 (observer를 통해)
    ///
    /// - Parameter period: 새로운 기간
    func changePeriod(to period: FetchBodyTrendsUseCase.TrendPeriod) {
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

        await loadTrends()
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

        await loadTrends()
    }

    /// 현재 날짜로 리셋
    /// 📚 학습 포인트: Reset to Default State
    /// - 커스텀 날짜 범위를 해제하고 현재 기준으로 조회
    func resetToCurrentPeriod() async {
        useCustomDateRange = false
        await loadTrends()
    }

    /// 대사율 데이터 포함 여부 토글
    /// 📚 학습 포인트: Toggle with Auto-Reload
    /// - 토글 후 자동으로 데이터 다시 로드
    func toggleMetabolismData() async {
        includeMetabolismData.toggle()
        await loadTrends()
    }

    /// 새로고침
    /// 📚 학습 포인트: Manual Refresh
    /// - Pull-to-refresh 등에서 사용
    func refresh() async {
        await loadTrends()
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
                    await self.loadTrends()
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

    /// 체중 변화량 포맷팅
    /// 📚 학습 포인트: Number Formatting with Sign
    /// - 양수는 +, 음수는 - 기호 포함
    /// - 변화 없음은 "0.0"
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+1.5 kg", "-0.8 kg")
    func formatWeightChange(_ change: Decimal?) -> String {
        guard let change = change else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + " kg"
    }

    /// 체지방률 변화량 포맷팅
    /// 📚 학습 포인트: Percentage Formatting
    /// - 퍼센트 기호 포함
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+2.0%", "-1.5%")
    func formatBodyFatChange(_ change: Decimal?) -> String {
        guard let change = change else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"

        let number = NSDecimalNumber(decimal: change)
        return (formatter.string(from: number) ?? "\(change)") + "%"
    }
}

// MARK: - Preview Support

#if DEBUG
extension BodyTrendsViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview() -> BodyTrendsViewModel {
        // Mock Repository 생성 (실제 구현 필요)
        fatalError("Preview support not yet implemented. Need to create MockBodyRepository.")
    }

    /// 샘플 데이터가 있는 ViewModel
    /// 📚 학습 포인트: Sample Data for Preview
    /// - 차트 미리보기를 위한 샘플 데이터 포함
    static func makePreviewWithData(repository: BodyRepositoryProtocol) -> BodyTrendsViewModel {
        let useCase = FetchBodyTrendsUseCase(bodyRepository: repository)
        let viewModel = BodyTrendsViewModel(
            fetchBodyTrendsUseCase: useCase,
            bodyRepository: repository
        )

        // 샘플 데이터 설정
        viewModel.trendsOutput = FetchBodyTrendsUseCase.sampleOutput()

        return viewModel
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: Chart ViewModel Pattern 이해
///
/// BodyTrendsViewModel의 역할:
/// - 차트 데이터 관리: FetchBodyTrendsUseCase를 통해 트렌드 데이터 조회
/// - 기간 선택: 7/30/90일 기간 또는 커스텀 날짜 범위
/// - 네비게이션: 이전/다음 기간으로 이동
/// - 빈 상태 처리: 데이터 없을 때 empty state 표시
/// - 로딩/에러 처리: 비동기 작업의 상태 관리
///
/// 주요 기능:
/// 1. 기간 선택 (7/30/90일)
/// 2. 날짜 범위 네비게이션 (이전/다음 기간)
/// 3. 대사율 데이터 선택적 로딩
/// 4. 실시간 상태 반영 (@Published)
/// 5. 자동 리로드 (기간 변경 시)
///
/// 차트 최적화:
/// - 데이터는 이미 날짜순 정렬됨 (Use Case에서 처리)
/// - 대사율 데이터는 선택적 로딩 (성능 최적화)
/// - 빈 상태 체크 용이 (isEmpty computed property)
///
/// 상태 관리:
/// - @Published: 값 변경 시 자동으로 View 업데이트
/// - @MainActor: 모든 메서드가 메인 스레드에서 실행
/// - Combine: 기간 변경 감지 및 자동 리로드
///
/// 의존성:
/// - FetchBodyTrendsUseCase: 트렌드 데이터 조회
/// - BodyRepositoryProtocol: 직접 조회가 필요한 경우
///
/// 사용 예시:
/// ```swift
/// struct BodyTrendsView: View {
///     @StateObject private var viewModel = BodyTrendsViewModel(
///         fetchBodyTrendsUseCase: trendsUseCase,
///         bodyRepository: repository
///     )
///
///     var body: some View {
///         VStack {
///             // 기간 선택기
///             Picker("기간", selection: $viewModel.selectedPeriod) {
///                 ForEach(FetchBodyTrendsUseCase.TrendPeriod.allCases, id: \.self) { period in
///                     Text(period.displayName).tag(period)
///                 }
///             }
///             .pickerStyle(.segmented)
///
///             // 차트
///             if viewModel.isEmpty {
///                 Text("데이터가 없습니다")
///             } else {
///                 Chart(viewModel.dataPoints) { dataPoint in
///                     LineMark(
///                         x: .value("날짜", dataPoint.date),
///                         y: .value("체중", dataPoint.weight)
///                     )
///                 }
///             }
///
///             // 네비게이션
///             HStack {
///                 Button("이전") {
///                     Task { await viewModel.navigateToPreviousPeriod() }
///                 }
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
