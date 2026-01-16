//
//  DashboardViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-15.
//

// 📚 학습 포인트: SwiftUI ViewModel with @Observable
// iOS 17+의 @Observable 매크로를 사용한 현대적인 MVVM 패턴
// 💡 Java 비교: Android의 ViewModel + LiveData와 유사하지만 더 간단

import Foundation
import Observation

/// 대시보드 뷰 모델
///
/// 일일 건강 데이터(칼로리, 매크로, 운동, 수면, 체성분)를 관리합니다.
///
/// ## 책임
/// - 선택된 날짜의 DailyLog 조회
/// - 날짜 네비게이션 (이전/다음 날)
/// - 새로고침 기능
/// - 로딩 및 에러 상태 관리
///
/// ## 의존성
/// - DailyLogRepository: 일일 집계 조회
///
/// ## 사용 예시
/// ```swift
/// let viewModel = DashboardViewModel(
///     dailyLogRepository: dailyLogRepository,
///     userId: user.id
/// )
///
/// // View에서 사용
/// if let dailyLog = viewModel.dailyLog {
///     CalorieBalanceCard(dailyLog: dailyLog)
/// }
/// ```
@Observable
final class DashboardViewModel {

    // MARK: - Properties

    // 📚 학습 포인트: @Observable과 프로퍼티
    // @Observable 매크로는 자동으로 모든 프로퍼티를 관찰 가능하게 만듦
    // 💡 Java 비교: @Published (이전 SwiftUI) 또는 MutableLiveData와 유사

    /// 현재 선택된 날짜
    var selectedDate: Date

    /// 일일 집계 데이터
    var dailyLog: DailyLog?

    /// 로딩 상태
    var isLoading: Bool = false

    /// 에러 메시지
    var errorMessage: String?

    // 📚 학습 포인트: Computed Property
    // 저장 공간 없이 계산되는 프로퍼티
    // 의존하는 프로퍼티가 변경되면 자동으로 재계산됨

    /// 총 섭취 칼로리
    var totalCaloriesIn: Int32 {
        dailyLog?.totalCaloriesIn ?? 0
    }

    /// TDEE (활동대사량)
    var tdee: Int32 {
        dailyLog?.tdee ?? 0
    }

    /// 순 칼로리 (섭취 - TDEE)
    var netCalories: Int32 {
        dailyLog?.netCalories ?? 0
    }

    /// 총 탄수화물 (g)
    var totalCarbs: Decimal {
        dailyLog?.totalCarbs ?? 0
    }

    /// 총 단백질 (g)
    var totalProtein: Decimal {
        dailyLog?.totalProtein ?? 0
    }

    /// 총 지방 (g)
    var totalFat: Decimal {
        dailyLog?.totalFat ?? 0
    }

    /// 탄수화물 비율 (%)
    var carbsRatio: Decimal? {
        dailyLog?.carbsRatio
    }

    /// 단백질 비율 (%)
    var proteinRatio: Decimal? {
        dailyLog?.proteinRatio
    }

    /// 지방 비율 (%)
    var fatRatio: Decimal? {
        dailyLog?.fatRatio
    }

    /// 운동 소모 칼로리
    var totalCaloriesOut: Int32 {
        dailyLog?.totalCaloriesOut ?? 0
    }

    /// 운동 시간 (분)
    var exerciseMinutes: Int32 {
        dailyLog?.exerciseMinutes ?? 0
    }

    /// 운동 횟수
    var exerciseCount: Int16 {
        dailyLog?.exerciseCount ?? 0
    }

    /// 수면 시간 (분)
    var sleepDuration: Int32? {
        dailyLog?.sleepDuration
    }

    /// 수면 상태
    var sleepStatus: SleepStatus? {
        dailyLog?.sleepStatus
    }

    /// 체중 (kg)
    var weight: Decimal? {
        dailyLog?.weight
    }

    /// 체지방률 (%)
    var bodyFatPct: Decimal? {
        dailyLog?.bodyFatPct
    }

    /// 데이터가 비어있는지 여부
    var isEmpty: Bool {
        dailyLog == nil
    }

    // 📚 학습 포인트: Private Dependencies
    // ViewModel은 Repository에 의존하지만, View는 이를 알 필요 없음
    // 의존성 주입을 통해 테스트 가능성 향상

    /// 일일 집계 저장소
    private let dailyLogRepository: DailyLogRepository

    /// 사용자 ID (private, but exposed via getter)
    private let _userId: UUID

    /// 사용자 ID를 공개적으로 노출
    ///
    /// 다른 ViewModel이나 UseCase에서 필요할 수 있으므로 public getter 제공
    var userId: UUID {
        _userId
    }

    // MARK: - Initialization

