//
//  Constants.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: App-wide Constants
// Swift는 enum을 네임스페이스로 사용하여 상수를 그룹화
// 💡 Java 비교: final class with private constructor와 유사하지만 Swift는 enum 사용

import Foundation

// MARK: - Constants

/// 앱 전역 상수
/// - 검증 범위, 기본값, 계산 상수를 포함
/// - enum을 네임스페이스로 사용하여 인스턴스화 방지
enum Constants {

    // MARK: - Validation Ranges

    /// 사용자 입력 검증을 위한 유효 범위
    enum Validation {

        // MARK: Body Measurements

        /// 키 유효 범위 (cm)
        enum Height {
            /// 최소 키: 100cm
            static let min: Double = 100.0
            /// 최대 키: 250cm
            static let max: Double = 250.0
        }

        /// 체중 유효 범위 (kg)
        enum Weight {
            /// 최소 체중: 20kg
            static let min: Double = 20.0
            /// 최대 체중: 300kg
            static let max: Double = 300.0
        }

        /// 체지방률 유효 범위 (%)
        enum BodyFatPercent {
            /// 최소 체지방률: 3%
            static let min: Double = 3.0
            /// 최대 체지방률: 60%
            static let max: Double = 60.0
        }

        /// 근육량 유효 범위 (kg)
        enum MuscleMass {
            /// 최소 근육량: 10kg
            static let min: Double = 10.0
            /// 최대 근육량: 60kg
            static let max: Double = 60.0
        }

        // MARK: User Profile

        /// 생년 유효 범위
        enum BirthYear {
            /// 최소 생년: 1900년
            static let min: Int = 1900
            /// 최대 생년: 현재 연도
            static var max: Int {
                Calendar.current.component(.year, from: Date())
            }
        }

        /// 이름 유효 범위
        enum Name {
            /// 최소 길이: 1글자
            static let minLength: Int = 1
            /// 최대 길이: 20글자
            static let maxLength: Int = 20
        }

        // MARK: Exercise

        /// 운동 시간 유효 범위 (분)
        enum ExerciseDuration {
            /// 최소 운동 시간: 1분
            static let min: Int = 1
            /// 최대 운동 시간: 480분 (8시간)
            static let max: Int = 480
        }

        // MARK: Food

        /// 음식 섭취량 유효 범위 (인분 단위)
        enum ServingQuantity {
            /// 최소 섭취량: 0.1인분
            static let min: Double = 0.1
            /// 최대 섭취량: 100인분
            static let max: Double = 100.0
        }

        /// 음식 섭취량 유효 범위 (그램 단위)
        enum GramQuantity {
            /// 최소 섭취량: 1g
            static let min: Double = 1.0
            /// 최대 섭취량: 10,000g (10kg)
            static let max: Double = 10_000.0
        }
    }

    // MARK: - Sleep Boundary

    /// 수면 경계 시간 설정
    /// - 02:00를 기준으로 전날/당일 구분
    enum Sleep {
        /// 수면 경계 시간: 02:00
        /// - 02:00 이전(00:00-01:59)은 전날로 간주
        /// - 02:00 이후(02:00-23:59)는 당일로 간주
        static let boundaryHour: Int = 2
    }

    // MARK: - Default Values

    /// 기본값
    enum Defaults {

        /// 기본 활동 수준: 보통 활동
        static let activityLevel: Int16 = 3  // ActivityLevel.moderate

        /// 기본 1인분 크기 (g)
        static let servingSize: Double = 100.0

        /// 기본 목표 타입: 유지
        static let goalType: Int16 = 1  // GoalType.maintain
    }

    // MARK: - BMR Calculation Constants

    /// 기초대사량(BMR) 계산 상수
    /// - Mifflin-St Jeor 방정식 사용
    enum BMR {

        /// 남성 BMR 계산 상수
        enum Male {
            /// 체중 계수: 10
            static let weightCoefficient: Double = 10.0
            /// 키 계수: 6.25
            static let heightCoefficient: Double = 6.25
            /// 나이 계수: 5
            static let ageCoefficient: Double = 5.0
            /// 기본 상수: +5
            static let baseConstant: Double = 5.0
        }

        /// 여성 BMR 계산 상수
        enum Female {
            /// 체중 계수: 10
            static let weightCoefficient: Double = 10.0
            /// 키 계수: 6.25
            static let heightCoefficient: Double = 6.25
            /// 나이 계수: 5
            static let ageCoefficient: Double = 5.0
            /// 기본 상수: -161
            static let baseConstant: Double = -161.0
        }
    }

    // MARK: - TDEE Calculation Constants

    /// 일일 총 에너지 소비량(TDEE) 계산 상수
    /// - TDEE = BMR × ActivityLevel.multiplier
    /// - ActivityLevel enum에서 multiplier 제공
    enum TDEE {
        /// 참고: ActivityLevel enum의 multiplier 사용
        /// - sedentary: 1.2
        /// - light: 1.375
        /// - moderate: 1.55
        /// - active: 1.725
        /// - veryActive: 1.9
    }

    // MARK: - Calorie Adjustment Constants

    /// 칼로리 조정 상수
    enum CalorieAdjustment {
        /// 1kg 체중 변화에 필요한 칼로리: 7,700 kcal
        static let caloriesPerKg: Double = 7_700.0

        /// 주당 안전한 최대 감량: 1kg
        static let maxWeeklyLossKg: Double = 1.0

        /// 주당 안전한 최대 증량: 0.5kg
        static let maxWeeklyGainKg: Double = 0.5
    }

    // MARK: - Macro Ratios

    /// 영양소 비율
    enum MacroRatios {
        /// 탄수화물 칼로리당 그램: 4 kcal/g
        static let carbCaloriesPerGram: Double = 4.0

        /// 단백질 칼로리당 그램: 4 kcal/g
        static let proteinCaloriesPerGram: Double = 4.0

        /// 지방 칼로리당 그램: 9 kcal/g
        static let fatCaloriesPerGram: Double = 9.0
    }

    // MARK: - Body Composition

    /// 체성분 계산 상수
    enum BodyComposition {
        /// 제지방량 = 체중 × (1 - 체지방률/100)
        /// 근육량은 제지방량의 일부
        /// - 제지방량 ≥ 근육량 검증 필요
    }
}
