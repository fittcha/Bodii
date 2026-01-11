//
//  DailyLog.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Daily Aggregation Pattern
// DailyLog는 여러 Record 엔티티들의 데이터를 날짜별로 집계하여 대시보드 표시용으로 최적화
// 💡 Java 비교: JPA의 @Formula나 View Entity와 유사하지만 실제 저장되는 엔티티

import Foundation

// MARK: - DailyLog

/// 일일 종합 로그 도메인 엔티티
/// - 하루 동안의 식사, 운동, 수면, 신체 데이터를 종합하여 대시보드에 표시
/// - FoodRecord, ExerciseRecord, SleepRecord, BodyRecord의 집계 데이터
/// - 날짜별로 하나의 DailyLog 생성 (unique date)
///
/// ## 주요 기능
/// - 일일 영양 섭취 합계 (칼로리, 탄수화물, 단백질, 지방)
/// - 일일 운동 소모 칼로리 및 시간 합계
/// - 일일 수면 시간 및 상태
/// - 당일 신체 데이터 (체중, 체지방률)
/// - 대사 정보 (BMR, TDEE) 및 순 칼로리 계산
///
/// ## 데이터 집계 관계
/// ```
/// DailyLog (1) ← (N) FoodRecord: 일일 영양 섭취 합계
/// DailyLog (1) ← (N) ExerciseRecord: 일일 운동 소모 합계
/// DailyLog (1) ← (N) SleepRecord: 일일 수면 합계
/// DailyLog (1) ← (1) BodyRecord: 당일 신체 데이터 (선택적)
/// DailyLog (1) ← (1) MetabolismSnapshot: 당일 대사 정보 (선택적)
/// ```
///
/// ## 계산 공식
/// ```
/// 순 칼로리(netCalories) = 섭취 칼로리 - 소모 칼로리 - TDEE
/// 탄수화물 비율 = (totalCarbs × 4) / totalCaloriesIn × 100
/// 단백질 비율 = (totalProtein × 4) / totalCaloriesIn × 100
/// 지방 비율 = (totalFat × 9) / totalCaloriesIn × 100
/// ```
///
/// ## 사용 예시
/// ```swift
/// // 1. 빈 DailyLog 생성 (데이터 없는 날)
/// let emptyLog = DailyLog.empty(userId: userId, date: Date())
///
/// // 2. FoodRecord 집계 후 DailyLog 업데이트
/// let updatedLog = emptyLog.withNutrition(
///     totalCaloriesIn: 2000,
///     totalCarbs: 250.0,
///     totalProtein: 120.0,
///     totalFat: 60.0
/// )
///
/// // 3. 순 칼로리 확인
/// print(updatedLog.netCalories) // 섭취 - 소모 - TDEE
/// ```
struct DailyLog: Identifiable, Codable, Equatable {

    // MARK: - Properties

    // MARK: Identifier

    /// 일일 로그 고유 식별자
    /// - UUID 타입으로 전역 고유성 보장
    let id: UUID

    /// 사용자 고유 식별자
    /// - User 엔티티와의 외래 키 관계
    let userId: UUID

    /// 로그 날짜
    /// - 02:00 sleep boundary 로직 적용 (논리적 날짜)
    /// - 하루에 하나의 DailyLog만 존재 (unique constraint)
    /// - 모든 Record의 집계 기준 날짜
    let date: Date

    // MARK: Intake Section (섭취)

    /// 일일 총 섭취 칼로리 (kcal)
    /// - 모든 FoodRecord의 계산된 칼로리 합계
    /// - 기본값: 0 (섭취 기록이 없는 경우)
    var totalCaloriesIn: Int

    /// 일일 총 섭취 탄수화물 (g)
    /// - 모든 FoodRecord의 계산된 탄수화물 합계
    /// - 기본값: 0.0
    var totalCarbs: Decimal

    /// 일일 총 섭취 단백질 (g)
    /// - 모든 FoodRecord의 계산된 단백질 합계
    /// - 기본값: 0.0
    var totalProtein: Decimal

    /// 일일 총 섭취 지방 (g)
    /// - 모든 FoodRecord의 계산된 지방 합계
    /// - 기본값: 0.0
    var totalFat: Decimal

