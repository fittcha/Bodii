//
//  DietCommentPopupView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Modal Sheet Presentation Pattern
// AI 식단 코멘트를 Sheet로 표시하는 팝업 뷰
// 💡 Java 비교: Android의 BottomSheetDialogFragment와 유사

import SwiftUI

// MARK: - Diet Comment Popup View

/// 식단 AI 코멘트 팝업 뷰
///
/// DietCommentCard를 Sheet 형태로 표시하는 래퍼 뷰입니다.
/// ViewModel의 상태에 따라 로딩, 에러, 성공 상태를 자동으로 처리합니다.
///
/// **주요 기능:**
/// - Sheet 형태로 AI 코멘트 표시
/// - 로딩 상태 자동 처리 (스피너 표시)
/// - 에러 상태 자동 처리 (에러 메시지 + 재시도 버튼)
/// - 닫기 버튼
/// - 저장 버튼 (향후 구현)
///
/// **사용 예시:**
/// ```swift
/// .sheet(isPresented: $viewModel.showComment) {
///     DietCommentPopupView(
///         viewModel: viewModel,
///         date: selectedDate,
///         mealType: .lunch
///     )
/// }
/// ```
struct DietCommentPopupView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @ObservedObject for ViewModel
    // ViewModel의 @Published 속성 변화를 관찰하여 UI 자동 업데이트
    // 💡 Java 비교: ViewModel + LiveData.observe()와 유사

    /// 식단 코멘트 ViewModel
    @ObservedObject var viewModel: DietCommentViewModel

    /// 평가 대상 날짜
    let date: Date

    /// 평가 대상 끼니 (nil이면 전체 식단)
    let mealType: MealType?

    // MARK: - Environment

    // 📚 학습 포인트: Environment Dismiss
    // SwiftUI에서 Sheet를 닫는 표준 방법
    // 💡 Java 비교: Fragment.dismiss() 또는 Activity.finish()와 유사

    /// 모달 닫기 액션
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    /// DietCommentPopupView 초기화
    ///
    /// - Parameters:
    ///   - viewModel: 식단 코멘트 ViewModel
    ///   - date: 평가 대상 날짜
    ///   - mealType: 평가 대상 끼니 (nil이면 전체 식단)
    init(
        viewModel: DietCommentViewModel,
        date: Date,
        mealType: MealType? = nil
    ) {
        self.viewModel = viewModel
        self.date = date
        self.mealType = mealType
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: NavigationStack in Sheet
        // Sheet 안에서도 NavigationBar를 사용하기 위해 NavigationStack 필요
        // 💡 Java 비교: BottomSheetDialog with Toolbar와 유사
        NavigationStack {
            VStack(spacing: 0) {
                // AI 코멘트 카드
                DietCommentCard(
                    comment: viewModel.comment,
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    onDismiss: {
                        viewModel.dismissComment()
                        dismiss()
                    },
                    onRetry: {
                        Task {
                            await viewModel.generateComment(for: date, mealType: mealType)
                        }
                    }
                )

                // 저장 버튼 (향후 구현)
                if viewModel.hasComment && !viewModel.isLoading {
                    saveButtonSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 왼쪽: 닫기 버튼
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        viewModel.dismissComment()
                        dismiss()
                    }
                }

                // 오른쪽: 새로고침 버튼 (코멘트가 있을 때만)
                if viewModel.hasComment && !viewModel.isLoading {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await viewModel.refresh(for: date, mealType: mealType)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
        }
        // 📚 학습 포인트: Task with onAppear
        // View가 나타날 때 자동으로 코멘트 생성 시작
        // 💡 Java 비교: onCreate() 또는 onViewCreated()에서 데이터 로드
        .task {
            // 코멘트가 없으면 자동으로 생성 시작
            if viewModel.comment == nil {
                await viewModel.generateComment(for: date, mealType: mealType)
            }
        }
        // 에러 알림 (네트워크 에러, Rate limit 등)
        .alert("오류", isPresented: .constant(viewModel.hasError && !viewModel.isLoading)) {
            // 확인 버튼
            Button("확인") {
                viewModel.clearError()
            }

            // Rate limit이 아닌 경우 재시도 버튼
            if !viewModel.isRateLimited {
                Button("재시도") {
                    Task {
                        await viewModel.generateComment(for: date, mealType: mealType)
                    }
                }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Subviews

    /// 저장 버튼 섹션
    ///
    /// 향후 "도움이 된 코멘트" 저장 기능을 위한 버튼입니다.
    /// 현재는 placeholder로, 실제 저장 기능은 향후 구현 예정입니다.
    ///
    /// - Note: SaveDietCommentUseCase 구현 후 활성화 예정
    private var saveButtonSection: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // 나중에 보기 버튼 (향후 구현)
                Button {
                    viewModel.saveComment()
                    // TODO: 저장 성공 시 토스트 메시지 표시
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bookmark")
                            .font(.subheadline)

                        Text("나중에 보기")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.3))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1.0 : 0.5)

                // 확인 버튼
                Button {
                    viewModel.dismissComment()
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.subheadline)

                        Text("확인")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview

// 📚 학습 포인트: Preview with Mock Data
// 다양한 상태를 미리 보며 개발 (성공/로딩/에러)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Loading State") {
    // Mock UseCase for loading state
    let mockUseCase = MockGenerateDietCommentUseCase()
    mockUseCase.shouldDelay = true

    let viewModel = DietCommentViewModel(
        generateCommentUseCase: mockUseCase,
        userId: UUID(),
        userGoalType: .lose,
        userTDEE: 2100
    )

    // 로딩 시작
    Task {
        await viewModel.generateComment(for: Date(), mealType: .lunch)
    }

    return DietCommentPopupView(
        viewModel: viewModel,
        date: Date(),
        mealType: .lunch
    )
}

#Preview("Success State") {
    // Mock UseCase for success state
    let mockUseCase = MockGenerateDietCommentUseCase()
    mockUseCase.mockComment = DietComment(
        id: UUID(),
        userId: UUID(),
        date: Date(),
        mealType: .lunch,
        goodPoints: [
            "단백질 섭취가 충분합니다",
            "채소 섭취가 균형있어요",
            "칼로리가 목표 범위에 있습니다"
        ],
        improvements: [
            "과일 섭취를 조금 더 늘려보세요",
            "수분 섭취를 충분히 해주세요"
        ],
        summary: "전반적으로 매우 균형잡힌 식단입니다. 영양소 비율이 목표에 잘 맞고 있어요!",
        score: 9,
        generatedAt: Date()
    )

    let viewModel = DietCommentViewModel(
        generateCommentUseCase: mockUseCase,
        userId: UUID(),
        userGoalType: .lose,
        userTDEE: 2100
    )

    // 코멘트 미리 설정
    viewModel.comment = mockUseCase.mockComment
    viewModel.showComment = true

    return DietCommentPopupView(
        viewModel: viewModel,
        date: Date(),
        mealType: .lunch
    )
}

