//
//  CalculateTDEEUseCaseTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: XCTest Framework
// Swift의 표준 테스트 프레임워크로 단위 테스트 작성
// 💡 Java 비교: JUnit과 유사한 역할

import XCTest
@testable import Bodii

/// CalculateTDEEUseCase에 대한 단위 테스트
/// 📚 학습 포인트: Test Class Naming Convention
/// 테스트 대상 클래스 이름 + Tests 패턴 사용
/// 💡 Java 비교: JUnit의 테스트 클래스 명명 규칙과 동일
final class CalculateTDEEUseCaseTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Use Case
    /// 📚 학습 포인트: System Under Test (SUT)
    /// 테스트할 객체를 명시적으로 선언
    var sut: CalculateTDEEUseCase!

    // MARK: - Setup & Teardown

    /// 각 테스트 메서드 실행 전에 호출
    /// 📚 학습 포인트: Test Setup
    /// 테스트 환경을 초기화하여 각 테스트가 독립적으로 실행되도록 보장
    /// 💡 Java 비교: JUnit의 @Before 또는 @BeforeEach와 유사
    override func setUp() {
        super.setUp()
        sut = CalculateTDEEUseCase()
    }

    /// 각 테스트 메서드 실행 후에 호출
    /// 📚 학습 포인트: Test Teardown
    /// 테스트 후 정리 작업 수행
    /// 💡 Java 비교: JUnit의 @After 또는 @AfterEach와 유사
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Activity Level Multiplier Tests

    /// Sedentary (1.2) 활동 계수 테스트
    /// 📚 학습 포인트: Test Method Naming
    /// test + 테스트하는 기능 + 예상 결과 패턴
    /// 💡 Given-When-Then 패턴 사용
    func testCalculateTDEE_SedentaryActivityLevel_AppliesCorrectMultiplier() {
        // Given: BMR 1500 kcal/day, Sedentary 활동 수준
        // 예상 TDEE: 1500 × 1.2 = 1800 kcal/day
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1500),
            activityLevel: .sedentary
        )

        // When: TDEE 계산 실행
        let result = try? sut.execute(input: input)

        // Then: 결과가 예상값과 일치
        XCTAssertNotNil(result, "TDEE 계산 결과가 nil이 아니어야 합니다")
        XCTAssertEqual(result?.tdee, Decimal(1800), accuracy: Decimal(0.01),
                      "Sedentary 활동 계수(1.2)가 정확하게 적용되어야 합니다")
    }

    /// Lightly Active (1.375) 활동 계수 테스트
    func testCalculateTDEE_LightlyActiveLevel_AppliesCorrectMultiplier() {
        // Given: BMR 1600 kcal/day, Lightly Active 활동 수준
        // 예상 TDEE: 1600 × 1.375 = 2200 kcal/day
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1600),
            activityLevel: .lightlyActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(2200), accuracy: Decimal(0.01),
                      "Lightly Active 활동 계수(1.375)가 정확하게 적용되어야 합니다")
    }

    /// Moderately Active (1.55) 활동 계수 테스트
    func testCalculateTDEE_ModeratelyActiveLevel_AppliesCorrectMultiplier() {
        // Given: BMR 1648 kcal/day, Moderately Active 활동 수준
        // 예상 TDEE: 1648 × 1.55 = 2554.4 kcal/day
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1648),
            activityLevel: .moderatelyActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(2554.4), accuracy: Decimal(0.01),
                      "Moderately Active 활동 계수(1.55)가 정확하게 적용되어야 합니다")
    }

    /// Very Active (1.725) 활동 계수 테스트
    func testCalculateTDEE_VeryActiveLevel_AppliesCorrectMultiplier() {
        // Given: BMR 2000 kcal/day, Very Active 활동 수준
        // 예상 TDEE: 2000 × 1.725 = 3450 kcal/day
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(2000),
            activityLevel: .veryActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(3450), accuracy: Decimal(0.01),
                      "Very Active 활동 계수(1.725)가 정확하게 적용되어야 합니다")
    }

    /// Extra Active (1.9) 활동 계수 테스트
    func testCalculateTDEE_ExtraActiveLevel_AppliesCorrectMultiplier() {
        // Given: BMR 2200 kcal/day, Extra Active 활동 수준
        // 예상 TDEE: 2200 × 1.9 = 4180 kcal/day
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(2200),
            activityLevel: .extraActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(4180), accuracy: Decimal(0.01),
                      "Extra Active 활동 계수(1.9)가 정확하게 적용되어야 합니다")
    }

    // MARK: - All Activity Levels Test

    /// 모든 활동 수준에 대한 계수 정확도 테스트
    /// 📚 학습 포인트: Comprehensive Testing
    /// 한 번의 테스트로 모든 케이스 검증
    func testCalculateTDEE_AllActivityLevels_ApplyCorrectMultipliers() {
        // Given: 각 활동 수준별 예상 결과
        let bmr = Decimal(1500)
        let testCases: [(ActivityLevel, Decimal)] = [
            (.sedentary, Decimal(1800)),           // 1500 × 1.2
            (.lightlyActive, Decimal(2062.5)),     // 1500 × 1.375
            (.moderatelyActive, Decimal(2325)),    // 1500 × 1.55
            (.veryActive, Decimal(2587.5)),        // 1500 × 1.725
            (.extraActive, Decimal(2850))          // 1500 × 1.9
        ]

        // When & Then: 각 활동 수준별로 검증
        for (activityLevel, expectedTDEE) in testCases {
            let input = CalculateTDEEUseCase.Input(bmr: bmr, activityLevel: activityLevel)
            let result = try? sut.execute(input: input)

            XCTAssertNotNil(result,
                          "\(activityLevel.displayName)의 TDEE 계산 결과가 nil이 아니어야 합니다")
            XCTAssertEqual(result?.tdee, expectedTDEE, accuracy: Decimal(0.01),
                          "\(activityLevel.displayName) (×\(activityLevel.multiplier))의 계수가 정확해야 합니다")
        }
    }

    // MARK: - Activity Level Comparison Tests

    /// 활동 수준 간 TDEE 차이 확인
    /// 📚 학습 포인트: Comparative Testing
    /// 활동 수준이 높을수록 TDEE가 증가하는지 확인
    func testCalculateTDEE_HigherActivityLevel_ResultsInHigherTDEE() {
        // Given: 같은 BMR, 다른 활동 수준
        let bmr = Decimal(1500)
        let sedentaryInput = CalculateTDEEUseCase.Input(bmr: bmr, activityLevel: .sedentary)
        let veryActiveInput = CalculateTDEEUseCase.Input(bmr: bmr, activityLevel: .veryActive)

        // When
        let sedentaryResult = try? sut.execute(input: sedentaryInput)
        let veryActiveResult = try? sut.execute(input: veryActiveInput)

        // Then: Very Active가 Sedentary보다 높아야 함
        XCTAssertNotNil(sedentaryResult)
        XCTAssertNotNil(veryActiveResult)
        XCTAssertGreaterThan(veryActiveResult?.tdee ?? 0, sedentaryResult?.tdee ?? 0,
                           "활동 수준이 높을수록 TDEE가 높아야 합니다")

        // 정확한 차이 검증
        let difference = (veryActiveResult?.tdee ?? 0) - (sedentaryResult?.tdee ?? 0)
        // 1500 × 1.725 - 1500 × 1.2 = 2587.5 - 1800 = 787.5
        XCTAssertEqual(difference, Decimal(787.5), accuracy: Decimal(0.01))
    }

    /// 인접한 활동 수준 간 차이 확인
    func testCalculateTDEE_AdjacentActivityLevels_ShowsExpectedIncrement() {
        // Given: 같은 BMR, 인접한 활동 수준
        let bmr = Decimal(1000)
        let sedentaryInput = CalculateTDEEUseCase.Input(bmr: bmr, activityLevel: .sedentary)
        let lightlyActiveInput = CalculateTDEEUseCase.Input(bmr: bmr, activityLevel: .lightlyActive)

        // When
        let sedentaryResult = try? sut.execute(input: sedentaryInput)
        let lightlyActiveResult = try? sut.execute(input: lightlyActiveInput)

        // Then
        // Sedentary: 1000 × 1.2 = 1200
        // Lightly Active: 1000 × 1.375 = 1375
        // 차이: 175 kcal
        XCTAssertNotNil(sedentaryResult)
        XCTAssertNotNil(lightlyActiveResult)

        let difference = (lightlyActiveResult?.tdee ?? 0) - (sedentaryResult?.tdee ?? 0)
        XCTAssertEqual(difference, Decimal(175), accuracy: Decimal(0.01),
                      "Sedentary에서 Lightly Active로 변경 시 175 kcal 증가해야 합니다")
    }

    // MARK: - Edge Case Tests

    /// 최소 유효 BMR 테스트
    /// 📚 학습 포인트: Boundary Value Testing
    /// 경계값에서의 동작 확인
    func testCalculateTDEE_MinimumValidBMR_Succeeds() {
        // Given: 최소한의 유효 BMR (1 kcal/day)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1),
            activityLevel: .sedentary
        )

        // When & Then: 에러 없이 계산되어야 함
        XCTAssertNoThrow(try sut.execute(input: input),
                        "최소 유효 BMR로 TDEE 계산이 가능해야 합니다")

        let result = try? sut.execute(input: input)
        XCTAssertNotNil(result)
        // 1 × 1.2 = 1.2
        XCTAssertEqual(result?.tdee, Decimal(1.2), accuracy: Decimal(0.01))
    }

    /// 높은 BMR 값 테스트
    func testCalculateTDEE_HighBMR_ReturnsCorrectValue() {
        // Given: 높은 BMR (3000 kcal/day) - 대형 운동선수
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(3000),
            activityLevel: .veryActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 3000 × 1.725 = 5175 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(5175), accuracy: Decimal(0.01))
        XCTAssertLessThan(result?.tdee ?? 0, Decimal(10000),
                         "TDEE가 합리적 최대값(10000) 이하여야 합니다")
    }

    /// 매우 높은 BMR - 엘리트 운동선수 케이스
    func testCalculateTDEE_VeryHighBMR_StillWithinSanityCheck() {
        // Given: 엘리트 운동선수 (BMR 4000, Extra Active)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(4000),
            activityLevel: .extraActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 4000 × 1.9 = 7600 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(7600), accuracy: Decimal(0.01))
        XCTAssertLessThan(result?.tdee ?? 0, Decimal(10000),
                         "TDEE가 10000 kcal 이하여야 합니다")
    }

    // MARK: - Invalid Input Tests

    /// 0 BMR 테스트
    /// 📚 학습 포인트: Error Testing
    /// 예상되는 에러가 올바르게 발생하는지 확인
    func testCalculateTDEE_ZeroBMR_ThrowsInvalidInputError() {
        // Given: BMR이 0
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(0),
            activityLevel: .sedentary
        )

        // When & Then: invalidInput 에러가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            XCTAssertTrue(error is CalculateTDEEUseCase.TDEEError,
                         "TDEEError 타입이어야 합니다")
            if let tdeeError = error as? CalculateTDEEUseCase.TDEEError {
                XCTAssertEqual(tdeeError, .invalidInput,
                             "invalidInput 에러여야 합니다")
            }
        }
    }

    /// 음수 BMR 테스트
    func testCalculateTDEE_NegativeBMR_ThrowsInvalidInputError() {
        // Given: 음수 BMR
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(-1000),
            activityLevel: .sedentary
        )

        // When & Then: invalidInput 에러가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let tdeeError = error as? CalculateTDEEUseCase.TDEEError {
                XCTAssertEqual(tdeeError, .invalidInput)
            }
        }
    }

    // MARK: - Sanity Check Tests

    /// 비정상적으로 낮은 TDEE - sanity check 테스트
    /// 📚 학습 포인트: Sanity Check Testing
    /// 계산 결과가 합리적 범위를 벗어나는지 확인
    func testCalculateTDEE_UnrealisticallyLowTDEE_ThrowsCalculationError() {
        // Given: 비현실적으로 낮은 BMR (100 kcal/day)
        // 예상 TDEE: 100 × 1.2 = 120 (400 미만)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(100),
            activityLevel: .sedentary
        )

        // When & Then: calculationError가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let tdeeError = error as? CalculateTDEEUseCase.TDEEError {
                XCTAssertEqual(tdeeError, .calculationError,
                             "400 kcal 미만은 calculationError여야 합니다")
            }
        }
    }

    /// 비정상적으로 높은 TDEE - sanity check 테스트
    func testCalculateTDEE_UnrealisticallyHighTDEE_ThrowsCalculationError() {
        // Given: 비현실적으로 높은 BMR (6000 kcal/day, Extra Active)
        // 예상 TDEE: 6000 × 1.9 = 11400 (10000 초과)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(6000),
            activityLevel: .extraActive
        )

        // When & Then: calculationError가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let tdeeError = error as? CalculateTDEEUseCase.TDEEError {
                XCTAssertEqual(tdeeError, .calculationError,
                             "10000 kcal 초과는 calculationError여야 합니다")
            }
        }
    }

    // MARK: - Precision Tests

    /// 소수점 정밀도 테스트
    /// 📚 학습 포인트: Decimal Precision Testing
    /// Decimal 타입이 소수점을 정확하게 처리하는지 확인
    func testCalculateTDEE_DecimalPrecision_MaintainsAccuracy() {
        // Given: 소수점이 있는 BMR
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1648.75),
            activityLevel: .moderatelyActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 2 decimal places까지 정확
        // 1648.75 × 1.55 = 2555.5625
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(2555.5625), accuracy: Decimal(0.01),
                      "소수점 2자리까지 정확해야 합니다")
    }

    /// 반올림된 TDEE 테스트
    func testCalculateTDEE_RoundedTDEE_ReturnsIntegerValue() {
        // Given
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1648),
            activityLevel: .moderatelyActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: roundedTDEE은 정수여야 함
        // 1648 × 1.55 = 2554.4 → 2554
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.roundedTDEE, 2554,
                      "반올림된 TDEE은 정수여야 합니다")
    }

    /// 반올림 정확도 테스트 (.5 케이스)
    func testCalculateTDEE_Rounding_HandlesHalfCorrectly() {
        // Given: 반올림 시 .5가 되는 케이스
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1250),
            activityLevel: .sedentary
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 1250 × 1.2 = 1500.0 → 1500
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(1500), accuracy: Decimal(0.01))
        XCTAssertEqual(result?.roundedTDEE, 1500)
    }

    // MARK: - Output Formatting Tests

    /// 포맷된 출력 테스트
    /// 📚 학습 포인트: Output Formatting Testing
    /// UI 표시용 문자열 포맷이 올바른지 확인
    func testCalculateTDEE_FormattedOutput_ReturnsCorrectString() {
        // Given
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1648),
            activityLevel: .moderatelyActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: "2,554 kcal/day" 형식이어야 함
        XCTAssertNotNil(result)
        let formattedString = result?.formatted()
        XCTAssertNotNil(formattedString)
        XCTAssertTrue(formattedString?.contains("2,554") ?? false,
                     "포맷된 문자열에 쉼표로 구분된 숫자가 포함되어야 합니다")
        XCTAssertTrue(formattedString?.contains("kcal/day") ?? false,
                     "포맷된 문자열에 단위가 포함되어야 합니다")
    }

    // MARK: - Convenience Method Tests

    /// 개별 파라미터 편의 메서드 테스트
    func testCalculateTDEE_ConvenienceMethodWithParameters_ReturnsCorrectValue() {
        // Given
        let bmr = Decimal(1648)
        let activityLevel = ActivityLevel.moderatelyActive

        // When: 편의 메서드 사용
        let result = try? sut.execute(bmr: bmr, activityLevel: activityLevel)

        // Then: 표준 메서드와 동일한 결과
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(2554.4), accuracy: Decimal(0.01))
    }

    /// BMR Output 편의 메서드 테스트
    /// 📚 학습 포인트: Use Case Composition Testing
    /// 다른 Use Case의 결과를 입력으로 받는 패턴 테스트
    func testCalculateTDEE_ConvenienceMethodWithBMROutput_ReturnsCorrectValue() {
        // Given: BMR 계산 결과
        let bmrOutput = CalculateBMRUseCase.Output(bmr: Decimal(1648.75))
        let activityLevel = ActivityLevel.moderatelyActive

        // When: BMR Output을 받는 편의 메서드 사용
        let result = try? sut.execute(bmrOutput: bmrOutput, activityLevel: activityLevel)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(2555.5625), accuracy: Decimal(0.01))
    }

    // MARK: - Integration Tests

    /// BMR → TDEE 통합 계산 테스트
    /// 📚 학습 포인트: Integration Testing
    /// 두 개의 Use Case를 연결하여 실제 사용 시나리오 테스트
    func testCalculateTDEE_IntegrationWithBMRCalculation_WorksCorrectly() {
        // Given: BMR 계산
        let bmrUseCase = CalculateBMRUseCase()
        let bmrInput = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(175),
            age: 30,
            gender: .male
        )

        // When: BMR 계산 후 TDEE 계산
        do {
            let bmrOutput = try bmrUseCase.execute(input: bmrInput)
            let tdeeOutput = try sut.execute(bmrOutput: bmrOutput, activityLevel: .moderatelyActive)

            // Then: 전체 흐름이 정상 작동
            // BMR: 1648.75
            // TDEE: 1648.75 × 1.55 = 2555.5625
            XCTAssertEqual(bmrOutput.bmr, Decimal(1648.75), accuracy: Decimal(0.01))
            XCTAssertEqual(tdeeOutput.tdee, Decimal(2555.5625), accuracy: Decimal(0.01))
        } catch {
            XCTFail("BMR → TDEE 통합 계산이 실패했습니다: \(error)")
        }
    }

    // MARK: - Performance Tests

    /// 성능 테스트
    /// 📚 학습 포인트: Performance Testing
    /// 계산이 충분히 빠른지 확인 (목표: 0.01초 이내)
    func testCalculateTDEE_Performance_CompletesQuickly() {
        // Given
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1648),
            activityLevel: .moderatelyActive
        )

        // When & Then: 성능 측정
        measure {
            _ = try? sut.execute(input: input)
        }
    }

    /// 여러 번 계산 성능 테스트
    func testCalculateTDEE_MultipleCalculations_MaintainsPerformance() {
        // Given: 다양한 BMR과 활동 수준 조합
        let testData: [(Decimal, ActivityLevel)] = [
            (Decimal(1200), .sedentary),
            (Decimal(1400), .lightlyActive),
            (Decimal(1600), .moderatelyActive),
            (Decimal(1800), .veryActive),
            (Decimal(2000), .extraActive)
        ]

        let inputs = (1...20).flatMap { _ in
            testData.map { CalculateTDEEUseCase.Input(bmr: $0.0, activityLevel: $0.1) }
        }

        // When & Then: 100번 계산 성능 측정
        measure {
            for input in inputs {
                _ = try? sut.execute(input: input)
            }
        }
    }

    // MARK: - Real World Scenario Tests

    /// 실제 시나리오: 다이어트 중인 사람의 TDEE
    /// 📚 학습 포인트: Real World Testing
    /// 실제 사용 케이스를 반영한 테스트
    func testCalculateTDEE_DietingScenario_ReturnsRealisticValue() {
        // Given: 다이어트 중인 30세 여성 (BMR 1300, Lightly Active)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1300),
            activityLevel: .lightlyActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 1300 × 1.375 = 1787.5 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(1787.5), accuracy: Decimal(0.01))

        // TDEE가 BMR보다 높아야 함
        XCTAssertGreaterThan(result?.tdee ?? 0, Decimal(1300),
                           "TDEE는 항상 BMR보다 높아야 합니다")
    }

    /// 실제 시나리오: 운동선수의 TDEE
    func testCalculateTDEE_AthleteScenario_ReturnsHighValue() {
        // Given: 엘리트 운동선수 (BMR 2300, Very Active)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(2300),
            activityLevel: .veryActive
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 2300 × 1.725 = 3967.5 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(3967.5), accuracy: Decimal(0.01))

        // 운동선수는 높은 TDEE를 가져야 함 (3500 이상)
        XCTAssertGreaterThanOrEqual(result?.tdee ?? 0, Decimal(3500),
                                   "운동선수의 TDEE는 3500 kcal 이상이어야 합니다")
    }

    /// 실제 시나리오: 사무직 근로자의 TDEE
    func testCalculateTDEE_OfficeWorkerScenario_ReturnsModerateValue() {
        // Given: 사무직 근로자 (BMR 1600, Sedentary)
        let input = CalculateTDEEUseCase.Input(
            bmr: Decimal(1600),
            activityLevel: .sedentary
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 1600 × 1.2 = 1920 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.tdee, Decimal(1920), accuracy: Decimal(0.01))

        // 일반적인 성인 범위 내 (1500-2500)
        XCTAssertGreaterThanOrEqual(result?.tdee ?? 0, Decimal(1500))
        XCTAssertLessThanOrEqual(result?.tdee ?? 0, Decimal(2500))
    }
}
