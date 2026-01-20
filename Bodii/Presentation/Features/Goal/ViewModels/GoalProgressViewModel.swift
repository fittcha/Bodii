//
//  GoalProgressViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Progress Dashboard ViewModel Pattern
// 목표 진행 상황 대시보드의 상태를 관리하는 ViewModel
// 💡 Java 비교: Android의 ViewModel with LiveData와 유사

import Foundation
import Combine

// MARK: - GoalProgressViewModel

/// 목표 진행 상황 대시보드 ViewModel
///
/// 목표 진행 상황을 조회하고 표시하며, 마일스톤 달성을 추적합니다.
///
/// ## 책임
/// - 활성 목표 진행 상황 조회
/// - 진행률 계산 및 표시
/// - 마일스톤 달성 감지 및 축하 표시
/// - 트렌드 분석 및 예상 달성일 계산
/// - 차트 데이터 제공
///
/// ## 의존성
/// - GetGoalProgressUseCase: 목표 진행 상황 조회 비즈니스 로직
///
/// ## 사용 예시
/// ```swift
/// let viewModel = GoalProgressViewModel(
///     getGoalProgressUseCase: getGoalProgressUseCase
/// )
///
/// // 진행 상황 로드
/// await viewModel.loadProgress()
///
/// // 새로고침
/// await viewModel.refresh()
/// ```
@MainActor
final class GoalProgressViewModel: ObservableObject {

    // MARK: - Published Properties (View State)

    // 📚 학습 포인트: Optional State for Data
    // nil이면 아직 데이터 로드 안 됨 또는 활성 목표 없음

    /// 목표 진행 상황 데이터
    ///
    /// nil이면 활성 목표가 없거나 아직 로드하지 않음
    @Published var progressData: GoalProgressData?

    /// 로딩 상태
    ///
    /// 📚 학습 포인트: Loading State
    /// - 데이터 조회 중 로딩 인디케이터 표시
    @Published var isLoading: Bool = false

    /// 에러 메시지
    ///
    /// 📚 학습 포인트: Error State
    /// - nil이면 에러 없음, 값이 있으면 에러 메시지 표시
    @Published var errorMessage: String?

    /// 활성 목표가 없는 상태
    ///
    /// 📚 학습 포인트: Empty State Detection
    /// - true면 목표 설정 화면으로 이동 유도
    @Published var hasNoActiveGoal: Bool = false

    /// 새로 달성한 마일스톤
    ///
    /// 📚 학습 포인트: Celebration Trigger
    /// - 비어있지 않으면 축하 애니메이션 표시
    /// - 표시 후 clear() 호출하여 초기화
    @Published var newMilestones: [Milestone] = []

    /// 마일스톤 축하 표시 여부
    ///
    /// 📚 학습 포인트: Celebration Modal State
    /// - true면 축하 모달/애니메이션 표시
    @Published var showCelebration: Bool = false

    // MARK: - Private Properties

    /// 목표 진행 상황 조회 유스케이스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - Use Case를 외부에서 주입받아 사용
    /// - 테스트 시 Mock으로 교체 가능
    private let getGoalProgressUseCase: GetGoalProgressUseCase

    /// 이전 진행률 (마일스톤 감지용)
    ///
    /// 📚 학습 포인트: State Tracking for Change Detection
    /// - 새로운 마일스톤 달성 감지를 위해 이전 값 저장
    private var previousProgress: Decimal?

    /// Combine 구독 저장소
    ///
    /// 📚 학습 포인트: Combine Framework
    /// - 비동기 이벤트 스트림 관리
    /// - 메모리 누수 방지를 위한 구독 관리
    /// 💡 Java 비교: RxJava의 CompositeDisposable과 유사
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// GoalProgressViewModel 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameter getGoalProgressUseCase: 목표 진행 상황 조회 유스케이스
    init(
        getGoalProgressUseCase: GetGoalProgressUseCase
    ) {
        self.getGoalProgressUseCase = getGoalProgressUseCase

        // 📚 학습 포인트: Initial Data Load
        // ViewModel 생성 시 자동으로 데이터 로드
        Task {
            await loadProgress()
        }
    }

    // MARK: - Computed Properties

    // 📚 학습 포인트: Convenience Properties for View
    // View에서 쉽게 접근할 수 있는 계산된 속성들

    /// 목표가 있는지 여부
    var hasGoal: Bool {
        progressData != nil
    }

