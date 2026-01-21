//
//  OnboardingViewModelTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-21.
//

import XCTest
import CoreData
@testable import Bodii

/// OnboardingViewModel에 대한 단위 테스트
/// 초기 상태, 단계 이동, 진행률 계산, 유효성 검증 등을 테스트
@MainActor
final class OnboardingViewModelTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 ViewModel
    var sut: OnboardingViewModel!

    /// 테스트용 Core Data 컨텍스트
    var testContext: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        // 테스트용 인메모리 Core Data 스택 사용
        let controller = PersistenceController(inMemory: true)
        testContext = controller.viewContext
        sut = OnboardingViewModel(context: testContext)
    }

    override func tearDown() async throws {
        sut = nil
        testContext = nil
        try await super.tearDown()
    }

    // MARK: - 초기 상태 테스트

    func test_initialState_isWelcomeStep() {
        // Then: 초기 단계는 welcome이어야 함
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func test_initialProgress_isZero() {
        // Then: 초기 진행률은 0이어야 함
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)
    }

    func test_initialGender_isMale() {
        // Then: 초기 성별은 남성이어야 함
        XCTAssertEqual(sut.gender, .male)
    }

    func test_initialActivityLevel_isModeratelyActive() {
        // Then: 초기 활동 수준은 보통 활동이어야 함
        XCTAssertEqual(sut.activityLevel, .moderatelyActive)
    }

    func test_initialName_isEmpty() {
        // Then: 초기 이름은 비어있어야 함
        XCTAssertTrue(sut.name.isEmpty)
    }

    func test_initialHeight_isEmpty() {
        // Then: 초기 키는 비어있어야 함
        XCTAssertTrue(sut.height.isEmpty)
    }

    func test_initialWeight_isEmpty() {
        // Then: 초기 몸무게는 비어있어야 함
        XCTAssertTrue(sut.weight.isEmpty)
    }

    func test_initialIsLoading_isFalse() {
        // Then: 초기 로딩 상태는 false여야 함
        XCTAssertFalse(sut.isLoading)
    }

    func test_initialErrorMessage_isNil() {
        // Then: 초기 에러 메시지는 nil이어야 함
        XCTAssertNil(sut.errorMessage)
    }

    func test_initialCalculatedBMR_isNil() {
        // Then: 초기 계산된 BMR은 nil이어야 함
        XCTAssertNil(sut.calculatedBMR)
    }

    func test_initialCalculatedTDEE_isNil() {
        // Then: 초기 계산된 TDEE는 nil이어야 함
        XCTAssertNil(sut.calculatedTDEE)
    }

    // MARK: - 단계 이동 테스트 (goToNext)

    func test_goToNext_fromWelcome_movesToBasicInfo() {
        // Given
        sut.currentStep = .welcome

        // When
        sut.goToNext()

        // Then
        XCTAssertEqual(sut.currentStep, .basicInfo)
    }

    func test_goToNext_fromBasicInfo_movesToBodyInfo() {
        // Given
        sut.currentStep = .basicInfo

        // When
        sut.goToNext()

        // Then
        XCTAssertEqual(sut.currentStep, .bodyInfo)
    }

    func test_goToNext_fromBodyInfo_movesToActivityLevel() {
        // Given
        sut.currentStep = .bodyInfo

        // When
        sut.goToNext()

        // Then
        XCTAssertEqual(sut.currentStep, .activityLevel)
    }

    func test_goToNext_fromActivityLevel_movesToComplete() {
        // Given
        sut.currentStep = .activityLevel

        // When
        sut.goToNext()

        // Then
        XCTAssertEqual(sut.currentStep, .complete)
    }

    func test_goToNext_fromComplete_staysAtComplete() {
        // Given
        sut.currentStep = .complete

        // When
        sut.goToNext()

        // Then: complete에서 더 이상 이동하지 않음
        XCTAssertEqual(sut.currentStep, .complete)
    }

    // MARK: - 단계 이동 테스트 (goToPrevious)

    func test_goToPrevious_fromBasicInfo_movesToWelcome() {
        // Given
        sut.currentStep = .basicInfo

        // When
        sut.goToPrevious()

        // Then
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    func test_goToPrevious_fromBodyInfo_movesToBasicInfo() {
        // Given
        sut.currentStep = .bodyInfo

        // When
        sut.goToPrevious()

        // Then
        XCTAssertEqual(sut.currentStep, .basicInfo)
    }

    func test_goToPrevious_fromActivityLevel_movesToBodyInfo() {
        // Given
        sut.currentStep = .activityLevel

        // When
        sut.goToPrevious()

        // Then
        XCTAssertEqual(sut.currentStep, .bodyInfo)
    }

    func test_goToPrevious_fromComplete_movesToActivityLevel() {
        // Given
        sut.currentStep = .complete

        // When
        sut.goToPrevious()

        // Then
        XCTAssertEqual(sut.currentStep, .activityLevel)
    }

    func test_goToPrevious_fromWelcome_staysAtWelcome() {
        // Given
        sut.currentStep = .welcome

        // When
        sut.goToPrevious()

        // Then: welcome에서 더 이상 뒤로 가지 않음
        XCTAssertEqual(sut.currentStep, .welcome)
    }

    // MARK: - 진행률 테스트

    func test_progress_atWelcome_isZero() {
        // Given
        sut.currentStep = .welcome

        // Then
        XCTAssertEqual(sut.progress, 0.0, accuracy: 0.01)
    }

    func test_progress_atBasicInfo_is25Percent() {
        // Given
        sut.currentStep = .basicInfo

        // Then: 1/4 = 0.25
        XCTAssertEqual(sut.progress, 0.25, accuracy: 0.01)
    }

    func test_progress_atBodyInfo_is50Percent() {
        // Given
        sut.currentStep = .bodyInfo

        // Then: 2/4 = 0.5
        XCTAssertEqual(sut.progress, 0.5, accuracy: 0.01)
    }

    func test_progress_atActivityLevel_is75Percent() {
        // Given
        sut.currentStep = .activityLevel

        // Then: 3/4 = 0.75
        XCTAssertEqual(sut.progress, 0.75, accuracy: 0.01)
    }

    func test_progress_atComplete_is100Percent() {
        // Given
        sut.currentStep = .complete

        // Then: 4/4 = 1.0
        XCTAssertEqual(sut.progress, 1.0, accuracy: 0.01)
    }

    // MARK: - 기본 정보 유효성 검증 테스트 (isBasicInfoValid)

    func test_isBasicInfoValid_emptyName_returnsFalse() {
        // Given
        sut.name = ""

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_whitespaceOnlyName_returnsFalse() {
        // Given
        sut.name = "   "

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_validName_returnsTrue() {
        // Given
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_singleCharacterName_returnsTrue() {
        // Given
        sut.name = "홍"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_maxLengthName20_returnsTrue() {
        // Given: 정확히 20자
        sut.name = String(repeating: "가", count: 20)
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_tooLongName21_returnsFalse() {
        // Given: 21자 (초과)
        sut.name = String(repeating: "가", count: 21)
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_ageTooYoung9_returnsFalse() {
        // Given: 9세 (10세 미만)
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -9, to: Date())!

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_ageExactly10_returnsTrue() {
        // Given: 정확히 10세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_ageExactly120_returnsTrue() {
        // Given: 정확히 120세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -120, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_ageTooOld121_returnsFalse() {
        // Given: 121세 (120세 초과)
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -121, to: Date())!

        // Then
        XCTAssertFalse(sut.isBasicInfoValid)
    }

    func test_isBasicInfoValid_validAge30_returnsTrue() {
        // Given: 30세
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.isBasicInfoValid)
    }

    // MARK: - 신체 정보 유효성 검증 테스트 (isBodyInfoValid)

    func test_isBodyInfoValid_emptyHeight_returnsFalse() {
        // Given
        sut.height = ""
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_emptyWeight_returnsFalse() {
        // Given
        sut.height = "175"
        sut.weight = ""

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_heightTooLow99_returnsFalse() {
        // Given: 99cm (100cm 미만)
        sut.height = "99"
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_heightExactly100_returnsTrue() {
        // Given: 정확히 100cm
        sut.height = "100"
        sut.weight = "70"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_heightExactly250_returnsTrue() {
        // Given: 정확히 250cm
        sut.height = "250"
        sut.weight = "70"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_heightTooHigh251_returnsFalse() {
        // Given: 251cm (250cm 초과)
        sut.height = "251"
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_weightTooLow19_returnsFalse() {
        // Given: 19kg (20kg 미만)
        sut.height = "175"
        sut.weight = "19"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_weightExactly20_returnsTrue() {
        // Given: 정확히 20kg
        sut.height = "175"
        sut.weight = "20"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_weightExactly300_returnsTrue() {
        // Given: 정확히 300kg
        sut.height = "175"
        sut.weight = "300"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_weightTooHigh301_returnsFalse() {
        // Given: 301kg (300kg 초과)
        sut.height = "175"
        sut.weight = "301"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_validValues_returnsTrue() {
        // Given: 유효한 값
        sut.height = "175"
        sut.weight = "70"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_nonNumericHeight_returnsFalse() {
        // Given: 숫자가 아닌 키
        sut.height = "abc"
        sut.weight = "70"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_nonNumericWeight_returnsFalse() {
        // Given: 숫자가 아닌 몸무게
        sut.height = "175"
        sut.weight = "abc"

        // Then
        XCTAssertFalse(sut.isBodyInfoValid)
    }

    func test_isBodyInfoValid_decimalValues_returnsTrue() {
        // Given: 소수점 값
        sut.height = "175.5"
        sut.weight = "70.3"

        // Then
        XCTAssertTrue(sut.isBodyInfoValid)
    }

    // MARK: - 나이 계산 테스트

    func test_age_30YearsAgo_returns30() {
        // Given
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertEqual(sut.age, 30)
    }

    func test_age_25YearsAgo_returns25() {
        // Given
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date())!

        // Then
        XCTAssertEqual(sut.age, 25)
    }

    func test_age_10YearsAgo_returns10() {
        // Given
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())!

        // Then
        XCTAssertEqual(sut.age, 10)
    }

    // MARK: - canProceed 테스트

    func test_canProceed_atWelcome_alwaysTrue() {
        // Given
        sut.currentStep = .welcome

        // Then
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atBasicInfo_withEmptyName_returnsFalse() {
        // Given
        sut.currentStep = .basicInfo
        sut.name = ""

        // Then
        XCTAssertFalse(sut.canProceed)
    }

    func test_canProceed_atBasicInfo_withValidName_returnsTrue() {
        // Given
        sut.currentStep = .basicInfo
        sut.name = "테스트"
        sut.birthDate = Calendar.current.date(byAdding: .year, value: -30, to: Date())!

        // Then
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atBodyInfo_withEmptyFields_returnsFalse() {
        // Given
        sut.currentStep = .bodyInfo
        sut.height = ""
        sut.weight = ""

        // Then
        XCTAssertFalse(sut.canProceed)
    }

    func test_canProceed_atBodyInfo_withValidFields_returnsTrue() {
        // Given
        sut.currentStep = .bodyInfo
        sut.height = "175"
        sut.weight = "70"

        // Then
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atActivityLevel_alwaysTrue() {
        // Given
        sut.currentStep = .activityLevel

        // Then: 활동 수준은 기본값이 있으므로 항상 true
        XCTAssertTrue(sut.canProceed)
    }

    func test_canProceed_atComplete_alwaysTrue() {
        // Given
        sut.currentStep = .complete

        // Then
        XCTAssertTrue(sut.canProceed)
    }

    // MARK: - 에러 처리 테스트

    func test_clearError_removesErrorMessage() {
        // Given
        sut.errorMessage = "테스트 에러"

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func test_clearError_whenNoError_remainsNil() {
        // Given
        XCTAssertNil(sut.errorMessage)

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Step enum 테스트

    func test_step_allCases_hasCorrectCount() {
        // Then: welcome, basicInfo, bodyInfo, activityLevel, complete = 5개
        XCTAssertEqual(OnboardingViewModel.Step.allCases.count, 5)
    }

    func test_step_rawValues_areSequential() {
        // Then
        XCTAssertEqual(OnboardingViewModel.Step.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingViewModel.Step.basicInfo.rawValue, 1)
        XCTAssertEqual(OnboardingViewModel.Step.bodyInfo.rawValue, 2)
        XCTAssertEqual(OnboardingViewModel.Step.activityLevel.rawValue, 3)
        XCTAssertEqual(OnboardingViewModel.Step.complete.rawValue, 4)
    }

    // MARK: - 성별 변경 테스트

    func test_genderChange_toFemale_updatesValue() {
        // Given
        XCTAssertEqual(sut.gender, .male)

        // When
        sut.gender = .female

        // Then
        XCTAssertEqual(sut.gender, .female)
    }

    // MARK: - 활동 수준 변경 테스트

    func test_activityLevelChange_toSedentary_updatesValue() {
        // Given
        XCTAssertEqual(sut.activityLevel, .moderatelyActive)

        // When
        sut.activityLevel = .sedentary

        // Then
        XCTAssertEqual(sut.activityLevel, .sedentary)
    }

    func test_activityLevelChange_toExtraActive_updatesValue() {
        // When
        sut.activityLevel = .extraActive

        // Then
        XCTAssertEqual(sut.activityLevel, .extraActive)
    }
}
