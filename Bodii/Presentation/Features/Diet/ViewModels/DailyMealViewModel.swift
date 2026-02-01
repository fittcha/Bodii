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

    /// 일일 전체 식단 AI 코멘트 (탭 상단 카드용)
    @Published var dailyComment: DietComment?

    /// 일일 코멘트 로딩 상태
    @Published var isDailyCommentLoading: Bool = false

    /// 일일 코멘트 에러 메시지
    @Published var dailyCommentError: String?

    // MARK: - Private Properties

    /// 식단 기록 서비스
    private let foodRecordService: FoodRecordServiceProtocol

    /// 일일 집계 Repository
    private let dailyLogRepository: DailyLogRepository

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

    /// 현재 목표 섭취 칼로리
    private var currentTargetCalories: Int = 0

    /// AI 식단 코멘트 생성 UseCase
    private let generateDietCommentUseCase: GenerateDietCommentUseCase

    /// Goal Repository (목표 칼로리 조회용)
    private let goalRepository: GoalRepositoryProtocol

    /// DI Container (AI comment ViewModel 생성용)
    private let diContainer: DIContainer

    // MARK: - Initialization

    /// DailyMealViewModel을 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodRecordService: 식단 기록 서비스
    ///   - dailyLogRepository: 일일 집계 Repository
    ///   - foodRepository: 음식 Repository
    ///   - generateDietCommentUseCase: AI 식단 코멘트 생성 UseCase
    ///   - diContainer: DI Container (AI comment ViewModel 생성용, 기본값: shared)
    init(
        foodRecordService: FoodRecordServiceProtocol,
        dailyLogRepository: DailyLogRepository,
        foodRepository: FoodRepositoryProtocol,
        generateDietCommentUseCase: GenerateDietCommentUseCase,
        goalRepository: GoalRepositoryProtocol,
        diContainer: DIContainer = .shared
    ) {
        self.foodRecordService = foodRecordService
        self.dailyLogRepository = dailyLogRepository
        self.foodRepository = foodRepository
        self.generateDietCommentUseCase = generateDietCommentUseCase
        self.goalRepository = goalRepository
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

        // 목표 칼로리 로드
        Task {
            await loadTargetCalories()
        }

        loadData()

        // 저장된 AI 일일 총평 로드 (캐시 → Core Data)
        loadStoredDailyComment()
    }

    /// 이전 날짜로 이동합니다.
    func navigateToPreviousDay() {
        guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else {
            return
        }

        selectedDate = previousDate
        dailyComment = nil
        dailyCommentError = nil
        loadData()
        loadStoredDailyComment()
    }

    /// 다음 날짜로 이동합니다.
    func navigateToNextDay() {
        guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else {
            return
        }

        selectedDate = nextDate
        dailyComment = nil
        dailyCommentError = nil
        loadData()
        loadStoredDailyComment()
    }

    /// 특정 날짜로 이동합니다.
    ///
    /// - Parameter date: 이동할 날짜
    func navigateToDate(_ date: Date) {
        selectedDate = date
        dailyComment = nil
        dailyCommentError = nil
        loadData()
        loadStoredDailyComment()
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

                // 데이터 새로고침 + AI 코멘트 재생성
                loadData()
                generateDailyComment()
            } catch {
                handleError(error)
            }
        }
    }

    /// 데이터를 새로고침합니다 (수동 새로고침 버튼용).
    func refresh() {
        loadData()
    }

    /// 식단 변경 후 호출 — 데이터 새로고침 + AI 코멘트 재생성
    func refreshAfterDietChange() {
        loadData()
        generateDailyComment()
    }

    /// AI 코멘트를 표시합니다.
    ///
    /// DietCommentViewModel을 생성하고 Sheet를 표시합니다.
    ///
    /// - Parameter mealType: 평가할 끼니 타입 (nil이면 전체 식단)
    func showAIComment(for mealType: MealType?) {
        guard let userId = currentUserId else { return }

        let targetCal = currentTargetCalories > 0 ? currentTargetCalories : Int(currentTDEE)
        dietCommentViewModel = diContainer.makeDietCommentViewModel(
            userId: userId,
            goalType: currentGoalType,
            tdee: Int(currentTDEE),
            targetCalories: targetCal
        )

        selectedMealTypeForComment = mealType
        showAICommentSheet = true
    }

    /// 일일 전체 식단 AI 코멘트를 자동 생성합니다.
    ///
    /// 식단 추가/수정/삭제 후 호출되어 오늘의 전체 식단(아침/점심/저녁/간식)을
    /// 종합 분석한 점수와 총평을 생성합니다.
    func generateDailyComment() {
        guard let userId = currentUserId else { return }
        guard hasAnyMeals else {
            dailyComment = nil
            dailyCommentError = nil
            return
        }

        isDailyCommentLoading = true
        dailyCommentError = nil

        Task {
            do {
                let targetCal = currentTargetCalories > 0 ? currentTargetCalories : Int(currentTDEE)
                let comment = try await generateDietCommentUseCase.executeIgnoringCache(
                    userId: userId,
                    date: selectedDate,
                    mealType: nil,
                    goalType: currentGoalType,
                    tdee: Int(currentTDEE),
                    targetCalories: targetCal
                )
                dailyComment = comment
                isDailyCommentLoading = false
            } catch let error as DietCommentError {
                isDailyCommentLoading = false
                switch error {
                case .noFoodRecords:
                    dailyComment = nil
                case .rateLimitExceeded:
                    dailyCommentError = "요청 한도 초과. 잠시 후 다시 시도해주세요."
                case .networkFailure:
                    dailyCommentError = "네트워크 연결을 확인해주세요."
                default:
                    dailyCommentError = "AI 분석을 불러올 수 없습니다."
                }
            } catch {
                isDailyCommentLoading = false
                dailyCommentError = "AI 분석을 불러올 수 없습니다."
            }
        }
    }

    /// 저장된 일일 AI 코멘트를 로드합니다 (API 호출 없음).
    ///
    /// 날짜 변경 시 호출되어 L1(메모리) 또는 L2(Core Data)에서
    /// 기존 저장된 코멘트를 불러옵니다.
    private func loadStoredDailyComment() {
        guard let userId = currentUserId else { return }

        Task {
            let stored = await generateDietCommentUseCase.loadCachedOrPersisted(
                userId: userId,
                date: selectedDate
            )
            dailyComment = stored
        }
    }

    // MARK: - Private Methods

    /// Goal에서 목표 섭취 칼로리를 불러옵니다.
    private func loadTargetCalories() async {
        do {
            if let activeGoal = try await goalRepository.fetchActiveGoal(),
               activeGoal.dailyCalorieTarget > 0 {
                currentTargetCalories = Int(activeGoal.dailyCalorieTarget)
            }
        } catch {
            // 목표 조회 실패 시 TDEE를 fallback으로 사용
            currentTargetCalories = Int(currentTDEE)
        }
    }

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

                // 식단 기록이 있고 AI 총평이 아직 없으면 자동 생성
                if hasAnyMeals && dailyComment == nil && !isDailyCommentLoading {
                    generateDailyComment()
                }
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
            // FoodRecord는 food relationship을 가짐 (Core Data)
            if let food = foodRecord.food {
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
        // mealType은 Int16이므로 MealType enum으로 변환
        for item in foodRecords {
            if let mealType = MealType(rawValue: item.foodRecord.mealType) {
                groups[mealType, default: []].append(item)
            }
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

    /// foodRecordId로 FoodRecordWithFood를 찾습니다.
    ///
    /// - Parameter foodRecordId: 식단 기록 ID
    /// - Returns: 해당하는 FoodRecordWithFood (없으면 nil)
    func findFoodRecordWithFood(by foodRecordId: UUID) -> FoodRecordWithFood? {
        for items in mealGroups.values {
            if let item = items.first(where: { $0.foodRecord.id == foodRecordId }) {
                return item
            }
        }
        return nil
    }

    /// 표시용 목표 칼로리 (목표 섭취량 > 0이면 목표 섭취량, 아니면 TDEE)
    var displayTargetCalories: Int32 {
        if currentTargetCalories > 0 {
            return Int32(currentTargetCalories)
        }
        return dailyLog?.tdee ?? currentTDEE
    }

    /// 남은 칼로리 (목표 섭취량 - 섭취 칼로리)
    var remainingCalories: Int32 {
        guard let log = dailyLog else { return 0 }
        return displayTargetCalories - log.totalCaloriesIn
    }

    /// 칼로리 섭취율 (섭취 / 목표 섭취량 * 100)
    var calorieIntakePercentage: Double {
        guard let log = dailyLog, displayTargetCalories > 0 else { return 0 }
        return Double(log.totalCaloriesIn) / Double(displayTargetCalories) * 100
    }
}

// MARK: - Helper Models

/// FoodRecord와 Food 정보를 함께 담는 헬퍼 모델
///
/// UI 렌더링 시 FoodRecord의 계산된 영양소와 Food의 이름을 함께 표시하기 위해 사용합니다.
struct FoodRecordWithFood: Identifiable, Equatable {
    /// FoodRecord의 ID를 사용 (Core Data의 id는 optional)
    var id: UUID {
        foodRecord.id ?? UUID()
    }

    /// 식단 기록
    let foodRecord: FoodRecord

    /// 음식 정보
    let food: Food

    // MARK: - Equatable

    static func == (lhs: FoodRecordWithFood, rhs: FoodRecordWithFood) -> Bool {
        lhs.id == rhs.id
    }
}