#Preview("Error State") {
    // Mock UseCase for error state
    let mockUseCase = MockGenerateDietCommentUseCase()
    mockUseCase.shouldThrowNetworkError = true

    let viewModel = DietCommentViewModel(
        generateCommentUseCase: mockUseCase,
        userId: UUID(),
        userGoalType: .lose,
        userTDEE: 2100
    )

    return DietCommentPopupView(
        viewModel: viewModel,
        date: Date(),
        mealType: .lunch
    )
}

#Preview("Rate Limit Error") {
    // Mock UseCase for rate limit error
    let mockUseCase = MockGenerateDietCommentUseCase()
    mockUseCase.shouldThrowRateLimitError = true

    let viewModel = DietCommentViewModel(
        generateCommentUseCase: mockUseCase,
        userId: UUID(),
        userGoalType: .lose,
        userTDEE: 2100
    )

    return DietCommentPopupView(
        viewModel: viewModel,
        date: Date(),
        mealType: .lunch
    )
}

// MARK: - Mock Use Case

// 📚 학습 포인트: Mock for Preview
// Preview에서 사용할 Mock UseCase
// 💡 Java 비교: Mockito의 Mock 객체와 유사

/// Mock GenerateDietCommentUseCase for Preview
private class MockGenerateDietCommentUseCase: GenerateDietCommentUseCase {

    /// Mock 코멘트 반환값
    var mockComment: DietComment?

    /// 지연 시뮬레이션 (로딩 상태 테스트)
    var shouldDelay: Bool = false

    /// 네트워크 에러 시뮬레이션
    var shouldThrowNetworkError: Bool = false

    /// Rate limit 에러 시뮬레이션
    var shouldThrowRateLimitError: Bool = false

    init() {
        // 더미 의존성으로 초기화
        let dummyRepository = DummyDietCommentRepository()
        let dummyGeminiService = DummyGeminiService()
        let dummyFoodRecordRepository = DummyFoodRecordRepository()

        super.init(
            dietCommentRepository: dummyRepository,
            geminiService: dummyGeminiService,
            foodRecordRepository: dummyFoodRecordRepository
        )
    }

