//
//  KFDAFoodDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Data Transfer Object (DTO)
// API 응답 데이터를 파싱하기 위한 중간 객체
// 💡 Java 비교: Retrofit의 Response Model과 동일한 역할

import Foundation

/// 식약처 API 식품 영양 정보 DTO
///
/// 📚 학습 포인트: DTO vs Domain Entity
/// DTO는 API 응답 구조를 그대로 반영하고, Domain Entity는 비즈니스 로직에 최적화
/// 💡 Java 비교: DTO pattern - 데이터 전송을 위한 객체
///
/// **API 응답 필드:**
/// - 식약처 API는 snake_case 필드명 사용 (예: FOOD_CD, DESC_KOR)
/// - JSONDecoder의 convertFromSnakeCase 전략으로 자동 변환
/// - 예: DESC_KOR → descKor, SERVING_SIZE → servingSize
///
/// **사용 예시:**
/// ```swift
/// let decoder = JSONDecoder()
/// decoder.keyDecodingStrategy = .convertFromSnakeCase
/// let foodDTO = try decoder.decode(KFDAFoodDTO.self, from: jsonData)
/// ```
///
/// **참고:**
/// - API 문서: https://www.data.go.kr/data/15127578/openapi.do
/// - 식품영양성분DB: https://various.foodsafetykorea.go.kr/nutrient/
struct KFDAFoodDTO: Codable {

    // MARK: - 식품 기본 정보

    /// 식품 코드
    ///
    /// API 필드명: FOOD_CD
    /// 식약처에서 부여한 고유 식품 코드 (예: "D000001")
    let foodCd: String

    /// 식품명 (한글)
    ///
    /// API 필드명: DESC_KOR
    /// 한글 식품명 (예: "현미밥", "김치찌개")
    let descKor: String

    /// 식품군 코드
    ///
    /// API 필드명: GROUP_CODE
    /// 식품 분류 코드 (예: "01" = 곡류, "04" = 채소류)
    let groupCode: String?

    /// 식품군명
    ///
    /// API 필드명: GROUP_NAME
    /// 식품 분류명 (예: "곡류", "채소류", "육류")
    let groupName: String?

    // MARK: - 영양 성분 정보

    /// 에너지 (kcal)
    ///
    /// API 필드명: ENERC_KCAL
    /// 1회 제공량 기준 칼로리
    let enercKcal: String?

    /// 단백질 (g)
    ///
    /// API 필드명: PROT
    /// 1회 제공량 기준 단백질 함량
    let prot: String?

    /// 지방 (g)
    ///
    /// API 필드명: FAT
    /// 1회 제공량 기준 지방 함량
    let fat: String?

    /// 탄수화물 (g)
    ///
    /// API 필드명: CHOCDF
    /// 1회 제공량 기준 탄수화물 함량
    let chocdf: String?

    /// 나트륨 (mg)
    ///
    /// API 필드명: NA
    /// 1회 제공량 기준 나트륨 함량
    let na: String?

    /// 식이섬유 (g)
    ///
    /// API 필드명: FIBTG
    /// 1회 제공량 기준 식이섬유 함량 (선택)
    let fibtg: String?

    /// 당류 (g)
    ///
    /// API 필드명: SUGAR
    /// 1회 제공량 기준 당류 함량 (선택)
    let sugar: String?

    // MARK: - 제공량 정보

    /// 1회 제공량 (g)
    ///
    /// API 필드명: SERVING_SIZE
    /// 영양 정보의 기준이 되는 제공량 (단위: 그램)
    let servingSize: String?

    /// 제공량 단위
    ///
    /// API 필드명: SERVING_UNIT
    /// 사용자 친화적 단위 표시 (예: "1인분", "1공기", "1개")
    let servingUnit: String?

    /// 식품 중량 (g)
    ///
    /// API 필드명: SERVING_WT
    /// 실제 식품의 중량 (servingSize와 동일하거나 다를 수 있음)
    let servingWt: String?

    // MARK: - 메타데이터

