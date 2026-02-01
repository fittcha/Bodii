//
//  USDAFoodMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Data Mapper Pattern for USDA
// USDA API의 복잡한 영양소 배열 구조를 Food 도메인 엔티티로 변환
// 💡 Java 비교: 식약처 매퍼보다 더 복잡한 변환 로직 (배열 검색 + 단위 변환)

import Foundation
import CoreData

/// USDA API DTO를 Food 도메인 엔티티로 변환하는 매퍼
///
/// 📚 학습 포인트: Complex Mapping with Nutrient ID Lookup
/// USDA API는 영양소를 ID 기반 배열로 제공하므로 매핑이 더 복잡함
/// 식약처는 필드명으로 직접 접근 vs USDA는 배열 검색 필요
/// 💡 Java 비교: Stream API filter + map 패턴과 유사
///
/// **변환 로직:**
/// - 영양소 ID로 배열에서 값 추출
/// - 단위 변환 (oz → g, lb → g 등)
/// - 필수 필드 검증 및 기본값 설정
/// - 출처를 .usda로 설정
/// - FDC ID를 apiCode로 저장
///
/// **사용 예시:**
/// ```swift
/// let dto = USDAFoodDTO(...)
/// let mapper = USDAFoodMapper()
///
/// // DTO를 도메인 엔티티로 변환
/// let food = try mapper.toDomain(from: dto)
/// print(food.name) // "Apple, raw"
/// print(food.calories) // 52
/// print(food.source) // .usda
/// ```
struct USDAFoodMapper {

    // MARK: - Mapping Methods

    /// USDAFoodDTO를 Food 도메인 엔티티로 변환
    ///
    /// 📚 학습 포인트: Nutrient ID-based Mapping
    /// 영양소 ID로 배열을 검색하여 값을 추출하는 복잡한 매핑 로직
    /// 💡 Java 비교: Map<Integer, Double> 구조에서 값 추출과 유사
    ///
    /// - Parameter dto: USDA API 응답 DTO
    ///
    /// - Returns: Food 도메인 엔티티
    ///
    /// - Throws: `MappingError` - 필수 필드 누락 또는 변환 실패
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let food = try mapper.toDomain(from: dto)
    /// } catch MappingError.missingRequiredField(let field) {
    ///     print("Missing field: \(field)")
    /// } catch MappingError.invalidNutritionData(let field) {
    ///     print("Invalid data: \(field)")
    /// }
    /// ```
    func toDomain(from dto: USDAFoodDTO, context: NSManagedObjectContext) throws -> Food {
        // 필수 필드 검증
        guard !dto.description.isEmpty else {
            throw MappingError.missingRequiredField("description")
        }

        // 영양소 배열 검증
        guard let nutrients = dto.foodNutrients, !nutrients.isEmpty else {
            throw MappingError.missingRequiredField("foodNutrients")
        }

        // 칼로리 추출 (필수 필드)
        // 📚 학습 포인트: Nutrient ID Lookup
        // USDA는 nutrientId 1008이 Energy (kcal)
        // 💡 Java 비교: nutrients.stream().filter(n -> n.getId() == 1008).findFirst()
        guard let calories = parseCalories(from: nutrients) else {
            throw MappingError.invalidNutritionData("energy (1008)")
        }

        // 탄수화물/단백질/지방 - 없으면 0으로 처리 (일부 식품에 영양소 누락 가능)
        let carbohydrates = extractNutrient(USDANutrientID.carbohydrate, from: nutrients) ?? Decimal.zero
        let protein = extractNutrient(USDANutrientID.protein, from: nutrients) ?? Decimal.zero
        let fat = extractNutrient(USDANutrientID.fat, from: nutrients) ?? Decimal.zero

        // 1회 제공량 추출 및 단위 변환
        let servingSize = parseServingSize(from: dto)

        // 선택 필드 추출
        let sodium = extractNutrient(USDANutrientID.sodium, from: nutrients)
        let fiber = extractNutrient(USDANutrientID.fiber, from: nutrients)
        let sugar = extractNutrient(USDANutrientID.sugar, from: nutrients)

        // 제공량 단위 처리
        let servingUnit = parseServingUnit(from: dto)

        // Food Core Data 엔티티 생성
        let food = Food(context: context)
        food.id = UUID()
        food.name = dto.description.trimmingCharacters(in: .whitespaces)
        food.calories = calories
        food.carbohydrates = NSDecimalNumber(decimal: carbohydrates)
        food.protein = NSDecimalNumber(decimal: protein)
        food.fat = NSDecimalNumber(decimal: fat)
        food.sodium = sodium.map { NSDecimalNumber(decimal: $0) }
        food.fiber = fiber.map { NSDecimalNumber(decimal: $0) }
        food.sugar = sugar.map { NSDecimalNumber(decimal: $0) }
        food.servingSize = NSDecimalNumber(decimal: servingSize)
        food.servingUnit = servingUnit
        food.source = FoodSource.usda.rawValue
        food.apiCode = String(dto.fdcId)
        food.createdAt = Date()

        return food
    }