    /// 전체 진행률 (%)
    var overallProgress: Decimal {
        progressData?.overallProgress ?? 0
    }

    /// 체중 진행률
    var weightProgress: ProgressResult? {
        progressData?.weightProgress
    }

    /// 체지방률 진행률
    var bodyFatProgress: ProgressResult? {
        progressData?.bodyFatProgress
    }

    /// 근육량 진행률
    var muscleProgress: ProgressResult? {
        progressData?.muscleProgress
    }

    /// 달성한 마일스톤 목록
    var achievedMilestones: [Milestone] {
        progressData?.achievedMilestones ?? []
    }

    /// 현재 목표
    var currentGoal: Goal? {
        progressData?.goal
    }

    /// 현재 체성분 상태
    var currentBody: BodyCompositionEntry? {
        progressData?.currentBody
    }

    /// 체중 목표 예상 달성일
    var weightCompletionDate: Date? {
        progressData?.weightProjection?.estimatedCompletionDate
    }

    /// 체지방률 목표 예상 달성일
    var bodyFatCompletionDate: Date? {
        progressData?.bodyFatProjection?.estimatedCompletionDate
    }

    /// 근육량 목표 예상 달성일
    var muscleCompletionDate: Date? {
        progressData?.muscleProjection?.estimatedCompletionDate
    }

    /// 가장 빠른 예상 달성일
    var earliestCompletionDate: Date? {
        progressData?.earliestCompletionDate
    }

    /// 가장 늦은 예상 달성일
    var latestCompletionDate: Date? {
        progressData?.latestCompletionDate
    }

    /// 목표가 계획대로 진행 중인지
    var isOnTrack: Bool {
        progressData?.isOnTrack ?? false
    }

    /// 트렌드 데이터가 충분한지
    var hasSufficientTrendData: Bool {
        progressData?.hasSufficientTrendData ?? false
    }

    /// 트렌드 분석에 사용된 데이터 포인트 수
    var dataPointsCount: Int {
        progressData?.dataPointsCount ?? 0
    }

    // MARK: - Public Methods

    /// 목표 진행 상황을 로드합니다.
    ///
    /// ## 실행 순서
    /// 1. 로딩 상태 시작
    /// 2. GetGoalProgressUseCase 호출
    /// 3. 이전 진행률과 비교하여 새 마일스톤 감지
    /// 4. 새 마일스톤이 있으면 축하 표시
    /// 5. 성공 시 progressData 업데이트
    /// 6. 실패 시 errorMessage 설정
    ///
    /// 📚 학습 포인트: Async Data Loading with Milestone Detection
    /// - 이전 진행률을 저장하여 새 마일스톤 감지
    /// - 새 마일스톤이 있으면 자동으로 축하 표시
    ///
    /// - Example:
    /// ```swift
    /// Button("새로고침") {
    ///     Task {
    ///         await viewModel.loadProgress()
    ///     }
    /// }
    /// .overlay {
    ///     if viewModel.isLoading {
    ///         ProgressView()
    ///     }
    /// }
    /// .alert("축하합니다!", isPresented: $viewModel.showCelebration) {
    ///     Button("확인") {
    ///         viewModel.clearCelebration()
    ///     }
    /// } message: {
    ///     Text("새로운 마일스톤을 달성했습니다!")
    /// }
    /// ```
    func loadProgress() async {
        // 1. 로딩 상태 시작
        isLoading = true
        errorMessage = nil
        hasNoActiveGoal = false
        defer { isLoading = false }

        do {
            // 2. GetGoalProgressUseCase 호출 (이전 진행률 전달)
            let newProgressData = try await getGoalProgressUseCase.execute(
                previousProgress: previousProgress
            )

            // 3. 새 마일스톤 감지
            if !newProgressData.newlyAchievedMilestones.isEmpty {
                // 새로운 마일스톤 달성!
                newMilestones = newProgressData.newlyAchievedMilestones
                showCelebration = true
            }

            // 4. 진행률 데이터 업데이트
            progressData = newProgressData

            // 5. 이전 진행률 저장 (다음 로드 시 비교용)
            previousProgress = newProgressData.overallProgress

        } catch GetGoalProgressError.noActiveGoal {
            // 활성 목표가 없음
            hasNoActiveGoal = true
            progressData = nil
            errorMessage = "활성 목표가 없습니다. 먼저 목표를 설정해주세요."

        } catch GetGoalProgressError.noBodyCompositionData {
            // 체성분 기록이 없음
            progressData = nil
            errorMessage = "체성분 기록이 없습니다. 먼저 체성분을 입력해주세요."

        } catch {
            // 예상하지 못한 에러
            progressData = nil
            errorMessage = "진행 상황 조회 실패: \(error.localizedDescription)"
        }
    }

