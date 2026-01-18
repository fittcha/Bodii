//
//  FoodRecord.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Transactional Record Pattern
// FoodRecord는 트랜잭션 데이터로 실제 섭취 기록을 저장하며 Food 마스터 데이터를 참조
// 💡 Java 비교: JPA에서 @ManyToOne 관계의 트랜잭션 엔티티와 동일 (OrderItem - Product 패턴)

import Foundation

// MARK: - FoodRecord

/// 음식 섭취 기록 도메인 엔티티
/// - 사용자가 실제로 섭취한 음식의 양과 영양 정보를 기록
/// - Food 마스터 데이터를 참조하여 섭취량에 따른 영양 정보 자동 계산
/// - DailyLog에서 일일 영양 합계 계산에 사용
///
/// ## 주요 기능
/// - 식사 유형별 음식 섭취 기록 (아침/점심/저녁/간식)
/// - 섭취량에 따른 영양 정보 자동 계산
/// - Food 마스터 데이터 참조를 통한 일관성 유지
/// - 일일 영양 합계 계산 지원
///
/// ## 계산 공식
/// ```
/// 섭취 칼로리 = Food.calories × (quantity / Food.servingSize)
/// 섭취 탄수화물 = Food.carbohydrates × (quantity / Food.servingSize)
/// 섭취 단백질 = Food.protein × (quantity / Food.servingSize)
/// 섭취 지방 = Food.fat × (quantity / Food.servingSize)
/// ```
///
/// ## 데이터 관계
/// - Food (N:1): FoodRecord는 하나의 Food를 참조
/// - DailyLog (N:1): 같은 날짜의 FoodRecord들이 DailyLog에 집계됨
///
/// ## 사용 예시
/// ```swift
/// // 1. Food 선택 후 섭취량 기록
/// let rice = Food(name: "백미밥", calories: 130, servingSize: 100.0, servingUnit: .gram, ...)
/// let record = FoodRecord(
///     id: UUID(),
///     userId: userId,
///     foodId: rice.id,
///     date: Date(),
///     mealType: .lunch,
///     quantity: 200.0,
///     quantityUnit: .gram,
///     createdAt: Date()
/// )
///
/// // 2. 영양 정보 계산
/// let nutrition = record.calculateNutrition(from: rice)
/// print(nutrition.calories) // 260 kcal (130 × 2.0)
/// print(nutrition.carbs) // 57.4g (28.7 × 2.0)
/// ```
struct FoodRecord: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 음식 섭취 기록 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    /// 음식 마스터 데이터 고유 식별자
    /// - Food 엔티티와의 외래 키 관계
    /// - N:1 관계: 여러 FoodRecord가 동일한 Food 참조 가능
    let foodId: UUID

    // MARK: Record Data

    /// 섭취 날짜
    /// - 02:00 sleep boundary 로직 적용 (DateUtils.getLogicalDate)
    /// - DailyLog 집계 시 이 날짜 기준으로 그룹화
    let date: Date

    /// 식사 유형
    /// - .breakfast (아침), .lunch (점심), .dinner (저녁), .snack (간식)
    /// - 식사별 영양 섭취 패턴 분석에 사용
    var mealType: MealType

    /// 섭취량
    /// - 실제 섭취한 음식의 양
    /// - quantityUnit과 함께 사용하여 영양 정보 계산
    /// - 예: 1.5인분, 200g
    var quantity: Decimal

    /// 섭취량 단위
    /// - .serving: 인분 단위 (예: 1.5인분)
    /// - .gram: 그램 단위 (예: 200g)
    /// - Food.servingUnit과 동일한 단위 사용 권장
    var quantityUnit: QuantityUnit

    // MARK: Timestamps

    /// 생성 시각
    /// - 섭취 기록이 DB에 추가된 시각
    let createdAt: Date

    // MARK: - Nested Types

    /// 계산된 영양 정보
    /// - FoodRecord의 섭취량을 기반으로 계산된 실제 섭취 영양소
    struct CalculatedNutrition: Equatable {
        /// 섭취 칼로리 (kcal)
        let calories: Int

        /// 섭취 탄수화물 (g)
        let carbohydrates: Decimal

        /// 섭취 단백질 (g)
        let protein: Decimal

        /// 섭취 지방 (g)
        let fat: Decimal

        /// 섭취 나트륨 (mg) - 옵셔널
        let sodium: Decimal?

        /// 섭취 식이섬유 (g) - 옵셔널
        let fiber: Decimal?

        /// 섭취 당류 (g) - 옵셔널
        let sugar: Decimal?
    }

    // MARK: - Methods

    /// Food 마스터 데이터를 기반으로 실제 섭취한 영양 정보 계산
    /// - Parameter food: 참조하는 Food 마스터 데이터
    /// - Returns: 섭취량에 따라 계산된 영양 정보
    ///
    /// ## 계산 로직
    /// 1. 섭취량과 Food의 기준 제공량 비율 계산
    /// 2. Food의 영양 정보에 비율을 곱하여 실제 섭취량 계산
    ///
    /// ## 계산 공식
    /// ```
    /// multiplier = quantity / Food.servingSize
    /// 섭취 칼로리 = Food.calories × multiplier
    /// 섭취 탄수화물 = Food.carbohydrates × multiplier
    /// 섭취 단백질 = Food.protein × multiplier
    /// 섭취 지방 = Food.fat × multiplier
    /// ```
    ///
    /// ## 예시
    /// ```swift
    /// // Food: 백미밥 100g당 130kcal, 탄수화물 28.7g
    /// let rice = Food(
    ///     name: "백미밥",
    ///     calories: 130,
    ///     carbohydrates: 28.7,
    ///     servingSize: 100.0,
    ///     ...
    /// )
    ///
    /// // FoodRecord: 200g 섭취
    /// let record = FoodRecord(
    ///     foodId: rice.id,
    ///     quantity: 200.0,
    ///     quantityUnit: .gram,
    ///     ...
    /// )
    ///
    /// // 영양 정보 계산
    /// let nutrition = record.calculateNutrition(from: rice)
    /// // nutrition.calories = 260 kcal (130 × 2.0)
    /// // nutrition.carbohydrates = 57.4g (28.7 × 2.0)
    /// ```
    ///
    /// ## 주의사항
    /// - foodId가 food.id와 일치하는지 확인하는 것은 호출자의 책임
    /// - quantityUnit과 food.servingUnit이 다를 경우 변환 필요 (현재는 동일 단위 가정)
    func calculateNutrition(from food: Food) -> CalculatedNutrition {
        // 섭취량 배수 계산 (실제 섭취량 / 기준 제공량)
        let multiplier = quantity / food.servingSize

        // 각 영양소에 배수를 곱하여 실제 섭취량 계산
        return CalculatedNutrition(
            calories: Int((Decimal(food.calories) * multiplier).rounded(scale: 0)),
            carbohydrates: (food.carbohydrates * multiplier).rounded(scale: 1),
            protein: (food.protein * multiplier).rounded(scale: 1),
            fat: (food.fat * multiplier).rounded(scale: 1),
            sodium: food.sodium.map { ($0 * multiplier).rounded(scale: 1) },
            fiber: food.fiber.map { ($0 * multiplier).rounded(scale: 1) },
            sugar: food.sugar.map { ($0 * multiplier).rounded(scale: 1) }
        )
    }

    /// 섭취량 업데이트
    /// - Parameters:
    ///   - newQuantity: 새로운 섭취량
    ///   - newUnit: 새로운 섭취량 단위 (기본값: 현재 단위 유지)
    /// - Returns: 업데이트된 FoodRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 섭취량을 수정할 때 (예: 1인분 → 1.5인분)
    ///
    /// ## 예시
    /// ```swift
    /// let original = FoodRecord(quantity: 1.0, quantityUnit: .serving, ...)
    /// let updated = original.updatingQuantity(1.5)
    /// // updated.quantity = 1.5, quantityUnit = .serving
    ///
    /// let converted = original.updatingQuantity(150.0, unit: .gram)
    /// // converted.quantity = 150.0, quantityUnit = .gram
    /// ```
    func updatingQuantity(_ newQuantity: Decimal, unit newUnit: QuantityUnit? = nil) -> FoodRecord {
        FoodRecord(
            id: id,
            userId: userId,
            foodId: foodId,
            date: date,
            mealType: mealType,
            quantity: newQuantity,
            quantityUnit: newUnit ?? quantityUnit,
            createdAt: createdAt
        )
    }

    /// 식사 유형 업데이트
    /// - Parameter newMealType: 새로운 식사 유형
    /// - Returns: 업데이트된 FoodRecord
    ///
    /// ## 사용 시나리오
    /// 사용자가 식사 유형을 변경할 때 (예: 간식 → 점심)
    ///
    /// ## 예시
    /// ```swift
    /// let original = FoodRecord(mealType: .snack, ...)
    /// let updated = original.updatingMealType(.lunch)
    /// // updated.mealType = .lunch
    /// ```
    func updatingMealType(_ newMealType: MealType) -> FoodRecord {
        FoodRecord(
            id: id,
            userId: userId,
            foodId: foodId,
            date: date,
            mealType: newMealType,
            quantity: quantity,
            quantityUnit: quantityUnit,
            createdAt: createdAt
        )
    }
}

// MARK: - FoodRecord + CustomStringConvertible

extension FoodRecord: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        """
        FoodRecord(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          foodId: \(foodId.uuidString.prefix(8))...,
          date: \(date.formatted(style: .short)),
          mealType: \(mealType.displayName),
          quantity: \(quantity)\(quantityUnit.displayName),
          createdAt: \(createdAt.formatted(style: .dateTime))
        )
        """
    }
}
