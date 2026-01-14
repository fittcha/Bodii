//
//  USDANutrientDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: USDA API Nutrient Structure
// USDA API는 영양소를 배열 형태로 제공하며, 각 영양소는 고유 ID로 식별됩니다
// 💡 Java 비교: DTO with nested objects - Jackson과 유사한 파싱 구조

import Foundation

/// USDA API 영양소 정보 DTO
///
/// 📚 학습 포인트: Nutrient ID-based Structure
/// USDA API는 영양소를 ID로 식별합니다 (예: 1008 = Energy, 1003 = Protein)
/// KFDA API는 필드명으로 영양소를 구분하는 것과 대조적
/// 💡 Java 비교: Map<String, Object> 대신 강타입 객체 사용
///
/// **주요 영양소 ID:**
/// - 1008: Energy (kcal) - 칼로리
/// - 1003: Protein (g) - 단백질
/// - 1004: Total lipid (fat) (g) - 지방
/// - 1005: Carbohydrate, by difference (g) - 탄수화물
/// - 1093: Sodium, Na (mg) - 나트륨
/// - 1079: Fiber, total dietary (g) - 식이섬유
/// - 2000: Total Sugars (g) - 당류
///
/// **사용 예시:**
/// ```swift
/// let nutrients = foodDTO.foodNutrients
/// let calories = nutrients.first { $0.nutrientId == 1008 }?.value
/// ```
///
/// **참고:**
/// - API 문서: https://fdc.nal.usda.gov/api-guide.html
/// - Nutrient List: https://fdc.nal.usda.gov/nutrient-list.html
struct USDANutrientDTO: Codable {

    // MARK: - Properties

    /// 영양소 고유 ID
    ///
    /// USDA 영양소 데이터베이스의 고유 식별자
    /// (예: 1008 = Energy, 1003 = Protein)
    let nutrientId: Int

    /// 영양소 이름
    ///
    /// 영문 영양소명 (예: "Energy", "Protein", "Total lipid (fat)")
    let nutrientName: String

    /// 영양소 번호 (순서)
    ///
    /// USDA 내부 정렬 순서 (선택적)
    let nutrientNumber: String?

    /// 영양소 값
    ///
    /// servingSize 기준 영양소 함량
    /// 단위는 unitName에 따름 (kcal, g, mg 등)
    let value: Double

    /// 단위명
    ///
    /// 영양소 값의 단위 (예: "kcal", "g", "mg", "µg")
    let unitName: String

    /// 파생 영양소 ID (선택적)
    ///
    /// 이 영양소가 다른 영양소로부터 계산된 경우 원본 영양소 ID
    let derivationId: Int?

    /// 파생 영양소 코드 (선택적)
    ///
    /// 영양소 계산 방법 코드 (예: "LCCS" = calculated from components)
    let derivationCode: String?

    /// 파생 영양소 설명 (선택적)
    ///
    /// 영양소 계산 방법 설명
    let derivationDescription: String?

    // MARK: - CodingKeys

    /// 📚 학습 포인트: CodingKeys
    /// USDA API는 camelCase를 사용하지만 명시적 매핑으로 안정성 확보
    /// 💡 Java 비교: @JsonProperty 어노테이션과 유사
    enum CodingKeys: String, CodingKey {
        case nutrientId = "nutrientId"
        case nutrientName = "nutrientName"
        case nutrientNumber = "nutrientNumber"
        case value = "value"
        case unitName = "unitName"
        case derivationId = "derivationId"
        case derivationCode = "derivationCode"
        case derivationDescription = "derivationDescription"
    }
}

// MARK: - Helper Extensions

extension USDANutrientDTO {

    /// 영양소 값을 Decimal로 변환
    ///
    /// 📚 학습 포인트: Type Conversion
    /// Double에서 Decimal로 변환하여 정밀도 향상
    /// 💡 Java 비교: BigDecimal.valueOf()와 유사
    ///
    /// - Returns: Decimal 값
    var decimalValue: Decimal {
        return Decimal(value)
    }

    /// 영양소 값을 Int32로 변환
    ///
    /// 칼로리 등 정수 값이 필요한 경우 사용
    ///
    /// - Returns: Int32 값 (소수점 버림)
    var int32Value: Int32 {
        return Int32(value)
    }
}

// MARK: - Common Nutrient IDs

/// USDA 주요 영양소 ID 상수
///
/// 📚 학습 포인트: Constants for Magic Numbers
/// 매직 넘버 대신 의미있는 상수로 관리하여 코드 가독성 향상
/// 💡 Java 비교: static final constants와 동일
enum USDANutrientID {
    /// 에너지 (kcal)
    static let energy = 1008

    /// 단백질 (g)
    static let protein = 1003

    /// 지방 (g)
    static let fat = 1004

    /// 탄수화물 (g)
    static let carbohydrate = 1005

    /// 나트륨 (mg)
    static let sodium = 1093

    /// 식이섬유 (g)
    static let fiber = 1079

    /// 당류 (g)
    static let sugar = 2000

    /// 포화지방 (g)
    static let saturatedFat = 1258

    /// 트랜스지방 (g)
    static let transFat = 1257

    /// 콜레스테롤 (mg)
    static let cholesterol = 1253

    /// 칼슘 (mg)
    static let calcium = 1087

    /// 철분 (mg)
    static let iron = 1089

    /// 비타민 A (µg)
    static let vitaminA = 1106

    /// 비타민 C (mg)
    static let vitaminC = 1162

    /// 비타민 D (µg)
    static let vitaminD = 1114
}

// MARK: - Nutrient Lookup Helper

extension Array where Element == USDANutrientDTO {

    /// 영양소 ID로 값 찾기
    ///
    /// 📚 학습 포인트: Collection Extension
    /// 배열에 편의 메서드를 추가하여 영양소 검색 단순화
    /// 💡 Java 비교: Stream API의 filter().findFirst()와 유사
    ///
    /// - Parameter nutrientId: 찾을 영양소 ID
    ///
    /// - Returns: 영양소 값 (찾지 못하면 nil)
    ///
    /// - Example:
    /// ```swift
    /// let nutrients = foodDTO.foodNutrients
    /// let calories = nutrients.value(for: USDANutrientID.energy) // Optional<Double>
    /// ```
    func value(for nutrientId: Int) -> Double? {
        return first { $0.nutrientId == nutrientId }?.value
    }

    /// 영양소 ID로 Decimal 값 찾기
    ///
    /// - Parameter nutrientId: 찾을 영양소 ID
    ///
    /// - Returns: Decimal 영양소 값 (찾지 못하면 nil)
    func decimalValue(for nutrientId: Int) -> Decimal? {
        return first { $0.nutrientId == nutrientId }?.decimalValue
    }

    /// 영양소 ID로 Int32 값 찾기
    ///
    /// - Parameter nutrientId: 찾을 영양소 ID
    ///
    /// - Returns: Int32 영양소 값 (찾지 못하면 nil)
    func int32Value(for nutrientId: Int) -> Int32? {
        return first { $0.nutrientId == nutrientId }?.int32Value
    }
}
