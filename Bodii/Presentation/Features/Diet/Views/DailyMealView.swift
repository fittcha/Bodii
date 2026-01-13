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

    // MARK: - State

    /// 음식 추가 시트 표시 여부
    @State private var showingAddFoodSheet = false

    /// 선택된 끼니 타입
    @State private var selectedMealType: MealType?

    // MARK: - Body

    var body: some View {
        NavigationView {
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
                                NutritionSummaryCardView(
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
                                        selectedMealType = mealType
                                        showingAddFoodSheet = true
                                    },
                                    onDeleteFood: { foodRecordId in
                                        viewModel.deleteFoodRecord(foodRecordId)
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
            .sheet(isPresented: $showingAddFoodSheet) {
                // 음식 추가 시트 (Phase 4에서 구현)
                Text("음식 추가 화면")
                    .font(.title)
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

// MARK: - Nutrition Summary Card View

/// 일일 영양 요약 카드
///
/// 총 섭취 칼로리, 남은 칼로리, 매크로 영양소 비율을 표시합니다.
///
/// - Note: DailyLog의 데이터를 기반으로 렌더링됩니다.
private struct NutritionSummaryCardView: View {

    // MARK: - Properties

    let dailyLog: DailyLog
    let remainingCalories: Int32
    let calorieIntakePercentage: Double

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 칼로리 섹션
            caloriesSection

            Divider()

            // 매크로 영양소 섹션
            macrosSection
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// 칼로리 섹션
    private var caloriesSection: some View {
        VStack(spacing: 12) {
            // 제목
            Text("일일 칼로리")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // 칼로리 표시
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(dailyLog.totalCaloriesIn)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)

                Text("/ \(dailyLog.tdee) kcal")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            // 진행 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)

                    // 진행률
                    Rectangle()
                        .fill(calorieColor)
                        .frame(
                            width: min(
                                geometry.size.width * CGFloat(calorieIntakePercentage / 100),
                                geometry.size.width
                            ),
                            height: 8
                        )
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)

            // 남은 칼로리
            HStack {
                Text("남은 칼로리")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(remainingCalories) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(remainingCalories >= 0 ? .green : .red)
            }
        }
    }

    /// 매크로 영양소 섹션
    private var macrosSection: some View {
        VStack(spacing: 8) {
            // 제목
            Text("매크로 영양소")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 영양소 목록
            HStack(spacing: 16) {
                macroItem(
                    name: "탄수화물",
                    amount: dailyLog.totalCarbs,
                    ratio: dailyLog.carbsRatio,
                    color: .blue
                )

                macroItem(
                    name: "단백질",
                    amount: dailyLog.totalProtein,
                    ratio: dailyLog.proteinRatio,
                    color: .orange
                )

                macroItem(
                    name: "지방",
                    amount: dailyLog.totalFat,
                    ratio: dailyLog.fatRatio,
                    color: .purple
                )
            }
        }
    }

    /// 매크로 영양소 아이템
    private func macroItem(name: String, amount: Decimal, ratio: Decimal?, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(formattedDecimal(amount))g")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)

            if let ratio = ratio {
                Text("\(formattedDecimal(ratio))%")
                    .font(.caption2)
                    .foregroundColor(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    /// 칼로리 진행률에 따른 색상
    private var calorieColor: Color {
        if calorieIntakePercentage < 50 {
            return .blue
        } else if calorieIntakePercentage < 90 {
            return .green
        } else if calorieIntakePercentage <= 110 {
            return .orange
        } else {
            return .red
        }
    }

    /// Decimal 값을 포맷팅
    private func formattedDecimal(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter.string(from: nsDecimal) ?? "0"
    }
}

// MARK: - Meal Section View

/// 끼니 섹션 뷰
///
/// 특정 끼니(아침, 점심, 저녁, 간식)의 식단 기록을 표시합니다.
///
/// - Note: 음식 추가 버튼과 식단 기록 목록을 포함합니다.
private struct MealSectionView: View {

    // MARK: - Properties

    let mealType: MealType
    let meals: [FoodRecordWithFood]
    let totalCalories: Int32
    let onAddFood: () -> Void
    let onDeleteFood: (UUID) -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                // 끼니 이름
                Text(mealType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // 총 칼로리
                if !meals.isEmpty {
                    Text("\(totalCalories) kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // 음식 추가 버튼
                Button(action: onAddFood) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(Color(.systemBackground))

            // 식단 기록 목록
            if meals.isEmpty {
                // 빈 상태
                Text("기록된 음식이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
            } else {
                // 식단 목록
                ForEach(meals) { item in
                    FoodRecordRowView(
                        foodRecord: item.foodRecord,
                        food: item.food,
                        onDelete: {
                            onDeleteFood(item.foodRecord.id)
                        }
                    )
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Food Record Row View

/// 식단 기록 행 뷰
///
/// 개별 음식 기록을 표시하고 삭제 기능을 제공합니다.
///
/// - Note: 음식 이름, 섭취량, 칼로리를 표시합니다.
private struct FoodRecordRowView: View {

    // MARK: - Properties

    let foodRecord: FoodRecord
    let food: Food
    let onDelete: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // 음식 이름
                Text(food.name)
                    .font(.body)
                    .foregroundColor(.primary)

                // 섭취량 정보
                Text(quantityText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 칼로리
            Text("\(foodRecord.calculatedCalories) kcal")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    /// 섭취량 텍스트
    private var quantityText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1

        let quantityString = formatter.string(from: foodRecord.quantity as NSDecimalNumber) ?? "0"

        switch foodRecord.quantityUnit {
        case .serving:
            return "\(quantityString)인분"
        case .grams:
            return "\(quantityString)g"
        }
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