    // MARK: Metabolism Section (대사)

    /// 기초대사량 (kcal/day)
    /// - 당일 MetabolismSnapshot의 bmr 값
    /// - 없으면 User의 currentBMR 사용
    /// - 기본값: 0 (데이터 없음)
    var bmr: Int

    /// 일일 총 에너지 소비량 (kcal/day)
    /// - 당일 MetabolismSnapshot의 tdee 값
    /// - 없으면 User의 currentTDEE 사용
    /// - 기본값: 0 (데이터 없음)
    var tdee: Int

    // MARK: Exercise Section (운동)

    /// 일일 총 소모 칼로리 (kcal)
    /// - 모든 ExerciseRecord의 caloriesBurned 합계
    /// - 기본값: 0 (운동 기록이 없는 경우)
    var totalCaloriesOut: Int

    /// 일일 총 운동 시간 (분)
    /// - 모든 ExerciseRecord의 duration 합계
    /// - 기본값: 0
    var exerciseMinutes: Int

    /// 일일 운동 횟수
    /// - ExerciseRecord의 개수
    /// - 기본값: 0
    var exerciseCount: Int

    /// 일일 걸음 수 (선택 사항)
    /// - HealthKit 연동 시 자동 기록
    /// - 기본값: nil (데이터 없음)
    var steps: Int?

    // MARK: Body Section (신체)

    /// 당일 체중 (kg)
    /// - 당일 BodyRecord의 weight 값
    /// - 기본값: nil (체중 측정 안함)
    var weight: Decimal?

    /// 당일 체지방률 (%)
    /// - 당일 BodyRecord의 bodyFatPercent 값
    /// - 기본값: nil (체지방 측정 안함)
    var bodyFatPct: Decimal?

    // MARK: Sleep Section (수면)

    /// 일일 총 수면 시간 (분)
    /// - 모든 SleepRecord의 duration 합계
    /// - 기본값: nil (수면 기록 없음)
    var sleepDuration: Int?

    /// 수면 상태
    /// - 당일 주요 SleepRecord의 status
    /// - 여러 수면 기록이 있으면 가장 긴 수면의 status 사용
    /// - 기본값: nil (수면 기록 없음)
    var sleepStatus: SleepStatus?

    // MARK: Timestamps

    /// 생성 시각
    /// - DailyLog가 처음 생성된 시각
    let createdAt: Date

    /// 수정 시각
    /// - DailyLog가 마지막으로 업데이트된 시각
    var updatedAt: Date

    // MARK: - Computed Properties

    /// 순 칼로리 (kcal)
    /// - 계산 공식: 섭취 칼로리 - 소모 칼로리 - TDEE
    /// - 양수: 칼로리 잉여 (체중 증가 경향)
    /// - 음수: 칼로리 부족 (체중 감소 경향)
    ///
    /// ## 예시
    /// ```swift
    /// // 섭취 2000kcal, 소모 300kcal, TDEE 1800kcal
    /// // netCalories = 2000 - 300 - 1800 = -100kcal (적자)
    /// ```
    var netCalories: Int {
        return totalCaloriesIn - totalCaloriesOut - tdee
    }

    /// 탄수화물 비율 (%)
    /// - 계산 공식: (탄수화물g × 4kcal/g) / 총 섭취 칼로리 × 100
    /// - 기본값: 0.0 (섭취 기록 없음)
    ///
    /// ## 예시
    /// ```swift
    /// // 탄수화물 250g, 총 칼로리 2000kcal
    /// // carbsRatio = (250 × 4) / 2000 × 100 = 50.0%
    /// ```
    var carbsRatio: Decimal {
        guard totalCaloriesIn > 0 else { return 0.0 }
        let carbsCalories = totalCarbs * 4 // 탄수화물 1g = 4kcal
        return (carbsCalories / Decimal(totalCaloriesIn) * 100).rounded(scale: 1)
    }