    /// 진행 상황을 새로고침합니다.
    ///
    /// 📚 학습 포인트: Manual Refresh
    /// - Pull-to-refresh 또는 수동 새로고침에서 사용
    /// - loadProgress()와 동일하지만 명시적 의도 표현
    ///
    /// - Example:
    /// ```swift
    /// List {
    ///     // 목표 진행 상황 UI
    /// }
    /// .refreshable {
    ///     await viewModel.refresh()
    /// }
    /// ```
    func refresh() async {
        await loadProgress()
    }

    /// 축하 표시를 클리어합니다.
    ///
    /// 📚 학습 포인트: State Reset
    /// - 축하 모달/애니메이션을 닫은 후 호출
    ///
    /// - Example:
    /// ```swift
    /// .alert("축하합니다!", isPresented: $viewModel.showCelebration) {
    ///     Button("확인") {
    ///         viewModel.clearCelebration()
    ///     }
    /// }
    /// ```
    func clearCelebration() {
        newMilestones = []
        showCelebration = false
    }

    /// 에러 메시지를 클리어합니다.
    ///
    /// 📚 학습 포인트: Error Dismissal
    /// - 에러 알림을 닫은 후 호출
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Chart Data Methods

    /// 체중 차트 데이터를 반환합니다.
    ///
    /// 📚 학습 포인트: Chart Data Preparation
    /// - 시작값, 현재값, 목표값을 차트 데이터로 변환
    ///
    /// - Returns: 차트 데이터 포인트 배열 (날짜, 체중)
    func getWeightChartData() -> [ChartDataPoint]? {
        guard let goal = currentGoal,
              let body = currentBody,
              let startWeight = goal.startWeight?.decimalValue,
              let targetWeight = goal.targetWeight?.decimalValue,
              let createdAt = goal.createdAt else {
            return nil
        }

        let currentWeight = body.weight

        return [
            ChartDataPoint(
                date: createdAt,
                value: startWeight,
                label: "시작"
            ),
            ChartDataPoint(
                date: body.date,
                value: currentWeight,
                label: "현재"
            ),
            ChartDataPoint(
                date: latestCompletionDate ?? Date(),
                value: targetWeight,
                label: "목표"
            )
        ]
    }

    /// 체지방률 차트 데이터를 반환합니다.
    ///
    /// - Returns: 차트 데이터 포인트 배열 (날짜, 체지방률)
    func getBodyFatChartData() -> [ChartDataPoint]? {
        guard let goal = currentGoal,
              let body = currentBody,
              let startBodyFat = goal.startBodyFatPct?.decimalValue,
              let targetBodyFat = goal.targetBodyFatPct?.decimalValue,
              let createdAt = goal.createdAt else {
            return nil
        }

        let currentBodyFat = body.bodyFatPercent

        return [
            ChartDataPoint(
                date: createdAt,
                value: startBodyFat,
                label: "시작"
            ),
            ChartDataPoint(
                date: body.date,
                value: currentBodyFat,
                label: "현재"
            ),
            ChartDataPoint(
                date: latestCompletionDate ?? Date(),
                value: targetBodyFat,
                label: "목표"
            )
        ]
    }

    /// 근육량 차트 데이터를 반환합니다.
    ///
    /// - Returns: 차트 데이터 포인트 배열 (날짜, 근육량)
    func getMuscleChartData() -> [ChartDataPoint]? {
        guard let goal = currentGoal,
              let body = currentBody,
              let startMuscle = goal.startMuscleMass?.decimalValue,
              let targetMuscle = goal.targetMuscleMass?.decimalValue,
              let createdAt = goal.createdAt else {
            return nil
        }

        let currentMuscle = body.muscleMass

        return [
            ChartDataPoint(
                date: createdAt,
                value: startMuscle,
                label: "시작"
            ),
            ChartDataPoint(
                date: body.date,
                value: currentMuscle,
                label: "현재"
            ),
            ChartDataPoint(
                date: latestCompletionDate ?? Date(),
                value: targetMuscle,
                label: "목표"
            )
        ]
    }

