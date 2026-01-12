//
//  ValidationServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-12.
//

import XCTest
@testable import Bodii

/// Unit tests for ValidationService input validation
///
/// ValidationService 입력 검증에 대한 단위 테스트
final class ValidationServiceTests: XCTestCase {

    // MARK: - Height Validation Tests

    /// Test: Valid height at minimum boundary (100cm)
    ///
    /// 테스트: 최소 경계의 유효한 키 (100cm)
    func testValidateHeight_MinimumBoundary_ReturnsSuccess() {
        // Given: Minimum valid height (100cm)
        let height: Double = 100.0

        // When: Validating height
        let result = ValidationService.validateHeight(height)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "100cm should be valid (minimum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid height at maximum boundary (250cm)
    ///
    /// 테스트: 최대 경계의 유효한 키 (250cm)
    func testValidateHeight_MaximumBoundary_ReturnsSuccess() {
        // Given: Maximum valid height (250cm)
        let height: Double = 250.0

        // When: Validating height
        let result = ValidationService.validateHeight(height)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "250cm should be valid (maximum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid height in normal range
    ///
    /// 테스트: 정상 범위의 유효한 키
    func testValidateHeight_NormalRange_ReturnsSuccess() {
        // Given: Normal height values
        let heights: [Double] = [150.5, 170.0, 175.5, 180.3, 200.0]

        // When/Then: All should be valid
        for height in heights {
            let result = ValidationService.validateHeight(height)
            XCTAssertTrue(result.isValid, "\(height)cm should be valid")
            XCTAssertNil(result.errorMessage, "Should not have error message for \(height)cm")
        }
    }

    /// Test: Invalid height below minimum (< 100cm)
    ///
    /// 테스트: 최소값 미만의 무효한 키 (< 100cm)
    func testValidateHeight_BelowMinimum_ReturnsFailure() {
        // Given: Heights below minimum
        let heights: [Double] = [99.9, 50.0, 0.0]

        // When/Then: All should be invalid
        for height in heights {
            let result = ValidationService.validateHeight(height)
            XCTAssertFalse(result.isValid, "\(height)cm should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "키는 100~250cm 사이로 입력해주세요",
                "Should return correct error message for \(height)cm"
            )
        }
    }

    /// Test: Invalid height above maximum (> 250cm)
    ///
    /// 테스트: 최대값 초과의 무효한 키 (> 250cm)
    func testValidateHeight_AboveMaximum_ReturnsFailure() {
        // Given: Heights above maximum
        let heights: [Double] = [250.1, 300.0, 999.9]

        // When/Then: All should be invalid
        for height in heights {
            let result = ValidationService.validateHeight(height)
            XCTAssertFalse(result.isValid, "\(height)cm should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "키는 100~250cm 사이로 입력해주세요",
                "Should return correct error message for \(height)cm"
            )
        }
    }

    // MARK: - Weight Validation Tests

    /// Test: Valid weight at minimum boundary (20kg)
    ///
    /// 테스트: 최소 경계의 유효한 몸무게 (20kg)
    func testValidateWeight_MinimumBoundary_ReturnsSuccess() {
        // Given: Minimum valid weight (20kg)
        let weight: Double = 20.0

        // When: Validating weight
        let result = ValidationService.validateWeight(weight)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "20kg should be valid (minimum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid weight at maximum boundary (300kg)
    ///
    /// 테스트: 최대 경계의 유효한 몸무게 (300kg)
    func testValidateWeight_MaximumBoundary_ReturnsSuccess() {
        // Given: Maximum valid weight (300kg)
        let weight: Double = 300.0

        // When: Validating weight
        let result = ValidationService.validateWeight(weight)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "300kg should be valid (maximum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid weight in normal range
    ///
    /// 테스트: 정상 범위의 유효한 몸무게
    func testValidateWeight_NormalRange_ReturnsSuccess() {
        // Given: Normal weight values
        let weights: [Double] = [50.5, 65.3, 72.5, 80.0, 100.0]

        // When/Then: All should be valid
        for weight in weights {
            let result = ValidationService.validateWeight(weight)
            XCTAssertTrue(result.isValid, "\(weight)kg should be valid")
            XCTAssertNil(result.errorMessage, "Should not have error message for \(weight)kg")
        }
    }

    /// Test: Invalid weight below minimum (< 20kg)
    ///
    /// 테스트: 최소값 미만의 무효한 몸무게 (< 20kg)
    func testValidateWeight_BelowMinimum_ReturnsFailure() {
        // Given: Weights below minimum
        let weights: [Double] = [19.9, 10.0, 0.0]

        // When/Then: All should be invalid
        for weight in weights {
            let result = ValidationService.validateWeight(weight)
            XCTAssertFalse(result.isValid, "\(weight)kg should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "몸무게는 20~300kg 사이로 입력해주세요",
                "Should return correct error message for \(weight)kg"
            )
        }
    }

    /// Test: Invalid weight above maximum (> 300kg)
    ///
    /// 테스트: 최대값 초과의 무효한 몸무게 (> 300kg)
    func testValidateWeight_AboveMaximum_ReturnsFailure() {
        // Given: Weights above maximum
        let weights: [Double] = [300.1, 400.0, 999.9]

        // When/Then: All should be invalid
        for weight in weights {
            let result = ValidationService.validateWeight(weight)
            XCTAssertFalse(result.isValid, "\(weight)kg should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "몸무게는 20~300kg 사이로 입력해주세요",
                "Should return correct error message for \(weight)kg"
            )
        }
    }

    // MARK: - Body Fat Percentage Validation Tests

    /// Test: Valid body fat at minimum boundary (1%)
    ///
    /// 테스트: 최소 경계의 유효한 체지방률 (1%)
    func testValidateBodyFatPercentage_MinimumBoundary_ReturnsSuccess() {
        // Given: Minimum valid body fat percentage (1%)
        let bodyFat: Double = 1.0

        // When: Validating body fat percentage
        let result = ValidationService.validateBodyFatPercentage(bodyFat)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "1% should be valid (minimum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid body fat at maximum boundary (60%)
    ///
    /// 테스트: 최대 경계의 유효한 체지방률 (60%)
    func testValidateBodyFatPercentage_MaximumBoundary_ReturnsSuccess() {
        // Given: Maximum valid body fat percentage (60%)
        let bodyFat: Double = 60.0

        // When: Validating body fat percentage
        let result = ValidationService.validateBodyFatPercentage(bodyFat)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "60% should be valid (maximum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid body fat in normal range
    ///
    /// 테스트: 정상 범위의 유효한 체지방률
    func testValidateBodyFatPercentage_NormalRange_ReturnsSuccess() {
        // Given: Normal body fat percentage values
        let bodyFatPercentages: [Double] = [10.5, 15.0, 18.2, 25.0, 35.5]

        // When/Then: All should be valid
        for bodyFat in bodyFatPercentages {
            let result = ValidationService.validateBodyFatPercentage(bodyFat)
            XCTAssertTrue(result.isValid, "\(bodyFat)% should be valid")
            XCTAssertNil(result.errorMessage, "Should not have error message for \(bodyFat)%")
        }
    }

    /// Test: Valid body fat in extreme but valid range (3% - extreme low)
    ///
    /// 테스트: 극단적이지만 유효한 체지방률 (3% - 극단적 낮음)
    func testValidateBodyFatPercentage_ExtremeLow_ReturnsSuccess() {
        // Given: Extreme low body fat (3% - should trigger warning but pass validation)
        let bodyFat: Double = 3.0

        // When: Validating body fat percentage
        let result = ValidationService.validateBodyFatPercentage(bodyFat)

        // Then: Should be valid (warning is separate from validation)
        XCTAssertTrue(result.isValid, "3% should be valid (extreme but within range)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid body fat in extreme but valid range (50% - extreme high)
    ///
    /// 테스트: 극단적이지만 유효한 체지방률 (50% - 극단적 높음)
    func testValidateBodyFatPercentage_ExtremeHigh_ReturnsSuccess() {
        // Given: Extreme high body fat (50% - should trigger warning but pass validation)
        let bodyFat: Double = 50.0

        // When: Validating body fat percentage
        let result = ValidationService.validateBodyFatPercentage(bodyFat)

        // Then: Should be valid (warning is separate from validation)
        XCTAssertTrue(result.isValid, "50% should be valid (extreme but within range)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Invalid body fat below minimum (< 1%)
    ///
    /// 테스트: 최소값 미만의 무효한 체지방률 (< 1%)
    func testValidateBodyFatPercentage_BelowMinimum_ReturnsFailure() {
        // Given: Body fat percentages below minimum
        let bodyFatPercentages: [Double] = [0.9, 0.5, 0.0]

        // When/Then: All should be invalid
        for bodyFat in bodyFatPercentages {
            let result = ValidationService.validateBodyFatPercentage(bodyFat)
            XCTAssertFalse(result.isValid, "\(bodyFat)% should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "체지방률은 1~60% 사이로 입력해주세요",
                "Should return correct error message for \(bodyFat)%"
            )
        }
    }

    /// Test: Invalid body fat above maximum (> 60%)
    ///
    /// 테스트: 최대값 초과의 무효한 체지방률 (> 60%)
    func testValidateBodyFatPercentage_AboveMaximum_ReturnsFailure() {
        // Given: Body fat percentages above maximum
        let bodyFatPercentages: [Double] = [60.1, 70.0, 100.0]

        // When/Then: All should be invalid
        for bodyFat in bodyFatPercentages {
            let result = ValidationService.validateBodyFatPercentage(bodyFat)
            XCTAssertFalse(result.isValid, "\(bodyFat)% should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "체지방률은 1~60% 사이로 입력해주세요",
                "Should return correct error message for \(bodyFat)%"
            )
        }
    }

    // MARK: - Name Validation Tests

    /// Test: Valid name at minimum boundary (1 character)
    ///
    /// 테스트: 최소 경계의 유효한 이름 (1자)
    func testValidateName_MinimumBoundary_ReturnsSuccess() {
        // Given: Minimum valid name (1 character)
        let name = "A"

        // When: Validating name
        let result = ValidationService.validateName(name)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "1 character name should be valid (minimum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid name at maximum boundary (20 characters)
    ///
    /// 테스트: 최대 경계의 유효한 이름 (20자)
    func testValidateName_MaximumBoundary_ReturnsSuccess() {
        // Given: Maximum valid name (20 characters)
        let name = "12345678901234567890"  // Exactly 20 characters

        // When: Validating name
        let result = ValidationService.validateName(name)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "20 character name should be valid (maximum boundary)")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid names in normal range
    ///
    /// 테스트: 정상 범위의 유효한 이름
    func testValidateName_NormalRange_ReturnsSuccess() {
        // Given: Normal name values
        let names = ["홍길동", "김철수", "John", "Jane Doe", "이영희"]

        // When/Then: All should be valid
        for name in names {
            let result = ValidationService.validateName(name)
            XCTAssertTrue(result.isValid, "'\(name)' should be valid")
            XCTAssertNil(result.errorMessage, "Should not have error message for '\(name)'")
        }
    }

    /// Test: Valid name with Korean characters at maximum boundary
    ///
    /// 테스트: 최대 경계의 한글 이름
    func testValidateName_KoreanMaxBoundary_ReturnsSuccess() {
        // Given: Korean name with 20 characters
        let name = "가나다라마바사아자차카타파하가나다라마바"  // 20 Korean characters

        // When: Validating name
        let result = ValidationService.validateName(name)

        // Then: Should return success
        XCTAssertTrue(result.isValid, "20 character Korean name should be valid")
        XCTAssertNil(result.errorMessage, "Should not have error message")
    }

    /// Test: Valid name with whitespace trimming
    ///
    /// 테스트: 공백 제거 후 유효한 이름
    func testValidateName_WithWhitespace_TrimsAndReturnsSuccess() {
        // Given: Names with leading/trailing whitespace
        let names = ["  홍길동  ", " John ", "\t김철수\n"]

        // When/Then: Should trim and validate successfully
        for name in names {
            let result = ValidationService.validateName(name)
            XCTAssertTrue(result.isValid, "'\(name)' should be valid after trimming")
            XCTAssertNil(result.errorMessage, "Should not have error message for '\(name)'")
        }
    }

    /// Test: Invalid empty name
    ///
    /// 테스트: 빈 이름 무효
    func testValidateName_Empty_ReturnsFailure() {
        // Given: Empty name
        let name = ""

        // When: Validating name
        let result = ValidationService.validateName(name)

        // Then: Should return failure
        XCTAssertFalse(result.isValid, "Empty name should be invalid")
        XCTAssertEqual(
            result.errorMessage,
            "이름을 입력해주세요",
            "Should return correct error message"
        )
    }

    /// Test: Invalid name with only whitespace
    ///
    /// 테스트: 공백만 있는 무효한 이름
    func testValidateName_OnlyWhitespace_ReturnsFailure() {
        // Given: Names with only whitespace
        let names = ["   ", "\t\t", "\n\n", "  \t  \n  "]

        // When/Then: All should be invalid
        for name in names {
            let result = ValidationService.validateName(name)
            XCTAssertFalse(result.isValid, "Whitespace-only name should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "이름을 입력해주세요",
                "Should return correct error message"
            )
        }
    }

    /// Test: Invalid name above maximum length (> 20 characters)
    ///
    /// 테스트: 최대 길이 초과의 무효한 이름 (> 20자)
    func testValidateName_AboveMaximum_ReturnsFailure() {
        // Given: Names above maximum length
        let names = [
            "123456789012345678901",  // 21 characters
            "가나다라마바사아자차카타파하가나다라마바사"  // 21 Korean characters
        ]

        // When/Then: All should be invalid
        for name in names {
            let result = ValidationService.validateName(name)
            XCTAssertFalse(result.isValid, "Name with \(name.count) characters should be invalid")
            XCTAssertEqual(
                result.errorMessage,
                "이름을 입력해주세요",
                "Should return correct error message"
            )
        }
    }

    // MARK: - Warning Check Tests

    /// Test: Extreme body fat detection (low)
    ///
    /// 테스트: 극단적 체지방률 감지 (낮음)
    func testIsExtremeBodyFat_ExtremeLow_ReturnsTrue() {
        // Given: Body fat below 3%
        let bodyFatPercentages: [Double] = [2.9, 2.5, 2.0, 1.0]

        // When/Then: All should be flagged as extreme
        for bodyFat in bodyFatPercentages {
            let isExtreme = ValidationService.isExtremeBodyFat(bodyFat)
            XCTAssertTrue(isExtreme, "\(bodyFat)% should be flagged as extreme low")
        }
    }

    /// Test: Extreme body fat detection (high)
    ///
    /// 테스트: 극단적 체지방률 감지 (높음)
    func testIsExtremeBodyFat_ExtremeHigh_ReturnsTrue() {
        // Given: Body fat above 50%
        let bodyFatPercentages: [Double] = [50.1, 55.0, 60.0]

        // When/Then: All should be flagged as extreme
        for bodyFat in bodyFatPercentages {
            let isExtreme = ValidationService.isExtremeBodyFat(bodyFat)
            XCTAssertTrue(isExtreme, "\(bodyFat)% should be flagged as extreme high")
        }
    }

    /// Test: Normal body fat not flagged as extreme
    ///
    /// 테스트: 정상 체지방률은 극단적으로 플래그되지 않음
    func testIsExtremeBodyFat_NormalRange_ReturnsFalse() {
        // Given: Normal body fat percentages (3-50%)
        let bodyFatPercentages: [Double] = [3.0, 10.0, 18.2, 25.0, 35.0, 50.0]

        // When/Then: None should be flagged as extreme
        for bodyFat in bodyFatPercentages {
            let isExtreme = ValidationService.isExtremeBodyFat(bodyFat)
            XCTAssertFalse(isExtreme, "\(bodyFat)% should not be flagged as extreme")
        }
    }

    /// Test: Rapid weight change detection (gain)
    ///
    /// 테스트: 급격한 체중 변화 감지 (증가)
    func testIsRapidWeightChange_Gain_ReturnsTrue() {
        // Given: Weight gain of 3kg or more
        let testCases: [(previous: Double, current: Double)] = [
            (70.0, 73.0),   // Exactly 3kg
            (70.0, 73.5),   // 3.5kg
            (70.0, 75.0)    // 5kg
        ]

        // When/Then: All should be flagged as rapid
        for testCase in testCases {
            let isRapid = ValidationService.isRapidWeightChange(
                previous: testCase.previous,
                current: testCase.current
            )
            let change = testCase.current - testCase.previous
            XCTAssertTrue(isRapid, "\(change)kg gain should be flagged as rapid")
        }
    }

    /// Test: Rapid weight change detection (loss)
    ///
    /// 테스트: 급격한 체중 변화 감지 (감소)
    func testIsRapidWeightChange_Loss_ReturnsTrue() {
        // Given: Weight loss of 3kg or more
        let testCases: [(previous: Double, current: Double)] = [
            (70.0, 67.0),   // Exactly 3kg
            (70.0, 66.5),   // 3.5kg
            (70.0, 65.0)    // 5kg
        ]

        // When/Then: All should be flagged as rapid
        for testCase in testCases {
            let isRapid = ValidationService.isRapidWeightChange(
                previous: testCase.previous,
                current: testCase.current
            )
            let change = testCase.previous - testCase.current
            XCTAssertTrue(isRapid, "\(change)kg loss should be flagged as rapid")
        }
    }

    /// Test: Normal weight change not flagged as rapid
    ///
    /// 테스트: 정상 체중 변화는 급격하게 플래그되지 않음
    func testIsRapidWeightChange_NormalChange_ReturnsFalse() {
        // Given: Weight changes less than 3kg
        let testCases: [(previous: Double, current: Double)] = [
            (70.0, 70.0),   // No change
            (70.0, 71.5),   // 1.5kg gain
            (70.0, 68.5),   // 1.5kg loss
            (70.0, 72.9)    // 2.9kg gain (just below threshold)
        ]

        // When/Then: None should be flagged as rapid
        for testCase in testCases {
            let isRapid = ValidationService.isRapidWeightChange(
                previous: testCase.previous,
                current: testCase.current
            )
            let change = abs(testCase.current - testCase.previous)
            XCTAssertFalse(isRapid, "\(change)kg change should not be flagged as rapid")
        }
    }
}