    // MARK: - Helper Methods

    /// 칼로리 영양소를 추출하여 Int32로 변환
    ///
    /// 📚 학습 포인트: Nutrient Extraction & Conversion
    /// 영양소 배열에서 칼로리를 찾아 Int32로 변환
    /// 💡 Java 비교: Stream filter + map + orElse 패턴
    ///
    /// - Parameter nutrients: 영양소 배열
    ///
    /// - Returns: Int32 칼로리 값 (반올림), 찾지 못하면 nil
    ///
    /// - Note: 소수점 칼로리는 반올림 처리 (52.3 → 52, 52.7 → 53)
    private func parseCalories(from nutrients: [USDANutrientDTO]) -> Int32? {
        guard let calorieValue = nutrients.value(for: USDANutrientID.energy) else {
            return nil
        }

        // 음수 칼로리 체크
        guard calorieValue >= 0 else {
            return nil
        }

        // 반올림하여 Int32로 변환
        return Int32(calorieValue.rounded())
    }

    /// 특정 영양소를 ID로 추출하여 Decimal로 변환
    ///
    /// 📚 학습 포인트: Generic Nutrient Extraction
    /// 모든 영양소에 대해 재사용 가능한 추출 함수
    /// 💡 Java 비교: Generic method with Optional return
    ///
    /// - Parameters:
    ///   - nutrientId: 영양소 ID (USDANutrientID 상수 사용)
    ///   - nutrients: 영양소 배열
    ///
    /// - Returns: Decimal 영양소 값 (없으면 nil)
    private func extractNutrient(_ nutrientId: Int, from nutrients: [USDANutrientDTO]) -> Decimal? {
        guard let value = nutrients.decimalValue(for: nutrientId) else {
            return nil
        }

        // 음수 값 체크 (영양소는 음수일 수 없음)
        guard value >= 0 else {
            return nil
        }

        return value
    }

    /// 1회 제공량을 그램(g) 단위 Decimal로 변환
    ///
    /// 📚 학습 포인트: Unit Conversion Strategy
    /// USDA는 다양한 단위(g, oz, lb 등)를 사용하므로 그램으로 통일
    /// 💡 Java 비교: Strategy pattern for unit conversion
    ///
    /// - Parameter dto: USDA API 응답 DTO
    ///
    /// - Returns: 제공량 (g)
    ///
    /// - Note: servingSize 필드를 단위에 따라 그램으로 변환, 없으면 100g 기본값
    private func parseServingSize(from dto: USDAFoodDTO) -> Decimal {
        guard let size = dto.servingSize else {
            // 기본값: 100g (표준 1회 제공량)
            return Decimal(100)
        }

        let servingSize = Decimal(size)

        // 단위에 따른 변환
        guard let unit = dto.servingSizeUnit?.lowercased() else {
            // 단위가 없으면 그램으로 가정
            return servingSize
        }

        // 📚 학습 포인트: Unit Conversion
        // USDA API는 다양한 단위를 사용하므로 표준화 필요
        // 💡 Java 비교: switch expression과 유사
        return convertToGrams(value: servingSize, unit: unit)
    }

