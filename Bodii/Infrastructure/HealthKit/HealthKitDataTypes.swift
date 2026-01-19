//
//  HealthKitDataTypes.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Data Type Configuration
// HealthKit에서 사용할 모든 데이터 타입을 중앙에서 관리
// 💡 Java 비교: Constants 클래스와 유사하지만 타입 안전성 제공

import Foundation
import HealthKit

/// HealthKit data type identifiers and configurations
///
/// HealthKit에서 사용하는 모든 데이터 타입을 정의하고 관리하는 구성 객체
///
/// 📚 학습 포인트: Type-Safe Configuration
/// 문자열 하드코딩 대신 타입 안전한 enum 사용
/// 💡 Java 비교: enum Constants와 유사하지만 더 강력한 타입 체크
///
/// **데이터 타입 분류:**
/// - **HKQuantityType**: 수치 데이터 (체중, 체지방률, 칼로리, 걸음 수)
/// - **HKCategoryType**: 카테고리 데이터 (수면 분석)
/// - **HKWorkoutType**: 운동 데이터 (특별한 타입)
///
/// **권한 분류:**
/// - **읽기(Read)**: HealthKit에서 데이터를 가져올 타입
/// - **쓰기(Write)**: HealthKit에 데이터를 저장할 타입
///
/// - Example:
/// ```swift
/// // 읽기 권한 요청할 타입들
/// let readTypes = HealthKitDataTypes.readTypes
///
/// // 쓰기 권한 요청할 타입들
/// let writeTypes = HealthKitDataTypes.writeTypes
///
/// // 모든 권한 요청
/// try await healthStore.requestAuthorization(
///     toShare: writeTypes,
///     read: readTypes
/// )
/// ```
struct HealthKitDataTypes {

    // MARK: - Quantity Types

    /// Quantity type identifiers
    ///
    /// 📚 학습 포인트: HKQuantityType
    /// 수치로 측정되는 건강 데이터 (체중, 칼로리, 걸음 수 등)
    /// 💡 Java 비교: 숫자 타입 데이터를 다루는 Column과 유사
    ///
    /// **포함된 타입:**
    /// - **weight**: 체중 (kg 단위)
    /// - **bodyFatPercentage**: 체지방률 (% 단위)
    /// - **activeEnergyBurned**: 활동 칼로리 (kcal 단위)
    /// - **stepCount**: 걸음 수 (count 단위)
    /// - **dietaryEnergyConsumed**: 섭취 칼로리 (kcal 단위)
    enum QuantityType: CaseIterable {

        /// 체중 (kg)
        ///
        /// 사용자의 체중 데이터
        ///
        /// - 읽기: HealthKit에서 체중 기록 가져오기
        /// - 쓰기: Bodii에서 입력한 체중을 HealthKit에 저장
        ///
        /// - Note: HKUnit.gramUnit(with: .kilo) 사용
        ///
        /// - Example:
        /// ```swift
        /// let weightType = HealthKitDataTypes.QuantityType.weight
        /// let weight = 70.5 // kg
        /// ```
        case weight

        /// 체지방률 (%)
        ///
        /// 사용자의 체지방 비율 데이터
        ///
        /// - 읽기: HealthKit에서 체지방률 기록 가져오기
        /// - 쓰기: Bodii에서 입력한 체지방률을 HealthKit에 저장
        ///
        /// - Note: HKUnit.percent() 사용
        ///
        /// - Example:
        /// ```swift
        /// let bodyFatType = HealthKitDataTypes.QuantityType.bodyFatPercentage
        /// let bodyFat = 18.5 // %
        /// ```
        case bodyFatPercentage

        /// 활동 칼로리 (kcal)
        ///
        /// 활동으로 소모된 칼로리 (기초대사량 제외)
        ///
        /// - 읽기: Apple Watch나 다른 앱에서 기록한 활동 칼로리
        /// - 쓰기: 현재는 읽기만 사용 (Apple Watch가 주로 기록)
        ///
        /// - Note: HKUnit.kilocalorie() 사용
        ///
        /// - Example:
        /// ```swift
        /// let activeCaloriesType = HealthKitDataTypes.QuantityType.activeEnergyBurned
        /// let calories = 450.0 // kcal
        /// ```
        case activeEnergyBurned

        /// 걸음 수 (count)
        ///
        /// 하루 동안 걸은 걸음 수
        ///
        /// - 읽기: iPhone이나 Apple Watch에서 자동 기록된 걸음 수
        /// - 쓰기: 현재는 읽기만 사용 (기기가 자동으로 기록)
        ///
        /// - Note: HKUnit.count() 사용
        ///
        /// - Example:
        /// ```swift
        /// let stepsType = HealthKitDataTypes.QuantityType.stepCount
        /// let steps = 8500.0 // 걸음
        /// ```
        case stepCount