    // MARK: - Formatting Helper Methods

    /// 진행률을 포맷팅합니다.
    ///
    /// 📚 학습 포인트: Number Formatting Helper
    /// - Decimal을 읽기 쉬운 백분율 문자열로 변환
    ///
    /// - Parameter progress: 진행률 (%)
    /// - Returns: 포맷된 문자열 (예: "60.0%")
    func formatProgress(_ progress: Decimal?) -> String {
        guard let progress = progress else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: progress)
        return (formatter.string(from: number) ?? "\(progress)") + "%"
    }

    /// 날짜를 포맷팅합니다.
    ///
    /// 📚 학습 포인트: Date Formatting Helper
    /// - 일관된 날짜 표시를 위한 헬퍼 메서드
    ///
    /// - Parameter date: 포맷할 날짜
    /// - Returns: 포맷된 문자열 (예: "2024년 3월 15일")
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")

        return formatter.string(from: date)
    }

    /// 체중을 포맷팅합니다.
    ///
    /// - Parameter weight: 체중 (kg)
    /// - Returns: 포맷된 문자열 (예: "65.0 kg")
    func formatWeight(_ weight: Decimal?) -> String {
        guard let weight = weight else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: weight)
        return (formatter.string(from: number) ?? "\(weight)") + " kg"
    }

    /// 체지방률을 포맷팅합니다.
    ///
    /// - Parameter bodyFat: 체지방률 (%)
    /// - Returns: 포맷된 문자열 (예: "18.0%")
    func formatBodyFat(_ bodyFat: Decimal?) -> String {
        guard let bodyFat = bodyFat else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: bodyFat)
        return (formatter.string(from: number) ?? "\(bodyFat)") + "%"
    }

    /// 근육량을 포맷팅합니다.
    ///
    /// - Parameter muscle: 근육량 (kg)
    /// - Returns: 포맷된 문자열 (예: "30.0 kg")
    func formatMuscle(_ muscle: Decimal?) -> String {
        guard let muscle = muscle else { return "-" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: muscle)
        return (formatter.string(from: number) ?? "\(muscle)") + " kg"
    }

    /// 남은 일수를 포맷팅합니다.
    ///
    /// - Parameter date: 목표 날짜
    /// - Returns: 포맷된 문자열 (예: "D-45")
    func formatDaysRemaining(to date: Date?) -> String {
        guard let date = date else { return "-" }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)

        guard let days = components.day else { return "-" }

        if days < 0 {
            return "D+\(abs(days))"
        } else if days == 0 {
            return "D-Day"
        } else {
            return "D-\(days)"
        }
    }
}

// MARK: - Supporting Types

/// 차트 데이터 포인트
///
/// 📚 학습 포인트: Chart Data Model
/// - Swift Charts에서 사용하기 위한 데이터 구조
struct ChartDataPoint: Identifiable, Equatable {
    /// 고유 식별자
    let id = UUID()

    /// 날짜
    let date: Date

    /// 값 (체중, 체지방률, 근육량 등)
    let value: Decimal

    /// 레이블 (시작, 현재, 목표 등)
    let label: String

    // MARK: - Equatable

    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preview Support

#if DEBUG
extension GoalProgressViewModel {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock ViewModel
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview() -> GoalProgressViewModel {
        // Mock UseCase 및 Repository 필요
        fatalError("Preview support not yet implemented. Need to create Mock GetGoalProgressUseCase.")
    }