    /// DashboardViewModel 초기화
    ///
    /// - Parameters:
    ///   - dailyLogRepository: 일일 집계 저장소
    ///   - userId: 사용자 ID
    ///   - selectedDate: 초기 선택 날짜 (기본값: 오늘)
    init(
        dailyLogRepository: DailyLogRepository,
        userId: UUID,
        selectedDate: Date = Date()
    ) {
        self.dailyLogRepository = dailyLogRepository
        self._userId = userId
        self.selectedDate = selectedDate
    }

    // MARK: - Public Methods

    /// 뷰가 나타날 때 호출
    ///
    /// 선택된 날짜의 DailyLog를 로드합니다.
    ///
    /// - Example:
    /// ```swift
    /// .onAppear {
    ///     viewModel.onAppear()
    /// }
    /// ```
    @MainActor
    func onAppear() {
        Task {
            await loadDailyLog(for: selectedDate)
        }
    }

    /// 특정 날짜의 DailyLog를 로드합니다.
    ///
    /// ## 실행 순서
    /// 1. 로딩 상태 시작
    /// 2. DailyLog 조회
    /// 3. 로딩 상태 종료
    ///
    /// - Parameter date: 로드할 날짜
    /// - Note: 에러 발생 시 errorMessage에 메시지 저장
    @MainActor
    func loadDailyLog(for date: Date) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 📚 학습 포인트: Repository를 통한 데이터 조회
            // DailyLog에는 모든 사전 계산된 값이 포함되어 있어
            // 추가 계산 없이 바로 UI에 표시 가능 (성능 최적화)
            dailyLog = try await dailyLogRepository.fetch(
                for: date,
                userId: _userId
            )

        } catch {
            // 📚 학습 포인트: Error Handling
            // Swift의 Error 프로토콜을 사용한 에러 처리
            // localizedDescription으로 사용자 친화적 메시지 제공
            errorMessage = "데이터 조회 실패: \(error.localizedDescription)"
            dailyLog = nil
        }
    }

    /// 현재 선택된 날짜의 데이터를 새로고침합니다.
    ///
    /// Pull-to-refresh 기능에서 사용됩니다.
    ///
    /// - Example:
    /// ```swift
    /// .refreshable {
    ///     await viewModel.refresh()
    /// }
    /// ```
    @MainActor
    func refresh() async {
        await loadDailyLog(for: selectedDate)
    }

    /// 날짜를 이동합니다.
    ///
    /// - Parameter days: 이동할 일수 (음수는 이전, 양수는 다음)
    ///
    /// - Example:
    /// ```swift
    /// // 이전 날로 이동
    /// viewModel.navigateDate(by: -1)
    ///
    /// // 다음 날로 이동
    /// viewModel.navigateDate(by: 1)
    /// ```
    @MainActor
    func navigateDate(by days: Int) {
        // 📚 학습 포인트: Calendar API
        // Swift의 Foundation 프레임워크에서 제공하는 날짜 계산
        // 💡 Java 비교: java.time.LocalDate.plusDays()와 유사

        guard let newDate = Calendar.current.date(
            byAdding: .day,
            value: days,
            to: selectedDate
        ) else { return }

        selectedDate = newDate

        Task {
            await loadDailyLog(for: newDate)
        }
    }

    /// 이전 날짜로 이동합니다.
    ///
    /// 하루 전 날짜로 이동하고 데이터를 다시 로드합니다.
    ///
    /// - Example:
    /// ```swift
    /// Button("이전", action: viewModel.goToPreviousDay)
    /// ```
    @MainActor
    func goToPreviousDay() {
        navigateDate(by: -1)
    }

    /// 다음 날짜로 이동합니다.
    ///
    /// 하루 후 날짜로 이동하고 데이터를 다시 로드합니다.
    ///
    /// - Example:
    /// ```swift
    /// Button("다음", action: viewModel.goToNextDay)
    /// ```
    @MainActor
    func goToNextDay() {
        navigateDate(by: 1)
    }

    /// 오늘 날짜로 돌아갑니다.
    ///
    /// - Example:
    /// ```swift
    /// Button("오늘", action: viewModel.goToToday)
    /// ```
    @MainActor
    func goToToday() {
        selectedDate = Date()

        Task {
            await loadDailyLog(for: selectedDate)
        }
    }

    /// 특정 날짜로 이동합니다.
    ///
    /// - Parameter date: 이동할 날짜
    ///
    /// - Example:
    /// ```swift
    /// DatePicker("날짜 선택", selection: Binding(
    ///     get: { viewModel.selectedDate },
    ///     set: { viewModel.selectDate($0) }
    /// ))
    /// ```
    @MainActor
    func selectDate(_ date: Date) {
        selectedDate = date

        Task {
            await loadDailyLog(for: date)
        }
    }

    /// 에러 메시지를 지웁니다.
    ///
    /// 에러 알림을 닫을 때 호출합니다.
    ///
    /// - Example:
    /// ```swift
    /// .alert("오류", isPresented: $viewModel.hasError) {
    ///     Button("확인") { viewModel.clearError() }
    /// }
    /// ```
    func clearError() {
        errorMessage = nil
    }

    /// 에러가 있는지 여부
    var hasError: Bool {
        errorMessage != nil
    }
}