    /// 다양한 단위를 그램(g)으로 변환
    ///
    /// 📚 학습 포인트: Unit Standardization
    /// 국제 표준 변환 계수를 사용하여 모든 단위를 그램으로 통일
    /// 💡 Java 비교: Conversion utility method
    ///
    /// - Parameters:
    ///   - value: 변환할 값
    ///   - unit: 현재 단위 (소문자)
    ///
    /// - Returns: 그램 단위로 변환된 값
    ///
    /// **지원 단위:**
    /// - g, grams: 그램 (변환 불필요)
    /// - oz, ounce: 온스 (× 28.3495)
    /// - lb, pound: 파운드 (× 453.592)
    /// - kg, kilogram: 킬로그램 (× 1000)
    /// - mg, milligram: 밀리그램 (÷ 1000)
    private func convertToGrams(value: Decimal, unit: String) -> Decimal {
        // 단위명 정규화 (공백 제거, 소문자 변환)
        let normalizedUnit = unit.trimmingCharacters(in: .whitespaces).lowercased()

        switch normalizedUnit {
        case "g", "gram", "grams":
            // 이미 그램
            return value

        case "oz", "ounce", "ounces":
            // 온스 → 그램 (1 oz = 28.3495 g)
            return value * Decimal(28.3495)

        case "lb", "lbs", "pound", "pounds":
            // 파운드 → 그램 (1 lb = 453.592 g)
            return value * Decimal(453.592)

        case "kg", "kilogram", "kilograms":
            // 킬로그램 → 그램 (1 kg = 1000 g)
            return value * 1000

        case "mg", "milligram", "milligrams":
            // 밀리그램 → 그램 (1 mg = 0.001 g)
            return value / 1000

        case "ml", "milliliter", "milliliters":
            // 밀리리터 → 그램 (물 기준 1:1, 근사값)
            // 📚 학습 포인트: Reasonable Approximation
            // 액체의 경우 밀도에 따라 다르지만, 물 기준으로 근사
            return value

        case "fl oz", "fluid ounce", "fluid ounces":
            // 액량 온스 → 밀리리터 → 그램 (1 fl oz = 29.5735 ml ≈ g)
            return value * Decimal(29.5735)

        case "cup", "cups":
            // 컵 → 그램 (1 cup = 236.588 ml ≈ g)
            return value * Decimal(236.588)

        case "tbsp", "tablespoon", "tablespoons":
            // 테이블스푼 → 그램 (1 tbsp = 14.7868 ml ≈ g)
            return value * Decimal(14.7868)

        case "tsp", "teaspoon", "teaspoons":
            // 티스푼 → 그램 (1 tsp = 4.92892 ml ≈ g)
            return value * Decimal(4.92892)

        default:
            // 알 수 없는 단위는 그대로 반환
            // 📚 학습 포인트: Graceful Degradation
            // 알 수 없는 단위라도 에러를 던지지 않고 원본 값 반환
            return value
        }
    }

    /// 제공량 단위를 사용자 친화적인 형식으로 변환
    ///
    /// 📚 학습 포인트: User-Friendly Display
    /// API의 원시 단위를 사용자가 이해하기 쉬운 형식으로 변환
    /// 💡 Java 비교: Presentation layer formatting
    ///
    /// - Parameter dto: USDA API 응답 DTO
    ///
    /// - Returns: 표시용 제공량 단위 (예: "100g", "1컵", "1개")
    private func parseServingUnit(from dto: USDAFoodDTO) -> String? {
        // householdServingFullText가 있으면 우선 사용
        // 📚 학습 포인트: Fallback Strategy
        // 사용자 친화적인 텍스트가 있으면 우선, 없으면 단위만 사용
        if let householdServing = dto.householdServingFullText,
           !householdServing.isEmpty {
            return householdServing.trimmingCharacters(in: .whitespaces)
        }

        // servingSizeUnit 사용
        if let unit = dto.servingSizeUnit,
           !unit.isEmpty {
            return unit.trimmingCharacters(in: .whitespaces)
        }

        // 둘 다 없으면 기본값
        return "100g"
    }
}

// MARK: - Batch Mapping

extension USDAFoodMapper {

    /// 여러 DTO를 한 번에 도메인 엔티티 배열로 변환
    ///
    /// 📚 학습 포인트: Batch Processing with Error Handling
    /// 일부 변환 실패해도 성공한 항목들은 반환
    /// 💡 Java 비교: Stream.map() with filter와 유사
    ///
    /// - Parameter dtos: USDA API 응답 DTO 배열
    ///
    /// - Returns: 성공적으로 변환된 Food 엔티티 배열
    ///
    /// - Note: 변환 실패한 항목은 자동으로 제외됨
    ///
    /// - Example:
    /// ```swift
    /// let dtos: [USDAFoodDTO] = [...]
    /// let foods = mapper.toDomainArray(from: dtos, context: context)
    /// // 일부 DTO가 잘못되어도 유효한 Food만 반환됨
    /// ```
    func toDomainArray(from dtos: [USDAFoodDTO], context: NSManagedObjectContext) -> [Food] {
        dtos.compactMap { dto in
            try? toDomain(from: dto, context: context)
        }
    }
}
