//
//  DietCommentViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: AI Feature ViewModel Pattern
// AI 코멘트 생성 기능을 위한 ViewModel
// 💡 Java 비교: Android의 ViewModel with LiveData/StateFlow와 유사

import Foundation

/// 식단 AI 코멘트 화면의 ViewModel
///
/// AI가 생성한 식단 코멘트의 상태를 관리하고, 사용자 액션을 처리합니다.
/// Rate limiting, 오프라인 처리, 캐싱 등 복잡한 비즈니스 로직은 UseCase에서 처리합니다.
///
/// ## 책임
/// - AI 코멘트 생성 요청 및 로딩 상태 관리
/// - 코멘트 표시 상태 관리
/// - 에러 처리 및 사용자 피드백
/// - Rate limit 피드백 제공
/// - 코멘트 dismiss/save 액션 처리
///
/// ## 의존성
/// - GenerateDietCommentUseCase: AI 코멘트 생성
///
/// ## 사용 예시
/// ```swift
/// let viewModel = DietCommentViewModel(
///     generateCommentUseCase: generateCommentUseCase,
///     userId: user.id,
///     userGoalType: user.goalType,
///     userTDEE: user.currentTDEE
/// )
///
/// // View에서 사용
/// Button("AI 코멘트 보기") {
///     Task {
///         await viewModel.generateComment(for: Date(), mealType: .lunch)
///     }
/// }
/// .sheet(isPresented: $viewModel.showComment) {
///     DietCommentPopupView(viewModel: viewModel)
/// }
/// ```
@MainActor
final class DietCommentViewModel: ObservableObject {

    // MARK: - Published Properties

    // 📚 학습 포인트: UI State Management
    // @Published로 View에 자동으로 업데이트 전파
    // 💡 Java 비교: LiveData<T> 또는 StateFlow<T>와 유사

    /// 현재 표시 중인 AI 코멘트
    @Published var comment: DietComment?

    /// 코멘트 로딩 중 여부
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// Rate limit 초과 시 재시도 가능 시간 (초)
    @Published var rateLimitRetryAfter: TimeInterval?

    /// 코멘트 표시 여부 (Sheet 제어)
    @Published var showComment: Bool = false

    // MARK: - Private Properties

    /// 코멘트 생성 유스케이스
    private let generateCommentUseCase: GenerateDietCommentUseCase

    /// 사용자 ID
    private let userId: UUID

    /// 사용자 목표 (감량/유지/증량)
    private let userGoalType: GoalType

    /// 사용자 활동대사량 (TDEE)
    private let userTDEE: Int

    /// 사용자 목표 섭취 칼로리
    private let userTargetCalories: Int

    // MARK: - Initialization

    /// DietCommentViewModel 초기화
    ///
    /// - Parameters:
    ///   - generateCommentUseCase: AI 코멘트 생성 유스케이스
    ///   - userId: 사용자 ID
    ///   - userGoalType: 사용자 목표 (감량/유지/증량)
    ///   - userTDEE: 사용자 활동대사량 (kcal)
    ///   - userTargetCalories: 사용자 목표 섭취 칼로리 (kcal)
    init(
        generateCommentUseCase: GenerateDietCommentUseCase,
        userId: UUID,
        userGoalType: GoalType,
        userTDEE: Int,
        userTargetCalories: Int
    ) {
        self.generateCommentUseCase = generateCommentUseCase
        self.userId = userId
        self.userGoalType = userGoalType
        self.userTDEE = userTDEE
        self.userTargetCalories = userTargetCalories
    }

    // MARK: - Public Methods

