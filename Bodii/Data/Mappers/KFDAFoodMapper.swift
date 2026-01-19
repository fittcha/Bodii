//
//  KFDAFoodMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Data Mapper Pattern
// DTO(Data Transfer Object)를 Domain Entity로 변환하는 매퍼
// 💡 Java 비교: ModelMapper, MapStruct와 유사한 역할

import Foundation
import CoreData

/// 식약처 API DTO를 Food 도메인 엔티티로 변환하는 매퍼
///
/// 📚 학습 포인트: Mapper Pattern in Clean Architecture
/// 데이터 레이어의 DTO를 도메인 레이어의 엔티티로 변환
/// 각 레이어 간의 의존성을 분리하고 도메인 로직을 보호
/// 💡 Java 비교: DTO -> Entity 변환 매퍼와 동일한 패턴
///
/// **변환 로직:**
/// - 문자열 영양 정보를 숫자 타입으로 변환
/// - 필수 필드 검증 및 기본값 설정
/// - 출처를 .governmentAPI로 설정
/// - API 코드 저장 (중복 제거에 사용)
///
/// **사용 예시:**
/// ```swift
/// let dto = KFDAFoodDTO(...)
/// let mapper = KFDAFoodMapper()
///
/// // DTO를 도메인 엔티티로 변환
/// let food = try mapper.toDomain(from: dto)
/// print(food.name) // "현미밥"
/// print(food.calories) // 330
/// print(food.source) // .governmentAPI
/// ```
struct KFDAFoodMapper {

    // MARK: - Mapping Methods

    /// KFDAFoodDTO를 Food 도메인 엔티티로 변환
    ///
    /// 📚 학습 포인트: Throwing Functions
    /// 변환 실패 시 에러를 throw하여 호출자가 처리하도록 함
    /// 💡 Java 비교: throws Exception과 동일한 개념
    ///
    /// - Parameter dto: 식약처 API 응답 DTO
    ///
    /// - Returns: Food 도메인 엔티티
    ///
    /// - Throws: `MappingError` - 필수 필드 누락 또는 변환 실패
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let food = try mapper.toDomain(from: dto, context: context)
    /// } catch MappingError.missingRequiredField(let field) {
    ///     print("Missing field: \(field)")
    /// } catch MappingError.invalidNutritionData(let field) {
    ///     print("Invalid data: \(field)")
    /// }
    /// ```
    func toDomain(from dto: KFDAFoodDTO, context: NSManagedObjectContext) throws -> Food {
        // 필수 필드 검증
        guard !dto.foodCd.isEmpty else {
            throw MappingError.missingRequiredField("foodCd")
        }

        guard !dto.descKor.isEmpty else {
            throw MappingError.missingRequiredField("descKor")
        }

        // 칼로리 변환 (필수 필드)
        guard let calories = parseCalories(from: dto.enercKcal) else {
            throw MappingError.invalidNutritionData("enercKcal")
        }

        // 탄수화물 변환 (필수 필드)
        guard let carbohydrates = dto.parseDecimal(dto.chocdf), carbohydrates >= 0 else {
            throw MappingError.invalidNutritionData("chocdf")
        }

        // 단백질 변환 (필수 필드)
        guard let protein = dto.parseDecimal(dto.prot), protein >= 0 else {
            throw MappingError.invalidNutritionData("prot")
        }

        // 지방 변환 (필수 필드)
        guard let fat = dto.parseDecimal(dto.fat), fat >= 0 else {
            throw MappingError.invalidNutritionData("fat")
        }

        // 1회 제공량 변환 (필수 필드)
        guard let servingSize = parseServingSize(from: dto) else {
            throw MappingError.invalidNutritionData("servingSize")
        }

        // 선택 필드 변환
        let sodium = dto.parseDecimal(dto.na)
        let fiber = dto.parseDecimal(dto.fibtg)
        let sugar = dto.parseDecimal(dto.sugar)
        let servingUnit = dto.servingUnit?.trimmingCharacters(in: .whitespaces)

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
        food.servingUnit = servingUnit
        food.source = FoodSource.governmentAPI.rawValue
        food.apiCode = dto.foodCd
        food.createdAt = Date()
        return food
    }