    /// 제조사명
    ///
    /// API 필드명: MAKER_NAME
    /// 제조사 또는 브랜드명 (가공식품의 경우)
    let makerName: String?

    /// 연구 수행 연월일
    ///
    /// API 필드명: RESEARCH_YMD
    /// 데이터 조사/수집 날짜
    let researchYmd: String?

    /// 데이터 생성 방법
    ///
    /// API 필드명: DATA_TYPE_NAME
    /// 데이터 수집 방법 (예: "영양성분표 기반", "실측")
    let dataTypeName: String?

    // MARK: - Custom CodingKeys

    /// 📚 학습 포인트: CodingKeys
    /// API의 대문자 snake_case를 Swift의 camelCase로 매핑
    /// 💡 Java 비교: @SerializedName 어노테이션과 유사
    ///
    /// - Note: NetworkManager의 JSONDecoder가 convertFromSnakeCase를 사용하지만,
    ///         식약처 API는 대문자를 사용하므로 명시적으로 매핑
    enum CodingKeys: String, CodingKey {
        case foodCd = "FOOD_CD"
        case descKor = "DESC_KOR"
        case groupCode = "GROUP_CODE"
        case groupName = "GROUP_NAME"
        case enercKcal = "ENERC_KCAL"
        case prot = "PROT"
        case fat = "FAT"
        case chocdf = "CHOCDF"
        case na = "NA"
        case fibtg = "FIBTG"
        case sugar = "SUGAR"
        case servingSize = "SERVING_SIZE"
        case servingUnit = "SERVING_UNIT"
        case servingWt = "SERVING_WT"
        case makerName = "MAKER_NAME"
        case researchYmd = "RESEARCH_YMD"
        case dataTypeName = "DATA_TYPE_NAME"
    }
}

// MARK: - Helper Extensions

extension KFDAFoodDTO {

    /// 영양 정보 문자열을 Decimal로 안전하게 변환
    ///
    /// 📚 학습 포인트: Optional Chaining & Nil Coalescing
    /// API 응답의 문자열 숫자를 안전하게 Decimal로 변환
    /// 💡 Java 비교: Optional.map()과 유사한 패턴
    ///
    /// - Parameter value: 변환할 문자열 값
    ///
    /// - Returns: Decimal 값 (변환 실패 시 nil)
    ///
    /// - Example:
    /// ```swift
    /// let calories = parseDecimal(enercKcal) // "330.5" → Decimal(330.5)
    /// ```
    func parseDecimal(_ value: String?) -> Decimal? {
        guard let value = value, !value.isEmpty else {
            return nil
        }

        // 공백 제거
        let trimmed = value.trimmingCharacters(in: .whitespaces)

        // Decimal 변환
        return Decimal(string: trimmed)
    }

    /// 영양 정보 문자열을 Int32로 안전하게 변환
    ///
    /// - Parameter value: 변환할 문자열 값
    ///
    /// - Returns: Int32 값 (변환 실패 시 nil)
    func parseInt32(_ value: String?) -> Int32? {
        guard let decimal = parseDecimal(value) else {
            return nil
        }

        return Int32(truncating: decimal as NSNumber)
    }
}

// MARK: - Validation

extension KFDAFoodDTO {

    /// DTO의 필수 필드가 유효한지 검증
    ///
    /// 📚 학습 포인트: Data Validation
    /// 파싱 후 필수 데이터가 있는지 검증하여 잘못된 데이터 걸러내기
    /// 💡 Java 비교: Bean Validation과 유사
    ///
    /// - Returns: 유효하면 true, 필수 필드 누락 시 false
    ///
    /// **검증 항목:**
    /// - 식품 코드 존재 여부
    /// - 식품명 존재 여부
    /// - 최소 하나 이상의 영양 정보 존재 여부
    var isValid: Bool {
        // 필수 필드 검증
        guard !foodCd.isEmpty, !descKor.isEmpty else {
            return false
        }

        // 최소 하나 이상의 영양 정보 필요
        let hasNutritionInfo = enercKcal != nil ||
                               prot != nil ||
                               fat != nil ||
                               chocdf != nil

        return hasNutritionInfo
    }
}
