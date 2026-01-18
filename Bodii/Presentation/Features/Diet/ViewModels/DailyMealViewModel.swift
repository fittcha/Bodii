//
//  DailyMealViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import Combine

/// 일일 식단 화면의 ViewModel
///
/// 특정 날짜의 식단 기록과 영양 정보를 표시하고 관리합니다.
/// 끼니별로 그룹화된 식단 기록과 일일 영양 요약 정보를 제공합니다.
///
/// - Note: ObservableObject를 준수하여 SwiftUI View와 바인딩됩니다.
/// - Note: 날짜 네비게이션(이전/다음)을 지원합니다.
///
/// - Example:
/// ```swift
/// let viewModel = DailyMealViewModel(
///     foodRecordService: foodRecordService,
///     dailyLogRepository: dailyLogRepository,
///     foodRepository: foodRepository
/// )
/// viewModel.onAppear(userId: userId, bmr: 1650, tdee: 2310)
/// ```
@MainActor
final class DailyMealViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 선택된 날짜
    @Published var selectedDate: Date = Date()

    /// 일일 영양 집계 정보
    @Published var dailyLog: DailyLog?

    /// 끼니별 식단 기록 (MealType별로 그룹화)
    @Published var mealGroups: [MealType: [FoodRecordWithFood]] = [:]

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// AI 코멘트 ViewModel (Optional)
    @Published var dietCommentViewModel: DietCommentViewModel?

    /// AI 코멘트 Sheet 표시 상태
    @Published var showAICommentSheet: Bool = false

    /// AI 코멘트 생성 중인 끼니 타입
    @Published var selectedMealTypeForComment: MealType?

    // MARK: - Private Properties

    /// 식단 기록 서비스
    private let foodRecordService: FoodRecordServiceProtocol

    /// 일일 집계 Repository
    private let dailyLogRepository: DailyLogRepositoryProtocol

    /// 음식 Repository
    private let foodRepository: FoodRepositoryProtocol

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    /// 현재 BMR (기초대사량)
    private var currentBMR: Int32 = 0

    /// 현재 TDEE (활동대사량)
    private var currentTDEE: Int32 = 0

    /// 현재 목표 타입 (감량/유지/증량)
    private var currentGoalType: GoalType = .maintain

    /// DI Container (AI comment ViewModel 생성용)
    private let diContainer: DIContainer

    // MARK: - Initialization

    /// DailyMealViewModel을 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRecordService: 식단 기록 서비스
    ///   - dailyLogRepository: 일일 집계 Repository
    ///   - foodRepository: 음식 Repository
    ///   - diContainer: DI Container (AI comment ViewModel 생성용, 기본값: shared)
    init(
        foodRecordService: FoodRecordServiceProtocol,
        dailyLogRepository: DailyLogRepositoryProtocol,
        foodRepository: FoodRepositoryProtocol,
        diContainer: DIContainer = .shared
    ) {
        self.foodRecordService = foodRecordService
        self.dailyLogRepository = dailyLogRepository
        self.foodRepository = foodRepository
        self.diContainer = diContainer
    }

    // MARK: - Public Methods

    /// 화면 진입 시 호출됩니다.
    ///
    /// 오늘 날짜의 식단 정보를 불러옵니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - bmr: 기초대사량 (kcal)
    ///   - tdee: 활동대사량 (kcal)
    ///   - goalType: 목표 타입 (감량/유지/증량, 기본값: maintain)
    func onAppear(userId: UUID, bmr: Int32, tdee: Int32, goalType: GoalType = .maintain) {
        self.currentUserId = userId
        self.currentBMR = bmr
        self.currentTDEE = tdee
        self.currentGoalType = goalType

        loadData()
    }

    /// 이전 날짜로 이동합니다.
    func navigateToPreviousDay() {
        guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else {
            return
        }

        selectedDate = previousDate
        loadData()
    }

    /// 다음 날짜로 이동합니다.
    func navigateToNextDay() {
        guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else {
            return
        }

        selectedDate = nextDate
        loadData()
    }

    /// 특정 날짜로 이동합니다.
    ///
    /// - Parameter date: 이동할 날짜
    func navigateToDate(_ date: Date) {
        selectedDate = date
        loadData()
    }

    /// 식단 기록을 삭제합니다.
    ///
    /// - Parameter foodRecordId: 삭제할 식단 기록 ID
    func deleteFoodRecord(_ foodRecordId: UUID) {
        guard currentUserId != nil else { return }

        Task {
            do {
                // 식단 기록 삭제 (DailyLog 자동 업데이트됨)
                try await foodRecordService.deleteFoodRecord(foodRecordId: foodRecordId)

                // 데이터 새로고침
                await loadData()
            } catch {
                handleError(error)
            }
        }
    }

    /// 데이터를 새로고침합니다.
    func refresh() {
        loadData()
    }

    /// AI 코멘트를 표시합니다.
    ///
    /// DietCommentViewModel을 생성하고 Sheet를 표시합니다.
    ///
    /// - Parameter mealType: 평가할 끼니 타입 (nil이면 전체 식단)
    func showAIComment(for mealType: MealType?) {
        guard let userId = currentUserId else { return }

        // DietCommentViewModel 생성
        dietCommentViewModel = diContainer.makeDietCommentViewModel(
            userId: userId,
            goalType: currentGoalType,
            tdee: Int(currentTDEE)
        )

        // 선택된 끼니 타입 저장
        selectedMealTypeForComment = mealType

        // Sheet 표시
        showAICommentSheet = true
    }

    // MARK: - Private Methods

    /// 선택된 날짜의 데이터를 불러옵니다.
    ///
    /// DailyLog와 FoodRecord를 병렬로 조회하여 성능을 최적화합니다.
    private func loadData() {
        guard let userId = currentUserId else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // DailyLog와 FoodRecord를 병렬로 조회
                async let dailyLogTask = loadDailyLog(for: selectedDate, userId: userId)
                async let foodRecordsTask = loadFoodRecordsWithFood(for: selectedDate, userId: userId)

                dailyLog = try await dailyLogTask
                let foodRecordsWithFood = try await foodRecordsTask

                // 끼니별로 그룹화
                mealGroups = groupByMealType(foodRecordsWithFood)

                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }

    /// 특정 날짜의 DailyLog를 불러옵니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Returns: DailyLog (없으면 초기값으로 생성)
    private func loadDailyLog(for date: Date, userId: UUID) async throws -> DailyLog {
        // getOrCreate를 사용하여 없으면 자동으로 생성
        return try await dailyLogRepository.getOrCreate(
            for: date,
            userId: userId,
            bmr: currentBMR,
            tdee: currentTDEE
        )
    }

    /// 특정 날짜의 FoodRecord와 Food 정보를 함께 불러옵니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Returns: FoodRecord와 Food가 결합된 목록
    private func loadFoodRecordsWithFood(for date: Date, userId: UUID) async throws -> [FoodRecordWithFood] {
        // FoodRecord 조회
        let foodRecords = try await foodRecordService.getFoodRecords(for: date, userId: userId)

        // 각 FoodRecord에 대해 Food 정보 조회
        var foodRecordsWithFood: [FoodRecordWithFood] = []

        for foodRecord in foodRecords {
            if let food = try await foodRepository.findById(foodRecord.foodId) {
                foodRecordsWithFood.append(
                    FoodRecordWithFood(foodRecord: foodRecord, food: food)
                )
            }
        }

        return foodRecordsWithFood
    }

    /// FoodRecord 목록을 끼니별로 그룹화합니다.
    ///
    /// - Parameter foodRecords: FoodRecord와 Food가 결합된 목록
    /// - Returns: MealType별로 그룹화된 딕셔너리
    private func groupByMealType(_ foodRecords: [FoodRecordWithFood]) -> [MealType: [FoodRecordWithFood]] {
        var groups: [MealType: [FoodRecordWithFood]] = [:]

        // 모든 MealType에 대해 빈 배열 초기화
        for mealType in MealType.allCases {
            groups[mealType] = []
        }

        // FoodRecord를 mealType별로 분류
        for item in foodRecords {
            groups[item.foodRecord.mealType, default: []].append(item)
        }

        return groups
    }

    /// 에러를 처리합니다.
    ///
    /// - Parameter error: 발생한 에러
    private func handleError(_ error: Error) {
        isLoading = false

        // 에러 메시지 설정
        if let repositoryError = error as? RepositoryError {
            errorMessage = repositoryError.localizedDescription
        } else if let serviceError = error as? ServiceError {
            errorMessage = serviceError.localizedDescription
        } else {
            errorMessage = "오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}

// MARK: - Computed Properties

extension DailyMealViewModel {

    /// 선택된 날짜가 오늘인지 여부
    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// 선택된 날짜가 미래인지 여부
    var isFuture: Bool {
        selectedDate > Date()
    }

    /// 표시할 날짜 문자열
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter.string(from: selectedDate)
    }

    /// 특정 끼니의 총 칼로리
    ///
    /// - Parameter mealType: 끼니 종류
    /// - Returns: 해당 끼니의 총 칼로리 (kcal)
    func totalCalories(for mealType: MealType) -> Int32 {
        guard let meals = mealGroups[mealType] else { return 0 }
        return meals.reduce(0) { $0 + $1.foodRecord.calculatedCalories }
    }

    /// 특정 끼니에 식단 기록이 있는지 여부
    ///
    /// - Parameter mealType: 끼니 종류
    /// - Returns: 식단 기록 존재 여부
    func hasMeals(for mealType: MealType) -> Bool {
        guard let meals = mealGroups[mealType] else { return false }
        return !meals.isEmpty
    }

    /// 하루 전체에 식단 기록이 있는지 여부
    var hasAnyMeals: Bool {
        return mealGroups.values.contains { !$0.isEmpty }
    }

    /// 남은 칼로리 (TDEE - 섭취 칼로리)
    var remainingCalories: Int32 {
        guard let log = dailyLog else { return 0 }
        return log.tdee - log.totalCaloriesIn
    }

    /// 칼로리 섭취율 (섭취 / TDEE * 100)
    var calorieIntakePercentage: Double {
        guard let log = dailyLog, log.tdee > 0 else { return 0 }
        return Double(log.totalCaloriesIn) / Double(log.tdee) * 100
    }
}

// MARK: - Helper Models

/// FoodRecord와 Food 정보를 함께 담는 헬퍼 모델
///
/// UI 렌더링 시 FoodRecord의 계산된 영양소와 Food의 이름을 함께 표시하기 위해 사용합니다.
struct FoodRecordWithFood: Identifiable {
    /// FoodRecord의 ID를 사용
    var id: UUID {
        foodRecord.id
    }

    /// 식단 기록
    let foodRecord: FoodRecord

    /// 음식 정보
    let food: Food
}
