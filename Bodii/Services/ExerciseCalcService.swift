//
//  ExerciseCalcService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 운동 칼로리 계산 서비스
///
/// MET (Metabolic Equivalent of Task) 값을 기반으로 운동 시 소모된 칼로리를 계산합니다.
///
/// **공식**: 소모 칼로리 = MET × 체중(kg) × 시간(hours)
///
/// **MET 값**:
/// - 운동 종류별 기본 MET 값 (ExerciseType.baseMET)
/// - 강도 보정 계수 적용 (Intensity.metMultiplier)
///   - 저강도: 기본 MET × 0.8
///   - 중강도: 기본 MET × 1.0
///   - 고강도: 기본 MET × 1.2
///
/// - Example:
/// ```swift
/// // 크로스핏 45분, 고강도, 체중 75kg
/// let calories = ExerciseCalcService.calculateCaloriesBurned(
///     exerciseType: .crossfit,
///     duration: 45,
///     intensity: .high,
///     weight: 75.0
/// )
/// // Returns: 540 kcal
/// // 계산 과정:
/// // - 기본 MET: 8.0
/// // - 강도 보정: 8.0 × 1.2 = 9.6
/// // - 시간: 45분 = 0.75시간
/// // - 칼로리: 9.6 × 75 × 0.75 = 540 kcal
/// ```
enum ExerciseCalcService {

    // MARK: - Calorie Calculation

    /// 운동 칼로리 소모량 계산
    ///
    /// MET 기반 공식을 사용하여 운동 중 소모된 칼로리를 계산합니다.
    ///
    /// **공식**: 소모 칼로리 = MET × 체중(kg) × 시간(hours)
    ///
    /// **처리 과정**:
    /// 1. ExerciseType에서 기본 MET 값 가져오기
    /// 2. Intensity에 따른 강도 보정 계수 적용
    /// 3. Duration을 분에서 시간으로 변환
    /// 4. MET × weight × hours 계산
    /// 5. 결과를 반올림하여 Int32로 반환
    ///
    /// **Edge Cases**:
    /// - duration이 0이면 0 반환
    /// - weight가 0 이하면 0 반환
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류 (ExerciseType enum)
    ///   - duration: 운동 시간 (분 단위, Int32)
    ///   - intensity: 운동 강도 (Intensity enum)
    ///   - weight: 사용자 체중 (kg, Double)
    /// - Returns: 소모된 칼로리 (kcal, Int32, 반올림)
    ///
    /// - Example:
    /// ```swift
    /// // 러닝 30분, 중강도, 70kg
    /// let calories1 = ExerciseCalcService.calculateCaloriesBurned(
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .medium,
    ///     weight: 70.0
    /// )
    /// // Returns: 280 kcal (8.0 × 70 × 0.5 = 280)
    ///
    /// // 요가 60분, 저강도, 55kg
    /// let calories2 = ExerciseCalcService.calculateCaloriesBurned(
    ///     exerciseType: .yoga,
    ///     duration: 60,
    ///     intensity: .low,
    ///     weight: 55.0
    /// )
    /// // Returns: 132 kcal (3.0 × 0.8 × 55 × 1.0 = 132)
    ///
    /// // Edge case: 0분 운동
    /// let calories3 = ExerciseCalcService.calculateCaloriesBurned(
    ///     exerciseType: .walking,
    ///     duration: 0,
    ///     intensity: .medium,
    ///     weight: 65.0
    /// )
    /// // Returns: 0 kcal
    /// ```
    static func calculateCaloriesBurned(
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        weight: Double
    ) -> Int32 {
        // Edge case: duration이 0이면 0 반환
        guard duration > 0 else {
            return 0
        }

        // Edge case: weight가 0 이하면 0 반환
        guard weight > 0 else {
            return 0
        }

        // 1. 운동 종류의 기본 MET 값 가져오기
        let baseMET = exerciseType.baseMET

        // 2. 강도 보정 계수 적용
        let intensityMultiplier = intensity.metMultiplier
        let adjustedMET = baseMET * intensityMultiplier

        // 3. Duration을 분에서 시간으로 변환
        let hours = Double(duration) / 60.0

        // 4. MET 공식 적용: 칼로리 = MET × 체중(kg) × 시간(hours)
        let calories = adjustedMET * weight * hours

        // 5. 결과를 반올림하여 Int32로 반환
        return Int32(calories.rounded())
    }
}
