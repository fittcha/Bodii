//
//  ExerciseListViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: SwiftUI ViewModel with @Observable
// iOS 17+의 @Observable 매크로를 사용한 현대적인 MVVM 패턴
// 💡 Java 비교: Android의 ViewModel + LiveData와 유사하지만 더 간단

import Foundation
import Observation

/// 운동 목록 뷰 모델
///
/// 특정 날짜의 운동 기록 목록과 일일 집계를 관리합니다.
///
/// ## 책임
/// - 선택된 날짜의 운동 기록 조회
/// - 일일 운동 집계 정보 표시 (총 칼로리, 총 시간, 운동 횟수)
/// - 날짜 네비게이션 (이전/다음 날)
/// - 로딩 및 에러 상태 관리
///
/// ## 의존성
/// - GetExerciseRecordsUseCase: 운동 기록 조회
/// - DailyLogRepository: 일일 집계 조회
///
/// ## 사용 예시
/// ```swift
/// let viewModel = ExerciseListViewModel(
///     getExerciseRecordsUseCase: getExerciseRecordsUseCase,
///     dailyLogRepository: dailyLogRepository,
///     userId: user.id
/// )
///
/// // View에서 사용
/// List(viewModel.exerciseRecords) { record in
///     ExerciseCardView(record: record)
/// }
/// ```
@Observable
final class ExerciseListViewModel {

    // MARK: - Properties

    // 📚 학습 포인트: @Observable과 프로퍼티
    // @Observable 매크로는 자동으로 모든 프로퍼티를 관찰 가능하게 만듦
    // 💡 Java 비교: @Published (이전 SwiftUI) 또는 MutableLiveData와 유사

    /// 현재 선택된 날짜
    var selectedDate: Date

    /// 운동 기록 목록
    var exerciseRecords: [ExerciseRecord] = []

    /// 일일 집계 정보
    var dailyLog: DailyLog?

    /// 로딩 상태
    var isLoading: Bool = false

    /// 에러 메시지
    var errorMessage: String?

    // 📚 학습 포인트: Computed Property
    // 저장 공간 없이 계산되는 프로퍼티
    // 의존하는 프로퍼티가 변경되면 자동으로 재계산됨

    /// 일일 총 소모 칼로리
    var totalCaloriesOut: Int32 {
        dailyLog?.totalCaloriesOut ?? 0
    }

    /// 일일 총 운동 시간 (분)
    var exerciseMinutes: Int32 {
        dailyLog?.exerciseMinutes ?? 0
    }

    /// 일일 운동 횟수
    var exerciseCount: Int16 {
        dailyLog?.exerciseCount ?? 0
    }

    /// 운동 기록이 비어있는지 여부
    var isEmpty: Bool {
        exerciseRecords.isEmpty
    }

    // 📚 학습 포인트: Private Dependencies
    // ViewModel은 UseCase에 의존하지만, View는 이를 알 필요 없음
    // 의존성 주입을 통해 테스트 가능성 향상

    /// 운동 기록 조회 유스케이스
    private let getExerciseRecordsUseCase: GetExerciseRecordsUseCase

    /// 일일 집계 저장소
    private let dailyLogRepository: DailyLogRepository

    /// 사용자 ID
    private let userId: UUID

    // MARK: - Initialization

    /// ExerciseListViewModel 초기화
    ///
    /// - Parameters:
    ///   - getExerciseRecordsUseCase: 운동 기록 조회 유스케이스
    ///   - dailyLogRepository: 일일 집계 저장소
    ///   - userId: 사용자 ID
    ///   - selectedDate: 초기 선택 날짜 (기본값: 오늘)
    init(
        getExerciseRecordsUseCase: GetExerciseRecordsUseCase,
        dailyLogRepository: DailyLogRepository,
        userId: UUID,
        selectedDate: Date = Date()
    ) {
        self.getExerciseRecordsUseCase = getExerciseRecordsUseCase
        self.dailyLogRepository = dailyLogRepository
        self.userId = userId
        self.selectedDate = selectedDate
    }

    // MARK: - Public Methods