    // MARK: - Helper Methods

    /// 칼로리 문자열을 Int32로 변환
    ///
    /// 📚 학습 포인트: Type Conversion with Validation
    /// API의 문자열 데이터를 앱에서 사용하는 타입으로 안전하게 변환
    /// 💡 Java 비교: Integer.parseInt() + validation과 유사
    ///
    /// - Parameter value: 칼로리 문자열 (예: "330", "330.5")
    ///
    /// - Returns: Int32 칼로리 값 (반올림), 변환 실패 시 nil
    ///
    /// - Note: 소수점 칼로리는 반올림 처리 (330.5 → 331)
    private func parseCalories(from value: String?) -> Int32? {
        guard let value = value,
              !value.isEmpty,
              let decimal = Decimal(string: value.trimmingCharacters(in: .whitespaces)),
              decimal >= 0 else {
            return nil
        }

        // 반올림하여 Int32로 변환
        let rounded = NSDecimalNumber(decimal: decimal).doubleValue.rounded()
        return Int32(rounded)
    }

    /// 1회 제공량을 그램(g) 단위 Decimal로 변환
    ///
    /// 📚 학습 포인트: Fallback Strategy
    /// 여러 필드 중 유효한 값을 찾아 사용하는 폴백 전략
    /// 💡 Java 비교: Optional chaining과 유사
    ///
    /// - Parameter dto: 식약처 API 응답 DTO
    ///
    /// - Returns: 제공량 (g), 변환 실패 시 nil
    ///
    /// - Note: servingSize → servingWt 순서로 폴백, 둘 다 없으면 100g 기본값
    private func parseServingSize(from dto: KFDAFoodDTO) -> Decimal? {
        // servingSize 우선 시도
        if let servingSize = dto.parseDecimal(dto.servingSize), servingSize > 0 {
            return servingSize
        }

        // servingWt로 폴백
        if let servingWt = dto.parseDecimal(dto.servingWt), servingWt > 0 {
            return servingWt
        }

        // 기본값: 100g (표준 1회 제공량)
        // 📚 학습 포인트: Reasonable Defaults
        // API 데이터가 불완전한 경우 합리적인 기본값 제공
        // 💡 Java 비교: Default value pattern
        return Decimal(100)
    }
}

// MARK: - Mapping Error

/// 매핑 과정에서 발생할 수 있는 에러
///
/// 📚 학습 포인트: Custom Error Types
/// 도메인별 에러 타입을 정의하여 명확한 에러 처리
/// 💡 Java 비교: Custom Exception과 동일한 개념
enum MappingError: Error {
    /// 필수 필드 누락
    case missingRequiredField(String)

    /// 잘못된 영양 정보 데이터
    case invalidNutritionData(String)

    /// 사용자 친화적 에러 메시지
    ///
    /// 📚 학습 포인트: LocalizedError Protocol
    /// 사용자에게 보여줄 수 있는 한글 에러 메시지 제공
    /// 💡 Java 비교: getMessage()와 유사
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

    /// 여러 DTO를 한 번에 도메인 엔티티 배열로 변환
    ///
    /// 📚 학습 포인트: Batch Processing with Error Handling
    /// 일부 변환 실패해도 성공한 항목들은 반환
    /// 💡 Java 비교: Stream.map() with filter와 유사
    ///
    /// - Parameter dtos: 식약처 API 응답 DTO 배열
    ///
    /// - Returns: 성공적으로 변환된 Food 엔티티 배열
    ///
    /// - Note: 변환 실패한 항목은 자동으로 제외됨
    ///
    /// - Example:
    /// ```swift
    /// let dtos: [KFDAFoodDTO] = [...]
    /// let foods = mapper.toDomainArray(from: dtos, context: context)
    /// // 일부 DTO가 잘못되어도 유효한 Food만 반환됨
    /// ```
    func toDomainArray(from dtos: [KFDAFoodDTO], context: NSManagedObjectContext) -> [Food] {
        dtos.compactMap { dto in
            try? toDomain(from: dto, context: context)
        }
    }
}
