//
//  DailyLog.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 일일 집계 도메인 엔티티
///
/// 사용자의 하루 동안의 식단, 운동, 체성분, 수면 등 모든 데이터를 집계합니다.
/// 각 날짜별로 고유한 레코드가 생성되며, 관련 이벤트 발생 시 자동으로 업데이트됩니다.
///
/// - Note: 섭취 데이터는 FoodRecord 추가/삭제 시 자동으로 업데이트됩니다.
/// - Note: 운동 데이터는 ExerciseRecord 추가/삭제 시 자동으로 업데이트됩니다.
/// - Note: 체성분 데이터는 해당일 BodyRecord 입력 시 자동으로 업데이트됩니다.
/// - Note: 수면 데이터는 SleepRecord 입력 시 자동으로 업데이트됩니다.
/// - Note: bmr, tdee는 DailyLog 생성 시 User.current* 값에서 복사됩니다.
///
/// - Example:
/// ```swift
/// let dailyLog = DailyLog(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     totalCaloriesIn: 2100,
///     totalCarbs: Decimal(260.5),
///     totalProtein: Decimal(105.2),
///     totalFat: Decimal(58.3),
///     carbsRatio: Decimal(49.6),
///     proteinRatio: Decimal(20.0),
///     fatRatio: Decimal(25.0),
///     bmr: 1650,
///     tdee: 2310,
///     netCalories: -210,
///     totalCaloriesOut: 450,
///     exerciseMinutes: 60,
///     exerciseCount: 2,
///     steps: 8500,
///     weight: Decimal(70.5),
///     bodyFatPct: Decimal(21.5),
///     sleepDuration: 420,
///     sleepStatus: .good,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// ```
struct DailyLog {
    // MARK: - Primary Key

    /// 고유 식별자
    let id: UUID

    // MARK: - Foreign Key

    /// User 참조
    let userId: UUID

    // MARK: - Date

    /// 날짜 (UNIQUE per user)
    ///
    /// 사용자별로 하루에 하나의 DailyLog만 존재합니다.
    var date: Date

    // MARK: - 섭취 (Calorie Intake)

    /// 총 섭취 칼로리 (kcal)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var totalCaloriesIn: Int32

    /// 총 탄수화물 (g)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var totalCarbs: Decimal

    /// 총 단백질 (g)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var totalProtein: Decimal

    /// 총 지방 (g)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var totalFat: Decimal

    /// 탄수화물 비율 (%)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 재계산됩니다.
    /// 섭취한 음식이 없는 경우 nil입니다.
    var carbsRatio: Decimal?

    /// 단백질 비율 (%)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 재계산됩니다.
    /// 섭취한 음식이 없는 경우 nil입니다.
    var proteinRatio: Decimal?

    /// 지방 비율 (%)
    ///
    /// FoodRecord 추가/삭제 시 자동으로 재계산됩니다.
    /// 섭취한 음식이 없는 경우 nil입니다.
    var fatRatio: Decimal?

    // MARK: - 대사량 스냅샷 (Metabolism Snapshot)

    /// 해당일 BMR (기초대사량, kcal)
    ///
    /// DailyLog 생성 시 User.currentBMR 또는 해당일 이전 MetabolismSnapshot에서 복사됩니다.
    /// 해당일 체성분 입력 시 업데이트될 수 있습니다.
    var bmr: Int32

    /// 해당일 TDEE (활동대사량, kcal)
    ///
    /// DailyLog 생성 시 User.currentTDEE 또는 해당일 이전 MetabolismSnapshot에서 복사됩니다.
    /// 해당일 체성분 입력 시 업데이트될 수 있습니다.
    var tdee: Int32

    /// 순 칼로리 (섭취 - TDEE, kcal)
    ///
    /// totalCaloriesIn - tdee 로 계산됩니다.
    /// FoodRecord 추가/삭제 시 자동으로 재계산됩니다.
    var netCalories: Int32

    // MARK: - 소모 & 운동 (Exercise & Activity)

    /// 운동 소모 칼로리 (kcal)
    ///
    /// ExerciseRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var totalCaloriesOut: Int32

    /// 총 운동 시간 (분)
    ///
    /// ExerciseRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var exerciseMinutes: Int32

    /// 운동 횟수
    ///
    /// ExerciseRecord 추가/삭제 시 자동으로 업데이트됩니다.
    var exerciseCount: Int16

    /// 걸음 수 (HealthKit)
    ///
    /// HealthKit 동기화 시 업데이트됩니다.
    /// 동기화되지 않았거나 데이터가 없으면 nil입니다.
    var steps: Int32?

    // MARK: - 체성분 스냅샷 (Body Composition Snapshot)

    /// 해당일 체중 (kg)
    ///
    /// 해당일 BodyRecord 입력 시 자동으로 업데이트됩니다.
    /// 체성분 기록이 없으면 nil입니다.
    var weight: Decimal?

    /// 해당일 체지방률 (%)
    ///
    /// 해당일 BodyRecord 입력 시 자동으로 업데이트됩니다.
    /// 체성분 기록이 없거나 체지방률을 측정하지 않았으면 nil입니다.
    var bodyFatPct: Decimal?

    // MARK: - 수면 (Sleep)

    /// 수면 시간 (분)
    ///
    /// SleepRecord 입력 시 자동으로 업데이트됩니다.
    /// 수면 기록이 없으면 nil입니다.
    var sleepDuration: Int32?

    /// 수면 상태 (0: Bad, 1: Soso, 2: Good, 3: Excellent, 4: Oversleep)
    ///
    /// SleepRecord 입력 시 자동으로 업데이트됩니다.
    /// 수면 기록이 없으면 nil입니다.
    var sleepStatus: SleepStatus?

    // MARK: - Metadata

    /// 생성일시
    let createdAt: Date

    /// 수정일시
    var updatedAt: Date
}

// MARK: - Identifiable

extension DailyLog: Identifiable {}

// MARK: - Equatable

extension DailyLog: Equatable {
    static func == (lhs: DailyLog, rhs: DailyLog) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable

extension DailyLog: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