    /// 뷰가 나타날 때 호출
    ///
    /// 선택된 날짜의 운동 기록과 일일 집계를 로드합니다.
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
            await loadData()
        }
    }

    /// 선택된 날짜의 데이터를 로드합니다.
    ///
    /// ## 실행 순서
    /// 1. 로딩 상태 시작
    /// 2. 운동 기록 조회
    /// 3. 일일 집계 조회
    /// 4. 로딩 상태 종료
    ///
    /// - Note: 에러 발생 시 errorMessage에 메시지 저장
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 📚 학습 포인트: async/await 동시 실행
            // async let으로 두 작업을 병렬로 실행하여 성능 향상
            // 💡 Java 비교: CompletableFuture.allOf()와 유사

            // 운동 기록과 일일 집계를 동시에 조회
            async let recordsTask = getExerciseRecordsUseCase.execute(
                forDate: selectedDate,
                userId: userId
            )

            async let dailyLogTask = dailyLogRepository.fetch(
                for: selectedDate,
                userId: userId
            )

            // 두 작업이 모두 완료될 때까지 대기
            let (records, log) = try await (recordsTask, dailyLogTask)

            exerciseRecords = records
            dailyLog = log

        } catch {
            // 📚 학습 포인트: Error Handling
            // Swift의 Error 프로토콜을 사용한 에러 처리
            // localizedDescription으로 사용자 친화적 메시지 제공
            errorMessage = "운동 기록 조회 실패: \(error.localizedDescription)"
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
        // 📚 학습 포인트: Calendar API
        // Swift의 Foundation 프레임워크에서 제공하는 날짜 계산
        // 💡 Java 비교: java.time.LocalDate.minusDays(1)과 유사

        guard let previousDay = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: selectedDate
        ) else { return }

        selectedDate = previousDay

        Task {
            await loadData()
        }
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
        guard let nextDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: selectedDate
        ) else { return }

        selectedDate = nextDay

        Task {
            await loadData()
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
            await loadData()
        }
    }

    /// 새로고침을 수행합니다.
    ///
    /// 현재 날짜의 데이터를 다시 로드합니다.
    ///
    /// - Example:
    /// ```swift
    /// .refreshable {
    ///     await viewModel.refresh()
    /// }
    /// ```
    @MainActor
    func refresh() async {
        await loadData()
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

extension ExerciseListViewModel {

    /// 선택된 날짜를 표시용 문자열로 변환
    ///
    /// - Returns: "2026년 1월 14일 (화)" 형식의 문자열
    var formattedSelectedDate: String {
        // 📚 학습 포인트: DateFormatter
        // 날짜를 사용자 친화적인 문자열로 변환
        // 로케일(locale)에 따라 자동으로 형식 조정

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter.string(from: selectedDate)
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
///     @Published var records: [ExerciseRecord] = []
///     @Published var isLoading = false
/// }
/// ```
///
/// **새로운 방식 (@Observable)**:
/// ```swift
/// @Observable
/// class ViewModel {
///     var records: [ExerciseRecord] = []
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
/// struct ExerciseListView: View {
///     @StateObject private var viewModel: ExerciseListViewModel
///     // 또는
///     @ObservedObject var viewModel: ExerciseListViewModel
/// }
/// ```
///
/// **새로운 방식**:
/// ```swift
/// struct ExerciseListView: View {
///     var viewModel: ExerciseListViewModel
///     // 또는 상태 소유가 필요한 경우
///     @State private var viewModel: ExerciseListViewModel
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
/// func loadData() async {
///     // 이 코드는 메인 스레드에서 실행됨
///     self.isLoading = true
/// }
/// ```
///
/// ### async/await 동시 실행
///
/// `async let`을 사용하면 여러 비동기 작업을 병렬로 실행할 수 있습니다:
///
/// ```swift
/// // 순차 실행 (느림)
/// let records = try await getRecords()
/// let log = try await getLog()
///
/// // 병렬 실행 (빠름)
/// async let recordsTask = getRecords()
/// async let logTask = getLog()
/// let (records, log) = try await (recordsTask, logTask)
/// ```
///
/// ### 테스트 가능성
///
/// ViewModel은 의존성 주입을 통해 쉽게 테스트할 수 있습니다:
///
/// ```swift
/// func testLoadData() async {
///     // given
///     let mockUseCase = MockGetExerciseRecordsUseCase()
///     let mockRepository = MockDailyLogRepository()
///     let viewModel = ExerciseListViewModel(
///         getExerciseRecordsUseCase: mockUseCase,
///         dailyLogRepository: mockRepository,
///         userId: UUID()
///     )
///
///     // when
///     await viewModel.loadData()
///
///     // then
///     XCTAssertFalse(viewModel.isEmpty)
/// }
/// ```
