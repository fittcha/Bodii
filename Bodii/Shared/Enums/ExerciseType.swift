//
//  ExerciseType.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Enum with MET Values
// Swift enum에서 운동 유형별 MET 값(대사당량)을 제공하여 칼로리 소모 계산
// 💡 Java 비교: enum에 메서드를 추가하여 동적 값 반환하는 것과 유사

import Foundation

// MARK: - ExerciseType

/// 운동 유형
/// - Core Data의 ExerciseRecord 엔티티에서 Int16으로 저장
/// - MET(Metabolic Equivalent of Task) 값을 통해 칼로리 소모량 계산
enum ExerciseType: Int16, CaseIterable, Codable {

    // MARK: - Cases

    /// 걷기 (0)
    case walking = 0

    /// 달리기 (1)
    case running = 1

    /// 자전거 (2)
    case cycling = 2

    /// 수영 (3)
    case swimming = 3

    /// 웨이트 트레이닝 (4)
    case weight = 4

    /// 크로스핏 (5)
    case crossfit = 5

    /// 요가 (6)
    case yoga = 6

    /// 기타 (7)
    case other = 7

    // MARK: - Display Name

    /// 한국어 표시 이름
    /// - 사용자 인터페이스에 표시되는 텍스트
    var displayName: String {
        switch self {
        case .walking:
            return "걷기"
        case .running:
            return "달리기"
        case .cycling:
            return "자전거"
        case .swimming:
            return "수영"
        case .weight:
            return "웨이트 트레이닝"
        case .crossfit:
            return "크로스핏"
        case .yoga:
            return "요가"
        case .other:
            return "기타"
        }
    }

    // MARK: - MET Values

    /// 운동 강도에 따른 MET 값 반환
    /// - Parameter intensity: 운동 강도 (0: 낮음, 1: 보통, 2: 높음)
    /// - Returns: 해당 운동의 MET 값 (Metabolic Equivalent of Task)
    /// - Note: MET 값은 칼로리 소모량 계산에 사용됨
    ///   칼로리 = MET × 체중(kg) × 시간(hour)
    func metValue(for intensity: Int16) -> Double {
        switch self {
        case .walking:
            switch intensity {
            case 0: return 3.5  // 낮은 강도 (느린 걷기)
            case 1: return 4.0  // 보통 강도 (일반 걷기)
            case 2: return 5.0  // 높은 강도 (빠른 걷기)
            default: return 4.0
            }

        case .running:
            switch intensity {
            case 0: return 7.0  // 낮은 강도 (조깅)
            case 1: return 8.0  // 보통 강도 (일반 달리기)
            case 2: return 10.0 // 높은 강도 (빠른 달리기)
            default: return 8.0
            }

        case .cycling:
            switch intensity {
            case 0: return 5.0  // 낮은 강도 (느린 속도)
            case 1: return 6.0  // 보통 강도 (일반 속도)
            case 2: return 8.0  // 높은 강도 (빠른 속도)
            default: return 6.0
            }

        case .swimming:
            switch intensity {
            case 0: return 6.0  // 낮은 강도 (느린 수영)
            case 1: return 7.0  // 보통 강도 (일반 수영)
            case 2: return 9.0  // 높은 강도 (빠른 수영)
            default: return 7.0
            }

        case .weight:
            switch intensity {
            case 0: return 4.0  // 낮은 강도 (가벼운 웨이트)
            case 1: return 6.0  // 보통 강도 (일반 웨이트)
            case 2: return 8.0  // 높은 강도 (고강도 웨이트)
            default: return 6.0
            }

        case .crossfit:
            switch intensity {
            case 0: return 6.0  // 낮은 강도
            case 1: return 8.0  // 보통 강도
            case 2: return 10.0 // 높은 강도
            default: return 8.0
            }

        case .yoga:
            switch intensity {
            case 0: return 2.5  // 낮은 강도 (스트레칭 요가)
            case 1: return 3.0  // 보통 강도 (일반 요가)
            case 2: return 4.0  // 높은 강도 (파워 요가)
            default: return 3.0
            }

        case .other:
            switch intensity {
            case 0: return 4.0  // 낮은 강도
            case 1: return 5.0  // 보통 강도
            case 2: return 6.0  // 높은 강도
            default: return 5.0
            }
        }
    }
}

// MARK: - Identifiable

extension ExerciseType: Identifiable {
    /// SwiftUI List와 ForEach에서 사용하기 위한 ID
    /// - rawValue를 ID로 사용하여 각 케이스를 고유하게 식별
    var id: Int16 {
        rawValue
    }
}
