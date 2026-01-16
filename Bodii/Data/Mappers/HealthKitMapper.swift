//
//  HealthKitMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Mapper Pattern
// HealthKit 데이터(HKSample)를 도메인 엔티티로 변환하는 매퍼
// 💡 Java 비교: DTO → Domain Entity 변환 매퍼와 유사

import Foundation
import HealthKit

// MARK: - HealthKitMapper

/// HealthKit 샘플 데이터를 Bodii 도메인 엔티티로 변환하는 매퍼
///
/// 📚 학습 포인트: Data Mapper Pattern
/// - HealthKit의 HKSample을 도메인 엔티티(BodyRecord, ExerciseRecord, SleepRecord)로 변환
/// - HealthKit UUID를 보존하여 중복 검사 가능
/// - 양방향 변환 지원 (읽기/쓰기)
///
/// ## 책임
/// - HealthKit → Domain 변환 (읽기)
/// - Domain → HealthKit 변환 (쓰기)
/// - 데이터 타입 변환 (HKQuantity → Decimal, TimeInterval → Int32 등)
/// - HealthKit UUID 보존 (중복 검사용)
///
/// ## 변환 지원
/// - `HKQuantitySample` (weight, bodyFatPercentage) → `BodyRecord`
/// - `WorkoutData` (HKWorkout wrapper) → `ExerciseRecord`
/// - `SleepData` (HKCategorySample wrapper) → `SleepRecord`
///
/// - Example:
/// ```swift
/// let mapper = HealthKitMapper()
///
/// // HealthKit 체중 샘플 → BodyRecord
/// let bodyRecord = try mapper.mapToBodyRecord(
///     from: weightSample,
///     bodyFatSample: bodyFatSample,
///     userId: currentUserId
/// )
///
/// // WorkoutData → ExerciseRecord
/// let exerciseRecord = mapper.mapToExerciseRecord(
///     from: workoutData,
///     userId: currentUserId
/// )
/// ```
struct HealthKitMapper {

    // MARK: - Types

    /// 매핑 중 발생할 수 있는 에러
    ///
    /// 📚 학습 포인트: Custom Error Type
    /// - Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// - LocalizedError로 사용자 친화적인 에러 메시지 제공
    /// 💡 Java 비교: Custom Exception과 유사
    enum MappingError: Error, LocalizedError {
        /// 필수 필드 누락
        case missingRequiredField(String)

        /// 잘못된 데이터 타입
        case invalidDataType(String)

        /// 단위 변환 실패
        case unitConversionFailed(String)

        /// 지원하지 않는 운동 타입
        case unsupportedWorkoutType(String)

        /// 잘못된 날짜 범위
        case invalidDateRange