    /// 단백질 비율 (%)
    /// - 계산 공식: (단백질g × 4kcal/g) / 총 섭취 칼로리 × 100
    /// - 기본값: 0.0 (섭취 기록 없음)
    ///
    /// ## 예시
    /// ```swift
    /// // 단백질 120g, 총 칼로리 2000kcal
    /// // proteinRatio = (120 × 4) / 2000 × 100 = 24.0%
    /// ```
    var proteinRatio: Decimal {
        guard totalCaloriesIn > 0 else { return 0.0 }
        let proteinCalories = totalProtein * 4 // 단백질 1g = 4kcal
        return (proteinCalories / Decimal(totalCaloriesIn) * 100).rounded(scale: 1)
    }

    /// 지방 비율 (%)
    /// - 계산 공식: (지방g × 9kcal/g) / 총 섭취 칼로리 × 100
    /// - 기본값: 0.0 (섭취 기록 없음)
    ///
    /// ## 예시
    /// ```swift
    /// // 지방 60g, 총 칼로리 2000kcal
    /// // fatRatio = (60 × 9) / 2000 × 100 = 27.0%
    /// ```
    var fatRatio: Decimal {
        guard totalCaloriesIn > 0 else { return 0.0 }
        let fatCalories = totalFat * 9 // 지방 1g = 9kcal
        return (fatCalories / Decimal(totalCaloriesIn) * 100).rounded(scale: 1)
    }

    // MARK: - Factory Methods

