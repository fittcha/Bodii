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
        // 📚 학습 포인트: Context-Aware Alert Titles
        // 에러 종류에 따라 다른 알림 타이틀 표시
        .alert(alertTitle, isPresented: .constant(viewModel.hasError && !viewModel.isLoading)) {
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

    /// 알림 타이틀 (에러 종류에 따라 다른 제목)
    ///
    /// 에러 메시지를 분석하여 적절한 알림 제목을 반환합니다.
    /// - 오프라인 에러: "네트워크 연결 필요"
    /// - Rate limit 에러: "요청 한도 초과"
    /// - 기타 에러: "오류"
    private var alertTitle: String {
        if isOfflineError {
            return "네트워크 연결 필요"
        } else if viewModel.isRateLimited {
            return "요청 한도 초과"
        } else {
            return "오류"
        }
    }

    /// 오프라인 에러인지 여부
    private var isOfflineError: Bool {
        viewModel.errorMessage?.contains("네트워크 연결") == true ||
        viewModel.errorMessage?.contains("오프라인") == true
    }

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

// 📚 학습 포인트: Core Data/UseCase 의존성 Preview 제한
// Mock 클래스가 final class (GenerateDietCommentUseCase)를 상속할 수 없음
// 프로토콜 준수 문제로 Dummy 클래스도 사용 불가
// TODO: Phase 7에서 Preview용 Mock 구현 완성

#Preview("Placeholder") {
    Text("DietCommentPopupView Preview")
        .font(.headline)
        .padding()
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