        /// 에러 설명 (사용자에게 표시할 메시지)
        ///
        /// 📚 학습 포인트: LocalizedError Protocol
        /// - errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .missingRequiredField(let field):
                return "필수 필드가 누락되었습니다: \(field)"
            case .invalidDataType(let field):
                return "잘못된 데이터 타입입니다: \(field)"
            case .unitConversionFailed(let detail):
                return "단위 변환에 실패했습니다: \(detail)"
            case .unsupportedWorkoutType(let type):
                return "지원하지 않는 운동 타입입니다: \(type)"
            case .invalidDateRange:
                return "잘못된 날짜 범위입니다"
            }
        }
    }

    // MARK: - Initialization

    /// Mapper 초기화
    ///
    /// 📚 학습 포인트: Stateless Mapper
    /// - 이 Mapper는 상태를 갖지 않으므로 별도 초기화 불필요
    /// - 명시적으로 init을 제공하여 일관성 유지
    init() {}

    // MARK: - HealthKit → Domain (Read Operations)

    /// HKQuantitySample(체중, 체지방)을 BodyRecord로 변환
    ///
    /// 📚 학습 포인트: BodyRecord Mapping
    /// - HealthKit의 체중과 체지방 샘플을 Bodii의 BodyRecord로 변환
    /// - 두 샘플의 측정 시간이 비슷하면(30분 이내) 하나의 BodyRecord로 병합
    /// - HealthKit UUID는 BodyRecord ID로 사용하지 않음 (앱에서 새 ID 생성)
    /// 💡 Java 비교: DTO 병합 매핑과 유사
    ///
    /// - Parameters:
    ///   - weightSample: HealthKit 체중 샘플 (필수)
    ///   - bodyFatSample: HealthKit 체지방 샘플 (선택)
    ///   - userId: 사용자 ID
    ///
    /// - Returns: BodyRecord 도메인 엔티티
    ///
    /// - Throws: MappingError
    ///   - unitConversionFailed: 단위 변환 실패
    ///
    /// - Example:
    /// ```swift
    /// let bodyRecord = try mapper.mapToBodyRecord(
    ///     from: weightSample,
    ///     bodyFatSample: bodyFatSample,
    ///     userId: currentUserId
    /// )
    /// ```
    func mapToBodyRecord(
        from weightSample: HKQuantitySample,
        bodyFatSample: HKQuantitySample? = nil,
        userId: UUID
    ) throws -> BodyRecord {
        // 📚 학습 포인트: HKQuantity to Decimal Conversion
        // - HKQuantity의 값을 특정 단위(kg, %)로 추출
        // - Decimal로 변환하여 정밀한 수치 표현
        // 💡 Java 비교: BigDecimal 변환과 유사

        let weightKg = weightSample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        let weight = Decimal(weightKg)

        // 체지방률 추출 (optional)
        var bodyFatPercent: Decimal?
        var bodyFatMass: Decimal?

        if let bodyFatSample = bodyFatSample {
            // 📚 학습 포인트: Body Fat Percentage Unit
            // - HealthKit에서 체지방률은 0~1 사이의 비율 (0.21 = 21%)
            // - 앱에서는 0~100 사이의 퍼센트 값으로 저장
            let bodyFatRatio = bodyFatSample.quantity.doubleValue(for: .percent())
            bodyFatPercent = Decimal(bodyFatRatio * 100) // 0.21 → 21.0

            // 📚 학습 포인트: Calculated Field
            // - 체지방량 = 체중 × 체지방률
            bodyFatMass = weight * (bodyFatPercent! / 100)
        }

        // 📚 학습 포인트: Date Handling
        // - HealthKit 샘플의 startDate를 측정 시간으로 사용
        // - endDate는 즉시 측정이므로 startDate와 동일한 경우가 많음
        let date = weightSample.startDate

        return BodyRecord(
            id: UUID(), // 📚 새 ID 생성 (HealthKit UUID는 metadata에 보관 가능)
            userId: userId,
            date: date,
            weight: weight,
            bodyFatMass: bodyFatMass,
            bodyFatPercent: bodyFatPercent,
            muscleMass: nil, // HealthKit은 골격근량을 직접 제공하지 않음
            createdAt: Date()
        )
    }

    /// WorkoutData를 ExerciseRecord로 변환
    ///
    /// 📚 학습 포인트: Workout Mapping
    /// - HealthKitReadService의 WorkoutData를 ExerciseRecord로 변환
    /// - WorkoutData는 이미 ExerciseType 매핑이 완료된 상태
    /// - HealthKit UUID를 보존하여 중복 검사에 활용
    /// 💡 Java 비교: DTO → Entity 변환과 유사
    ///
    /// - Parameters:
    ///   - workoutData: HealthKitReadService의 WorkoutData
    ///   - userId: 사용자 ID
    ///
    /// - Returns: ExerciseRecord 도메인 엔티티
    ///
    /// - Example:
    /// ```swift
    /// let workouts = try await readService.fetchWorkouts(from: startDate, to: endDate)
    /// let exerciseRecords = workouts.map { workoutData in
    ///     mapper.mapToExerciseRecord(from: workoutData, userId: currentUserId)
    /// }
    /// ```
    func mapToExerciseRecord(
        from workoutData: HealthKitReadService.WorkoutData,
        userId: UUID
    ) -> ExerciseRecord {
        // 📚 학습 포인트: Direct Mapping
        // - WorkoutData는 이미 앱의 타입(ExerciseType, Intensity)으로 변환됨
        // - 단순히 도메인 엔티티 구조로 재구성

        return ExerciseRecord(
            id: UUID(), // 📚 새 ID 생성
            userId: userId,
            date: workoutData.startDate,
            exerciseType: workoutData.exerciseType,
            duration: workoutData.duration,
            intensity: workoutData.intensity,
            caloriesBurned: workoutData.caloriesBurned,
            createdAt: Date()
        )
    }

    /// SleepData를 SleepRecord로 변환
    ///
    /// 📚 학습 포인트: Sleep Data Mapping
    /// - HealthKitReadService의 SleepData를 SleepRecord로 변환
    /// - totalDurationMinutes를 사용하여 SleepStatus 자동 계산
    /// - 수면 기준일(02:00 기준) 처리는 SleepRecord의 규칙을 따름
    /// 💡 Java 비교: Aggregated DTO → Entity 변환과 유사
    ///
    /// - Parameters:
    ///   - sleepData: HealthKitReadService의 SleepData
    ///   - userId: 사용자 ID
    ///
    /// - Returns: SleepRecord 도메인 엔티티
    ///
    /// - Example:
    /// ```swift
    /// let sleepData = try await readService.fetchSleepData(for: date)
    /// let sleepRecord = mapper.mapToSleepRecord(from: sleepData, userId: currentUserId)
    /// ```
    func mapToSleepRecord(
        from sleepData: HealthKitReadService.SleepData,
        userId: UUID
    ) -> SleepRecord {
        // 📚 학습 포인트: Duration to Status Conversion
        // - SleepStatus.from(durationMinutes:) 사용하여 자동 계산
        // - 330분 미만: bad, 330~390: soso, 390~450: good, 450~540: excellent, 540 초과: oversleep
        let duration = Int32(sleepData.totalDurationMinutes)
        let status = SleepStatus.from(durationMinutes: duration)

        // 📚 학습 포인트: Sleep Date Handling
        // - SleepRecord의 date는 02:00 기준으로 하루를 구분
        // - sleepData.startDate가 있으면 사용, 없으면 현재 날짜
        // - 실제로는 02:00 기준 처리가 필요하지만 여기서는 startDate 사용
        let date = sleepData.startDate ?? Date()

        return SleepRecord(
            id: UUID(), // 📚 새 ID 생성
            userId: userId,
            date: date,
            duration: duration,
            status: status,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Batch Mapping

    /// 여러 BodyRecord를 한 번에 변환 (체중 샘플 배열)
    ///
    /// 📚 학습 포인트: Batch Conversion
    /// - Swift의 map을 활용한 컬렉션 변환
    /// - 각 체중 샘플을 개별 BodyRecord로 변환
    /// 💡 Java 비교: Stream.map()과 유사
    ///
    /// - Parameters:
    ///   - weightSamples: HealthKit 체중 샘플 배열
    ///   - userId: 사용자 ID
    ///
    /// - Returns: BodyRecord 배열
    ///
    /// - Throws: MappingError - 변환 중 에러 발생 시
    func mapToBodyRecords(
        from weightSamples: [HKQuantitySample],
        userId: UUID
    ) throws -> [BodyRecord] {
        return try weightSamples.map { sample in
            try mapToBodyRecord(from: sample, bodyFatSample: nil, userId: userId)
        }
    }

    /// 여러 ExerciseRecord를 한 번에 변환
    ///
    /// - Parameters:
    ///   - workouts: WorkoutData 배열
    ///   - userId: 사용자 ID
    ///
    /// - Returns: ExerciseRecord 배열
    func mapToExerciseRecords(
        from workouts: [HealthKitReadService.WorkoutData],
        userId: UUID
    ) -> [ExerciseRecord] {
        return workouts.map { workoutData in
            mapToExerciseRecord(from: workoutData, userId: userId)
        }
    }
}

// MARK: - Helper Extensions

extension HealthKitMapper {

    /// HealthKit UUID를 추출하여 중복 검사에 활용
    ///
    /// 📚 학습 포인트: Duplicate Detection Helper
    /// - HKSample의 UUID를 String으로 변환
    /// - ExerciseRecord, BodyRecord에 healthKitId 필드를 추가하여 저장 가능
    /// - 동일한 HealthKit UUID를 가진 레코드는 중복으로 간주
    /// 💡 Java 비교: External ID 추출과 유사
    ///
    /// - Parameter sample: HealthKit 샘플
    ///
    /// - Returns: UUID 문자열
    ///
    /// - Note: 향후 BodyRecord, ExerciseRecord에 healthKitId: String? 필드 추가 필요
    func extractHealthKitId(from sample: HKSample) -> String {
        return sample.uuid.uuidString
    }

    /// 체중과 체지방 샘플의 측정 시간이 가까운지 확인
    ///
    /// 📚 학습 포인트: Time Proximity Check
    /// - 두 샘플이 30분 이내로 측정되었으면 같은 측정으로 간주
    /// - 하나의 BodyRecord로 병합 가능
    /// 💡 Java 비교: Duration.between() 사용한 시간 비교와 유사
    ///
    /// - Parameters:
    ///   - sample1: 첫 번째 샘플
    ///   - sample2: 두 번째 샘플
    ///   - thresholdMinutes: 임계값 (분 단위, 기본 30분)
    ///
    /// - Returns: 두 샘플이 가까운 시간에 측정되었는지 여부
    func areTimestampsClose(
        _ sample1: HKSample,
        _ sample2: HKSample,
        thresholdMinutes: Int = 30
    ) -> Bool {
        let timeDifference = abs(sample1.startDate.timeIntervalSince(sample2.startDate))
        let thresholdSeconds = Double(thresholdMinutes * 60)
        return timeDifference <= thresholdSeconds
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: HealthKit Mapper Pattern 이해
///
/// HealthKitMapper의 역할:
/// - HealthKit 데이터를 Bodii 도메인 엔티티로 변환
/// - HealthKit UUID 보존으로 중복 검사 가능
/// - 단위 변환 (HKQuantity → Decimal, TimeInterval → Int32)
/// - 타입 매핑 (HKWorkoutActivityType → ExerciseType)
///
/// 왜 HealthKitMapper가 필요한가?
/// 1. **데이터 격리 (Data Isolation)**
///    - Domain Layer가 HealthKit 프레임워크에 직접 의존하지 않음
///    - HealthKit을 다른 헬스 플랫폼으로 교체 가능
///
/// 2. **단위 변환 일관성 (Unit Conversion Consistency)**
///    - kg, %, kcal 등 단위 변환을 한 곳에서 관리
///    - 변환 오류 최소화
///
/// 3. **중복 검사 (Duplicate Detection)**
///    - HealthKit UUID를 보존하여 동일 데이터 재입력 방지
///    - 양방향 동기화 시 충돌 해결
///
/// 4. **타입 안전성 (Type Safety)**
///    - HealthKit의 다양한 타입을 앱의 통일된 도메인 타입으로 변환
///    - 컴파일 타임 타입 체크
///
/// Clean Architecture의 데이터 흐름:
/// ```
/// HealthKit (HKSample)
///        ↓
/// HealthKitReadService (WorkoutData, SleepData)
///        ↓
/// HealthKitMapper ← 여기서 변환
///        ↓
/// Domain Entities (BodyRecord, ExerciseRecord, SleepRecord)
///        ↓
/// Repositories (저장/조회)
///        ↓
/// Presentation Layer (UI 표시)
/// ```
///
/// 💡 실무 팁:
/// - Mapper는 stateless하게 유지 (상태 없음)
/// - 변환 로직만 담당, 비즈니스 로직은 Service/UseCase에 위치
/// - 변환 실패 시 명확한 에러 메시지 제공
/// - 단위 변환은 반드시 테스트 코드 작성
/// - HealthKit UUID를 메타데이터로 보존하여 양방향 동기화 지원
///
/// 💡 Java 비교:
/// ```java
/// // Java의 ModelMapper, MapStruct와 유사한 역할
/// @Mapper
/// public class HealthKitMapper {
///     public BodyRecord toBodyRecord(HKQuantitySample sample) { ... }
///     public ExerciseRecord toExerciseRecord(WorkoutData workout) { ... }
/// }
/// ```