    /// AI 식단 코멘트를 생성합니다.
    ///
    /// ## 실행 순서
    /// 1. 로딩 상태 시작
    /// 2. 기존 에러 초기화
    /// 3. GenerateDietCommentUseCase 호출
    ///    - 캐시 확인
    ///    - API 호출 (캐시 미스 시)
    ///    - 응답 파싱 및 캐싱
    /// 4. 성공 시 comment 업데이트 및 showComment = true
    /// 5. 실패 시 에러 메시지 설정
    ///
    /// ## 에러 처리
    /// - noFoodRecords: "식단을 먼저 기록해주세요"
    /// - rateLimitExceeded: "N분 후 다시 시도해주세요"
    /// - networkFailure: "네트워크 연결을 확인해주세요"
    /// - 기타: 에러의 localizedDescription 표시
    ///
    /// - Parameters:
    ///   - date: 평가 대상 날짜
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///
    /// - Note: MainActor로 UI 업데이트 보장
    ///
    /// - Example:
    /// ```swift
    /// Button("AI 코멘트 보기") {
    ///     Task {
    ///         await viewModel.generateComment(
    ///             for: Date(),
    ///             mealType: .lunch
    ///         )
    ///     }
    /// }
    /// ```
    func generateComment(for date: Date, mealType: MealType?) async {
        // 1. 로딩 상태 시작
        isLoading = true
        errorMessage = nil
        rateLimitRetryAfter = nil
        defer { isLoading = false }

        do {
            // 2. UseCase 호출 (모든 비즈니스 로직은 UseCase가 처리)
            // 📚 학습 포인트: Single Responsibility
            // ViewModel은 UI 상태만 관리, 비즈니스 로직은 UseCase에 위임
            let generatedComment = try await generateCommentUseCase.execute(
                userId: userId,
                date: date,
                mealType: mealType,
                goalType: userGoalType,
                tdee: userTDEE,
                targetCalories: userTargetCalories
            )

            // 3. 성공 - 코멘트 표시
            comment = generatedComment
            showComment = true

        } catch let error as DietCommentError {
            // 4. DietCommentError 처리
            handleDietCommentError(error)

        } catch {
            // 5. 기타 에러 처리
            errorMessage = "코멘트 생성 실패: \(error.localizedDescription)"
        }
    }

    /// 코멘트를 닫습니다.
    ///
    /// Sheet를 닫고 현재 코멘트를 유지합니다.
    /// 사용자가 다시 코멘트를 열 수 있도록 comment는 nil로 설정하지 않습니다.
    ///
    /// - Example:
    /// ```swift
    /// Button("닫기") {
    ///     viewModel.dismissComment()
    /// }
    /// ```
    func dismissComment() {
        showComment = false
    }

    /// 코멘트를 저장합니다. (향후 구현)
    ///
    /// 현재는 placeholder 메서드입니다.
    /// 향후 "도움이 된 코멘트" 저장 기능이 추가될 예정입니다.
    ///
    /// ## 향후 구현 예정
    /// - SaveDietCommentUseCase 추가
    /// - 저장된 코멘트 목록 화면
    /// - 저장된 코멘트 재확인 기능
    ///
    /// - Note: 현재는 호출해도 아무 동작하지 않음
    ///
    /// - Example:
    /// ```swift
    /// Button("저장") {
    ///     viewModel.saveComment()
    /// }
    /// .disabled(!viewModel.canSave)
    /// ```
    func saveComment() {
        // TODO: SaveDietCommentUseCase 구현 후 연동
        // 현재는 placeholder
        print("💾 코멘트 저장 기능은 향후 구현 예정입니다.")
    }