    /// 빈 DailyLog 생성 (초기 상태)
    /// - Parameters:
    ///   - userId: 사용자 고유 식별자
    ///   - date: 로그 날짜
    /// - Returns: 모든 집계 값이 0 또는 nil인 DailyLog
    ///
    /// ## 사용 시나리오
    /// 새로운 날짜에 첫 Record가 생성될 때 빈 DailyLog 생성 후 업데이트
    ///
    /// ## 예시
    /// ```swift
    /// let emptyLog = DailyLog.empty(userId: userId, date: Date())
    /// // totalCaloriesIn = 0, totalCaloriesOut = 0, weight = nil, etc.
    /// ```
    static func empty(userId: UUID, date: Date) -> DailyLog {
        let now = Date()
        return DailyLog(
            id: UUID(),
            userId: userId,
            date: date,
            totalCaloriesIn: 0,
            totalCarbs: 0.0,
            totalProtein: 0.0,
            totalFat: 0.0,
            bmr: 0,
            tdee: 0,
            totalCaloriesOut: 0,
            exerciseMinutes: 0,
            exerciseCount: 0,
            steps: nil,
            weight: nil,
            bodyFatPct: nil,
            sleepDuration: nil,
            sleepStatus: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Update Methods

    /// 영양 섭취 데이터 업데이트
    /// - Parameters:
    ///   - totalCaloriesIn: 총 섭취 칼로리
    ///   - totalCarbs: 총 섭취 탄수화물
    ///   - totalProtein: 총 섭취 단백질
    ///   - totalFat: 총 섭취 지방
    /// - Returns: 영양 데이터가 업데이트된 DailyLog
    ///
    /// ## 사용 시나리오
    /// FoodRecord가 추가/수정/삭제될 때 DailyLog의 영양 합계 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let updatedLog = dailyLog.withNutrition(
    ///     totalCaloriesIn: 2000,
    ///     totalCarbs: 250.0,
    ///     totalProtein: 120.0,
    ///     totalFat: 60.0
    /// )
    /// ```
    func withNutrition(
        totalCaloriesIn: Int,
        totalCarbs: Decimal,
        totalProtein: Decimal,
        totalFat: Decimal
    ) -> DailyLog {
        DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            bmr: bmr,
            tdee: tdee,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 운동 데이터 업데이트
    /// - Parameters:
    ///   - totalCaloriesOut: 총 소모 칼로리
    ///   - exerciseMinutes: 총 운동 시간
    ///   - exerciseCount: 운동 횟수
    ///   - steps: 걸음 수 (선택 사항)
    /// - Returns: 운동 데이터가 업데이트된 DailyLog
    ///
    /// ## 사용 시나리오
    /// ExerciseRecord가 추가/수정/삭제될 때 DailyLog의 운동 합계 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let updatedLog = dailyLog.withExercise(
    ///     totalCaloriesOut: 300,
    ///     exerciseMinutes: 60,
    ///     exerciseCount: 2,
    ///     steps: 10000
    /// )
    /// ```
    func withExercise(
        totalCaloriesOut: Int,
        exerciseMinutes: Int,
        exerciseCount: Int,
        steps: Int? = nil
    ) -> DailyLog {
        DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            bmr: bmr,
            tdee: tdee,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 대사 데이터 업데이트
    /// - Parameters:
    ///   - bmr: 기초대사량
    ///   - tdee: 일일 총 에너지 소비량
    /// - Returns: 대사 데이터가 업데이트된 DailyLog
    ///
    /// ## 사용 시나리오
    /// MetabolismSnapshot이 생성될 때 DailyLog에 BMR/TDEE 반영
    ///
    /// ## 예시
    /// ```swift
    /// let updatedLog = dailyLog.withMetabolism(bmr: 1650, tdee: 2550)
    /// ```
    func withMetabolism(bmr: Int, tdee: Int) -> DailyLog {
        DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            bmr: bmr,
            tdee: tdee,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 신체 데이터 업데이트
    /// - Parameters:
    ///   - weight: 체중
    ///   - bodyFatPct: 체지방률
    /// - Returns: 신체 데이터가 업데이트된 DailyLog
    ///
    /// ## 사용 시나리오
    /// BodyRecord가 생성/수정될 때 DailyLog에 당일 체중/체지방 반영
    ///
    /// ## 예시
    /// ```swift
    /// let updatedLog = dailyLog.withBody(weight: 70.0, bodyFatPct: 18.5)
    /// ```
    func withBody(weight: Decimal?, bodyFatPct: Decimal?) -> DailyLog {
        DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            bmr: bmr,
            tdee: tdee,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// 수면 데이터 업데이트
    /// - Parameters:
    ///   - sleepDuration: 총 수면 시간 (분)
    ///   - sleepStatus: 수면 상태
    /// - Returns: 수면 데이터가 업데이트된 DailyLog
    ///
    /// ## 사용 시나리오
    /// SleepRecord가 추가/수정/삭제될 때 DailyLog의 수면 합계 재계산
    ///
    /// ## 예시
    /// ```swift
    /// let updatedLog = dailyLog.withSleep(sleepDuration: 420, sleepStatus: .good)
    /// ```
    func withSleep(sleepDuration: Int?, sleepStatus: SleepStatus?) -> DailyLog {
        DailyLog(
            id: id,
            userId: userId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            bmr: bmr,
            tdee: tdee,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: steps,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - DailyLog + CustomStringConvertible

extension DailyLog: CustomStringConvertible {
    /// 디버깅용 문자열 표현
    var description: String {
        let weightText = weight.map { "\($0)kg" } ?? "미측정"
        let bodyFatText = bodyFatPct.map { "\($0)%" } ?? "미측정"
        let sleepText = sleepDuration.map { "\($0)분" } ?? "기록 없음"
        let sleepStatusText = sleepStatus?.displayName ?? "-"
        let stepsText = steps.map { "\($0)걸음" } ?? "기록 없음"

        return """
        DailyLog(
          id: \(id.uuidString.prefix(8))...,
          userId: \(userId.uuidString.prefix(8))...,
          date: \(date.formatted(style: .short)),
          영양 섭취: 칼로리 \(totalCaloriesIn)kcal, 탄수화물 \(totalCarbs)g (\(carbsRatio)%), 단백질 \(totalProtein)g (\(proteinRatio)%), 지방 \(totalFat)g (\(fatRatio)%),
          대사: BMR \(bmr)kcal, TDEE \(tdee)kcal, 순 칼로리 \(netCalories)kcal,
          운동: 소모 \(totalCaloriesOut)kcal, 시간 \(exerciseMinutes)분, 횟수 \(exerciseCount)회, 걸음 \(stepsText),
          신체: 체중 \(weightText), 체지방 \(bodyFatText),
          수면: \(sleepText) (\(sleepStatusText)),
          updatedAt: \(updatedAt.formatted(style: .dateTime))
        )
        """
    }
}
