//
//  USDAFoodDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: USDA FoodData Central DTO
// USDA API의 복잡한 중첩 구조를 Swift 타입으로 안전하게 파싱
// 💡 Java 비교: Complex DTO with nested objects - KFDA보다 더 깊은 중첩 구조

import Foundation

/// USDA FoodData Central API 식품 정보 DTO
///
/// 📚 학습 포인트: Multi-Type Food Data
/// USDA API는 여러 식품 타입을 지원합니다:
/// - Foundation Foods: 기본 식품 (사과, 쌀 등)
/// - SR Legacy: Standard Reference 레거시 데이터
/// - Branded Foods: 브랜드 제품 (바코드 있는 상품)
/// - Survey (FNDDS): 영양 조사 데이터
/// 💡 Java 비교: Polymorphic DTO - 다양한 타입을 하나의 구조로 처리
///
/// **API 응답 구조:**
/// ```json
/// {
///   "fdcId": 123456,
///   "description": "Apple, raw",
///   "dataType": "Foundation",
///   "foodNutrients": [
///     { "nutrientId": 1008, "value": 52, "unitName": "kcal" },
///     ...
///   ],
///   "servingSize": 100,
///   "servingSizeUnit": "g",
///   "brandOwner": "Some Brand",
///   "gtinUpc": "012345678901"
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let decoder = JSONDecoder()
/// let foodDTO = try decoder.decode(USDAFoodDTO.self, from: jsonData)
/// let calories = foodDTO.foodNutrients?.value(for: USDANutrientID.energy)
/// ```
///
/// **참고:**
/// - API 문서: https://fdc.nal.usda.gov/api-guide.html
/// - API Spec: https://app.swaggerhub.com/apis/fdcnal/food-data_central_api
struct USDAFoodDTO: Codable {

    // MARK: - 식품 기본 정보

    /// FDC ID (Food Data Central 고유 식별자)
    ///
    /// USDA 식품 데이터베이스의 고유 ID
    /// API 호출 및 중복 체크에 사용
    let fdcId: Int

    /// 식품 설명 (이름)
    ///
    /// 영문 식품명 (예: "Apple, raw", "Milk, whole")
    /// Branded 식품의 경우 브랜드명 포함
    let description: String

    /// 데이터 타입
    ///
    /// 식품 데이터의 출처/타입
    /// - "Foundation": 기본 식품
    /// - "SR Legacy": Standard Reference 레거시
    /// - "Branded": 브랜드 제품
    /// - "Survey (FNDDS)": 영양 조사 데이터
    let dataType: String?

    /// 식품 코드 (선택적)
    ///
    /// Survey 데이터의 경우 식품 코드 제공
    let foodCode: String?

    /// 게시 날짜
    ///
    /// 데이터가 FDC에 게시된 날짜 (ISO 8601 형식)
    let publicationDate: String?

    // MARK: - 영양 정보

    /// 영양소 배열
    ///
    /// 📚 학습 포인트: Array of Nutrients
    /// KFDA와 달리 USDA는 영양소를 배열로 제공
    /// 각 영양소는 ID로 식별됨
    /// 💡 Java 비교: List<Nutrient> - 동적 영양소 목록
    let foodNutrients: [USDANutrientDTO]?

    // MARK: - 제공량 정보

    /// 1회 제공량 크기
    ///
    /// 영양 정보의 기준이 되는 제공량
    /// Branded 식품에서 주로 제공됨
    let servingSize: Double?

    /// 제공량 단위
    ///
    /// 제공량의 단위 (예: "g", "ml", "oz")
    let servingSizeUnit: String?

    /// 가구 제공량 설명 (선택적)
    ///
    /// 사용자 친화적 제공량 표시 (예: "1 cup", "1 medium apple")
    let householdServingFullText: String?

    // MARK: - 브랜드 식품 정보

    /// 브랜드 소유자
    ///
    /// Branded 식품의 제조사/브랜드명
    let brandOwner: String?

    /// 브랜드명
    ///
    /// Branded 식품의 제품 브랜드
    let brandName: String?

    /// GTIN/UPC 바코드
    ///
    /// 제품 바코드 번호 (Branded 식품)
    let gtinUpc: String?

    /// 성분 리스트
    ///
    /// Branded 식품의 원재료 목록 (영문)
    let ingredients: String?

    // MARK: - 식품 카테고리

    /// 식품 카테고리 ID
    ///
    /// USDA 식품 분류 ID
    let foodCategoryId: Int?

    /// 식품 카테고리명
    ///
    /// USDA 식품 분류명 (예: "Fruits and Fruit Juices")
    let foodCategory: String?

    // MARK: - 추가 메타데이터

    /// 과학적 이름 (선택적)
    ///
    /// 식품의 학명 (예: "Malus domestica" for apple)
    let scientificName: String?

    /// 모든 카테고리 정보 (선택적)
    ///
    /// 식품이 속한 모든 카테고리 정보
    let allHighlightFields: String?

    /// 점수 (선택적)
    ///
    /// 검색 결과의 관련도 점수
    let score: Double?

    // MARK: - CodingKeys

