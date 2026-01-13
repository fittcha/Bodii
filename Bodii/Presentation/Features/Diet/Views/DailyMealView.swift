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

                if viewModel.isLoading {
                    // 로딩 상태
                    ProgressView()
                        .scaleEffect(1.5)
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
                                        viewModel.deleteFoodRecord(foodRecordId)
                                    },
                                    onEditFood: { foodRecordId in
                                        // TODO: Phase 5에서 식단 수정 화면 구현
                                        print("Edit food record: \(foodRecordId)")
                                    }
                                )
                                .padding(.horizontal)
                            }

                            // 빈 상태 메시지
                            if !viewModel.hasAnyMeals {
                                emptyStateView
                                    .padding(.top, 40)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationTitle("식단")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 새로고침 버튼
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
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
        .onAppear {
            viewModel.onAppear(userId: userId, bmr: bmr, tdee: tdee)
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
                viewModel.navigateToPreviousDay()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

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

            Spacer()

            // 다음 날짜 버튼
            Button(action: {
                viewModel.navigateToNextDay()
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            // 미래 날짜는 비활성화
            .disabled(viewModel.isFuture)
            .opacity(viewModel.isFuture ? 0.3 : 1.0)
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

            Text("기록된 식단이 없습니다")
                .font(.headline)
                .foregroundColor(.primary)

            Text("'+ 음식 추가' 버튼을 눌러\n첫 식사를 기록해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    // 프리뷰용 Mock 데이터
    let mockViewModel = DailyMealViewModel(
        foodRecordService: MockFoodRecordService(),
        dailyLogRepository: MockDailyLogRepository(),
        foodRepository: MockFoodRepository()
    )

    return DailyMealView(
        viewModel: mockViewModel,
        userId: UUID(),
        bmr: 1650,
        tdee: 2310
    )
}

// MARK: - Mock Services for Preview

private class MockFoodRecordService: FoodRecordServiceProtocol {
    func addFoodRecord(userId: UUID, foodId: UUID, date: Date, mealType: MealType, quantity: Decimal, quantityUnit: QuantityUnit) async throws -> FoodRecord {
        fatalError("Mock not implemented")
    }

    func updateFoodRecord(foodRecordId: UUID, quantity: Decimal, quantityUnit: QuantityUnit, mealType: MealType) async throws -> FoodRecord {
        fatalError("Mock not implemented")
    }

    func deleteFoodRecord(foodRecordId: UUID) async throws {
        // Mock implementation
    }

    func getFoodRecords(for date: Date, userId: UUID) async throws -> [FoodRecord] {
        return []
    }

    func getFoodRecords(for date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord] {
        return []
    }
}

private class MockDailyLogRepository: DailyLogRepositoryProtocol {
    func save(_ dailyLog: DailyLog) async throws -> DailyLog {
        return dailyLog
    }

    func findByDate(_ date: Date, userId: UUID) async throws -> DailyLog? {
        return DailyLog(
            id: UUID(),
            userId: userId,
            date: date,
            totalCaloriesIn: 1500,
            totalCarbs: 200,
            totalProtein: 80,
            totalFat: 50,
            carbsRatio: 50,
            proteinRatio: 25,
            fatRatio: 25,
            bmr: 1650,
            tdee: 2310,
            netCalories: -810,
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0,
            steps: nil,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
        return try await findByDate(date, userId: userId) ?? DailyLog(
            id: UUID(),
            userId: userId,
            date: date,
            totalCaloriesIn: 0,
            totalCarbs: 0,
            totalProtein: 0,
            totalFat: 0,
            carbsRatio: nil,
            proteinRatio: nil,
            fatRatio: nil,
            bmr: bmr,
            tdee: tdee,
            netCalories: -tdee,
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0,
            steps: nil,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func findByDateRange(startDate: Date, endDate: Date, userId: UUID) async throws -> [DailyLog] {
        return []
    }

    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        return dailyLog
    }

    func delete(_ dailyLogId: UUID) async throws {
        // Mock implementation
    }
}

private class MockFoodRepository: FoodRepositoryProtocol {
    func save(_ food: Food) async throws -> Food {
        return food
    }

    func findById(_ id: UUID) async throws -> Food? {
        return nil
    }

    func findAll() async throws -> [Food] {
        return []
    }

    func search(by name: String) async throws -> [Food] {
        return []
    }

    func getRecentFoods(userId: UUID, limit: Int) async throws -> [Food] {
        return []
    }

    func getFrequentFoods(userId: UUID, limit: Int) async throws -> [Food] {
        return []
    }

    func getUserDefinedFoods(userId: UUID) async throws -> [Food] {
        return []
    }

    func update(_ food: Food) async throws -> Food {
        return food
    }

    func delete(_ foodId: UUID) async throws {
        // Mock implementation
    }
}
