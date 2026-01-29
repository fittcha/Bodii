//
//  PhotoRecognitionViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Photo Recognition Flow Orchestration
// 사진 인식 워크플로우를 관리하는 ViewModel
// 💡 Java 비교: Presenter/ViewModel in MVP/MVVM pattern

import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

/// 사진 인식 워크플로우 상태
///
/// 📚 학습 포인트: State Machine Pattern
/// 사진 인식 플로우의 각 단계를 명확하게 표현
/// 💡 Java 비교: Enum-based State Machine
enum PhotoRecognitionState: Equatable {
    /// 초기 상태 (사진 선택 대기)
    case idle

    /// 사진 촬영/선택 중
    case capturing

    /// AI 분석 중 (Vision API 호출 + 음식 매칭)
    case analyzing(progress: String)

    /// 분석 결과 표시
    case results([FoodMatch])

    /// 오프라인 상태 (네트워크 연결 없음)
    case offline

    /// 에러 발생
    case error(String)
}

/// 사진 인식 화면의 ViewModel
///
/// 📚 학습 포인트: Multi-Service Orchestration ViewModel
/// 여러 서비스를 조합하여 복잡한 워크플로우를 관리합니다:
/// 1. 사진 촬영/선택 (PhotoCaptureService)
/// 2. AI 이미지 분석 (VisionAPIService)
/// 3. 음식 매칭 (FoodLabelMatcherService)
/// 4. 식단 기록 저장 (FoodRecordService)
/// 💡 Java 비교: Use Case / Interactor pattern
///
/// ## 워크플로우
/// 1. 사용자가 사진 촬영/선택
/// 2. Vision API로 이미지 분석 (라벨 추출)
/// 3. 라벨을 음식 데이터베이스와 매칭
/// 4. 사용자 확인/수정
/// 5. 식단 기록으로 저장
///
/// - Note: ObservableObject를 준수하여 SwiftUI View와 바인딩됩니다.
/// - Note: @MainActor를 사용하여 모든 UI 업데이트가 메인 스레드에서 실행됩니다.
///
/// - Example:
/// ```swift
/// let viewModel = PhotoRecognitionViewModel(
///     visionAPIService: visionAPIService,
///     foodLabelMatcher: foodLabelMatcher,
///     foodRecordService: foodRecordService,
///     usageTracker: usageTracker
/// )
/// viewModel.onAppear(userId: userId, date: Date(), mealType: .lunch, bmr: 1650, tdee: 2310)
///
/// // 사진 분석 시작
/// await viewModel.analyzeImage(image)
///
/// // 결과를 식단에 저장
/// try await viewModel.saveFoodRecords(selectedMatches)
/// ```
@MainActor
final class PhotoRecognitionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 현재 워크플로우 상태
    ///
    /// 📚 학습 포인트: State-driven UI
    /// 상태에 따라 UI가 자동으로 변경됩니다
    /// 💡 SwiftUI의 reactive binding을 활용
    @Published var state: PhotoRecognitionState = .idle

    /// 선택/촬영한 사진
    @Published var capturedImage: UIImage?

    /// 분석된 음식 매칭 결과
    @Published var foodMatches: [FoodMatch] = []

    /// Gemini AI 분석 결과
    @Published var geminiResults: [GeminiFoodAnalysis] = []

    /// 에러 메시지
    @Published var errorMessage: String?

    /// API 할당량 경고 표시 여부
    @Published var showQuotaWarning: Bool = false

    /// 남은 API 할당량
    @Published var remainingQuota: Int = 0

    /// 할당량 초기화까지 남은 일수
    @Published var daysUntilReset: Int = 0

    // MARK: - Private Properties

    /// Gemini AI 서비스 (Multimodal 음식 분석)
    private let geminiService: GeminiServiceProtocol

    /// Vision API 서비스
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 테스트 용이성 향상
    /// 💡 Java 비교: Constructor Injection
    private let visionAPIService: VisionAPIServiceProtocol

    /// 음식 라벨 매칭 서비스
    private let foodLabelMatcher: FoodLabelMatcherServiceProtocol

    /// 식단 기록 서비스
    private let foodRecordService: FoodRecordServiceProtocol

    /// API 사용량 추적기
    private let usageTracker: VisionAPIUsageTrackerProtocol

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    /// 섭취 날짜
    private var currentDate: Date?

    /// 선택된 끼니 종류
    private var currentMealType: MealType = .breakfast

    /// 기초대사량 (kcal)
    private var currentBMR: Int32 = 0

    /// 활동대사량 (kcal)
    private var currentTDEE: Int32 = 0

    // MARK: - Initialization

    /// PhotoRecognitionViewModel을 초기화합니다.
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 모든 의존성을 생성자를 통해 주입받아 테스트와 유연성 향상
    /// 💡 Java 비교: @Inject constructor
    ///
    /// - Parameters:
    ///   - geminiService: Gemini AI 서비스 (Multimodal 음식 분석)
    ///   - visionAPIService: Vision API 서비스 (fallback)
    ///   - foodLabelMatcher: 음식 라벨 매칭 서비스 (fallback)
    ///   - foodRecordService: 식단 기록 서비스
    ///   - usageTracker: API 사용량 추적기
    init(
        geminiService: GeminiServiceProtocol,
        visionAPIService: VisionAPIServiceProtocol,
        foodLabelMatcher: FoodLabelMatcherServiceProtocol,
        foodRecordService: FoodRecordServiceProtocol,
        usageTracker: VisionAPIUsageTrackerProtocol
    ) {
        self.geminiService = geminiService
        self.visionAPIService = visionAPIService
        self.foodLabelMatcher = foodLabelMatcher
        self.foodRecordService = foodRecordService
        self.usageTracker = usageTracker

        // 할당량 정보 업데이트
        updateQuotaInfo()
    }

    // MARK: - Public Methods

    /// 화면 진입 시 호출됩니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 섭취 날짜
    ///   - mealType: 끼니 종류
    ///   - bmr: 기초대사량 (kcal)
    ///   - tdee: 활동대사량 (kcal)
    func onAppear(
        userId: UUID,
        date: Date,
        mealType: MealType,
        bmr: Int32,
        tdee: Int32
    ) {
        self.currentUserId = userId
        self.currentDate = date
        self.currentMealType = mealType
        self.currentBMR = bmr
        self.currentTDEE = tdee

        // 할당량 정보 업데이트
        updateQuotaInfo()

        // 초기 상태로 리셋
        resetState()
    }

    /// 사진 촬영/선택을 시작합니다.
    ///
    /// 📚 학습 포인트: State Transition
    /// 상태를 capturing으로 변경하여 UI 업데이트
    func startCapture() {
        state = .capturing
        errorMessage = nil
    }

    /// 사진 촬영/선택을 취소합니다.
    func cancelCapture() {
        state = .idle
        capturedImage = nil
    }

    /// 사진이 선택/촬영되었을 때 호출됩니다.
    ///
    /// - Parameter image: 선택/촬영된 이미지
    func didCaptureImage(_ image: UIImage) {
        self.capturedImage = image
        state = .idle
    }

    /// 이미지를 분석하여 음식을 인식합니다.
    ///
    /// 📚 학습 포인트: Multi-Step Async Operation
    /// 여러 비동기 작업을 순차적으로 실행하고 진행 상황을 UI에 표시
    /// 💡 Java 비교: RxJava의 flatMap chain과 유사
    ///
    /// ## 처리 단계
    /// 1. API 할당량 확인
    /// 2. Vision API로 이미지 분석
    /// 3. 인식된 라벨을 음식과 매칭
    /// 4. 결과 표시
    ///
    /// - Parameter image: 분석할 이미지
    ///
    /// - Throws: VisionAPIError 또는 네트워크 에러
    func analyzeImage(_ image: UIImage) async throws {
        do {
            // 1차: Gemini Multimodal 분석 시도
            state = .analyzing(progress: "AI 음식 분석 중...")

            #if DEBUG
            print("🤖 Gemini Multimodal 분석 시작...")
            #endif

            let results = try await geminiService.analyzeFoodImage(image)

            guard !results.isEmpty else {
                throw GeminiServiceError.invalidResponse("음식이 인식되지 않았습니다.")
            }

            #if DEBUG
            print("✅ Gemini 분석 완료: \(results.count)개 음식 인식")
            results.forEach { food in
                print("   - \(food.name): \(food.estimatedGrams)g, \(food.calories)kcal")
            }
            #endif

            geminiResults = results
            state = .analyzing(progress: "") // Gemini 결과를 별도 뷰에서 표시
            return

        } catch {
            #if DEBUG
            print("⚠️ Gemini 분석 실패, Vision API fallback: \(error)")
            #endif

            // Gemini 실패 시 기존 Vision API로 fallback
            geminiResults = []
        }

        // 2차 Fallback: Vision API + FoodLabelMatcher
        guard usageTracker.canMakeRequest() else {
            let days = usageTracker.getDaysUntilReset()
            let error = VisionAPIError.quotaExceeded(resetInDays: days)
            handleError(error)
            throw error
        }

        do {
            state = .analyzing(progress: "사진 분석 중...")

            let labels = try await visionAPIService.analyzeImage(image)

            #if DEBUG
            print("🔍 Vision API 결과: \(labels.count)개 라벨 인식")
            #endif

            state = .analyzing(progress: "음식 매칭 중...")

            let matches = try await foodLabelMatcher.matchLabelsToFoods(labels)

            #if DEBUG
            print("✅ 음식 매칭 완료: \(matches.count)개 매칭")
            #endif

            foodMatches = matches

            guard !matches.isEmpty else {
                throw VisionAPIError.noFoodDetected
            }

            state = .results(matches)
            updateQuotaInfo()

        } catch {
            handleError(error)
            throw error
        }
    }

    /// 편집된 음식 항목을 식단 기록으로 저장합니다.
    ///
    /// 📚 학습 포인트: Batch Operation with User Quantities
    /// 사용자가 편집한 수량/단위 정보를 포함하여 여러 음식을 한 번에 저장하는 배치 작업
    /// 💡 Java 비교: @Transactional batch insert
    ///
    /// - Parameter editedItems: 저장할 편집된 음식 항목 목록
    ///
    /// - Throws: FoodRecordService 에러
    ///
    /// - Note: 각 음식은 사용자가 편집한 수량과 단위로 저장됩니다.
    func saveFoodRecords(_ editedItems: [EditedFoodItem]) async throws {
        guard let userId = currentUserId,
              let date = currentDate else {
            throw ServiceError.invalidQuantity
        }

        state = .analyzing(progress: "저장 중...")

        do {
            // 각 편집된 음식 항목을 식단 기록으로 저장
            for item in editedItems {
                // Core Data Food.id는 UUID?이므로 언래핑 필요
                guard let foodId = item.match.food.id else {
                    #if DEBUG
                    print("⚠️ Food ID가 없습니다: \(item.match.food.name ?? "Unknown")")
                    #endif
                    continue
                }

                _ = try await foodRecordService.addFoodRecord(
                    userId: userId,
                    foodId: foodId,
                    date: date,
                    mealType: currentMealType,
                    quantity: item.quantity,  // 사용자가 편집한 수량
                    quantityUnit: item.unit,  // 사용자가 선택한 단위
                    bmr: currentBMR,
                    tdee: currentTDEE
                )
            }

            #if DEBUG
            print("✅ \(editedItems.count)개 음식 기록 저장 완료")
            editedItems.forEach { item in
                print("   - \(item.match.food.name): \(item.quantity) \(item.unit)")
            }
            #endif

            // 성공 시 초기 상태로 리셋
            resetState()

        } catch {
            handleError(error)
            throw error
        }
    }

    /// Gemini 분석 결과를 식단 기록으로 저장합니다.
    ///
    /// - Parameter selectedItems: 저장할 Gemini 분석 결과 (사용자가 선택/편집한 항목)
    func saveGeminiResults(_ selectedItems: [GeminiFoodAnalysis]) async throws {
        guard let userId = currentUserId,
              let date = currentDate else {
            throw ServiceError.invalidQuantity
        }

        state = .analyzing(progress: "저장 중...")

        do {
            for item in selectedItems {
                // Gemini 결과를 FoodRecord로 저장
                // Food 엔티티를 먼저 찾거나 생성해야 함
                _ = try await foodRecordService.addFoodRecordFromGemini(
                    userId: userId,
                    foodName: item.name,
                    date: date,
                    mealType: currentMealType,
                    estimatedGrams: item.estimatedGrams,
                    calories: item.calories,
                    carbohydrates: item.carbohydrates,
                    protein: item.protein,
                    fat: item.fat,
                    bmr: currentBMR,
                    tdee: currentTDEE
                )
            }

            #if DEBUG
            print("✅ Gemini 결과 \(selectedItems.count)개 저장 완료")
            #endif

            resetState()

        } catch {
            handleError(error)
            throw error
        }
    }

    /// 다시 시도 (재분석)
    ///
    /// 분석 실패 시 같은 이미지로 다시 시도합니다.
    func retry() async throws {
        guard let image = capturedImage else { return }

        errorMessage = nil
        try await analyzeImage(image)
    }

    /// 상태를 초기화합니다.
    ///
    /// 새로운 사진 인식을 시작하기 위해 모든 상태를 리셋합니다.
    func resetState() {
        state = .idle
        capturedImage = nil
        foodMatches = []
        geminiResults = []
        errorMessage = nil
    }

    // MARK: - Private Methods

    /// API 할당량 정보를 업데이트합니다.
    ///
    /// 📚 학습 포인트: Quota Monitoring
    /// 사용량을 실시간으로 추적하여 UI에 반영
    private func updateQuotaInfo() {
        remainingQuota = usageTracker.getRemainingQuota()
        daysUntilReset = usageTracker.getDaysUntilReset()
        showQuotaWarning = usageTracker.shouldShowWarning()

        #if DEBUG
        print("📊 API 할당량: \(usageTracker.getCurrentUsage())/\(usageTracker.getMonthlyLimit())")
        print("   남은 횟수: \(remainingQuota)")
        if showQuotaWarning {
            print("   ⚠️ 경고: 90% 초과")
        }
        #endif
    }

    /// 에러를 처리합니다.
    ///
    /// 📚 학습 포인트: Centralized Error Handling
    /// 모든 에러를 한 곳에서 처리하여 일관성 유지
    /// 💡 Java 비교: Exception Handler pattern
    ///
    /// - Parameter error: 발생한 에러
    private func handleError(_ error: Error) {
        #if DEBUG
        print("❌ 에러 발생: \(error)")
        #endif

        // 에러 메시지 설정
        if let visionError = error as? VisionAPIError {
            // 네트워크 에러 확인
            if case .networkError(let networkError) = visionError {
                if case .networkUnavailable = networkError {
                    // 오프라인 상태로 전환
                    state = .offline
                    errorMessage = "네트워크 연결을 확인해주세요"
                    return
                }
            }

            errorMessage = visionError.localizedDescription

            // 할당량 초과 시 특별 처리
            if case .quotaExceeded = visionError {
                updateQuotaInfo()
            }
        } else if let networkError = error as? NetworkError {
            // 네트워크 에러 직접 처리
            if case .networkUnavailable = networkError {
                // 오프라인 상태로 전환
                state = .offline
                errorMessage = "네트워크 연결을 확인해주세요"
                return
            }

            errorMessage = networkError.localizedDescription
        } else if let serviceError = error as? ServiceError {
            errorMessage = serviceError.localizedDescription
        } else {
            errorMessage = "오류가 발생했습니다: \(error.localizedDescription)"
        }

        state = .error(errorMessage ?? "알 수 없는 오류")
    }
}

