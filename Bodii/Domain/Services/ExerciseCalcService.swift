//
//  ExerciseCalcService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 운동 칼로리 계산 서비스
///
/// MET (Metabolic Equivalent of Task) 기반으로 운동 시 소모되는 칼로리를 계산합니다.
///
/// ## MET 계산 공식
/// ```
/// 소모 칼로리 = MET × 체중(kg) × 시간(hour) × 성별보정계수
/// ```
///
/// ## MET 값 결정
/// ```
/// MET = 운동 종류의 기본 MET × 강도 보정 계수
/// ```
///
/// ## 강도 보정 계수
/// - 저강도: 기본 MET × 0.8
/// - 중강도: 기본 MET × 1.0
/// - 고강도: 기본 MET × 1.2
///
/// ## 성별 보정 계수
/// - 남성: × 1.0
/// - 여성: × 0.9 (ACSM 가이드라인 기반)
///
/// - Example:
/// ```swift
/// // 크로스핏 45분, 고강도, 체중 75kg, 남성
/// let calories = ExerciseCalcService.calculateCalories(
///     exerciseType: .crossfit,
///     duration: 45,
///     intensity: .high,
///     weight: 75.0,
///     gender: .male
/// )
/// // 결과: 540 kcal
/// // 계산: 8.0 × 1.2 = 9.6 MET
/// //       9.6 × 75 × 0.75 × 1.0 = 540
/// ```
enum ExerciseCalcService {

    // MARK: - Public Methods

    /// 운동으로 소모된 칼로리를 계산합니다. (성별 고려)
    ///
    /// MET 공식을 사용하여 칼로리를 계산합니다:
    /// ```
    /// 칼로리 = MET × 체중(kg) × 시간(hours) × 성별보정계수
    /// ```
    ///
    /// MET 값은 운동 종류의 기본 MET에 강도 보정 계수를 곱하여 결정됩니다.
    /// 성별에 따라 추가 보정이 적용됩니다 (여성은 약 10% 적은 칼로리 소모).
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류 (걷기, 러닝, 자전거 등)
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도 (저강도, 중강도, 고강도)
    ///   - weight: 사용자 체중 (kg)
    ///   - gender: 사용자 성별 (남성/여성)
    ///
    /// - Returns: 소모된 칼로리 (kcal), Int32로 반올림된 값
    ///
    /// - Example:
    /// ```swift
    /// // 러닝 30분, 중강도, 체중 70kg, 남성
    /// let calories = ExerciseCalcService.calculateCalories(
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .medium,
    ///     weight: 70.0,
    ///     gender: .male
    /// )
    /// // 결과: 280 kcal
    /// // 계산: 8.0 × 1.0 = 8.0 MET
    /// //       8.0 × 70 × 0.5 × 1.0 = 280
    ///
    /// // 동일 조건, 여성
    /// let caloriesFemale = ExerciseCalcService.calculateCalories(
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .medium,
    ///     weight: 70.0,
    ///     gender: .female
    /// )
    /// // 결과: 252 kcal (280 × 0.9)
    /// ```
    static func calculateCalories(
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        weight: Double,
        gender: Gender
    ) -> Int32 {
        // 1. 기본 MET 값 가져오기
        let baseMET = exerciseType.baseMET

        // 2. 강도 보정 계수 적용
        let adjustedMET = baseMET * intensity.metMultiplier

        // 3. 시간을 분에서 시간으로 변환
        let hours = Double(duration) / 60.0

        // 4. 성별 보정 계수 가져오기
        let genderMultiplier = gender.exerciseCalorieMultiplier

        // 5. MET 공식 적용: 칼로리 = MET × 체중(kg) × 시간(hour) × 성별보정계수
        let calories = adjustedMET * weight * hours * genderMultiplier

        // 6. Int32로 반올림하여 반환
        return Int32(calories.rounded())
    }

    /// 운동으로 소모된 칼로리를 계산합니다. (Decimal 타입 체중, 성별 고려)
    ///
    /// Decimal 타입의 체중을 받아서 칼로리를 계산하는 편의 메서드입니다.
    /// User 엔티티의 currentWeight가 Decimal 타입이므로 직접 전달할 수 있습니다.
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류 (걷기, 러닝, 자전거 등)
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도 (저강도, 중강도, 고강도)
    ///   - weight: 사용자 체중 (kg), Decimal 타입
    ///   - gender: 사용자 성별 (남성/여성)
    ///
    /// - Returns: 소모된 칼로리 (kcal), Int32로 반올림된 값
    ///
    /// - Example:
    /// ```swift
    /// let user = User(...)
    /// let calories = ExerciseCalcService.calculateCalories(
    ///     exerciseType: .walking,
    ///     duration: 60,
    ///     intensity: .low,
    ///     weight: user.currentWeight ?? 70.0,
    ///     gender: Gender(rawValue: user.gender) ?? .male
    /// )
    /// ```
    static func calculateCalories(
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        weight: Decimal,
        gender: Gender
    ) -> Int32 {
        // Decimal을 Double로 변환하여 기본 메서드 호출
        let weightDouble = NSDecimalNumber(decimal: weight).doubleValue
        return calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weightDouble,
            gender: gender
        )
    }

    // MARK: - Legacy Methods (Backward Compatibility)

    /// 운동으로 소모된 칼로리를 계산합니다. (성별 미고려, 기본값: 남성)
    ///
    /// - Note: 이 메서드는 하위 호환성을 위해 유지됩니다.
    ///         새로운 코드에서는 `calculateCalories(exerciseType:duration:intensity:weight:gender:)`를 사용하세요.
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - weight: 사용자 체중 (kg)
    ///
    /// - Returns: 소모된 칼로리 (kcal)
    static func calculateCalories(
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        weight: Double
    ) -> Int32 {
        // 기본값으로 남성 사용
        return calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weight,
            gender: .male
        )
    }

    /// 운동으로 소모된 칼로리를 계산합니다. (Decimal 타입, 성별 미고려)
    ///
    /// - Note: 이 메서드는 하위 호환성을 위해 유지됩니다.
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류
    ///   - duration: 운동 시간 (분)
    ///   - intensity: 운동 강도
    ///   - weight: 사용자 체중 (kg), Decimal 타입
    ///
    /// - Returns: 소모된 칼로리 (kcal)
    static func calculateCalories(
        exerciseType: ExerciseType,
        duration: Int32,
        intensity: Intensity,
        weight: Decimal
    ) -> Int32 {
        let weightDouble = NSDecimalNumber(decimal: weight).doubleValue
        return calculateCalories(
            exerciseType: exerciseType,
            duration: duration,
            intensity: intensity,
            weight: weightDouble,
            gender: .male
        )
    }
}