    /// 에러를 초기화합니다.
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
        rateLimitRetryAfter = nil
    }

    /// 새로고침 (캐시 무시하고 새로 생성)
    ///
    /// 현재 표시 중인 코멘트를 다시 생성합니다.
    /// 캐시를 무시하고 새로운 AI 분석을 요청합니다.
    ///
    /// - Parameters:
    ///   - date: 평가 대상 날짜
    ///   - mealType: 끼니 종류
    ///
    /// - Note: 구현은 향후 DietCommentRepository에 refreshComment 메서드 추가 필요
    ///
    /// - Example:
    /// ```swift
    /// Button("새로고침") {
    ///     Task {
    ///         await viewModel.refresh(for: Date(), mealType: .lunch)
    ///     }
    /// }
    /// ```
    func refresh(for date: Date, mealType: MealType?) async {
        // TODO: DietCommentRepository에 clearCache 호출 후 generateComment 실행
        // 현재는 단순히 generateComment 재호출
        await generateComment(for: date, mealType: mealType)
    }

    // MARK: - Private Helpers

    /// DietCommentError를 사용자 친화적인 메시지로 변환
    ///
    /// - Parameter error: DietCommentError
    ///
    /// - Note: Rate limit 에러의 경우 rateLimitRetryAfter 프로퍼티도 설정
    private func handleDietCommentError(_ error: DietCommentError) {
        switch error {
        case .noFoodRecords:
            errorMessage = "식단을 먼저 기록해주세요."

        case .rateLimitExceeded(let retryAfter):
            // Rate limit 정보 저장
            rateLimitRetryAfter = retryAfter

            // 사용자 친화적 메시지 생성
            let minutes = Int(retryAfter / 60)
            if minutes > 0 {
                errorMessage = "요청 한도를 초과했습니다.\n약 \(minutes)분 후에 다시 시도해주세요."
            } else {
                let seconds = Int(retryAfter)
                errorMessage = "요청 한도를 초과했습니다.\n약 \(seconds)초 후에 다시 시도해주세요."
            }

        case .networkFailure:
            errorMessage = "네트워크 연결을 확인해주세요.\n오프라인 상태에서는 AI 코멘트를 생성할 수 없습니다."

        case .invalidResponse:
            errorMessage = "AI 응답을 처리할 수 없습니다.\n잠시 후 다시 시도해주세요."

        case .apiError(let message):
            errorMessage = "AI 코멘트 생성 실패:\n\(message)"

        case .cachingFailed:
            errorMessage = "코멘트 저장에 실패했습니다.\n다시 시도해주세요."
        }
    }
}

// MARK: - Computed Properties

extension DietCommentViewModel {

    /// 에러가 있는지 여부
    var hasError: Bool {
        errorMessage != nil
    }

    /// 코멘트가 있는지 여부
    var hasComment: Bool {
        comment != nil
    }

    /// 저장 가능 여부 (향후 구현)
    var canSave: Bool {
        // TODO: SaveDietCommentUseCase 구현 후 실제 저장 가능 여부 체크
        hasComment && !isLoading
    }

    /// Rate limit 상태인지 여부
    var isRateLimited: Bool {
        rateLimitRetryAfter != nil
    }

    /// Rate limit 재시도 가능 시간 (분)
    var rateLimitRetryMinutes: Int {
        guard let retryAfter = rateLimitRetryAfter else { return 0 }
        return Int(retryAfter / 60)
    }
}

// MARK: - Learning Notes