    override func execute(
        userId: UUID,
        date: Date,
        mealType: MealType?,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment {
        // 지연 시뮬레이션
        if shouldDelay {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        }

        // 에러 시뮬레이션
        if shouldThrowNetworkError {
            throw DietCommentError.networkFailure
        }

        if shouldThrowRateLimitError {
            throw DietCommentError.rateLimitExceeded(retryAfter: 300) // 5 minutes
        }

        // Mock 코멘트 반환
        if let mockComment = mockComment {
            return mockComment
        }

        // 기본 Mock 코멘트
        return DietComment(
            id: UUID(),
            userId: userId,
            date: date,
            mealType: mealType,
            goodPoints: ["단백질 섭취가 좋습니다"],
            improvements: ["채소를 더 드세요"],
            summary: "괜찮은 식단입니다",
            score: 7,
            generatedAt: Date()
        )
    }
}

// MARK: - Dummy Dependencies

/// Dummy DietCommentRepository for Mock UseCase
private class DummyDietCommentRepository: DietCommentRepository {
    func generateComment(userId: UUID, date: Date, mealType: MealType?, goalType: GoalType, tdee: Int) async throws -> DietComment {
        fatalError("Not implemented - use MockGenerateDietCommentUseCase instead")
    }

    func getCachedComment(userId: UUID, date: Date, mealType: MealType?) async -> DietComment? {
        return nil
    }

    func saveComment(_ comment: DietComment) async throws {
        // No-op
    }

    func clearCache(userId: UUID, date: Date, mealType: MealType?) async {
        // No-op
    }

    func clearAllCache() async {
        // No-op
    }
}

/// Dummy GeminiService for Mock UseCase
private class DummyGeminiService: GeminiServiceProtocol {
    func generateDietComment(
        foodRecords: [FoodRecord],
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment {
        fatalError("Not implemented - use MockGenerateDietCommentUseCase instead")
    }
}

/// Dummy FoodRecordRepository for Mock UseCase
private class DummyFoodRecordRepository: FoodRecordRepositoryProtocol {
    func addFoodRecord(userId: UUID, food: Food, mealType: MealType, servingSize: Double, date: Date) throws -> FoodRecord {
        fatalError("Not implemented")
    }

    func updateFoodRecord(_ record: FoodRecord) throws {
        fatalError("Not implemented")
    }

    func deleteFoodRecord(_ record: FoodRecord) throws {
        fatalError("Not implemented")
    }

    func fetchFoodRecords(userId: UUID, date: Date, mealType: MealType?) -> [FoodRecord] {
        return []
    }

    func fetchRecentFoodRecords(userId: UUID, limit: Int) -> [FoodRecord] {
        return []
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: DietCommentPopupView 사용법
///
/// **기본 사용:**
/// ```swift
/// struct DailyMealView: View {
///     @StateObject var dietCommentViewModel: DietCommentViewModel
///     @State private var selectedDate = Date()
///     @State private var selectedMealType: MealType? = .lunch
///
///     var body: some View {
///         VStack {
///             // AI 코멘트 보기 버튼
///             Button("AI 코멘트 보기") {
///                 dietCommentViewModel.showComment = true
///             }
///         }
///         // Sheet로 팝업 표시
///         .sheet(isPresented: $dietCommentViewModel.showComment) {
///             DietCommentPopupView(
///                 viewModel: dietCommentViewModel,
///                 date: selectedDate,
///                 mealType: selectedMealType
///             )
///         }
///     }
/// }
/// ```
///
/// **전체 식단 평가:**
/// ```swift
/// // mealType을 nil로 설정하면 하루 전체 식단 평가
/// DietCommentPopupView(
///     viewModel: viewModel,
///     date: Date(),
///     mealType: nil
/// )
/// ```
///
/// **주요 기능:**
/// 1. **자동 코멘트 생성**: View가 나타나면 자동으로 AI 코멘트 생성 시작
/// 2. **로딩 상태**: 스피너와 함께 로딩 메시지 표시
/// 3. **에러 처리**: 네트워크 에러, Rate limit 등을 사용자 친화적으로 표시
/// 4. **재시도 기능**: 에러 발생 시 재시도 버튼 제공
/// 5. **새로고침**: 코멘트가 마음에 들지 않으면 새로고침 가능
/// 6. **저장 기능**: 도움이 된 코멘트를 나중에 보기 위해 저장 (향후 구현)
///
/// **ViewModel 상태:**
/// - `comment`: 생성된 AI 코멘트
/// - `isLoading`: 로딩 중 여부
/// - `errorMessage`: 에러 메시지
/// - `rateLimitRetryAfter`: Rate limit 재시도 시간
/// - `showComment`: Sheet 표시 여부
///
/// **에러 처리:**
/// - **네트워크 에러**: "네트워크 연결을 확인해주세요" + 재시도 버튼
/// - **Rate Limit**: "N분 후 다시 시도해주세요" + 확인 버튼
/// - **기타 에러**: 에러 메시지 + 재시도 버튼
///
/// **💡 Android 비교:**
/// - Android: BottomSheetDialogFragment + ViewModel + LiveData
/// - SwiftUI: .sheet() + @ObservedObject ViewModel + @Published
/// - Android: Fragment lifecycle (onCreate, onViewCreated)
/// - SwiftUI: View lifecycle (.task, .onAppear)
/// - Android: Dialog dismiss()
/// - SwiftUI: @Environment(\.dismiss)
///
