//
//  OpenFoodFactsMapper.swift
//  Bodii
//
//  Open Food Facts DTO를 Food Core Data 엔티티로 변환

import Foundation
import CoreData

/// Open Food Facts DTO → Food 엔티티 매퍼
struct OpenFoodFactsMapper {

    /// OFFProductDTO 배열을 Food 엔티티 배열로 변환
    func toDomainArray(from products: [OFFProductDTO], context: NSManagedObjectContext) -> [Food] {
        return products.compactMap { toDomain(from: $0, context: context) }
    }

    /// OFFProductDTO를 Food 엔티티로 변환
    ///
    /// 유효한 영양 데이터가 없는 제품은 nil을 반환합니다.
    func toDomain(from dto: OFFProductDTO, context: NSManagedObjectContext) -> Food? {
        // 제품명 결정: 한국어명 > 일반명
        let rawName = dto.productNameKo ?? dto.productName
        guard let name = rawName, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }

        // 칼로리가 없으면 스킵
        guard let kcal = dto.nutriments?.energyKcal100g, kcal > 0 else {
            return nil
        }

        let food = Food(context: context)
        food.id = UUID()

        // 이름: "브랜드 제품명" 형식
        if let brand = dto.brands, !brand.isEmpty {
            food.name = "\(brand) \(name)"
        } else {
            food.name = name
        }

        food.source = FoodSource.openFoodFacts.rawValue

        // apiCode: "off:바코드" 형식
        if let code = dto.code, !code.isEmpty {
            food.apiCode = "off:\(code)"
        }

        // 영양소 (100g 기준)
        let nutriments = dto.nutriments
        food.calories = Int32(kcal.rounded())
        food.protein = NSDecimalNumber(value: nutriments?.proteins100g ?? 0)
        food.carbohydrates = NSDecimalNumber(value: nutriments?.carbohydrates100g ?? 0)
        food.fat = NSDecimalNumber(value: nutriments?.fat100g ?? 0)

        // 나트륨: OFF는 g 단위, Bodii는 mg 단위
        if let sodiumG = nutriments?.sodium100g {
            food.sodium = NSDecimalNumber(value: sodiumG * 1000)
        }

        if let fiber = nutriments?.fiber100g {
            food.fiber = NSDecimalNumber(value: fiber)
        }

        if let sugars = nutriments?.sugars100g {
            food.sugar = NSDecimalNumber(value: sugars)
        }

        // 1회 제공량: 100g 기준 (OFF 기본)
        food.servingSize = NSDecimalNumber(value: 100)
        food.servingUnit = "100g"

        // OFF의 servingSize 파싱 시도 (예: "120g", "1봉지 (100g)")
        if let servingText = dto.servingSize {
            parseServingSize(servingText, into: food)
        }

        food.createdAt = Date()

        return food
    }

    // MARK: - Private

    /// OFF의 서빙 사이즈 텍스트를 파싱합니다.
    /// 예: "120g" → 120, "1봉지 (100g)" → 100
    private func parseServingSize(_ text: String, into food: Food) {
        // 패턴: 숫자 + g 또는 ml
        let pattern = #"(\d+(?:\.\d+)?)\s*(?:g|ml)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let valueRange = Range(match.range(at: 1), in: text) else {
            return
        }

        if let value = Double(text[valueRange]) {
            food.servingSize = NSDecimalNumber(value: value)
        }

        // 단위 설명 텍스트 보존
        food.servingUnit = text
    }
}