/// ## AI Feature ViewModel Pattern
///
/// DietCommentViewModel은 AI 코멘트 생성이라는 복잡한 비동기 작업의 UI 상태를 관리합니다.
///
/// ### 주요 특징
///
/// 1. **MainActor 사용**:
///    - @MainActor 어노테이션으로 모든 메서드가 메인 스레드에서 실행됨 보장
///    - UI 업데이트가 안전하게 처리됨
///    - 💡 Java 비교: runOnUiThread()를 자동으로 호출하는 것과 유사
///
/// 2. **Published Properties**:
///    - comment: 생성된 AI 코멘트
///    - isLoading: 로딩 상태 (스피너 표시)
///    - errorMessage: 에러 메시지 (Alert 표시)
///    - rateLimitRetryAfter: Rate limit 재시도 시간 (사용자 피드백)
///    - showComment: Sheet 표시 제어
///
/// 3. **UseCase 위임**:
///    - 복잡한 비즈니스 로직은 GenerateDietCommentUseCase에 위임
///    - ViewModel은 UI 상태 관리만 집중
///    - 캐싱, Rate limiting, 에러 처리는 UseCase가 담당
///
/// 4. **에러 처리 전략**:
///    - DietCommentError를 사용자 친화적인 메시지로 변환
///    - Rate limit의 경우 재시도 가능 시간 표시
///    - 네트워크 에러의 경우 명확한 안내 메시지
///
/// ### UI Integration
///
/// **Sheet Presentation**:
/// ```swift
/// struct DailyMealView: View {
///     @StateObject var viewModel: DietCommentViewModel
///
///     var body: some View {
///         VStack {
///             // AI 코멘트 버튼
///             Button("AI 코멘트 보기") {
///                 Task {
///                     await viewModel.generateComment(
///                         for: Date(),
///                         mealType: .lunch
///                     )
///                 }
///             }
///             .disabled(viewModel.isLoading)
///         }
///         // Sheet로 코멘트 표시
///         .sheet(isPresented: $viewModel.showComment) {
///             DietCommentPopupView(viewModel: viewModel)
///         }
///         // 에러 알림
///         .alert("오류", isPresented: $viewModel.hasError) {
///             Button("확인") { viewModel.clearError() }
///         } message: {
///             Text(viewModel.errorMessage ?? "")
///         }
///     }
/// }
/// ```
///
/// **Loading State**:
/// ```swift
/// if viewModel.isLoading {
///     ProgressView("AI 분석 중...")
/// } else if let comment = viewModel.comment {
///     DietCommentCard(comment: comment)
/// }
/// ```
///
/// **Rate Limit Feedback**:
/// ```swift
/// if viewModel.isRateLimited {
///     Text("요청 한도 초과")
///     Text("\(viewModel.rateLimitRetryMinutes)분 후 재시도")
/// }
/// ```
///
/// ### Testing
///
/// ViewModel은 의존성 주입을 통해 쉽게 테스트할 수 있습니다:
///
/// ```swift
/// func testGenerateCommentSuccess() async {
///     // given
///     let mockUseCase = MockGenerateDietCommentUseCase()
///     mockUseCase.mockComment = DietComment(...)
///
///     let viewModel = DietCommentViewModel(
///         generateCommentUseCase: mockUseCase,
///         userId: UUID(),
///         userGoalType: .lose,
///         userTDEE: 2100
///     )
///
///     // when
///     await viewModel.generateComment(for: Date(), mealType: .lunch)
///
///     // then
///     XCTAssertTrue(viewModel.hasComment)
///     XCTAssertTrue(viewModel.showComment)
///     XCTAssertFalse(viewModel.isLoading)
///     XCTAssertNil(viewModel.errorMessage)
/// }
///
/// func testGenerateCommentRateLimitExceeded() async {
///     // given
///     let mockUseCase = MockGenerateDietCommentUseCase()
///     mockUseCase.shouldThrowRateLimitError = true
///
///     let viewModel = DietCommentViewModel(...)
///
///     // when
///     await viewModel.generateComment(for: Date(), mealType: .lunch)
///
///     // then
///     XCTAssertTrue(viewModel.hasError)
///     XCTAssertTrue(viewModel.isRateLimited)
///     XCTAssertGreaterThan(viewModel.rateLimitRetryAfter ?? 0, 0)
///     XCTAssertFalse(viewModel.showComment)
/// }
/// ```
///
/// ### Best Practices
///
/// 1. **MainActor for UI State**:
///    - UI 상태를 관리하는 ViewModel은 항상 @MainActor
///    - Published 프로퍼티가 메인 스레드에서 업데이트됨 보장
///
/// 2. **Clear Error Messages**:
///    - 에러를 사용자가 이해할 수 있는 한글 메시지로 변환
///    - Rate limit의 경우 재시도 가능 시간 명시
///
/// 3. **Loading State**:
///    - defer를 사용하여 isLoading이 항상 false로 복원되도록 보장
///    - 에러가 발생해도 로딩이 끝나도록 처리
///
/// 4. **Separation of Concerns**:
///    - ViewModel: UI 상태 관리
///    - UseCase: 비즈니스 로직 (캐싱, API 호출, 에러 처리)
///    - Repository: 데이터 영속성
///
/// 5. **Future-Proof Design**:
///    - saveComment() 메서드는 placeholder로 미리 정의
///    - 향후 기능 확장 시 View 수정 최소화
///
