//
//  KFDAFoodDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import Foundation

/// 식약처 API 식품 영양 정보 DTO (FoodNtrCpntDbInfo02 API)
///
/// **주요 AMT_NUM 매핑:**
/// - AMT_NUM1: 에너지 (kcal)
/// - AMT_NUM3: 단백질 (g)
/// - AMT_NUM4: 지방 (g)
/// - AMT_NUM6: 탄수화물 (g)
/// - AMT_NUM7: 당류 (g)
/// - AMT_NUM8: 식이섬유 (g)
/// - AMT_NUM13: 나트륨 (mg)
///
/// - Note: NetworkManager의 JSONDecoder가 convertFromSnakeCase 전략을 사용하므로
///   API의 대문자 snake_case 필드명(FOOD_CD, AMT_NUM1 등)이 자동으로
///   camelCase 프로퍼티(foodCd, amtNum1 등)에 매핑됩니다.
struct KFDAFoodDTO: Codable {

    // MARK: - 식품 기본 정보

    /// 식품 코드 (API: FOOD_CD)
    let foodCd: String

    /// 식품명 한글 (API: FOOD_NM_KR)
    let foodNmKr: String

    /// 데이터구분 코드 (API: DB_GRP_CM)
    let dbGrpCm: String?

    /// 데이터구분명 (API: DB_GRP_NM, 예: "음식", "가공식품")
    let dbGrpNm: String?

    /// 식품 대분류명 (API: FOOD_CAT1_NM)
    let foodCat1Nm: String?

    // MARK: - 영양 성분 정보

    /// 에너지 kcal (API: AMT_NUM1)
    let amtNum1: String?

    /// 수분 g (API: AMT_NUM2)
    let amtNum2: String?

    /// 단백질 g (API: AMT_NUM3)
    let amtNum3: String?

    /// 지방 g (API: AMT_NUM4)
    let amtNum4: String?

    /// 탄수화물 g (API: AMT_NUM6)
    let amtNum6: String?

    /// 당류 g (API: AMT_NUM7)
    let amtNum7: String?

    /// 식이섬유 g (API: AMT_NUM8)
    let amtNum8: String?

    /// 나트륨 mg (API: AMT_NUM13)
    let amtNum13: String?

    // MARK: - 제공량 정보

    /// 1회 제공량 (API: SERVING_SIZE, 예: "100g", "200ml")
    let servingSize: String?

    // MARK: - 메타데이터

    /// 제조사명 (API: MAKER_NM)
    let makerNm: String?

    /// 출처 참조명 (API: SUB_REF_NAME)
    let subRefName: String?

    /// 연구 수행 연월일 (API: RESEARCH_YMD)
    let researchYmd: String?

    /// 데이터 생성 방법명 (API: CRT_MTH_NM)
    let crtMthNm: String?
}

// MARK: - Helper Extensions

extension KFDAFoodDTO {

    /// 영양 정보 문자열을 Decimal로 안전하게 변환
    func parseDecimal(_ value: String?) -> Decimal? {
        guard let value = value, !value.isEmpty else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        // 콤마 제거 (예: "1,010.000" → "1010.000")
        let cleaned = trimmed.replacingOccurrences(of: ",", with: "")
        return Decimal(string: cleaned)
    }

    /// 영양 정보 문자열을 Int32로 안전하게 변환
    func parseInt32(_ value: String?) -> Int32? {
        guard let decimal = parseDecimal(value) else {
            return nil
        }
        return Int32(truncating: decimal as NSNumber)
    }

    /// SERVING_SIZE에서 숫자(그램) 추출 (예: "100g" → 100)
    func parseServingSizeGrams() -> Decimal? {
        guard let raw = servingSize, !raw.isEmpty else {
            return nil
        }
        let digits = raw.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard !digits.isEmpty else { return nil }
        return Decimal(string: digits)
    }

    // MARK: - Backward Compatibility Accessors

    /// 식품명 (기존 descKor 호환)
    var descKor: String { foodNmKr }

    /// 에너지 kcal (기존 enercKcal 호환)
    var enercKcal: String? { amtNum1 }

    /// 단백질 g (기존 prot 호환)
    var prot: String? { amtNum3 }

    /// 지방 g (기존 fat 호환)
    var fat: String? { amtNum4 }

    /// 탄수화물 g (기존 chocdf 호환)
    var chocdf: String? { amtNum6 }

    /// 나트륨 mg (기존 na 호환)
    var na: String? { amtNum13 }

    /// 식이섬유 g (기존 fibtg 호환)
    var fibtg: String? { amtNum8 }

    /// 당류 g (기존 sugar 호환)
    var sugar: String? { amtNum7 }

    /// 제조사명 (기존 makerName 호환)
    var makerName: String? { makerNm }

    /// 제공량 단위 (새 API에는 별도 필드 없음)
    var servingUnit: String? { nil }

    /// 제공량 중량
    var servingWt: String? { servingSize }
}

// MARK: - Validation

extension KFDAFoodDTO {

    /// DTO의 필수 필드가 유효한지 검증
    var isValid: Bool {
        guard !foodCd.isEmpty, !foodNmKr.isEmpty else {
            return false
        }
        let hasNutritionInfo = amtNum1 != nil ||
                               amtNum3 != nil ||
                               amtNum4 != nil ||
                               amtNum6 != nil
        return hasNutritionInfo
    }
}