        /// 섭취 칼로리 (kcal)
        ///
        /// 음식으로 섭취한 칼로리
        ///
        /// - 읽기: 현재는 사용하지 않음
        /// - 쓰기: Bodii에서 기록한 식단을 HealthKit에 저장
        ///
        /// - Note: HKUnit.kilocalorie() 사용
        ///
        /// - Example:
        /// ```swift
        /// let dietaryType = HealthKitDataTypes.QuantityType.dietaryEnergyConsumed
        /// let consumed = 1800.0 // kcal
        /// ```
        case dietaryEnergyConsumed

        /// HKQuantityTypeIdentifier 반환
        ///
        /// 📚 학습 포인트: Computed Property
        /// enum case를 HKQuantityTypeIdentifier로 변환
        /// 💡 Java 비교: enum의 getValue() 메서드와 유사
        ///
        /// - Returns: 해당하는 HKQuantityTypeIdentifier
        var identifier: HKQuantityTypeIdentifier {
            switch self {
            case .weight:
                return .bodyMass
            case .bodyFatPercentage:
                return .bodyFatPercentage
            case .activeEnergyBurned:
                return .activeEnergyBurned
            case .stepCount:
                return .stepCount
            case .dietaryEnergyConsumed:
                return .dietaryEnergyConsumed
            }
        }

        /// HKQuantityType 객체 반환
        ///
        /// 📚 학습 포인트: Optional Wrapping
        /// HKQuantityType 생성은 실패할 수 있으므로 Optional 반환
        /// 💡 Java 비교: Optional<HKQuantityType>와 동일
        ///
        /// - Returns: HKQuantityType 객체 (생성 실패 시 nil)
        ///
        /// - Example:
        /// ```swift
        /// guard let weightType = HealthKitDataTypes.QuantityType.weight.type else {
        ///     throw HealthKitError.invalidSampleType(identifier: "bodyMass")
        /// }
        /// ```
        var type: HKQuantityType? {
            return HKQuantityType.quantityType(forIdentifier: identifier)
        }

        /// HKQuantityType 객체 반환 (alias for type)
        ///
        /// Background sync에서 사용하는 alias
        var hkQuantityType: HKQuantityType? {
            return type
        }

        /// 사용자 친화적인 표시 이름 (한국어)
        ///
        /// UI에서 표시할 데이터 타입 이름
        ///
        /// - Returns: 한국어 표시 이름
        var displayName: String {
            switch self {
            case .weight:
                return "체중"
            case .bodyFatPercentage:
                return "체지방률"
            case .activeEnergyBurned:
                return "활동 칼로리"
            case .stepCount:
                return "걸음 수"
            case .dietaryEnergyConsumed:
                return "섭취 칼로리"
            }
        }

        /// 해당 타입의 기본 단위
        ///
        /// 📚 학습 포인트: HKUnit
        /// HealthKit에서 수치 데이터의 단위 표현
        /// 💡 Java 비교: Unit of Measurement와 유사
        ///
        /// - Returns: HKUnit 객체
        var unit: HKUnit {
            switch self {
            case .weight:
                return HKUnit.gramUnit(with: .kilo)
            case .bodyFatPercentage:
                return HKUnit.percent()
            case .activeEnergyBurned, .dietaryEnergyConsumed:
                return HKUnit.kilocalorie()
            case .stepCount:
                return HKUnit.count()
            }
        }
    }

    // MARK: - Category Types

    /// Category type identifiers
    ///
    /// 📚 학습 포인트: HKCategoryType
    /// 카테고리로 분류되는 건강 데이터 (수면, 마음 챙김 등)
    /// 💡 Java 비교: Enum 타입 데이터를 다루는 Column과 유사
    enum CategoryType: CaseIterable {

        /// 수면 분석
        ///
        /// 사용자의 수면 데이터
        ///
        /// - 읽기: HealthKit에서 수면 기록 가져오기
        /// - 쓰기: 현재는 읽기만 사용 (향후 확장 가능)
        ///
        /// 📚 학습 포인트: Sleep Analysis
        /// 수면 카테고리: inBed, asleep, awake, core, deep, REM
        /// 💡 Java 비교: SleepCategory enum과 유사
        ///
        /// - Note: 수면 시간 계산 시 asleep 상태만 집계
        ///
        /// - Example:
        /// ```swift
        /// let sleepType = HealthKitDataTypes.CategoryType.sleepAnalysis
        /// // HKCategoryValueSleepAnalysis.asleepUnspecified
        /// ```
        case sleepAnalysis