    /// 📚 학습 포인트: CodingKeys
    /// USDA API는 camelCase를 사용하지만 명시적 매핑으로 안정성 확보
    /// 💡 Java 비교: @JsonProperty 어노테이션과 유사
    enum CodingKeys: String, CodingKey {
        case fdcId = "fdcId"
        case description = "description"
        case dataType = "dataType"
        case foodCode = "foodCode"
        case publicationDate = "publicationDate"
        case foodNutrients = "foodNutrients"
        case servingSize = "servingSize"
        case servingSizeUnit = "servingSizeUnit"
        case householdServingFullText = "householdServingFullText"
        case brandOwner = "brandOwner"
        case brandName = "brandName"
        case gtinUpc = "gtinUpc"
        case ingredients = "ingredients"
        case foodCategoryId = "foodCategoryId"
        case foodCategory = "foodCategory"
        case scientificName = "scientificName"
        case allHighlightFields = "allHighlightFields"
        case score = "score"
    }
}

// MARK: - Helper Extensions

extension USDAFoodDTO {

    /// 특정 영양소 값 가져오기
    ///
    /// 📚 학습 포인트: Convenience Method
    /// 영양소 배열에서 특정 영양소를 쉽게 찾을 수 있도록 헬퍼 메서드 제공
    /// 💡 Java 비교: Stream API filter와 유사
    ///
    /// - Parameter nutrientId: 영양소 ID
    ///
    /// - Returns: 영양소 값 (없으면 nil)
    ///
    /// - Example:
    /// ```swift
    /// let calories = foodDTO.getNutrientValue(USDANutrientID.energy)
    /// let protein = foodDTO.getNutrientValue(USDANutrientID.protein)
    /// ```
    func getNutrientValue(_ nutrientId: Int) -> Double? {
        return foodNutrients?.value(for: nutrientId)
    }

    /// 특정 영양소 Decimal 값 가져오기
    ///
    /// - Parameter nutrientId: 영양소 ID
    ///
    /// - Returns: Decimal 영양소 값 (없으면 nil)
    func getNutrientDecimalValue(_ nutrientId: Int) -> Decimal? {
        return foodNutrients?.decimalValue(for: nutrientId)
    }

    /// 특정 영양소 Int32 값 가져오기
    ///
    /// - Parameter nutrientId: 영양소 ID
    ///
    /// - Returns: Int32 영양소 값 (없으면 nil)
    func getNutrientInt32Value(_ nutrientId: Int) -> Int32? {
        return foodNutrients?.int32Value(for: nutrientId)
    }

    /// 제공량 크기를 Decimal로 변환
    ///
    /// - Returns: Decimal 제공량 (없으면 100g 기본값)
    func getServingSizeDecimal() -> Decimal {
        guard let servingSize = servingSize else {
            return 100 // 기본값: 100g
        }
        return Decimal(servingSize)
    }
}

// MARK: - Food Type Helpers

extension USDAFoodDTO {

    /// Branded 식품 여부
    ///
    /// 📚 학습 포인트: Computed Property
    /// 식품 타입을 판단하는 편의 프로퍼티
    /// 💡 Java 비교: getter 메서드와 동일하지만 더 간결
    ///
    /// - Returns: Branded 식품이면 true
    var isBranded: Bool {
        return dataType?.lowercased() == "branded"
    }

    /// Foundation 식품 여부
    ///
    /// - Returns: Foundation 식품이면 true
    var isFoundation: Bool {
        return dataType?.lowercased() == "foundation"
    }

    /// SR Legacy 식품 여부
    ///
    /// - Returns: SR Legacy 식품이면 true
    var isSRLegacy: Bool {
        return dataType?.lowercased() == "sr legacy"
    }

    /// Survey 식품 여부
    ///
    /// - Returns: Survey 식품이면 true
    var isSurvey: Bool {
        return dataType?.lowercased().contains("survey") ?? false
    }

    /// 식품 타입 표시명
    ///
    /// 사용자에게 보여줄 식품 타입명 (한글)
    ///
    /// - Returns: 한글 타입명
    var dataTypeDisplayName: String {
        guard let dataType = dataType else {
            return "알 수 없음"
        }

        switch dataType.lowercased() {
        case "branded":
            return "브랜드 제품"
        case "foundation":
            return "기본 식품"
        case "sr legacy":
            return "표준 참고 데이터"
        case let type where type.contains("survey"):
            return "영양 조사 데이터"
        default:
            return dataType
        }
    }
}

// MARK: - Validation

extension USDAFoodDTO {

    /// DTO의 필수 필드가 유효한지 검증
    ///
    /// 📚 학습 포인트: Data Validation
    /// 파싱 후 필수 데이터가 있는지 검증하여 잘못된 데이터 걸러내기
    /// 💡 Java 비교: Bean Validation과 유사
    ///
    /// - Returns: 유효하면 true, 필수 필드 누락 시 false
    ///
    /// **검증 항목:**
    /// - FDC ID 존재 여부
    /// - 식품명 존재 여부
    /// - 영양소 배열 존재 및 최소 하나 이상의 영양소
    var isValid: Bool {
        // FDC ID는 항상 존재 (non-optional)

        // 식품명 검증
        guard !description.isEmpty else {
            return false
        }

        // 최소 하나 이상의 영양소 필요
        guard let nutrients = foodNutrients, !nutrients.isEmpty else {
            return false
        }

        // 칼로리 정보가 있는지 확인 (필수 영양소)
        let hasCalories = nutrients.contains { $0.nutrientId == USDANutrientID.energy }

        return hasCalories
    }
}
