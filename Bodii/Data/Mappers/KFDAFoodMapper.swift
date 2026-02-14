//
//  KFDAFoodMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation
import CoreData

/// 식약처 API DTO를 Food Core Data 엔티티로 변환하는 매퍼
struct KFDAFoodMapper {

    // MARK: - Mapping Methods

    /// KFDAFoodDTO를 Food 도메인 엔티티로 변환
    func toDomain(from dto: KFDAFoodDTO, context: NSManagedObjectContext) throws -> Food {
        // 필수 필드 검증
        guard !dto.foodCd.isEmpty else {
            throw MappingError.missingRequiredField("foodCd")
        }

        guard !dto.descKor.isEmpty else {
            throw MappingError.missingRequiredField("foodNmKr")
        }

        // 칼로리 변환 (필수 - 없으면 매핑 실패)
        guard let calories = parseCalories(from: dto.enercKcal) else {
            throw MappingError.invalidNutritionData("amtNum1 (kcal)")
        }

        // 탄수화물/단백질/지방 - 없으면 0으로 처리 (새 API는 빈 문자열이 많음)
        let carbohydrates = dto.parseDecimal(dto.chocdf) ?? Decimal.zero
        let protein = dto.parseDecimal(dto.prot) ?? Decimal.zero
        let fat = dto.parseDecimal(dto.fat) ?? Decimal.zero

        // 1회 제공량
        let servingSize = parseServingSize(from: dto)

        // 선택 필드
        let sodium = dto.parseDecimal(dto.na)
        let fiber = dto.parseDecimal(dto.fibtg)
        let sugar = dto.parseDecimal(dto.sugar)

        // Food Core Data 엔티티 생성
        let food = Food(context: context)
        food.id = UUID()
        food.name = dto.descKor.trimmingCharacters(in: .whitespaces)
        food.calories = calories
        food.carbohydrates = NSDecimalNumber(decimal: carbohydrates)
        food.protein = NSDecimalNumber(decimal: protein)
        food.fat = NSDecimalNumber(decimal: fat)
        food.sodium = sodium.map { NSDecimalNumber(decimal: $0) }
        food.fiber = fiber.map { NSDecimalNumber(decimal: $0) }
        food.sugar = sugar.map { NSDecimalNumber(decimal: $0) }
        food.servingSize = NSDecimalNumber(decimal: servingSize)
        // 서빙 단위 파싱 시도 (예: "1봉지(120g)")
        food.servingUnit = parseServingUnit(from: dto)
        food.source = FoodSource.governmentAPI.rawValue
        food.apiCode = dto.foodCd
        food.createdAt = Date()
        return food
    }

    // MARK: - Helper Methods

    /// 칼로리 문자열을 Int32로 변환
    private func parseCalories(from value: String?) -> Int32? {
        guard let value = value,
              !value.isEmpty else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        let cleaned = trimmed.replacingOccurrences(of: ",", with: "")
        guard let decimal = Decimal(string: cleaned),
              decimal >= 0 else {
            return nil
        }
        let rounded = NSDecimalNumber(decimal: decimal).doubleValue.rounded()
        return Int32(rounded)
    }

    /// 1회 제공량을 그램(g) 단위 Decimal로 변환
    private func parseServingSize(from dto: KFDAFoodDTO) -> Decimal {
        // SERVING_SIZE에서 숫자 추출 (예: "100g" → 100)
        if let grams = dto.parseServingSizeGrams(), grams > 0 {
            return grams
        }
        // 기본값: 100g
        return Decimal(100)
    }

    /// 서빙 단위 텍스트를 파싱합니다.
    /// 예: "1봉지(120g)" → "1봉지", "100g" → nil, "1컵(200ml)" → "1컵"
    private func parseServingUnit(from dto: KFDAFoodDTO) -> String? {
        guard let servingText = dto.servingSize,
              !servingText.isEmpty else { return nil }

        let text = servingText.trimmingCharacters(in: .whitespaces)

        // 패턴: 숫자+한글 단위 + (숫자g/ml)
        // 예: "1봉지(120g)", "2조각(50g)", "1공기(210g)"
        let pattern = #"(\d+(?:\.\d+)?\s*[가-힣]+)\s*\("#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let unitRange = Range(match.range(at: 1), in: text) {
            return String(text[unitRange])
        }

        // 순수 숫자+g/ml 패턴은 서빙 단위 없음 (예: "100g")
        let simplePattern = #"^\d+(?:\.\d+)?\s*(?:g|ml|kcal)$"#
        if let simpleRegex = try? NSRegularExpression(pattern: simplePattern, options: .caseInsensitive),
           simpleRegex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
            return nil
        }

        return nil
    }
}

// MARK: - Mapping Error

enum MappingError: Error {
    case missingRequiredField(String)
    case invalidNutritionData(String)

    var localizedDescription: String {
        switch self {
        case .missingRequiredField(let field):
            return "필수 필드가 누락되었습니다: \(field)"
        case .invalidNutritionData(let field):
            return "영양 정보 데이터가 잘못되었습니다: \(field)"
        }
    }
}

// MARK: - Batch Mapping

extension KFDAFoodMapper {

    /// 여러 DTO를 한 번에 Food 엔티티 배열로 변환 (실패한 항목은 제외)
    func toDomainArray(from dtos: [KFDAFoodDTO], context: NSManagedObjectContext) -> [Food] {
        dtos.compactMap { dto in
            try? toDomain(from: dto, context: context)
        }
    }
}