        /// HKCategoryTypeIdentifier 반환
        ///
        /// - Returns: 해당하는 HKCategoryTypeIdentifier
        var identifier: HKCategoryTypeIdentifier {
            switch self {
            case .sleepAnalysis:
                return .sleepAnalysis
            }
        }

        /// HKCategoryType 객체 반환
        ///
        /// - Returns: HKCategoryType 객체 (생성 실패 시 nil)
        ///
        /// - Example:
        /// ```swift
        /// guard let sleepType = HealthKitDataTypes.CategoryType.sleepAnalysis.type else {
        ///     throw HealthKitError.invalidSampleType(identifier: "sleepAnalysis")
        /// }
        /// ```
        var type: HKCategoryType? {
            return HKCategoryType.categoryType(forIdentifier: identifier)
        }

        /// HKCategoryType 객체 반환 (alias for type)
        ///
        /// Background sync에서 사용하는 alias
        var hkCategoryType: HKCategoryType? {
            return type
        }

        /// 사용자 친화적인 표시 이름 (한국어)
        ///
        /// - Returns: 한국어 표시 이름
        var displayName: String {
            switch self {
            case .sleepAnalysis:
                return "수면"
            }
        }
    }

    // MARK: - Workout Type

    /// 운동 데이터 타입
    ///
    /// 📚 학습 포인트: HKWorkoutType
    /// 운동 기록을 위한 특별한 타입 (Quantity나 Category가 아님)
    /// 💡 Java 비교: 특수한 Entity 타입과 유사
    ///
    /// **포함 정보:**
    /// - 운동 종류 (HKWorkoutActivityType: 달리기, 걷기, 사이클링 등)
    /// - 운동 시간 (시작/종료 시간)
    /// - 소모 칼로리
    /// - 이동 거리 (해당하는 경우)
    ///
    /// - Example:
    /// ```swift
    /// let workoutType = HealthKitDataTypes.workoutType
    /// let workout = HKWorkout(
    ///     activityType: .running,
    ///     start: startDate,
    ///     end: endDate,
    ///     duration: 1800, // 30분
    ///     totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: 300),
    ///     totalDistance: HKQuantity(unit: .meter(), doubleValue: 5000),
    ///     device: nil,
    ///     metadata: nil
    /// )
    /// ```
    static var workoutType: HKWorkoutType {
        return HKWorkoutType.workoutType()
    }

    /// 운동 타입 표시 이름
    static var workoutDisplayName: String {
        return "운동"
    }

    // MARK: - Read Types

    /// HealthKit에서 읽기 권한을 요청할 타입들
    ///
    /// 📚 학습 포인트: Permission Management
    /// 읽기 권한이 필요한 모든 데이터 타입을 Set으로 관리
    /// 💡 Java 비교: Set<Permission>과 유사
    ///
    /// **읽기 권한 요청 타입:**
    /// - 체중 (weight)
    /// - 체지방률 (bodyFatPercentage)
    /// - 활동 칼로리 (activeEnergyBurned)
    /// - 걸음 수 (stepCount)
    /// - 수면 분석 (sleepAnalysis)
    /// - 운동 (workout)
    ///
    /// - Note: HealthKit은 읽기 권한 거부를 앱에서 확인 불가 (프라이버시)
    ///
    /// - Example:
    /// ```swift
    /// let readTypes = HealthKitDataTypes.readTypes
    /// try await healthStore.requestAuthorization(
    ///     toShare: [],
    ///     read: readTypes
    /// )
    /// ```
    static var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()

        // Quantity Types (읽기)
        let quantityTypesToRead: [QuantityType] = [
            .weight,
            .bodyFatPercentage,
            .activeEnergyBurned,
            .stepCount
        ]

        for quantityType in quantityTypesToRead {
            if let type = quantityType.type {
                types.insert(type)
            }
        }

        // Category Types (읽기)
        let categoryTypesToRead: [CategoryType] = [
            .sleepAnalysis
        ]

        for categoryType in categoryTypesToRead {
            if let type = categoryType.type {
                types.insert(type)
            }
        }

        // Workout Type (읽기)
        types.insert(workoutType)

