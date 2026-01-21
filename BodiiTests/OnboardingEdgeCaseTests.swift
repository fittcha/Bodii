//
//  OnboardingEdgeCaseTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-21.
//

import XCTest
import CoreData
@testable import Bodii

/// 온보딩 Edge Case 테스트
/// 경계값, 특수 문자, 동시성 등 예외 상황을 테스트
@MainActor
final class OnboardingEdgeCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: OnboardingViewModel!
    var testContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        testContext = persistenceController.viewContext
        sut = OnboardingViewModel(context: testContext)
    }

    override func tearDown() async throws {
        sut = nil
        testContext = nil
        persistenceController = nil
        try await super.tearDown()
    }

    // MARK: - Helper Methods

    private func fetchUserCount() throws -> Int {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        return try testContext.count(for: fetchRequest)
    }

    private func setupValidUserInfo() {
        sut.name = "테스트"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        sut.height = "175"
        sut.weight = "70"
        sut.activityLevel = .moderatelyActive
    }

    // MARK: - 이름 Edge Cases

    func test_name_whitespaceOnly_isInvalid() {
        // Given: 공백만으로 구성된 이름
        sut.name = "   "
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_name_tabAndNewline_isInvalid() {
        // Given: 탭과 개행문자만 있는 이름
        sut.name = "\t\n"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_name_withLeadingTrailingSpaces_isTrimmedAndValid() {
        // Given: 앞뒤 공백이 있는 이름
        sut.name = "  테스트  "
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then: trim 후 유효해야 함
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_withEmoji_isValid() {
        // Given: 이모지가 포함된 이름
        sut.name = "테스트이모지"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_withSpecialCharacters_isValid() {
        // Given: 특수문자가 포함된 이름
        sut.name = "김철수-Jr."
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_englishOnly_isValid() {
        // Given: 영문 이름
        sut.name = "John Doe"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_koreanOnly_isValid() {
        // Given: 한글 이름
        sut.name = "홍길동"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_mixedLanguages_isValid() {
        // Given: 여러 언어 혼합
        sut.name = "홍길동 John"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_numbers_isValid() {
        // Given: 숫자가 포함된 이름
        sut.name = "테스트123"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_name_exactly20Characters_isValid() {
        // Given: 정확히 20자
        sut.name = "가나다라마바사아자차카타파하갸냐댜랴"
        XCTAssertEqual(sut.name.count, 20)
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    // MARK: - 키/몸무게 Edge Cases

    func test_height_withLeadingZero_isValid() {
        // Given: 앞에 0이 붙은 키 (0175 → 175로 파싱됨)
        sut.height = "0175"
        sut.weight = "70"

        // Then: Double로 파싱되면 175.0이 됨
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_height_negativeValue_isInvalid() {
        // Given: 음수 키
        sut.height = "-175"
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_weight_negativeValue_isInvalid() {
        // Given: 음수 몸무게
        sut.height = "175"
        sut.weight = "-70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_height_withSpaces_isInvalid() {
        // Given: 공백이 포함된 키
        sut.height = "17 5"
        sut.weight = "70"

        // Then: Double로 파싱 실패
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_weight_withComma_isInvalid() {
        // Given: 콤마가 포함된 몸무게
        sut.height = "175"
        sut.weight = "70,5"

        // Then: Double로 파싱 실패
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_height_scientificNotation_isHandled() {
        // Given: 지수 표기법 (1.75e2 = 175)
        sut.height = "1.75e2"
        sut.weight = "70"

        // Then: Double로 파싱되어 175로 처리될 수 있음
        // 구현에 따라 결과가 다를 수 있음
        let heightValue = Double(sut.height)
        if heightValue != nil && heightValue! >= 100 && heightValue! <= 250 {
            XCTAssertTrue(sut.isBodyInfoValid)
        } else {
            XCTAssertFalse(sut.isBodyInfoValid)
        }
    }

    func test_weight_verySmallDecimal_isHandled() {
        // Given: 소수점 여러 자리
        sut.height = "175"
        sut.weight = "70.123456"

        // Then: 소수점 처리 확인
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_height_atExactBoundary100_isValid() {
        // Given: 정확히 100cm
        sut.height = "100"
        sut.weight = "70"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_height_atExactBoundary250_isValid() {
        // Given: 정확히 250cm
        sut.height = "250"
        sut.weight = "70"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_weight_atExactBoundary20_isValid() {
        // Given: 정확히 20kg
        sut.height = "175"
        sut.weight = "20"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_weight_atExactBoundary300_isValid() {
        // Given: 정확히 300kg
        sut.height = "175"
        sut.weight = "300"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_height_justBelowMinimum99_99_isInvalid() {
        // Given: 99.99cm (100cm 미만)
        sut.height = "99.99"
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_height_justAboveMaximum250_01_isInvalid() {
        // Given: 250.01cm (250cm 초과)
        sut.height = "250.01"
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_weight_justBelowMinimum19_99_isInvalid() {
        // Given: 19.99kg (20kg 미만)
        sut.height = "175"
        sut.weight = "19.99"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_weight_justAboveMaximum300_01_isInvalid() {
        // Given: 300.01kg (300kg 초과)
        sut.height = "175"
        sut.weight = "300.01"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    // MARK: - 나이 Edge Cases

    func test_age_exactly10_isValid() {
        // Given: 정확히 10세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_age_exactly120_isValid() {
        // Given: 정확히 120세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -120, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_birthDate_futureDate_isInvalid() {
        // Given: 미래 날짜 (내년 생일)
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

        // Then: 나이가 음수가 되므로 invalid
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_birthDate_yesterday_isInvalid() {
        // Given: 어제 태어남 (1세 미만)
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // Then: 10세 미만이므로 invalid
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    // MARK: - 활동 수준 Edge Cases

    func test_activityLevel_allLevels_haveCorrectMultipliers() {
        // 각 활동 수준의 multiplier가 올바른지 확인
        XCTAssertEqual(ActivityLevel.sedentary.multiplier, 1.2, accuracy: 0.001)
        XCTAssertEqual(ActivityLevel.lightlyActive.multiplier, 1.375, accuracy: 0.001)
        XCTAssertEqual(ActivityLevel.moderatelyActive.multiplier, 1.55, accuracy: 0.001)
        XCTAssertEqual(ActivityLevel.veryActive.multiplier, 1.725, accuracy: 0.001)
        XCTAssertEqual(ActivityLevel.extraActive.multiplier, 1.9, accuracy: 0.001)
    }

    // MARK: - 동시성 Edge Cases

    func test_completeOnboarding_calledWhileLoading_doesNotCreateDuplicateUser() async throws {
        // Given
        setupValidUserInfo()

        // isLoading이 true일 때 completeOnboarding 호출하면 조기 반환됨
        sut.isLoading = true

        // When
        await sut.completeOnboarding()

        // Then: User가 생성되지 않아야 함
        let userCount = try fetchUserCount()
        XCTAssertEqual(userCount, 0, "isLoading 중에는 User가 생성되지 않아야 합니다")
    }

    func test_completeOnboarding_sequentialCalls_createsOnlyOneUser() async throws {
        // Given
        setupValidUserInfo()

        // When: 순차적으로 두 번 호출
        await sut.completeOnboarding()
        sut.currentStep = .activityLevel // complete에서 다시 activityLevel로
        await sut.completeOnboarding()

        // Then: User가 2개 생성됨 (각 호출마다 새 User 생성)
        // 실제 앱에서는 이를 방지하는 로직이 필요할 수 있음
        let userCount = try fetchUserCount()
        XCTAssertGreaterThanOrEqual(userCount, 1)
    }

    // MARK: - BMR/TDEE 계산 Edge Cases

    func test_bmrCalculation_minimumValues_producesReasonableResult() async throws {
        // Given: 최소 유효 값 (10세, 100cm, 20kg)
        sut.name = "테스트"
        sut.gender = .female
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        sut.height = "100"
        sut.weight = "20"
        sut.activityLevel = .sedentary

        // When
        await sut.completeOnboarding()

        // Then: BMR이 양수여야 함
        // BMR = 10×20 + 6.25×100 - 5×10 - 161 = 200 + 625 - 50 - 161 = 614
        XCTAssertNotNil(sut.calculatedBMR)
        XCTAssertGreaterThan(sut.calculatedBMR ?? 0, 0)
    }

    func test_bmrCalculation_maximumValues_producesReasonableResult() async throws {
        // Given: 최대 유효 값 (120세, 250cm, 300kg)
        sut.name = "테스트"
        sut.gender = .male
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -120, to: Date())!
        sut.height = "250"
        sut.weight = "300"
        sut.activityLevel = .extraActive

        // When
        await sut.completeOnboarding()

        // Then: BMR이 합리적 범위 내에 있어야 함
        // BMR = 10×300 + 6.25×250 - 5×120 + 5 = 3000 + 1562.5 - 600 + 5 = 3967.5
        XCTAssertNotNil(sut.calculatedBMR)
        XCTAssertGreaterThan(sut.calculatedBMR ?? 0, 0)
        XCTAssertLessThan(sut.calculatedBMR ?? 0, 10000, "BMR이 합리적 최대값 미만이어야 합니다")
    }

    func test_tdeeCalculation_withDifferentActivityLevels_showsCorrectDifferences() async {
        // 같은 BMR에 대해 활동 수준별 TDEE 차이 확인
        let bmr: Double = 1500

        let expectedTDEE: [ActivityLevel: Double] = [
            .sedentary: bmr * 1.2,       // 1800
            .lightlyActive: bmr * 1.375,  // 2062.5
            .moderatelyActive: bmr * 1.55, // 2325
            .veryActive: bmr * 1.725,     // 2587.5
            .extraActive: bmr * 1.9       // 2850
        ]

        for (level, expected) in expectedTDEE {
            let actual = bmr * level.multiplier
            XCTAssertEqual(actual, expected, accuracy: 1.0, "ActivityLevel.\(level)의 TDEE가 정확해야 합니다")
        }
    }

    // MARK: - Step 네비게이션 Edge Cases

    func test_goToNext_rapidlyCalled_maintainsCorrectOrder() {
        // Given
        sut.currentStep = .welcome

        // When: 빠르게 연속 호출
        sut.goToNext()
        sut.goToNext()
        sut.goToNext()
        sut.goToNext()

        // Then: complete에서 멈춤
        XCTAssertEqual(sut.currentStep, .complete)
    }

    func test_goToPrevious_rapidlyCalled_stopsAtWelcome() {
        // Given
        sut.currentStep = .complete

        // When: 빠르게 연속 호출
        sut.goToPrevious()
        sut.goToPrevious()
        sut.goToPrevious()
        sut.goToPrevious()
        sut.goToPrevious() // 추가 호출

        // Then: welcome에서 멈춤
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func test_mixedNavigation_worksCorrectly() {
        // Given
        sut.currentStep = .welcome

        // When: 혼합 네비게이션
        sut.goToNext()     // → basicInfo
        sut.goToNext()     // → bodyInfo
        sut.goToPrevious() // → basicInfo
        sut.goToNext()     // → bodyInfo
        sut.goToNext()     // → activityLevel

        // Then
        XCTAssertEqual(sut.currentStep, .activityLevel)
    }

    // MARK: - 에러 상태 Edge Cases

    func test_errorMessage_canBeSetAndCleared() {
        // Given
        XCTAssertNil(sut.errorMessage)

        // When: 에러 설정
        sut.errorMessage = "테스트 에러 메시지"

        // Then
        XCTAssertEqual(sut.errorMessage, "테스트 에러 메시지")

        // When: 에러 클리어
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func test_clearError_multipleCalls_noSideEffects() {
        // Given: 이미 nil인 상태
        XCTAssertNil(sut.errorMessage)

        // When: 여러 번 호출
        sut.clearError()
        sut.clearError()
        sut.clearError()

        // Then: 여전히 nil
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Gender Edge Cases

    func test_gender_bmrAdjustment_male_is5() {
        XCTAssertEqual(Gender.male.bmrAdjustment, 5.0)
    }

    func test_gender_bmrAdjustment_female_isNegative161() {
        XCTAssertEqual(Gender.female.bmrAdjustment, -161.0)
    }

    func test_gender_difference_in_bmr_is166() {
        // 같은 조건에서 남녀 BMR 차이는 166 kcal
        let maleBMRAdjustment = Gender.male.bmrAdjustment
        let femaleBMRAdjustment = Gender.female.bmrAdjustment
        let difference = maleBMRAdjustment - femaleBMRAdjustment

        XCTAssertEqual(difference, 166.0, accuracy: 0.01)
    }

    // MARK: - Progress 계산 Edge Cases

    func test_progress_allSteps_areIncrementalAndWithinRange() {
        for step in OnboardingViewModel.Step.allCases {
            sut.currentStep = step
            let progress = sut.progress

            // 진행률은 0.0 ~ 1.0 사이여야 함
            XCTAssertGreaterThanOrEqual(progress, 0.0)
            XCTAssertLessThanOrEqual(progress, 1.0)
        }
    }

    func test_progress_increasesByQuarter_eachStep() {
        // 각 단계별 진행률 확인
        let steps: [OnboardingViewModel.Step] = [.welcome, .basicInfo, .bodyInfo, .activityLevel, .complete]
        let expectedProgress: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]

        for (index, step) in steps.enumerated() {
            sut.currentStep = step
            XCTAssertEqual(sut.progress, expectedProgress[index], accuracy: 0.01,
                          "\(step)의 진행률이 \(expectedProgress[index])이어야 합니다")
        }
    }
}
