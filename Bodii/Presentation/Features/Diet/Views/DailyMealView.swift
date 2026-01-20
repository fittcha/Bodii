//
//  DailyMealView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Daily Meal View
// 일일 식단 기록을 표시하는 메인 뷰
// 💡 날짜 네비게이션, 끼니별 섹션, 영양 요약 카드로 구성

import SwiftUI

// MARK: - Daily Meal View

/// 일일 식단 화면
///
/// 선택된 날짜의 식단 기록을 끼니별로 표시하고 일일 영양 요약을 제공합니다.
///
/// - Note: DailyMealViewModel을 사용하여 데이터를 관리합니다.
/// - Note: 날짜 네비게이션으로 이전/다음 날짜로 이동할 수 있습니다.
///
/// - Example:
/// ```swift
/// DailyMealView(viewModel: dailyMealViewModel, userId: userId, bmr: 1650, tdee: 2310)
/// ```
struct DailyMealView: View {

    // MARK: - Properties

    /// ViewModel
    @ObservedObject var viewModel: DailyMealViewModel

    /// 사용자 ID
    let userId: UUID

    /// 기초대사량 (kcal)
    let bmr: Int32

    /// 활동대사량 (kcal)
    let tdee: Int32

    /// 음식 추가 콜백 (끼니 타입 전달)
    let onAddFood: ((MealType) -> Void)?

    // MARK: - State

    /// 성공 토스트 메시지
    @State private var successToastMessage: String?

    /// 정보 토스트 메시지
    @State private var infoToastMessage: String?

    // MARK: - Initialization

    init(
        viewModel: DailyMealViewModel,
        userId: UUID,
        bmr: Int32,
        tdee: Int32,
        onAddFood: ((MealType) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.userId = userId
        self.bmr = bmr
        self.tdee = tdee
        self.onAddFood = onAddFood
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 📚 학습 포인트: Background Color
            // iOS 디자인 가이드에 따른 시스템 배경색 사용
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            if viewModel.isLoading {
                // 로딩 상태 (개선된 애니메이션)
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

                    Text("식단 불러오는 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("식단 불러오는 중")
                .transition(.opacity)
            } else {
                // 메인 컨텐츠
                ScrollView {
                    VStack(spacing: 16) {
                        // 날짜 헤더
                        dateHeaderView

                        // 일일 영양 요약 카드
                        if let dailyLog = viewModel.dailyLog {
                            NutritionSummaryCard(
                                dailyLog: dailyLog,
                                remainingCalories: viewModel.remainingCalories,
                                calorieIntakePercentage: viewModel.calorieIntakePercentage
                            )
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                        }

                        // 끼니 섹션들
                        ForEach(MealType.allCases) { mealType in
                            MealSectionView(
                                mealType: mealType,
                                meals: viewModel.mealGroups[mealType] ?? [],
                                totalCalories: viewModel.totalCalories(for: mealType),
                                onAddFood: {
                                    onAddFood?(mealType)
                                },
                                onDeleteFood: { foodRecordId in
                                    Task {
                                        await deleteFoodWithFeedback(foodRecordId)
                                    }
                                },
                                onEditFood: { foodRecordId in
                                    // TODO: Phase 5에서 식단 수정 화면 구현
                                    print("Edit food record: \(foodRecordId)")
                                },
                                onGetAIComment: {
                                    viewModel.showAIComment(for: mealType)
                                }
                            )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 빈 상태 메시지
                        if !viewModel.hasAnyMeals {
                            emptyStateView
                                .padding(.top, 40)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.vertical)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.mealGroups)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.hasAnyMeals)
            }
        }
        .navigationTitle("식단")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 새로고침 버튼
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await refreshWithFeedback()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .accessibilityLabel("새로고침")
                        .accessibilityHint("식단 데이터를 다시 불러옵니다")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .successToast(message: $successToastMessage)
        .infoToast(message: $infoToastMessage)
        .sheet(isPresented: $viewModel.showAICommentSheet) {
            // AI 코멘트 팝업
            if let dietCommentViewModel = viewModel.dietCommentViewModel {
                DietCommentPopupView(
                    viewModel: dietCommentViewModel,
                    date: viewModel.selectedDate,
                    mealType: viewModel.selectedMealTypeForComment
                )
            }
        }
        .onAppear {
            viewModel.onAppear(userId: userId, bmr: bmr, tdee: tdee)
        }
    }

    // MARK: - Actions

    /// 음식 삭제 및 피드백 표시
    ///
    /// - Parameter foodRecordId: 삭제할 음식 기록 ID
    @MainActor
    private func deleteFoodWithFeedback(_ foodRecordId: UUID) async {
        await viewModel.deleteFoodRecord(foodRecordId)
        if viewModel.errorMessage == nil {
            successToastMessage = "식단에서 삭제되었습니다"
        }
    }

    /// 새로고침 및 피드백 표시
    @MainActor
    private func refreshWithFeedback() async {
        await viewModel.refresh()
        if viewModel.errorMessage == nil {
            infoToastMessage = "데이터를 새로고침했습니다"
        }
    }

    // MARK: - Subviews

    /// 날짜 헤더 뷰
    ///
    /// 현재 선택된 날짜와 이전/다음 날짜 네비게이션 버튼을 표시합니다.
    private var dateHeaderView: some View {
        HStack {
            // 이전 날짜 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.navigateToPreviousDay()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("이전 날짜")
            .accessibilityHint("전날 식단 보기")

            Spacer()

            // 날짜 표시
            VStack(spacing: 4) {
                Text(viewModel.dateString)
                    .font(.headline)
                    .foregroundColor(.primary)

                if viewModel.isToday {
                    Text("오늘")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(viewModel.isToday ? "오늘, \(viewModel.dateString)" : viewModel.dateString)

            Spacer()

            // 다음 날짜 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewModel.navigateToNextDay()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            // 미래 날짜는 비활성화
            .disabled(viewModel.isFuture)
            .opacity(viewModel.isFuture ? 0.3 : 1.0)
            .accessibilityLabel("다음 날짜")
            .accessibilityHint(viewModel.isFuture ? "미래 날짜는 볼 수 없습니다" : "다음 날 식단 보기")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    /// 빈 상태 뷰
    ///
    /// 식단 기록이 없을 때 표시되는 안내 메시지입니다.
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text("기록된 식단이 없습니다")
                .font(.headline)
                .foregroundColor(.primary)

            Text("'+ 음식 추가' 버튼을 눌러\n첫 식사를 기록해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("기록된 식단이 없습니다. 플러스 음식 추가 버튼을 눌러 첫 식사를 기록해보세요")
    }
}

// MARK: - Preview

// 📚 학습 포인트: Core Data/UseCase 의존성 Preview 제한
// Mock 클래스가 프로토콜을 준수하지 않거나 final class 상속 불가
// TODO: Phase 7에서 Preview용 Mock 구현 완성

#Preview("Placeholder") {
    Text("DailyMealView Preview")
        .font(.headline)
        .padding()
}
