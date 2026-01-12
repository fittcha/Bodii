//
//  CalculateBMRUseCaseTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: XCTest Framework
// Swift의 표준 테스트 프레임워크로 단위 테스트 작성
// 💡 Java 비교: JUnit과 유사한 역할

import XCTest
@testable import Bodii

/// CalculateBMRUseCase에 대한 단위 테스트
/// 📚 학습 포인트: Test Class Naming Convention
/// 테스트 대상 클래스 이름 + Tests 패턴 사용
/// 💡 Java 비교: JUnit의 테스트 클래스 명명 규칙과 동일
final class CalculateBMRUseCaseTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Use Case
    /// 📚 학습 포인트: System Under Test (SUT)
    /// 테스트할 객체를 명시적으로 선언
    var sut: CalculateBMRUseCase!

    // MARK: - Setup & Teardown

    /// 각 테스트 메서드 실행 전에 호출
    /// 📚 학습 포인트: Test Setup
    /// 테스트 환경을 초기화하여 각 테스트가 독립적으로 실행되도록 보장
    /// 💡 Java 비교: JUnit의 @Before 또는 @BeforeEach와 유사
    override func setUp() {
        super.setUp()
        sut = CalculateBMRUseCase()
    }

    /// 각 테스트 메서드 실행 후에 호출
    /// 📚 학습 포인트: Test Teardown
    /// 테스트 후 정리 작업 수행
    /// 💡 Java 비교: JUnit의 @After 또는 @AfterEach와 유사
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Male BMR Calculation Tests

    /// 남성 BMR 계산 - 표준 케이스
    /// 📚 학습 포인트: Test Method Naming
    /// test + 테스트하는 기능 + 예상 결과 패턴
    /// 💡 Given-When-Then 패턴 사용
    func testCalculateBMR_MaleStandardCase_ReturnsCorrectValue() {
        // Given: 30세 남성, 70kg, 175cm
        // 예상 BMR: (10 × 70) + (6.25 × 175) - (5 × 30) + 5
        //         = 700 + 1093.75 - 150 + 5
        //         = 1648.75 kcal/day
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(175),
            age: 30,
            gender: .male
        )

        // When: BMR 계산 실행
        let result = try? sut.execute(input: input)

        // Then: 결과가 예상값과 일치
        XCTAssertNotNil(result, "BMR 계산 결과가 nil이 아니어야 합니다")
        XCTAssertEqual(result?.bmr, Decimal(1648.75), accuracy: Decimal(0.01),
                      "남성 BMR 계산이 정확해야 합니다")
    }

    /// 남성 BMR 계산 - 젊고 가벼운 케이스
    func testCalculateBMR_MaleYoungAndLight_ReturnsCorrectValue() {
        // Given: 20세 남성, 60kg, 170cm
        // 예상 BMR: (10 × 60) + (6.25 × 170) - (5 × 20) + 5
        //         = 600 + 1062.5 - 100 + 5
        //         = 1567.5 kcal/day
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(60),
            height: Decimal(170),
            age: 20,
            gender: .male
        )

        let result = try? sut.execute(input: input)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1567.5), accuracy: Decimal(0.01))
    }

    /// 남성 BMR 계산 - 나이가 많고 무거운 케이스
    func testCalculateBMR_MaleOldAndHeavy_ReturnsCorrectValue() {
        // Given: 60세 남성, 90kg, 180cm
        // 예상 BMR: (10 × 90) + (6.25 × 180) - (5 × 60) + 5
        //         = 900 + 1125 - 300 + 5
        //         = 1730 kcal/day
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(90),
            height: Decimal(180),
            age: 60,
            gender: .male
        )

        let result = try? sut.execute(input: input)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1730), accuracy: Decimal(0.01))
    }

    // MARK: - Female BMR Calculation Tests

    /// 여성 BMR 계산 - 표준 케이스
    func testCalculateBMR_FemaleStandardCase_ReturnsCorrectValue() {
        // Given: 25세 여성, 55kg, 162cm
        // 예상 BMR: (10 × 55) + (6.25 × 162) - (5 × 25) - 161
        //         = 550 + 1012.5 - 125 - 161
        //         = 1276.5 kcal/day
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(55),
            height: Decimal(162),
            age: 25,
            gender: .female
        )

        let result = try? sut.execute(input: input)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1276.5), accuracy: Decimal(0.01),
                      "여성 BMR 계산이 정확해야 합니다")
    }

    /// 여성 BMR 계산 - 젊고 가벼운 케이스
    func testCalculateBMR_FemaleYoungAndLight_ReturnsCorrectValue() {
        // Given: 20세 여성, 50kg, 160cm
        // 예상 BMR: (10 × 50) + (6.25 × 160) - (5 × 20) - 161
        //         = 500 + 1000 - 100 - 161
        //         = 1239 kcal/day
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(50),
            height: Decimal(160),
            age: 20,
            gender: .female
        )

        let result = try? sut.execute(input: input)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1239), accuracy: Decimal(0.01))
    }

    /// 여성 BMR 계산 - 나이가 많고 무거운 케이스
    func testCalculateBMR_FemaleOldAndHeavy_ReturnsCorrectValue() {
        // Given: 55세 여성, 75kg, 168cm
        // 예상 BMR: (10 × 75) + (6.25 × 168) - (5 × 55) - 161
        //         = 750 + 1050 - 275 - 161
        //         = 1364 kcal/day
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(75),
            height: Decimal(168),
            age: 55,
            gender: .female
        )

        let result = try? sut.execute(input: input)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1364), accuracy: Decimal(0.01))
    }

    // MARK: - Gender Difference Tests

    /// 동일한 조건에서 남성과 여성의 BMR 차이 확인
    /// 📚 학습 포인트: Comparative Testing
    /// 같은 조건에서 다른 값이 나와야 하는 케이스 테스트
    func testCalculateBMR_SameConditionsDifferentGender_ShowsExpectedDifference() {
        // Given: 같은 체격의 남성과 여성
        let maleInput = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(170),
            age: 30,
            gender: .male
        )
        let femaleInput = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(170),
            age: 30,
            gender: .female
        )

        // When: 각각 BMR 계산
        let maleResult = try? sut.execute(input: maleInput)
        let femaleResult = try? sut.execute(input: femaleInput)

        // Then: 남성이 여성보다 166 kcal 더 높아야 함 (5 - (-161) = 166)
        XCTAssertNotNil(maleResult)
        XCTAssertNotNil(femaleResult)

        let difference = (maleResult?.bmr ?? 0) - (femaleResult?.bmr ?? 0)
        XCTAssertEqual(difference, Decimal(166), accuracy: Decimal(0.01),
                      "성별에 따른 BMR 차이가 정확해야 합니다 (166 kcal)")

        // 남성 BMR이 더 높아야 함
        XCTAssertGreaterThan(maleResult?.bmr ?? 0, femaleResult?.bmr ?? 0,
                           "같은 조건에서 남성의 BMR이 여성보다 높아야 합니다")
    }

    // MARK: - Edge Case Tests

    /// 최소 유효 값 테스트
    /// 📚 학습 포인트: Boundary Value Testing
    /// 경계값에서의 동작 확인
    func testCalculateBMR_MinimumValidValues_Succeeds() {
        // Given: 최소한의 유효 값 (1세, 20kg, 50cm)
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(20),
            height: Decimal(50),
            age: 1,
            gender: .female
        )

        // When & Then: 에러 없이 계산되어야 함
        XCTAssertNoThrow(try sut.execute(input: input),
                        "최소 유효 값으로 BMR 계산이 가능해야 합니다")

        let result = try? sut.execute(input: input)
        XCTAssertNotNil(result)
        // (10 × 20) + (6.25 × 50) - (5 × 1) - 161 = 200 + 312.5 - 5 - 161 = 346.5
        XCTAssertEqual(result?.bmr, Decimal(346.5), accuracy: Decimal(0.01))
    }

    /// 높은 값 테스트
    func testCalculateBMR_HighValues_ReturnsCorrectValue() {
        // Given: 높은 값 (80세, 150kg, 200cm) - 비만인 노인
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(150),
            height: Decimal(200),
            age: 80,
            gender: .male
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 계산이 성공하고 결과가 합리적 범위 내
        // (10 × 150) + (6.25 × 200) - (5 × 80) + 5
        // = 1500 + 1250 - 400 + 5 = 2355 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(2355), accuracy: Decimal(0.01))
        XCTAssertLessThan(result?.bmr ?? 0, Decimal(5000),
                         "BMR이 합리적 최대값(5000) 이하여야 합니다")
    }

    /// 매우 높은 값 - 엘리트 운동선수 케이스
    func testCalculateBMR_VeryHighValues_StillWithinSanityCheck() {
        // Given: 엘리트 운동선수 (25세, 120kg, 195cm) - 근육질 대형 선수
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(120),
            height: Decimal(195),
            age: 25,
            gender: .male
        )

        // When
        let result = try? sut.execute(input: input)

        // Then
        // (10 × 120) + (6.25 × 195) - (5 × 25) + 5
        // = 1200 + 1218.75 - 125 + 5 = 2298.75 kcal/day
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(2298.75), accuracy: Decimal(0.01))
    }

    // MARK: - Invalid Input Tests

    /// 0 또는 음수 체중 테스트
    /// 📚 학습 포인트: Error Testing
    /// 예상되는 에러가 올바르게 발생하는지 확인
    func testCalculateBMR_ZeroWeight_ThrowsInvalidInputError() {
        // Given: 체중이 0
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(0),
            height: Decimal(170),
            age: 30,
            gender: .male
        )

        // When & Then: invalidInput 에러가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            XCTAssertTrue(error is CalculateBMRUseCase.BMRError,
                         "BMRError 타입이어야 합니다")
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .invalidInput,
                             "invalidInput 에러여야 합니다")
            }
        }
    }

    /// 음수 체중 테스트
    func testCalculateBMR_NegativeWeight_ThrowsInvalidInputError() {
        // Given: 음수 체중
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(-10),
            height: Decimal(170),
            age: 30,
            gender: .male
        )

        // When & Then: invalidInput 에러가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .invalidInput)
            }
        }
    }

    /// 0 또는 음수 신장 테스트
    func testCalculateBMR_ZeroHeight_ThrowsInvalidInputError() {
        // Given: 신장이 0
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(0),
            age: 30,
            gender: .male
        )

        // When & Then
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .invalidInput)
            }
        }
    }

    /// 음수 신장 테스트
    func testCalculateBMR_NegativeHeight_ThrowsInvalidInputError() {
        // Given: 음수 신장
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(-170),
            age: 30,
            gender: .male
        )

        // When & Then
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .invalidInput)
            }
        }
    }

    /// 0 또는 음수 나이 테스트
    func testCalculateBMR_ZeroAge_ThrowsInvalidInputError() {
        // Given: 나이가 0
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(170),
            age: 0,
            gender: .male
        )

        // When & Then
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .invalidInput)
            }
        }
    }

    /// 음수 나이 테스트
    func testCalculateBMR_NegativeAge_ThrowsInvalidInputError() {
        // Given: 음수 나이
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(170),
            age: -5,
            gender: .male
        )

        // When & Then
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .invalidInput)
            }
        }
    }

    // MARK: - Sanity Check Tests

    /// 비정상적으로 낮은 BMR - sanity check 테스트
    /// 📚 학습 포인트: Sanity Check Testing
    /// 계산 결과가 합리적 범위를 벗어나는지 확인
    func testCalculateBMR_UnrealisticallyLowBMR_ThrowsCalculationError() {
        // Given: 비현실적으로 낮은 값 (1세, 1kg, 10cm)
        // 예상 BMR: (10 × 1) + (6.25 × 10) - (5 × 1) - 161
        //         = 10 + 62.5 - 5 - 161 = -93.5 (300 미만)
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(1),
            height: Decimal(10),
            age: 1,
            gender: .female
        )

        // When & Then: calculationError가 발생해야 함
        XCTAssertThrowsError(try sut.execute(input: input)) { error in
            if let bmrError = error as? CalculateBMRUseCase.BMRError {
                XCTAssertEqual(bmrError, .calculationError,
                             "300 kcal 미만은 calculationError여야 합니다")
            }
        }
    }

    // MARK: - Precision Tests

    /// 소수점 정밀도 테스트
    /// 📚 학습 포인트: Decimal Precision Testing
    /// Decimal 타입이 소수점을 정확하게 처리하는지 확인
    func testCalculateBMR_DecimalPrecision_MaintainsAccuracy() {
        // Given: 소수점이 있는 값
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70.5),
            height: Decimal(175.5),
            age: 30,
            gender: .male
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: 2 decimal places까지 정확
        // (10 × 70.5) + (6.25 × 175.5) - (5 × 30) + 5
        // = 705 + 1096.875 - 150 + 5 = 1656.875
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1656.875), accuracy: Decimal(0.01),
                      "소수점 2자리까지 정확해야 합니다")
    }

    /// 반올림된 BMR 테스트
    func testCalculateBMR_RoundedBMR_ReturnsIntegerValue() {
        // Given
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(175),
            age: 30,
            gender: .male
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: roundedBMR은 정수여야 함 (1648.75 → 1649)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.roundedBMR, 1649,
                      "반올림된 BMR은 정수여야 합니다")
    }

    // MARK: - Output Formatting Tests

    /// 포맷된 출력 테스트
    /// 📚 학습 포인트: Output Formatting Testing
    /// UI 표시용 문자열 포맷이 올바른지 확인
    func testCalculateBMR_FormattedOutput_ReturnsCorrectString() {
        // Given
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(175),
            age: 30,
            gender: .male
        )

        // When
        let result = try? sut.execute(input: input)

        // Then: "1,649 kcal/day" 형식이어야 함
        XCTAssertNotNil(result)
        let formattedString = result?.formatted()
        XCTAssertNotNil(formattedString)
        XCTAssertTrue(formattedString?.contains("1,649") ?? false,
                     "포맷된 문자열에 쉼표로 구분된 숫자가 포함되어야 합니다")
        XCTAssertTrue(formattedString?.contains("kcal/day") ?? false,
                     "포맷된 문자열에 단위가 포함되어야 합니다")
    }

    // MARK: - Convenience Method Tests

    /// 개별 파라미터 편의 메서드 테스트
    func testCalculateBMR_ConvenienceMethodWithParameters_ReturnsCorrectValue() {
        // Given
        let weight = Decimal(70)
        let height = Decimal(175)
        let age = 30
        let gender = Gender.male

        // When: 편의 메서드 사용
        let result = try? sut.execute(weight: weight, height: height, age: age, gender: gender)

        // Then: 표준 메서드와 동일한 결과
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.bmr, Decimal(1648.75), accuracy: Decimal(0.01))
    }

    // MARK: - Performance Tests

    /// 성능 테스트
    /// 📚 학습 포인트: Performance Testing
    /// 계산이 충분히 빠른지 확인 (목표: 0.01초 이내)
    func testCalculateBMR_Performance_CompletesQuickly() {
        // Given
        let input = CalculateBMRUseCase.Input(
            weight: Decimal(70),
            height: Decimal(175),
            age: 30,
            gender: .male
        )

        // When & Then: 성능 측정
        measure {
            _ = try? sut.execute(input: input)
        }
    }

    /// 여러 번 계산 성능 테스트
    func testCalculateBMR_MultipleCalculations_MaintainsPerformance() {
        // Given
        let inputs = (1...100).map { index in
            CalculateBMRUseCase.Input(
                weight: Decimal(50 + index),
                height: Decimal(150 + index / 2),
                age: 20 + index / 5,
                gender: index % 2 == 0 ? .male : .female
            )
        }

        // When & Then: 100번 계산 성능 측정
        measure {
            for input in inputs {
                _ = try? sut.execute(input: input)
            }
        }
    }
}

// MARK: - XCTAssert Extensions

/// 📚 학습 포인트: Custom Assertion Helper
/// Decimal 타입의 근사값 비교를 위한 커스텀 assertion
/// 💡 Java 비교: assertThat().isCloseTo()와 유사
extension XCTAssertEqual where T == Decimal {
    static func assertEqual(_ expression1: @autoclosure () throws -> Decimal,
                           _ expression2: @autoclosure () throws -> Decimal,
                           accuracy: Decimal,
                           _ message: @autoclosure () -> String = "",
                           file: StaticString = #filePath,
                           line: UInt = #line) {
        do {
            let value1 = try expression1()
            let value2 = try expression2()
            let difference = abs(value1 - value2)

            XCTAssertLessThanOrEqual(difference, accuracy, message(), file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