// MARK: - Computed Properties

extension PhotoRecognitionViewModel {

    /// 로딩 중인지 여부
    var isLoading: Bool {
        if case .analyzing = state {
            return true
        }
        return false
    }

    /// 결과가 있는지 여부
    var hasResults: Bool {
        if case .results = state {
            return true
        }
        return !foodMatches.isEmpty
    }

    /// 에러 상태인지 여부
    var hasError: Bool {
        if case .error = state {
            return true
        }
        return errorMessage != nil
    }

    /// 오프라인 상태인지 여부
    var isOffline: Bool {
        if case .offline = state {
            return true
        }
        return false
    }

    /// Gemini 분석 결과가 있는지 여부
    var hasGeminiResults: Bool {
        return !geminiResults.isEmpty
    }

    /// 사진이 선택되었는지 여부
    var hasImage: Bool {
        return capturedImage != nil
    }

    /// API 할당량이 부족한지 여부 (10% 미만)
    var isQuotaLow: Bool {
        let percentRemaining = Double(remainingQuota) / Double(usageTracker.getMonthlyLimit())
        return percentRemaining < 0.1
    }

    /// API 할당량이 초과되었는지 여부
    var isQuotaExceeded: Bool {
        return remainingQuota <= 0
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Photo Recognition ViewModel
///
/// 📚 학습 포인트: Mock ViewModel for Testing
/// UI 테스트를 위한 Mock ViewModel
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockPhotoRecognitionViewModel: ObservableObject {

    @Published var state: PhotoRecognitionState = .idle
    @Published var capturedImage: UIImage?
    @Published var foodMatches: [FoodMatch] = []
    @Published var errorMessage: String?
    @Published var showQuotaWarning: Bool = false
    @Published var remainingQuota: Int = 1000
    @Published var daysUntilReset: Int = 15

    var shouldFailAnalysis: Bool = false
    var analyzeImageCallCount = 0
    var saveFoodRecordsCallCount = 0

    func onAppear(userId: UUID, date: Date, mealType: MealType, bmr: Int32, tdee: Int32) {
        // Mock implementation
    }

    func startCapture() {
        state = .capturing
    }

    func cancelCapture() {
        state = .idle
    }

    func didCaptureImage(_ image: UIImage) {
        capturedImage = image
        state = .idle
    }

    func analyzeImage(_ image: UIImage) async throws {
        analyzeImageCallCount += 1

        if shouldFailAnalysis {
            let error = VisionAPIError.noFoodDetected
            errorMessage = error.localizedDescription
            state = .error(error.localizedDescription)
            throw error
        }

        state = .analyzing(progress: "분석 중...")

        // 짧은 딜레이 시뮬레이션
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초

        state = .results(foodMatches)
    }

    func saveFoodRecords(_ editedItems: [EditedFoodItem]) async throws {
        saveFoodRecordsCallCount += 1
        state = .idle
    }

    func retry() async throws {
        if let image = capturedImage {
            try await analyzeImage(image)
        }
    }

    func resetState() {
        state = .idle
        capturedImage = nil
        foodMatches = []
        errorMessage = nil
    }

    var isLoading: Bool {
        if case .analyzing = state { return true }
        return false
    }

    var hasResults: Bool {
        if case .results = state { return true }
        return !foodMatches.isEmpty
    }

    var hasError: Bool {
        if case .error = state { return true }
        return errorMessage != nil
    }

    var hasImage: Bool {
        return capturedImage != nil
    }

    var isQuotaLow: Bool {
        return remainingQuota < 100
    }

    var isQuotaExceeded: Bool {
        return remainingQuota <= 0
    }

    var isOffline: Bool {
        if case .offline = state { return true }
        return false
    }
}
#endif
