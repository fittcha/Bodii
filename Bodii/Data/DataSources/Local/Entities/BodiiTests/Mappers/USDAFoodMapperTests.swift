//
//  USDAFoodMapperTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

import XCTest
@testable import Bodii

/// Unit tests for USDAFoodMapper DTO to Food entity mapping
///
/// USDAFoodMapper의 DTO → Food 엔티티 매핑 단위 테스트
final class USDAFoodMapperTests: XCTestCase {

    // MARK: - Properties

    var mapper: USDAFoodMapper!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mapper = USDAFoodMapper()
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    // MARK: - Successful Mapping Tests

    /// Test: Valid USDA DTO with all nutrients maps to Food entity successfully
    ///
    /// 테스트: 모든 영양소가 있는 유효한 USDA DTO가 Food 엔티티로 성공적으로 변환됨
    func testToDomain_ValidDTOWithAllNutrients_ReturnsFood() throws {
        // Given: Valid USDA DTO with complete nutrient array
        let nutrients = [
            USDANutrientDTO(
                nutrientId: 1008,
                nutrientName: "Energy",
                nutrientNumber: "208",
                value: 52.0,
                unitName: "kcal",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDANutrientDTO(
                nutrientId: 1005,
                nutrientName: "Carbohydrate, by difference",
                nutrientNumber: "205",
                value: 13.8,
                unitName: "g",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDANutrientDTO(
                nutrientId: 1003,
                nutrientName: "Protein",
                nutrientNumber: "203",
                value: 0.3,
                unitName: "g",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDANutrientDTO(
                nutrientId: 1004,
                nutrientName: "Total lipid (fat)",
                nutrientNumber: "204",
                value: 0.2,
                unitName: "g",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDANutrientDTO(
                nutrientId: 1093,
                nutrientName: "Sodium, Na",
                nutrientNumber: "307",
                value: 1.0,
                unitName: "mg",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDANutrientDTO(
                nutrientId: 1079,
                nutrientName: "Fiber, total dietary",
                nutrientNumber: "291",
                value: 2.4,
                unitName: "g",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            ),
            USDANutrientDTO(
                nutrientId: 2000,
                nutrientName: "Total Sugars",
                nutrientNumber: "269",
                value: 10.4,
                unitName: "g",
                derivationId: nil,
                derivationCode: nil,
                derivationDescription: nil
            )
        ]

        let dto = USDAFoodDTO(
            fdcId: 123456,
            description: "Apple, raw",
            dataType: "Foundation",
            foodCode: nil,
            publicationDate: "2021-10-28",
            foodNutrients: nutrients,
            servingSize: 100.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 medium apple",
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: 9,
            foodCategory: "Fruits and Fruit Juices"
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should map all fields correctly
        XCTAssertEqual(food.name, "Apple, raw", "Name should match")
        XCTAssertEqual(food.calories, 52, "Calories should match")
        XCTAssertEqual(food.carbohydrates, Decimal(13.8), "Carbohydrates should match")
        XCTAssertEqual(food.protein, Decimal(0.3), "Protein should match")
        XCTAssertEqual(food.fat, Decimal(0.2), "Fat should match")
        XCTAssertEqual(food.sodium, Decimal(1.0), "Sodium should match")
        XCTAssertEqual(food.fiber, Decimal(2.4), "Fiber should match")
        XCTAssertEqual(food.sugar, Decimal(10.4), "Sugar should match")
        XCTAssertEqual(food.servingSize, Decimal(100), "Serving size should match")
        XCTAssertEqual(food.servingUnit, "1 medium apple", "Serving unit should use householdServingFullText")
        XCTAssertEqual(food.source, .usda, "Source should be usda")
        XCTAssertEqual(food.apiCode, "123456", "API code should match fdcId")
        XCTAssertNil(food.createdByUserId, "createdByUserId should be nil for API data")
    }

    /// Test: DTO with minimum required nutrients (no optional fields)
    ///
    /// 테스트: 최소 필수 영양소만 있는 DTO (선택 필드 없음)
    func testToDomain_MinimumRequiredNutrients_ReturnsFood() throws {
        // Given: DTO with only required nutrients
        let nutrients = [
            createNutrient(id: 1008, value: 100.0, name: "Energy"),      // calories
            createNutrient(id: 1005, value: 20.0, name: "Carbohydrate"), // carbs
            createNutrient(id: 1003, value: 5.0, name: "Protein"),       // protein
            createNutrient(id: 1004, value: 3.0, name: "Fat")            // fat
        ]

        let dto = USDAFoodDTO(
            fdcId: 789012,
            description: "Test Food",
            dataType: "Foundation",
            foodCode: nil,
            publicationDate: nil,
            foodNutrients: nutrients,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should map required fields and set defaults for optional
        XCTAssertEqual(food.name, "Test Food", "Name should match")
        XCTAssertEqual(food.calories, 100, "Calories should match")
        XCTAssertEqual(food.carbohydrates, Decimal(20.0), "Carbohydrates should match")
        XCTAssertEqual(food.protein, Decimal(5.0), "Protein should match")
        XCTAssertEqual(food.fat, Decimal(3.0), "Fat should match")
        XCTAssertNil(food.sodium, "Sodium should be nil")
        XCTAssertNil(food.fiber, "Fiber should be nil")
        XCTAssertNil(food.sugar, "Sugar should be nil")
        XCTAssertEqual(food.servingSize, Decimal(100), "Serving size should default to 100g")
        XCTAssertEqual(food.servingUnit, "100g", "Serving unit should default to 100g")
    }

    /// Test: Name trimming (removes leading/trailing whitespace)
    ///
    /// 테스트: 이름 공백 제거 (앞뒤 공백 제거됨)
    func testToDomain_NameWithWhitespace_TrimsWhitespace() throws {
        // Given: DTO with whitespace in description
        let nutrients = createCompleteNutrients()
        let dto = createValidDTO(
            fdcId: 111111,
            description: "  Milk, whole  ",
            nutrients: nutrients
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Name should be trimmed
        XCTAssertEqual(food.name, "Milk, whole", "Name should be trimmed")
    }

    /// Test: Decimal calorie values are rounded correctly
    ///
    /// 테스트: 소수점 칼로리 값이 올바르게 반올림됨
    func testToDomain_DecimalCalories_Rounded() throws {
        // Given: DTOs with decimal calorie values
        let testCases: [(calories: Double, expected: Int32)] = [
            (52.3, 52),
            (52.5, 53),
            (52.7, 53),
            (99.9, 100)
        ]

        for testCase in testCases {
            var nutrients = createCompleteNutrients()
            // Replace energy nutrient with test value
            nutrients.removeAll { $0.nutrientId == 1008 }
            nutrients.append(createNutrient(id: 1008, value: testCase.calories, name: "Energy"))

            let dto = createValidDTO(fdcId: 222222, description: "Test", nutrients: nutrients)

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

    // MARK: - Unit Conversion Tests

    /// Test: Serving size unit conversion (oz to g)
    ///
    /// 테스트: 제공량 단위 변환 (oz → g)
    func testToDomain_ServingSizeInOunces_ConvertsToGrams() throws {
        // Given: DTO with serving size in ounces
        let nutrients = createCompleteNutrients()
        let dto = USDAFoodDTO(
            fdcId: 333333,
            description: "Test Food",
            dataType: "Branded",
            foodCode: nil,
            publicationDate: nil,
            foodNutrients: nutrients,
            servingSize: 3.5,
            servingSizeUnit: "oz",
            householdServingFullText: nil,
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Serving size should be converted to grams (3.5 oz * 28.3495 = ~99.22g)
        let expectedGrams = Decimal(3.5) * Decimal(28.3495)
        XCTAssertEqual(
            food.servingSize,
            expectedGrams,
            accuracy: Decimal(0.01),
            "3.5 oz should convert to ~99.22g"
        )
    }

    /// Test: Serving size unit conversion (lb to g)
    ///
    /// 테스트: 제공량 단위 변환 (lb → g)
    func testToDomain_ServingSizeInPounds_ConvertsToGrams() throws {
        // Given: DTO with serving size in pounds
        let nutrients = createCompleteNutrients()
        let dto = createValidDTO(
            fdcId: 444444,
            description: "Test Food",
            nutrients: nutrients,
            servingSize: 1.0,
            servingUnit: "lb"
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Serving size should be converted to grams (1 lb = 453.592g)
        XCTAssertEqual(
            food.servingSize,
            Decimal(453.592),
            accuracy: Decimal(0.01),
            "1 lb should convert to 453.592g"
        )
    }

    /// Test: Serving size already in grams (no conversion)
    ///
    /// 테스트: 이미 그램인 제공량 (변환 불필요)
    func testToDomain_ServingSizeInGrams_NoConversion() throws {
        // Given: DTO with serving size in grams
        let nutrients = createCompleteNutrients()
        let dto = createValidDTO(
            fdcId: 555555,
            description: "Test Food",
            nutrients: nutrients,
            servingSize: 150.0,
            servingUnit: "g"
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Serving size should remain as-is
        XCTAssertEqual(food.servingSize, Decimal(150), "Serving size should remain 150g")
    }

    /// Test: Multiple unit conversions
    ///
    /// 테스트: 다양한 단위 변환
    func testToDomain_VariousUnits_ConvertsCorrectly() throws {
        // Given: Test cases for various unit conversions
        let testCases: [(value: Double, unit: String, expectedGrams: Decimal)] = [
            (100.0, "g", 100.0),
            (1.0, "kg", 1000.0),
            (500.0, "mg", 0.5),
            (1.0, "oz", 28.3495),
            (1.0, "lb", 453.592),
            (236.588, "ml", 236.588), // water-based approximation
            (1.0, "cup", 236.588)
        ]

        for testCase in testCases {
            let nutrients = createCompleteNutrients()
            let dto = createValidDTO(
                fdcId: 666666,
                description: "Test",
                nutrients: nutrients,
                servingSize: testCase.value,
                servingUnit: testCase.unit
            )

            // When: Mapping to domain entity
            let food = try mapper.toDomain(from: dto)

            // Then: Should convert to grams correctly
            XCTAssertEqual(
                food.servingSize,
                testCase.expectedGrams,
                accuracy: Decimal(0.01),
                "\(testCase.value) \(testCase.unit) should convert to ~\(testCase.expectedGrams)g"
            )
        }
    }

    // MARK: - Serving Unit Tests

    /// Test: Household serving text takes precedence over servingSizeUnit
    ///
    /// 테스트: householdServingFullText가 servingSizeUnit보다 우선함
    func testToDomain_HouseholdServingText_TakesPrecedence() throws {
        // Given: DTO with both householdServingFullText and servingSizeUnit
        let nutrients = createCompleteNutrients()
        let dto = USDAFoodDTO(
            fdcId: 777777,
            description: "Banana",
            dataType: "Foundation",
            foodCode: nil,
            publicationDate: nil,
            foodNutrients: nutrients,
            servingSize: 100.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 medium banana",
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should use householdServingFullText
        XCTAssertEqual(food.servingUnit, "1 medium banana", "Should use household serving text")
    }

    /// Test: Falls back to servingSizeUnit when no householdServingFullText
    ///
    /// 테스트: householdServingFullText가 없으면 servingSizeUnit 사용
    func testToDomain_NoHouseholdText_UsesServingSizeUnit() throws {
        // Given: DTO with only servingSizeUnit
        let nutrients = createCompleteNutrients()
        let dto = createValidDTO(
            fdcId: 888888,
            description: "Test",
            nutrients: nutrients,
            servingSize: 100.0,
            servingUnit: "g",
            householdText: nil
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should use servingSizeUnit
        XCTAssertEqual(food.servingUnit, "g", "Should use serving size unit")
    }

    /// Test: Defaults to 100g when no serving unit provided
    ///
    /// 테스트: 제공량 단위가 없으면 100g으로 기본값 설정
    func testToDomain_NoServingUnit_DefaultsTo100g() throws {
        // Given: DTO with no serving unit information
        let nutrients = createCompleteNutrients()
        let dto = USDAFoodDTO(
            fdcId: 999999,
            description: "Test",
            dataType: nil,
            foodCode: nil,
            publicationDate: nil,
            foodNutrients: nutrients,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )

        // When: Mapping to domain entity
        let food = try mapper.toDomain(from: dto)

        // Then: Should default to 100g
        XCTAssertEqual(food.servingUnit, "100g", "Should default to 100g")
    }

    // MARK: - Error Cases Tests

    /// Test: Empty description throws error
    ///
    /// 테스트: 빈 설명 시 에러 발생
    func testToDomain_EmptyDescription_ThrowsError() {
        // Given: DTO with empty description
        let nutrients = createCompleteNutrients()
        let dto = createValidDTO(fdcId: 111, description: "", nutrients: nutrients)

        // When/Then: Should throw missingRequiredField error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.missingRequiredField(let field) = error else {
                XCTFail("Expected MappingError.missingRequiredField, got \(error)")
                return
            }
            XCTAssertEqual(field, "description", "Error should indicate missing description")
        }
    }

    /// Test: Nil food nutrients throws error
    ///
    /// 테스트: foodNutrients가 nil이면 에러 발생
    func testToDomain_NilFoodNutrients_ThrowsError() {
        // Given: DTO with nil foodNutrients
        let dto = USDAFoodDTO(
            fdcId: 222,
            description: "Test Food",
            dataType: nil,
            foodCode: nil,
            publicationDate: nil,
            foodNutrients: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )

        // When/Then: Should throw missingRequiredField error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.missingRequiredField(let field) = error else {
                XCTFail("Expected MappingError.missingRequiredField, got \(error)")
                return
            }
            XCTAssertEqual(field, "foodNutrients", "Error should indicate missing foodNutrients")
        }
    }

    /// Test: Empty food nutrients array throws error
    ///
    /// 테스트: 빈 foodNutrients 배열 시 에러 발생
    func testToDomain_EmptyFoodNutrients_ThrowsError() {
        // Given: DTO with empty foodNutrients array
        let dto = createValidDTO(fdcId: 333, description: "Test", nutrients: [])

        // When/Then: Should throw missingRequiredField error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.missingRequiredField(let field) = error else {
                XCTFail("Expected MappingError.missingRequiredField, got \(error)")
                return
            }
            XCTAssertEqual(field, "foodNutrients", "Error should indicate missing foodNutrients")
        }
    }

    /// Test: Missing calories nutrient throws error
    ///
    /// 테스트: 칼로리 영양소 누락 시 에러 발생
    func testToDomain_MissingCalories_ThrowsError() {
        // Given: Nutrients without energy (ID 1008)
        let nutrients = [
            createNutrient(id: 1005, value: 20.0, name: "Carbohydrate"),
            createNutrient(id: 1003, value: 5.0, name: "Protein"),
            createNutrient(id: 1004, value: 3.0, name: "Fat")
        ]
        let dto = createValidDTO(fdcId: 444, description: "Test", nutrients: nutrients)

        // When/Then: Should throw invalidNutritionData error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.invalidNutritionData(let field) = error else {
                XCTFail("Expected MappingError.invalidNutritionData, got \(error)")
                return
            }
            XCTAssertEqual(field, "energy (1008)", "Error should indicate missing energy")
        }
    }

    /// Test: Missing carbohydrates nutrient throws error
    ///
    /// 테스트: 탄수화물 영양소 누락 시 에러 발생
    func testToDomain_MissingCarbohydrates_ThrowsError() {
        // Given: Nutrients without carbohydrates (ID 1005)
        let nutrients = [
            createNutrient(id: 1008, value: 100.0, name: "Energy"),
            createNutrient(id: 1003, value: 5.0, name: "Protein"),
            createNutrient(id: 1004, value: 3.0, name: "Fat")
        ]
        let dto = createValidDTO(fdcId: 555, description: "Test", nutrients: nutrients)

        // When/Then: Should throw invalidNutritionData error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.invalidNutritionData(let field) = error else {
                XCTFail("Expected MappingError.invalidNutritionData, got \(error)")
                return
            }
            XCTAssertEqual(field, "carbohydrate (1005)", "Error should indicate missing carbohydrate")
        }
    }

    /// Test: Missing protein nutrient throws error
    ///
    /// 테스트: 단백질 영양소 누락 시 에러 발생
    func testToDomain_MissingProtein_ThrowsError() {
        // Given: Nutrients without protein (ID 1003)
        let nutrients = [
            createNutrient(id: 1008, value: 100.0, name: "Energy"),
            createNutrient(id: 1005, value: 20.0, name: "Carbohydrate"),
            createNutrient(id: 1004, value: 3.0, name: "Fat")
        ]
        let dto = createValidDTO(fdcId: 666, description: "Test", nutrients: nutrients)

        // When/Then: Should throw invalidNutritionData error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.invalidNutritionData(let field) = error else {
                XCTFail("Expected MappingError.invalidNutritionData, got \(error)")
                return
            }
            XCTAssertEqual(field, "protein (1003)", "Error should indicate missing protein")
        }
    }

    /// Test: Missing fat nutrient throws error
    ///
    /// 테스트: 지방 영양소 누락 시 에러 발생
    func testToDomain_MissingFat_ThrowsError() {
        // Given: Nutrients without fat (ID 1004)
        let nutrients = [
            createNutrient(id: 1008, value: 100.0, name: "Energy"),
            createNutrient(id: 1005, value: 20.0, name: "Carbohydrate"),
            createNutrient(id: 1003, value: 5.0, name: "Protein")
        ]
        let dto = createValidDTO(fdcId: 777, description: "Test", nutrients: nutrients)

        // When/Then: Should throw invalidNutritionData error
        XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
            guard case MappingError.invalidNutritionData(let field) = error else {
                XCTFail("Expected MappingError.invalidNutritionData, got \(error)")
                return
            }
            XCTAssertEqual(field, "fat (1004)", "Error should indicate missing fat")
        }
    }

    /// Test: Negative nutrient values throw error
    ///
    /// 테스트: 음수 영양소 값 시 에러 발생
    func testToDomain_NegativeNutrients_ThrowsError() {
        // Given: Nutrients with negative values
        let testCases: [(id: Int, name: String, field: String)] = [
            (1008, "Energy", "energy (1008)"),
            (1005, "Carbohydrate", "carbohydrate (1005)"),
            (1003, "Protein", "protein (1003)"),
            (1004, "Fat", "fat (1004)")
        ]

        for testCase in testCases {
            var nutrients = createCompleteNutrients()
            nutrients.removeAll { $0.nutrientId == testCase.id }
            nutrients.append(createNutrient(id: testCase.id, value: -10.0, name: testCase.name))

            let dto = createValidDTO(fdcId: 888, description: "Test", nutrients: nutrients)

            // When/Then: Should throw invalidNutritionData error
            XCTAssertThrowsError(try mapper.toDomain(from: dto)) { error in
                guard case MappingError.invalidNutritionData(let field) = error else {
                    XCTFail("Expected MappingError.invalidNutritionData for \(testCase.name), got \(error)")
                    return
                }
                XCTAssertEqual(field, testCase.field, "Error should indicate invalid \(testCase.name)")
            }
        }
    }

    // MARK: - Batch Mapping Tests

    /// Test: Batch mapping with all valid DTOs
    ///
    /// 테스트: 모두 유효한 DTO의 배치 매핑
    func testToDomainArray_AllValid_ReturnsAllFoods() {
        // Given: Array of valid DTOs
        let nutrients = createCompleteNutrients()
        let dtos = [
            createValidDTO(fdcId: 1, description: "Apple", nutrients: nutrients),
            createValidDTO(fdcId: 2, description: "Banana", nutrients: nutrients),
            createValidDTO(fdcId: 3, description: "Orange", nutrients: nutrients)
        ]

        // When: Batch mapping to domain entities
        let foods = mapper.toDomainArray(from: dtos)

        // Then: All DTOs should be mapped
        XCTAssertEqual(foods.count, 3, "Should map all 3 DTOs")
        XCTAssertEqual(foods[0].name, "Apple", "First food should be Apple")
        XCTAssertEqual(foods[1].name, "Banana", "Second food should be Banana")
        XCTAssertEqual(foods[2].name, "Orange", "Third food should be Orange")
    }

    /// Test: Batch mapping with some invalid DTOs (filters out failures)
    ///
    /// 테스트: 일부 무효한 DTO의 배치 매핑 (실패한 것은 제외됨)
    func testToDomainArray_SomeInvalid_FiltersOutInvalid() {
        // Given: Array with mix of valid and invalid DTOs
        let validNutrients = createCompleteNutrients()
        let invalidNutrients = [createNutrient(id: 1008, value: 100.0, name: "Energy")] // Missing required nutrients

        let dtos = [
            createValidDTO(fdcId: 1, description: "Apple", nutrients: validNutrients),
            createValidDTO(fdcId: 2, description: "", nutrients: validNutrients), // Invalid: empty description
            createValidDTO(fdcId: 3, description: "Banana", nutrients: validNutrients),
            createValidDTO(fdcId: 4, description: "Invalid", nutrients: invalidNutrients), // Invalid: missing nutrients
            createValidDTO(fdcId: 5, description: "Orange", nutrients: validNutrients)
        ]

        // When: Batch mapping to domain entities
        let foods = mapper.toDomainArray(from: dtos)

        // Then: Only valid DTOs should be mapped
        XCTAssertEqual(foods.count, 3, "Should map only 3 valid DTOs")
        XCTAssertEqual(foods[0].name, "Apple", "First food should be Apple")
        XCTAssertEqual(foods[1].name, "Banana", "Second food should be Banana")
        XCTAssertEqual(foods[2].name, "Orange", "Third food should be Orange")
    }

    /// Test: Batch mapping with all invalid DTOs returns empty array
    ///
    /// 테스트: 모두 무효한 DTO의 배치 매핑 시 빈 배열 반환
    func testToDomainArray_AllInvalid_ReturnsEmptyArray() {
        // Given: Array of all invalid DTOs
        let incompleteNutrients = [createNutrient(id: 1008, value: 100.0, name: "Energy")]
        let dtos = [
            createValidDTO(fdcId: 1, description: "", nutrients: incompleteNutrients),
            createValidDTO(fdcId: 2, description: "Test", nutrients: []),
            createValidDTO(fdcId: 3, description: "Test", nutrients: incompleteNutrients)
        ]

        // When: Batch mapping to domain entities
        let foods = mapper.toDomainArray(from: dtos)

        // Then: Should return empty array
        XCTAssertEqual(foods.count, 0, "Should return empty array for all invalid DTOs")
    }

    // MARK: - Helper Methods

    /// Create a complete set of nutrients for testing
    private func createCompleteNutrients() -> [USDANutrientDTO] {
        return [
            createNutrient(id: 1008, value: 100.0, name: "Energy"),
            createNutrient(id: 1005, value: 20.0, name: "Carbohydrate"),
            createNutrient(id: 1003, value: 5.0, name: "Protein"),
            createNutrient(id: 1004, value: 3.0, name: "Fat"),
            createNutrient(id: 1093, value: 10.0, name: "Sodium"),
            createNutrient(id: 1079, value: 2.0, name: "Fiber"),
            createNutrient(id: 2000, value: 5.0, name: "Sugars")
        ]
    }

    /// Create a nutrient DTO for testing
    private func createNutrient(
        id: Int,
        value: Double,
        name: String
    ) -> USDANutrientDTO {
        return USDANutrientDTO(
            nutrientId: id,
            nutrientName: name,
            nutrientNumber: "\(id)",
            value: value,
            unitName: id == 1008 ? "kcal" : (id == 1093 ? "mg" : "g"),
            derivationId: nil,
            derivationCode: nil,
            derivationDescription: nil
        )
    }

    /// Create a valid DTO for testing
    private func createValidDTO(
        fdcId: Int,
        description: String,
        nutrients: [USDANutrientDTO],
        servingSize: Double = 100.0,
        servingUnit: String = "g",
        householdText: String? = nil
    ) -> USDAFoodDTO {
        return USDAFoodDTO(
            fdcId: fdcId,
            description: description,
            dataType: "Foundation",
            foodCode: nil,
            publicationDate: nil,
            foodNutrients: nutrients,
            servingSize: servingSize,
            servingSizeUnit: servingUnit,
            householdServingFullText: householdText,
            brandOwner: nil,
            brandName: nil,
            gtinUpc: nil,
            ingredients: nil,
            foodCategoryId: nil,
            foodCategory: nil
        )
    }
}