// MARK: - Date Formatting Helper

extension DashboardViewModel {

    /// 선택된 날짜를 표시용 문자열로 변환
    ///
    /// - Returns: "오늘", "어제", 또는 "2026년 1월 15일 (수)" 형식의 문자열
    var formattedSelectedDate: String {
        // 📚 학습 포인트: Date Comparison
        // Calendar를 사용하여 날짜 비교 및 포맷팅

        let calendar = Calendar.current

        if calendar.isDateInToday(selectedDate) {
            return "오늘"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "어제"
        } else {
            // 📚 학습 포인트: DateFormatter
            // 날짜를 사용자 친화적인 문자열로 변환
            // 로케일(locale)에 따라 자동으로 형식 조정
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "yyyy년 M월 d일 (E)"
            return formatter.string(from: selectedDate)
        }
    }

    /// 오늘 날짜인지 여부
    ///
    /// - Returns: 선택된 날짜가 오늘이면 true
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// 미래 날짜인지 여부
    ///
    /// - Returns: 선택된 날짜가 미래이면 true
    var isFuture: Bool {
        selectedDate > Date()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension DashboardViewModel {

    /// 샘플 데이터가 있는 ViewModel (모든 섹션에 데이터 있음)
    ///
    /// 대시보드 Preview에서 정상 상태를 확인하는 용도입니다.
    @MainActor
    static func makePreviewWithData() -> DashboardViewModel {
        let viewModel = DashboardViewModel(
            dailyLogRepository: MockDailyLogRepository(),
            userId: UUID()
        )

        // 샘플 DailyLog 설정
        viewModel.dailyLog = DailyLog(
            id: UUID(),
            userId: viewModel.userId,
            date: Date(),
            // 섭취 (칼로리 적자 상태)
            totalCaloriesIn: 1800,
            totalCarbs: Decimal(187.5),
            totalProtein: Decimal(93.75),
            totalFat: Decimal(41.67),
            carbsRatio: Decimal(50.0),
            proteinRatio: Decimal(25.0),
            fatRatio: Decimal(25.0),
            // 대사
            bmr: 1650,
            tdee: 2310,
            netCalories: -510,
            // 운동
            totalCaloriesOut: 450,
            exerciseMinutes: 75,
            exerciseCount: 2,
            steps: 8500,
            // 체성분
            weight: Decimal(70.5),
            bodyFatPct: Decimal(21.5),
            // 수면
            sleepDuration: 420,
            sleepStatus: .good,
            createdAt: Date(),
            updatedAt: Date()
        )

        return viewModel
    }

    /// 빈 상태의 ViewModel (데이터 없음)
    ///
    /// Empty State를 확인하는 용도입니다.
    @MainActor
    static func makePreviewEmpty() -> DashboardViewModel {
        let viewModel = DashboardViewModel(
            dailyLogRepository: MockDailyLogRepository(),
            userId: UUID()
        )

        // 빈 DailyLog (섭취, 운동, 체성분, 수면 모두 없음)
        viewModel.dailyLog = DailyLog(
            id: UUID(),
            userId: viewModel.userId,
            date: Date(),
            totalCaloriesIn: 0,
            totalCarbs: 0,
            totalProtein: 0,
            totalFat: 0,
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil,
            bmr: 1650,
            tdee: 2310,
            netCalories: -2310,
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0,
            steps: 0,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        return viewModel
    }

    /// 로딩 중인 ViewModel
    ///
    /// Loading State를 확인하는 용도입니다.
    @MainActor
    static func makePreviewLoading() -> DashboardViewModel {
        let viewModel = DashboardViewModel(
            dailyLogRepository: MockDailyLogRepository(),
            userId: UUID()
        )

        viewModel.isLoading = true
        viewModel.dailyLog = nil

        return viewModel
    }

    /// 에러 상태의 ViewModel
    ///
    /// Error State를 확인하는 용도입니다.
    @MainActor
    static func makePreviewError() -> DashboardViewModel {
        let viewModel = DashboardViewModel(
            dailyLogRepository: MockDailyLogRepository(),
            userId: UUID()
        )

        viewModel.errorMessage = "네트워크 연결을 확인해주세요."
        viewModel.dailyLog = nil

        return viewModel
    }

    /// 칼로리 과잉 상태의 ViewModel
    ///
    /// 칼로리 과잉 상태(surplus)를 확인하는 용도입니다.
    @MainActor
    static func makePreviewSurplus() -> DashboardViewModel {
        let viewModel = DashboardViewModel(
            dailyLogRepository: MockDailyLogRepository(),
            userId: UUID()
        )

        viewModel.dailyLog = DailyLog(
            id: UUID(),
            userId: viewModel.userId,
            date: Date(),
            // 섭취 (칼로리 과잉 상태)
            totalCaloriesIn: 2800,
            totalCarbs: Decimal(280.0),
            totalProtein: Decimal(140.0),
            totalFat: Decimal(70.0),
            carbsRatio: Decimal(52.0),
            proteinRatio: Decimal(28.0),
            fatRatio: Decimal(20.0),
            bmr: 1650,
            tdee: 2310,
            netCalories: 490,
            totalCaloriesOut: 200,
            exerciseMinutes: 30,
            exerciseCount: 1,
            steps: 5000,
            weight: Decimal(71.2),
            bodyFatPct: Decimal(22.0),
            sleepDuration: 360,
            sleepStatus: .soso,
            createdAt: Date(),
            updatedAt: Date()
        )

        return viewModel
    }
}

/// Mock DailyLogRepository for Previews
///
/// Preview에서만 사용되는 간단한 Mock Repository입니다.
private final class MockDailyLogRepository: DailyLogRepository {
    func fetch(for date: Date, userId: UUID) async throws -> DailyLog? {
        // Preview에서는 실제 조회를 하지 않음
        return nil
    }

    func save(_ dailyLog: DailyLog) async throws {
        // Preview에서는 저장하지 않음
    }

    func fetchCurrentDay(userId: UUID) async throws -> DailyLog? {
        // Preview에서는 실제 조회를 하지 않음
        return nil
    }
}
#endif

// MARK: - Learning Notes

/// ## @Observable 매크로 (iOS 17+)
///
/// @Observable은 iOS 17에서 도입된 새로운 관찰 메커니즘입니다.
/// 이전의 ObservableObject + @Published를 대체하며 더 간단하고 효율적입니다.
///
/// ### 주요 차이점
///
/// **이전 방식 (ObservableObject)**:
/// ```swift
/// class ViewModel: ObservableObject {
///     @Published var dailyLog: DailyLog?
///     @Published var isLoading = false
/// }
/// ```
///
/// **새로운 방식 (@Observable)**:
/// ```swift
/// @Observable
/// class ViewModel {
///     var dailyLog: DailyLog?
///     var isLoading = false
/// }
/// ```
///
/// ### 장점
///
/// 1. **간결성**: @Published 어노테이션 불필요
/// 2. **성능**: 변경된 프로퍼티만 관찰 (세분화된 업데이트)
/// 3. **타입 안정성**: 모든 프로퍼티가 자동으로 관찰 가능
///
/// ### 사용 방법 (View에서)
///
/// **이전 방식**:
/// ```swift
/// struct DashboardView: View {
///     @StateObject private var viewModel: DashboardViewModel
///     // 또는
///     @ObservedObject var viewModel: DashboardViewModel
/// }
/// ```
///
/// **새로운 방식**:
/// ```swift
/// struct DashboardView: View {
///     var viewModel: DashboardViewModel
///     // 또는 상태 소유가 필요한 경우
///     @State private var viewModel: DashboardViewModel
/// }
/// ```
///
/// ### @MainActor
///
/// @MainActor는 메서드나 프로퍼티가 메인 스레드에서 실행되도록 보장합니다.
/// UI 업데이트는 항상 메인 스레드에서 이루어져야 하므로 필수적입니다.
///
/// ```swift
/// @MainActor
/// func loadDailyLog(for date: Date) async {
///     // 이 코드는 메인 스레드에서 실행됨
///     self.isLoading = true
/// }
/// ```
///
/// ### Pre-calculated Values
///
/// DashboardViewModel은 DailyLog의 사전 계산된 값을 활용합니다:
/// - totalCaloriesIn, totalCarbs, totalProtein, totalFat
/// - carbsRatio, proteinRatio, fatRatio
/// - bmr, tdee, netCalories
/// - totalCaloriesOut, exerciseMinutes, exerciseCount
/// - sleepDuration, sleepStatus
/// - weight, bodyFatPct
///
/// 이렇게 하면 대시보드 로딩 시 추가 계산이 필요 없어 <0.5s 성능 목표를 달성할 수 있습니다.
///
/// ### 테스트 가능성
///
/// ViewModel은 의존성 주입을 통해 쉽게 테스트할 수 있습니다:
///
/// ```swift
/// func testLoadDailyLog() async {
///     // given
///     let mockRepository = MockDailyLogRepository()
///     let viewModel = DashboardViewModel(
///         dailyLogRepository: mockRepository,
///         userId: UUID()
///     )
///
///     // when
///     await viewModel.loadDailyLog(for: Date())
///
///     // then
///     XCTAssertFalse(viewModel.isEmpty)
/// }
/// ```
///
