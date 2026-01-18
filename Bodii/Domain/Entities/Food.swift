//
//  Food.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Master Data Pattern
// Food는 마스터 데이터로 여러 FoodRecord에서 참조되는 불변 영양 정보 저장
// 💡 Java 비교: JPA에서 @OneToMany 관계의 마스터 테이블과 동일 (Product - OrderItem 패턴)

import Foundation

// MARK: - Food

/// 음식 마스터 데이터 도메인 엔티티
/// - 음식의 영양 정보와 기준 제공량을 관리하는 마스터 데이터
/// - FoodRecord에서 참조하여 섭취량 계산에 사용
/// - 데이터 출처: 식약처 API, USDA API, 사용자 직접 생성
///
/// ## 주요 기능
/// - 음식별 영양 정보 관리 (칼로리, 탄수화물, 단백질, 지방 등)
/// - 기준 제공량 및 단위 정보
/// - 데이터 출처 추적 (API 코드 포함)
/// - 사용자 생성 음식 지원
///
/// ## 데이터 출처
/// - 식품의약품안전처(KFDA) API: 한국 음식 데이터
/// - 미국 농무부(USDA) API: 미국/국제 음식 데이터
/// - 사용자 생성: 커스텀 음식 등록
///
/// ## 사용 예시
/// ```swift
/// // 1. API에서 가져온 음식
/// let rice = Food(
///     id: UUID(),
///     name: "백미밥",
///     calories: 130,
///     carbohydrates: 28.7,
///     protein: 2.5,
///     fat: 0.2,
///     sodium: 0,
///     fiber: 0.3,
///     sugar: 0.1,
///     servingSize: 100.0,
///     servingUnit: .gram,
///     source: .kfdaAPI,
///     apiCode: "KFDA_12345",
///     createdByUserId: nil,
///     createdAt: Date()
/// )
///
/// // 2. 사용자가 직접 생성한 음식
/// let customMeal = Food(
///     id: UUID(),
///     name: "엄마표 된장찌개",
///     calories: 120,
///     carbohydrates: 8.5,
///     protein: 7.2,
///     fat: 5.1,
///     sodium: 980,
///     fiber: 1.2,
///     sugar: 2.1,
///     servingSize: 1.0,
///     servingUnit: .serving,
///     source: .userCreated,
///     apiCode: nil,
///     createdByUserId: userId,
///     createdAt: Date()
/// )
///
/// // 3. FoodRecord에서 영양 정보 계산
/// let quantity: Decimal = 1.5 // 1.5인분
/// let totalCalories = rice.calories * Int(truncating: NSDecimalNumber(decimal: quantity))
/// ```
struct Food: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 음식 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    // MARK: Basic Information

    /// 음식 이름
    /// - 한국어 음식명 또는 영문 음식명
    /// - 검색 및 표시에 사용
    var name: String

    // MARK: Nutritional Information

    /// 열량 (kcal)
    /// - 기준 제공량당 칼로리
    /// - FoodRecord에서 섭취량에 따라 계산
    var calories: Int

    /// 탄수화물 (g)
    /// - 기준 제공량당 탄수화물 함량
    /// - 3대 영양소 중 하나
    var carbohydrates: Decimal

    /// 단백질 (g)
    /// - 기준 제공량당 단백질 함량
    /// - 3대 영양소 중 하나
    var protein: Decimal

    /// 지방 (g)
    /// - 기준 제공량당 지방 함량
    /// - 3대 영양소 중 하나
    var fat: Decimal

    /// 나트륨 (mg)
    /// - 기준 제공량당 나트륨 함량
    /// - 옵셔널: API에 데이터가 없을 수 있음
    var sodium: Decimal?

    /// 식이섬유 (g)
    /// - 기준 제공량당 식이섬유 함량
    /// - 옵셔널: API에 데이터가 없을 수 있음
    var fiber: Decimal?

    /// 당류 (g)
    /// - 기준 제공량당 당류 함량
    /// - 옵셔널: API에 데이터가 없을 수 있음
    var sugar: Decimal?

    // MARK: Serving Information

    /// 기준 제공량
    /// - 영양 정보의 기준이 되는 양
    /// - 예: 100g, 1인분
    var servingSize: Decimal

    /// 기준 제공량 단위
    /// - .gram: 그램 단위 (예: 100g)
    /// - .serving: 인분 단위 (예: 1인분)
    /// - nil 가능: 단위 정보가 없는 경우
    var servingUnit: QuantityUnit?

    // MARK: Source Tracking

    /// 데이터 출처
    /// - .kfdaAPI: 식품의약품안전처 API
    /// - .usdaAPI: 미국 농무부 API
    /// - .userCreated: 사용자 직접 생성
    var source: FoodSource

    /// API 고유 코드
    /// - API 출처의 원본 데이터 식별자
    /// - 데이터 동기화 및 중복 방지에 사용
    /// - 옵셔널: 사용자 생성 음식은 nil
    var apiCode: String?

    /// 음식 생성 사용자 ID
    /// - 사용자가 직접 생성한 음식일 경우 생성자 ID
    /// - 옵셔널: API 음식은 nil, userCreated만 값 존재
    var createdByUserId: UUID?

    // MARK: Timestamps

    /// 생성 시각
    /// - 음식 데이터가 DB에 추가된 시각
    let createdAt: Date
}

// MARK: - Food + CustomStringConvertible

extension Food: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        let servingInfo: String
        if let unit = servingUnit {
            servingInfo = "\(servingSize)\(unit.displayName)"
        } else {
            servingInfo = "\(servingSize)"
        }

        return """
        Food(
          id: \(id.uuidString.prefix(8))...,
          name: \(name),
          calories: \(calories)kcal,
          carbs: \(carbohydrates)g,
          protein: \(protein)g,
          fat: \(fat)g,
          servingSize: \(servingInfo),
          source: \(source.displayName)\(apiCode.map { " (\($0))" } ?? "")
        )
        """
    }
}