        return types
    }

    // MARK: - Write Types

    /// HealthKit에 쓰기 권한을 요청할 타입들
    ///
    /// 📚 학습 포인트: Write Permissions
    /// 쓰기 권한이 필요한 데이터 타입들
    /// 💡 Java 비교: Write Access Control과 유사
    ///
    /// **쓰기 권한 요청 타입:**
    /// - 체중 (weight)
    /// - 체지방률 (bodyFatPercentage)
    /// - 섭취 칼로리 (dietaryEnergyConsumed)
    /// - 운동 (workout)
    ///
    /// - Note: 쓰기 권한은 사용자가 거부 여부를 앱에서 확인 가능
    ///
    /// - Example:
    /// ```swift
    /// let writeTypes = HealthKitDataTypes.writeTypes
    /// try await healthStore.requestAuthorization(
    ///     toShare: writeTypes,
    ///     read: []
    /// )
    /// ```
    static var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()

        // Quantity Types (쓰기)
        let quantityTypesToWrite: [QuantityType] = [
            .weight,
            .bodyFatPercentage,
            .dietaryEnergyConsumed
        ]

        for quantityType in quantityTypesToWrite {
            if let type = quantityType.type {
                types.insert(type)
            }
        }

        // Workout Type (쓰기)
        types.insert(workoutType)

        return types
    }

    // MARK: - All Types

    /// 앱에서 사용하는 모든 HealthKit 타입
    ///
    /// 읽기와 쓰기 타입을 모두 포함
    ///
    /// 📚 학습 포인트: Set Union
    /// 두 Set을 합쳐 모든 타입을 포함하는 Set 생성
    /// 💡 Java 비교: Set.addAll()과 유사
    ///
    /// - Returns: 읽기 + 쓰기 권한이 필요한 모든 타입
    ///
    /// - Example:
    /// ```swift
    /// let allTypes = HealthKitDataTypes.allTypes
    /// print("총 \(allTypes.count)개의 HealthKit 데이터 타입 사용")
    /// ```
    static var allTypes: Set<HKObjectType> {
        var types = readTypes
        types.formUnion(writeTypes)
        return types
    }
}

// MARK: - Helper Methods

extension HealthKitDataTypes {

    /// 데이터 타입의 권한 설명 텍스트 (권한 요청 UI용)
    ///
    /// 📚 학습 포인트: User-Facing Descriptions
    /// 사용자에게 왜 각 데이터 타입이 필요한지 설명
    /// 💡 Java 비교: Resource String과 유사
    ///
    /// - Parameter type: 설명할 HKObjectType
    ///
    /// - Returns: 사용자 친화적인 설명 (한국어)
    ///
    /// - Example:
    /// ```swift
    /// let description = HealthKitDataTypes.permissionDescription(for: weightType)
    /// // "체중 기록을 불러오고 저장하기 위해 필요합니다"
    /// ```
    static func permissionDescription(for type: HKObjectType) -> String {
        let identifier = type.identifier

        switch identifier {
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return "체중 기록을 불러오고 저장하기 위해 필요합니다"

        case HKQuantityTypeIdentifier.bodyFatPercentage.rawValue:
            return "체지방률 기록을 불러오고 저장하기 위해 필요합니다"

        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return "활동 칼로리를 불러와 일일 목표 계산에 활용합니다"

        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return "걸음 수를 불러와 활동량을 추적합니다"

        case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
            return "Bodii에서 기록한 식단을 Apple Health에 저장합니다"

        case HKCategoryTypeIdentifier.sleepAnalysis.rawValue:
            return "수면 기록을 불러와 건강 분석에 활용합니다"

        case HKWorkoutType.workoutType().identifier:
            return "운동 기록을 불러오고 저장하기 위해 필요합니다"

        default:
            return "건강 데이터 관리를 위해 필요합니다"
        }
    }

    /// 데이터 타입이 읽기 권한이 필요한지 확인
    ///
    /// - Parameter type: 확인할 HKObjectType
    ///
    /// - Returns: 읽기 권한이 필요하면 true
    ///
    /// - Example:
    /// ```swift
    /// if HealthKitDataTypes.isReadType(weightType) {
    ///     print("체중은 읽기 권한이 필요합니다")
    /// }
    /// ```
    static func isReadType(_ type: HKObjectType) -> Bool {
        return readTypes.contains(type)
    }

    /// 데이터 타입이 쓰기 권한이 필요한지 확인
    ///
    /// - Parameter type: 확인할 HKObjectType
    ///
    /// - Returns: 쓰기 권한이 필요하면 true
    ///
    /// - Example:
    /// ```swift
    /// if HealthKitDataTypes.isWriteType(weightType) {
    ///     print("체중은 쓰기 권한이 필요합니다")
    /// }
    /// ```
    static func isWriteType(_ type: HKObjectType) -> Bool {
        guard let sampleType = type as? HKSampleType else { return false }
        return writeTypes.contains(sampleType)
    }
}
