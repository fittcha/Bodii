//
//  KFDAFoodMapperTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Unit tests for KFDAFoodMapper DTO to Food entity mapping
///
/// KFDAFoodMapper의 DTO → Food 엔티티 매핑 단위 테스트
final class KFDAFoodMapperTests: XCTestCase {

    // MARK: - Properties

    var mapper: KFDAFoodMapper!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mapper = KFDAFoodMapper()
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    // MARK: - Successful Mapping Tests

    /// Test: Valid KFDA DTO maps to Food entity successfully
    ///
    /// 테스트: 유효한 KFDA DTO가 Food 엔티티로 성공적으로 변환됨
    func testToDomain_ValidDTO_ReturnsFood() throws {
        // Given: Valid KFDA DTO with all required fields
        let dto = KFDAFoodDTO(
            foodCd: "D000001",
            descKor: "현미밥",
            groupCode: "01",
            groupName: "곡류",
            enercKcal: "330",
            prot: "6.8",
            fat: "2.5",
            chocdf: "73.4",
            na: "5",
            fibtg: "3.0",
            sugar: "0.5",
            servingSize: "210",
            servingWt: "200",
            servingUnit: "1공기"
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should map all fields correctly
        XCTAssertEqual(food.name, "현미밥", "Name should match")
        XCTAssertEqual(food.calories, 330, "Calories should match")
        XCTAssertEqual(food.carbohydrates, Decimal(string: "73.4"), "Carbohydrates should match")
        XCTAssertEqual(food.protein, Decimal(string: "6.8"), "Protein should match")
        XCTAssertEqual(food.fat, Decimal(string: "2.5"), "Fat should match")
        XCTAssertEqual(food.sodium, Decimal(5), "Sodium should match")
        XCTAssertEqual(food.fiber, Decimal(3.0), "Fiber should match")
        XCTAssertEqual(food.sugar, Decimal(0.5), "Sugar should match")
        XCTAssertEqual(food.servingSize, Decimal(210), "Serving size should match")
        XCTAssertEqual(food.servingUnit, "1공기", "Serving unit should match")
        XCTAssertEqual(food.source, .governmentAPI, "Source should be governmentAPI")
        XCTAssertEqual(food.apiCode, "D000001", "API code should match")
        XCTAssertNil(food.createdByUserId, "createdByUserId should be nil for API data")
    }

    /// Test: DTO with minimum required fields only
    ///
    /// 테스트: 최소 필수 필드만 있는 DTO
    func testToDomain_MinimumRequiredFields_ReturnsFood() throws {
        // Given: DTO with only required fields (no optional fields)
        let dto = KFDAFoodDTO(
            foodCd: "D000002",
            descKor: "쌀밥",
            groupCode: nil,
            groupName: nil,
            enercKcal: "300",
            prot: "5.5",
            fat: "1.2",
            chocdf: "70.0",
            na: nil,
            fibtg: nil,
            sugar: nil,
            servingSize: nil,
            servingWt: nil,
            servingUnit: nil
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should map required fields and use defaults for optional
        XCTAssertEqual(food.name, "쌀밥", "Name should match")
        XCTAssertEqual(food.calories, 300, "Calories should match")
        XCTAssertEqual(food.carbohydrates, Decimal(70), "Carbohydrates should match")
        XCTAssertEqual(food.protein, Decimal(5.5), "Protein should match")
        XCTAssertEqual(food.fat, Decimal(1.2), "Fat should match")
        XCTAssertNil(food.sodium, "Sodium should be nil")
        XCTAssertNil(food.fiber, "Fiber should be nil")
        XCTAssertNil(food.sugar, "Sugar should be nil")
        XCTAssertEqual(food.servingSize, Decimal(100), "Serving size should default to 100g")
        XCTAssertNil(food.servingUnit, "Serving unit should be nil")
        XCTAssertEqual(food.source, .governmentAPI, "Source should be governmentAPI")
        XCTAssertEqual(food.apiCode, "D000002", "API code should match")
    }

    /// Test: Name trimming (removes leading/trailing whitespace)
    ///
    /// 테스트: 이름 공백 제거 (앞뒤 공백 제거됨)
    func testToDomain_NameWithWhitespace_TrimsWhitespace() throws {
        // Given: DTO with whitespace in name
        let dto = KFDAFoodDTO(
            foodCd: "D000003",
            descKor: "  김치찌개  ",
            groupCode: nil,
            groupName: nil,
            enercKcal: "150",
            prot: "10.0",
            fat: "8.0",
            chocdf: "5.0",
            na: "1000",
            fibtg: nil,
            sugar: nil,
            servingSize: "250",
            servingWt: nil,
            servingUnit: "1인분"
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Name should be trimmed
        XCTAssertEqual(food.name, "김치찌개", "Name should be trimmed")
    }

    /// Test: Decimal calorie values are rounded correctly
    ///
    /// 테스트: 소수점 칼로리 값이 올바르게 반올림됨
    func testToDomain_DecimalCalories_Rounded() throws {
        // Given: DTOs with decimal calorie values
        let testCases: [(calories: String, expected: Int32)] = [
            ("330.4", 330),
            ("330.5", 331),
            ("330.6", 331),
            ("99.9", 100)
        ]

        for testCase in testCases {
            let dto = KFDAFoodDTO(
                foodCd: "D000004",
                descKor: "Test Food",
                groupCode: nil,
                groupName: nil,
                enercKcal: testCase.calories,
                prot: "5.0",
                fat: "2.0",
                chocdf: "10.0",
                na: nil,
                fibtg: nil,
                sugar: nil,
                servingSize: "100",
                servingWt: nil,
                servingUnit: nil
            )

            // When: Mapping to domain entity
            let food = try mapper.toDomain(from: dto)

            // Then: Calories should be rounded correctly
            XCTAssertEqual(
                food.calories,
                testCase.expected,
                "Calories \(testCase.calories) should round to \(testCase.expected)"
            )
        }
    }

    /// Test: Serving size fallback logic (servingSize → servingWt → 100g default)
    ///
    /// 테스트: 제공량 폴백 로직 (servingSize → servingWt → 100g 기본값)
    func testToDomain_ServingSizeFallback_UsesCorrectValue() throws {
        // Given: DTOs with different serving size fields
        let testCases: [(servingSize: String?, servingWt: String?, expected: Decimal)] = [
            ("210", "200", 210),  // servingSize takes precedence
            (nil, "200", 200),     // falls back to servingWt
            (nil, nil, 100),       // defaults to 100g
            ("0", "200", 200),     // servingSize=0 falls back to servingWt
            ("0", "0", 100)        // both zero defaults to 100g
        ]

        for (index, testCase) in testCases.enumerated() {
            let dto = KFDAFoodDTO(
                foodCd: "D\(index)",
                descKor: "Test Food \(index)",
                groupCode: nil,
                groupName: nil,
                enercKcal: "100",
                prot: "5.0",
                fat: "2.0",
                chocdf: "10.0",
                na: nil,
                fibtg: nil,
                sugar: nil,
                servingSize: testCase.servingSize,
                servingWt: testCase.servingWt,
                servingUnit: nil
            )

            // When: Mapping to domain entity
            let food = try mapper.toDomain(from: dto)

            // Then: Serving size should follow fallback logic
            XCTAssertEqual(
                food.servingSize,
                testCase.expected,
                "Serving size should be \(testCase.expected) for servingSize=\(String(describing: testCase.servingSize)), servingWt=\(String(describing: testCase.servingWt))"
            )
        }
    }

    // MARK: - Error Cases Tests

    /// Test: Missing foodCd throws error
    ///
    /// 테스트: foodCd 누락 시 에러 발생
    func testToDomain_MissingFoodCd_ThrowsError() {
        // Given: DTO with empty foodCd
        let dto = KFDAFoodDTO(
            foodCd: "",
            descKor: "Test Food",
            groupCode: nil,
            groupName: nil,
            enercKcal: "100",
            prot: "5.0",
            fat: "2.0",
            chocdf: "10.0",
            na: nil,
            fibtg: nil,
            sugar: nil,
            servingSize: "100",
            servingWt: nil,
            servingUnit: nil
        )

        // When/Then: Should throw missingRequiredField error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.missingRequiredField(let field) = error else {
                XCTFail("Expected MappingError.missingRequiredField, got \(error)")
                return
            }
            XCTAssertEqual(field, "foodCd", "Error should indicate missing foodCd")
        }
    }

    /// Test: Missing descKor throws error
    ///
    /// 테스트: descKor 누락 시 에러 발생
    func testToDomain_MissingDescKor_ThrowsError() {
        // Given: DTO with empty descKor
        let dto = KFDAFoodDTO(
            foodCd: "D000001",
            descKor: "",
            groupCode: nil,
            groupName: nil,
            enercKcal: "100",
            prot: "5.0",
            fat: "2.0",
            chocdf: "10.0",
            na: nil,
            fibtg: nil,
            sugar: nil,
            servingSize: "100",
            servingWt: nil,
            servingUnit: nil
        )

        // When/Then: Should throw missingRequiredField error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.missingRequiredField(let field) = error else {
                XCTFail("Expected MappingError.missingRequiredField, got \(error)")
                return
            }
            XCTAssertEqual(field, "descKor", "Error should indicate missing descKor")
        }
    }

    /// Test: Invalid calories throws error
    ///
    /// 테스트: 잘못된 칼로리 값 시 에러 발생
    func testToDomain_InvalidCalories_ThrowsError() {
        // Given: DTOs with invalid calorie values
        let invalidCalories = [nil, "", "abc", "-100"]

        for invalidValue in invalidCalories {
            let dto = KFDAFoodDTO(
                foodCd: "D000001",
                descKor: "Test Food",
                groupCode: nil,
                groupName: nil,
                enercKcal: invalidValue,
                prot: "5.0",
                fat: "2.0",
                chocdf: "10.0",
                na: nil,
                fibtg: nil,
                sugar: nil,
                servingSize: "100",
                servingWt: nil,
                servingUnit: nil
            )

            // When/Then: Should throw invalidNutritionData error
            XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
                guard case MappingError.invalidNutritionData(let field) = error else {
                    XCTFail("Expected MappingError.invalidNutritionData for calories=\(String(describing: invalidValue)), got \(error)")
                    return
                }
                XCTAssertEqual(field, "enercKcal", "Error should indicate invalid enercKcal")
            }
        }
    }

    /// Test: Invalid carbohydrates throws error
    ///
    /// 테스트: 잘못된 탄수화물 값 시 에러 발생
    func testToDomain_InvalidCarbohydrates_ThrowsError() {
        // Given: DTOs with invalid carbohydrate values
        let invalidValues = [nil, "", "abc", "-10"]

        for invalidValue in invalidValues {
            let dto = KFDAFoodDTO(
                foodCd: "D000001",
                descKor: "Test Food",
                groupCode: nil,
                groupName: nil,
                enercKcal: "100",
                prot: "5.0",
                fat: "2.0",
                chocdf: invalidValue,
                na: nil,
                fibtg: nil,
                sugar: nil,
                servingSize: "100",
                servingWt: nil,
                servingUnit: nil
            )

            // When/Then: Should throw invalidNutritionData error
            XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
                guard case MappingError.invalidNutritionData(let field) = error else {
                    XCTFail("Expected MappingError.invalidNutritionData for chocdf=\(String(describing: invalidValue)), got \(error)")
                    return
                }
                XCTAssertEqual(field, "chocdf", "Error should indicate invalid chocdf")
            }
        }
    }

    /// Test: Invalid protein throws error
    ///
    /// 테스트: 잘못된 단백질 값 시 에러 발생
    func testToDomain_InvalidProtein_ThrowsError() {
        // Given: DTOs with invalid protein values
        let invalidValues = [nil, "", "abc", "-5"]

        for invalidValue in invalidValues {
            let dto = KFDAFoodDTO(
                foodCd: "D000001",
                descKor: "Test Food",
                groupCode: nil,
                groupName: nil,
                enercKcal: "100",
                prot: invalidValue,
                fat: "2.0",
                chocdf: "10.0",
                na: nil,
                fibtg: nil,
                sugar: nil,
                servingSize: "100",
                servingWt: nil,
                servingUnit: nil
            )

            // When/Then: Should throw invalidNutritionData error
            XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
                guard case MappingError.invalidNutritionData(let field) = error else {
                    XCTFail("Expected MappingError.invalidNutritionData for prot=\(String(describing: invalidValue)), got \(error)")
                    return
                }
                XCTAssertEqual(field, "prot", "Error should indicate invalid prot")
            }
        }
    }

    /// Test: Invalid fat throws error
    ///
    /// 테스트: 잘못된 지방 값 시 에러 발생
    func testToDomain_InvalidFat_ThrowsError() {
        // Given: DTOs with invalid fat values
        let invalidValues = [nil, "", "abc", "-2"]

        for invalidValue in invalidValues {
            let dto = KFDAFoodDTO(
                foodCd: "D000001",
                descKor: "Test Food",
                groupCode: nil,
                groupName: nil,
                enercKcal: "100",
                prot: "5.0",
                fat: invalidValue,
                chocdf: "10.0",
                na: nil,
                fibtg: nil,
                sugar: nil,
                servingSize: "100",
                servingWt: nil,
                servingUnit: nil
            )

            // When/Then: Should throw invalidNutritionData error
            XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
                guard case MappingError.invalidNutritionData(let field) = error else {
                    XCTFail("Expected MappingError.invalidNutritionData for fat=\(String(describing: invalidValue)), got \(error)")
                    return
                }
                XCTAssertEqual(field, "fat", "Error should indicate invalid fat")
            }
        }
    }

    // MARK: - Batch Mapping Tests

    /// Test: Batch mapping with all valid DTOs
    ///
    /// 테스트: 모두 유효한 DTO의 배치 매핑
    func testToDomainArray_AllValid_ReturnsAllFoods() {
        // Given: Array of valid DTOs
        let dtos = [
            createValidDTO(foodCd: "D000001", descKor: "현미밥", calories: "330"),
            createValidDTO(foodCd: "D000002", descKor: "김치찌개", calories: "150"),
            createValidDTO(foodCd: "D000003", descKor: "된장찌개", calories: "120")
        ]

        // When: Batch mapping to domain entities
        let foods = mapper.toDomainArray(from: dtos)

        // Then: All DTOs should be mapped
        XCTAssertEqual(foods.count, 3, "Should map all 3 DTOs")
        XCTAssertEqual(foods[0].name, "현미밥", "First food should be 현미밥")
        XCTAssertEqual(foods[1].name, "김치찌개", "Second food should be 김치찌개")
        XCTAssertEqual(foods[2].name, "된장찌개", "Third food should be 된장찌개")
    }

    /// Test: Batch mapping with some invalid DTOs (filters out failures)
    ///
    /// 테스트: 일부 무효한 DTO의 배치 매핑 (실패한 것은 제외됨)
    func testToDomainArray_SomeInvalid_FiltersOutInvalid() {
        // Given: Array with mix of valid and invalid DTOs
        let dtos = [
            createValidDTO(foodCd: "D000001", descKor: "현미밥", calories: "330"),
            createInvalidDTO(foodCd: "", descKor: "Invalid", calories: "100"), // Invalid: empty foodCd
            createValidDTO(foodCd: "D000003", descKor: "김치찌개", calories: "150"),
            createInvalidDTO(foodCd: "D000004", descKor: "Invalid", calories: nil), // Invalid: nil calories
            createValidDTO(foodCd: "D000005", descKor: "된장찌개", calories: "120")
        ]

        // When: Batch mapping to domain entities
        let foods = mapper.toDomainArray(from: dtos)

        // Then: Only valid DTOs should be mapped
        XCTAssertEqual(foods.count, 3, "Should map only 3 valid DTOs")
        XCTAssertEqual(foods[0].name, "현미밥", "First food should be 현미밥")
        XCTAssertEqual(foods[1].name, "김치찌개", "Second food should be 김치찌개")
        XCTAssertEqual(foods[2].name, "된장찌개", "Third food should be 된장찌개")
    }

    /// Test: Batch mapping with all invalid DTOs returns empty array
    ///
    /// 테스트: 모두 무효한 DTO의 배치 매핑 시 빈 배열 반환
    func testToDomainArray_AllInvalid_ReturnsEmptyArray() {
        // Given: Array of all invalid DTOs
        let dtos = [
            createInvalidDTO(foodCd: "", descKor: "Invalid 1", calories: "100"),
            createInvalidDTO(foodCd: "D000002", descKor: "", calories: "100"),
            createInvalidDTO(foodCd: "D000003", descKor: "Invalid 3", calories: nil)
        ]

        // When: Batch mapping to domain entities
        let foods = mapper.toDomainArray(from: dtos)

        // Then: Should return empty array
        XCTAssertEqual(foods.count, 0, "Should return empty array for all invalid DTOs")
    }

    // MARK: - Helper Methods

    /// Create a valid DTO for testing
    private func createValidDTO(
        foodCd: String,
        descKor: String,
        calories: String
    ) -> KFDAFoodDTO {
        return KFDAFoodDTO(
            foodCd: foodCd,
            descKor: descKor,
            groupCode: "01",
            groupName: "곡류",
            enercKcal: calories,
            prot: "5.0",
            fat: "2.0",
            chocdf: "10.0",
            na: "5",
            fibtg: "1.0",
            sugar: "0.5",
            servingSize: "100",
            servingWt: "100",
            servingUnit: "1인분"
        )
    }

    /// Create an invalid DTO for testing
    private func createInvalidDTO(
        foodCd: String,
        descKor: String,
        calories: String?
    ) -> KFDAFoodDTO {
        return KFDAFoodDTO(
            foodCd: foodCd,
            descKor: descKor,
            groupCode: nil,
            groupName: nil,
            enercKcal: calories,
            prot: "5.0",
            fat: "2.0",
            chocdf: "10.0",
            na: nil,
            fibtg: nil,
            sugar: nil,
            servingSize: "100",
            servingWt: nil,
            servingUnit: nil
        )
    }
}
