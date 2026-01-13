//
//  ExerciseType.swift
//  Bodii
//
//  Created by Auto-Claude on 2024-01-12.
//

import Foundation

/// 운동 종류 열거형
///
/// 운동 기록 시 운동의 종류를 나타냅니다.
/// Core Data 호환성을 위해 Int16 rawValue를 사용합니다.
///
/// - Cases:
///   - walking: 걷기
///   - running: 러닝
///   - cycling: 자전거
///   - swimming: 수영
///   - weight: 웨이트
///   - crossfit: 크로스핏
///   - yoga: 요가
///   - other: 기타
///
/// - Example:
/// ```swift
/// let exercise = ExerciseType.running
/// print(exercise.displayName) // "러닝"
/// print(exercise.baseMET) // 8.0
/// print(exercise.metValue(for: 2)) // 9.6 (고강도)
/// ```
enum ExerciseType: Int16, CaseIterable, Codable {
    case walking = 0
    case running = 1
    case cycling = 2
    case swimming = 3
    case weight = 4
    case crossfit = 5
    case yoga = 6
    case other = 7

    /// 사용자에게 표시할 운동 종류 이름
    var displayName: String {
        switch self {
        case .walking: return "걷기"
        case .running: return "러닝"
        case .cycling: return "자전거"
        case .swimming: return "수영"
        case .weight: return "웨이트"
        case .crossfit: return "크로스핏"
        case .yoga: return "요가"
        case .other: return "기타"
        }
    }

    /// 운동 종류별 SF Symbol 아이콘 이름
    ///
    /// 각 운동 종류에 대응하는 SF Symbol 아이콘의 이름을 반환합니다.
    ///
    /// - Returns: SF Symbol 아이콘 이름 (String)
    var iconName: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .weight: return "dumbbell.fill"
        case .crossfit: return "figure.cross.training"
        case .yoga: return "figure.yoga"
        case .other: return "figure.mixed.cardio"
        }
    }

    /// 기본 MET 값 (중강도 기준)
    ///
    /// MET (Metabolic Equivalent of Task): 안정 시 산소 소비량 대비 활동 시 산소 소비량의 비율
    /// 1 MET = 약 1 kcal/kg/hour
    ///
    /// - Returns: 중강도 기준 MET 값
    var baseMET: Double {
        switch self {
        case .walking: return 3.5
        case .running: return 8.0
        case .cycling: return 6.0
        case .swimming: return 7.0
        case .weight: return 6.0
        case .crossfit: return 8.0
        case .yoga: return 3.0
        case .other: return 5.0
        }
    }

    /// 강도별 MET 값 조회
    ///
    /// 강도 보정 계수:
    /// - 저강도: 기본 MET × 0.8
    /// - 중강도: 기본 MET × 1.0
    /// - 고강도: 기본 MET × 1.2
    ///
    /// - Parameter intensity: 운동 강도 (0: 저강도, 1: 중강도, 2: 고강도)
    /// - Returns: 강도에 따른 MET 값
    func metValue(for intensity: Int16) -> Double {
        let multiplier: Double
        switch intensity {
        case 0: multiplier = 0.8  // 저강도
        case 2: multiplier = 1.2  // 고강도
        default: multiplier = 1.0  // 중강도
        }
        return baseMET * multiplier
    }
}

// MARK: - Identifiable

extension ExerciseType: Identifiable {
    var id: Int16 { rawValue }
}
