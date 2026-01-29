//
//  FoodRecordServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// FoodRecord 비즈니스 로직을 처리하는 서비스 인터페이스
///
/// 식단 기록 추가/삭제 시 DailyLog를 자동으로 업데이트하는 비즈니스 로직을 포함합니다.
/// Repository 레이어와 달리 Service 레이어는 여러 Repository를 조합하여 복잡한 비즈니스 로직을 처리합니다.
///
/// - Note: 모든 메서드는 Swift Concurrency를 사용하여 비동기로 동작합니다.
/// - Note: Food의 영양소 정보를 기반으로 quantity에 비례하여 실제 섭취량을 계산합니다.
///
/// - Example:
/// ```swift
/// let service: FoodRecordServiceProtocol = FoodRecordService(
///     foodRecordRepository: foodRecordRepository,
///     dailyLogRepository: dailyLogRepository,
///     foodRepository: foodRepository
/// )
/// try await service.addFoodRecord(
///     userId: userId,
///     foodId: foodId,
///     date: Date(),
///     mealType: .breakfast,
///     quantity: Decimal(1.5),
///     quantityUnit: .serving,
///     bmr: 1650,
///     tdee: 2310
/// )
/// ```
protocol FoodRecordServiceProtocol {

    // MARK: - Food Record Operations

    /// 식단 기록을 추가하고 DailyLog를 업데이트합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. Food 정보를 조회하여 영양소 계산
    /// 2. FoodRecord 생성 및 저장
    /// 3. DailyLog 조회 또는 생성
    /// 4. DailyLog 총합 업데이트 (칼로리, 탄수화물, 단백질, 지방)
    /// 5. 매크로 비율 재계산
    /// 6. 순 칼로리 재계산
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - foodId: 음식 ID
    ///   - date: 섭취 날짜
    ///   - mealType: 끼니 종류 (아침, 점심, 저녁, 간식)
    ///   - quantity: 섭취량 (quantityUnit에 따라 인분 또는 그램)
    ///   - quantityUnit: 섭취량 단위
    ///   - bmr: 기초대사량 (DailyLog 생성 시 사용, kcal)
    ///   - tdee: 활동대사량 (DailyLog 생성 시 사용, kcal)
    /// - Returns: 생성된 FoodRecord
    /// - Throws: Food를 찾을 수 없거나 저장 중 에러 발생 시
    func addFoodRecord(
        userId: UUID,
        foodId: UUID,
        date: Date,
        mealType: MealType,
        quantity: Decimal,
        quantityUnit: QuantityUnit,
        bmr: Int32,
        tdee: Int32
    ) async throws -> FoodRecord

    /// 식단 기록을 수정하고 DailyLog를 재계산합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. 기존 FoodRecord 조회
    /// 2. 이전 영양소 값으로 DailyLog 감소
    /// 3. 새로운 영양소 계산
    /// 4. FoodRecord 업데이트
    /// 5. 새로운 영양소 값으로 DailyLog 증가
    /// 6. 매크로 비율 및 순 칼로리 재계산
    ///
    /// - Parameters:
    ///   - foodRecordId: 수정할 FoodRecord ID
    ///   - quantity: 새로운 섭취량
    ///   - quantityUnit: 새로운 섭취량 단위
    ///   - mealType: 새로운 끼니 종류 (옵션)
    /// - Returns: 수정된 FoodRecord
    /// - Throws: FoodRecord를 찾을 수 없거나 업데이트 중 에러 발생 시
    func updateFoodRecord(
        foodRecordId: UUID,
        quantity: Decimal,
        quantityUnit: QuantityUnit,
        mealType: MealType?
    ) async throws -> FoodRecord

    /// 식단 기록을 삭제하고 DailyLog를 업데이트합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. FoodRecord 조회하여 영양소 값 확인
    /// 2. DailyLog 총합에서 해당 영양소 값 차감
    /// 3. 매크로 비율 재계산
    /// 4. 순 칼로리 재계산
    /// 5. FoodRecord 삭제
    ///
    /// - Parameters:
    ///   - foodRecordId: 삭제할 FoodRecord ID
    /// - Throws: FoodRecord를 찾을 수 없거나 삭제 중 에러 발생 시
    func deleteFoodRecord(foodRecordId: UUID) async throws

    // MARK: - Query Operations

    /// 특정 날짜의 모든 식단 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    /// - Returns: 해당 날짜의 식단 기록 목록
    /// - Throws: 조회 중 에러 발생 시
    func getFoodRecords(for date: Date, userId: UUID) async throws -> [FoodRecord]

    /// 특정 날짜와 끼니의 식단 기록을 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - mealType: 끼니 종류
    ///   - userId: 사용자 ID
    /// - Returns: 해당 날짜와 끼니의 식단 기록 목록
    /// - Throws: 조회 중 에러 발생 시
    func getFoodRecords(for date: Date, mealType: MealType, userId: UUID) async throws -> [FoodRecord]

    // MARK: - Gemini AI Food Record

    /// Gemini AI 분석 결과를 식단 기록으로 저장합니다.
    ///
    /// AI가 추정한 영양소 값을 직접 사용하여 Food 엔티티를 생성/조회하고
    /// FoodRecord를 생성한 후 DailyLog를 업데이트합니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - foodName: AI가 인식한 음식 이름
    ///   - date: 섭취 날짜
    ///   - mealType: 끼니 종류
    ///   - estimatedGrams: AI 추정 중량 (g)
    ///   - calories: AI 추정 칼로리 (kcal)
    ///   - carbohydrates: AI 추정 탄수화물 (g)
    ///   - protein: AI 추정 단백질 (g)
    ///   - fat: AI 추정 지방 (g)
    ///   - bmr: 기초대사량 (kcal)
    ///   - tdee: 활동대사량 (kcal)
    /// - Returns: 생성된 FoodRecord
    func addFoodRecordFromGemini(
        userId: UUID,
        foodName: String,
        date: Date,
        mealType: MealType,
        estimatedGrams: Double,
        calories: Double,
        carbohydrates: Double,
        protein: Double,
        fat: Double,
        bmr: Int32,
        tdee: Int32
    ) async throws -> FoodRecord
}