    /// 샘플 데이터가 있는 ViewModel
    ///
    /// 📚 학습 포인트: Sample Data for Preview
    /// - 진행 상황 UI 미리보기를 위한 샘플 데이터 포함
    static func makePreviewWithData(useCase: GetGoalProgressUseCase) -> GoalProgressViewModel {
        let viewModel = GoalProgressViewModel(getGoalProgressUseCase: useCase)

        // 샘플 데이터는 useCase에서 제공
        // Task { await viewModel.loadProgress() }

        return viewModel
    }
}
#endif

// MARK: - Documentation

/// ## GoalProgressViewModel 설명
///
/// 목표 진행 상황 대시보드의 상태를 관리하는 ViewModel입니다.
///
/// ### 주요 기능
///
/// 1. **Progress Loading**:
///    - 활성 목표의 진행 상황 조회
///    - 각 목표별 진행률 계산 (체중, 체지방률, 근육량)
///    - 전체 진행률 계산 (평균)
///
/// 2. **Milestone Tracking**:
///    - 달성한 마일스톤 확인 (25%, 50%, 75%, 100%)
///    - 새로 달성한 마일스톤 감지
///    - 축하 애니메이션 트리거
///
/// 3. **Trend Analysis**:
///    - 14일 트렌드 분석
///    - 예상 달성일 계산
///    - 계획 대비 진행 상태 확인
///
/// 4. **Chart Data**:
///    - 시작, 현재, 목표 데이터 포인트 제공
///    - Swift Charts용 데이터 변환
///
/// ### 상태 구조
///
/// ```
/// GoalProgressViewModel
/// ├── progressData: GoalProgressData?
/// │   ├── goal: Goal (활성 목표)
/// │   ├── currentBody: BodyCompositionEntry (현재 상태)
/// │   ├── overallProgress: Decimal (전체 진행률)
/// │   ├── weightProgress: ProgressResult? (체중 진행률)
/// │   ├── bodyFatProgress: ProgressResult? (체지방률 진행률)
/// │   ├── muscleProgress: ProgressResult? (근육량 진행률)
/// │   ├── achievedMilestones: [Milestone] (달성한 마일스톤)
/// │   ├── newlyAchievedMilestones: [Milestone] (새 마일스톤)
/// │   └── projections: ProjectionResult (예상 달성일)
/// ├── isLoading: Bool
/// ├── errorMessage: String?
/// ├── hasNoActiveGoal: Bool
/// ├── newMilestones: [Milestone]
/// └── showCelebration: Bool
/// ```
///
/// ### 사용 예시
///
/// ```swift
/// struct GoalProgressView: View {
///     @StateObject private var viewModel: GoalProgressViewModel
///
///     var body: some View {
///         ScrollView {
///             if viewModel.hasNoActiveGoal {
///                 // Empty state: 목표 설정 유도
///                 EmptyGoalView()
///             } else if let progressData = viewModel.progressData {
///                 VStack {
///                     // 전체 진행률
///                     ProgressCircle(progress: viewModel.overallProgress)
///
///                     // 각 목표별 진행률
///                     if let weightProgress = viewModel.weightProgress {
///                         ProgressBar(title: "체중", progress: weightProgress)
///                     }
///
///                     // 예상 달성일
///                     if let completionDate = viewModel.earliestCompletionDate {
///                         CompletionDateCard(date: completionDate)
///                     }
///
///                     // 마일스톤 표시
///                     MilestoneProgressBar(
///                         progress: viewModel.overallProgress,
///                         achieved: viewModel.achievedMilestones
///                     )
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
///         .alert("축하합니다!", isPresented: $viewModel.showCelebration) {
///             Button("확인") {
///                 viewModel.clearCelebration()
///             }
///         } message: {
///             Text("새로운 마일스톤을 달성했습니다!")
///         }
///         .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
///             Button("확인") {
///                 viewModel.clearError()
///             }
///         } message: {
///             Text(viewModel.errorMessage ?? "")
///         }
///     }
/// }
/// ```
///
/// ### Milestone Detection Flow
///
/// 1. **첫 로드**: previousProgress = nil
///    - 현재 진행률만 계산, 새 마일스톤 없음
///
/// 2. **두 번째 로드**: previousProgress = 40%
///    - 현재 진행률 = 55%
///    - 새 마일스톤 = [.half] (50% 새로 달성)
///    - showCelebration = true
///
/// 3. **축하 표시**: clearCelebration() 호출
///    - newMilestones = []
///    - showCelebration = false
///
/// 4. **다음 로드**: previousProgress = 55%
///    - 새 마일스톤이 없으면 축하 표시 안 함
///
/// ### 에러 처리
///
/// - **noActiveGoal**: hasNoActiveGoal = true, 목표 설정 유도
/// - **noBodyCompositionData**: 체성분 입력 유도
/// - **fetchFailed**: errorMessage 표시
///
/// ### Clean Architecture에서의 위치
///
/// ```
/// [Presentation]     GoalProgressView → GoalProgressViewModel
///       ↓
/// [Domain]          GoalProgressViewModel → GetGoalProgressUseCase
///       ↓
/// [Data]            GetGoalProgressUseCase → Repository
/// ```
///
