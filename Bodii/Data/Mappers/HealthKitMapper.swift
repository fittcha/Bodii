//
//  HealthKitMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

import Foundation
import HealthKit
import CoreData

// MARK: - HealthKitMapper

/// HealthKit 샘플 데이터를 Bodii 도메인 엔티티로 변환하는 매퍼
struct HealthKitMapper {

    // MARK: - Types

    /// 매핑 중 발생할 수 있는 에러
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

    /// Body data DTO (Core Data 엔티티 생성 전 데이터)
    struct BodyDataDTO {
        let date: Date
        let weight: Decimal
        let bodyFatMass: Decimal?
        let bodyFatPercent: Decimal?
        let muscleMass: Decimal?
        let healthKitId: String?
    }

    /// Exercise data DTO (Core Data 엔티티 생성 전 데이터)
    struct ExerciseDataDTO {
        let date: Date
        let exerciseType: ExerciseType
        let duration: Int32
        let intensity: Intensity
        let caloriesBurned: Int32
        let healthKitId: String?
    }

    /// Sleep data DTO (Core Data 엔티티 생성 전 데이터)
    struct SleepDataDTO {
        let date: Date
        let duration: Int32
        let status: SleepStatus
        let healthKitId: String?
    }

    // MARK: - Initialization

    init() {}

    // MARK: - HealthKit → DTO (Read Operations)

    /// HKQuantitySample(체중, 체지방)을 BodyDataDTO로 변환
    func mapToBodyDataDTO(
        from weightSample: HKQuantitySample,
        bodyFatSample: HKQuantitySample? = nil
    ) throws -> BodyDataDTO {
        let weightKg = weightSample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        let weight = Decimal(weightKg)

        var bodyFatPercent: Decimal?
        var bodyFatMass: Decimal?

        if let bodyFatSample = bodyFatSample {
            let bodyFatRatio = bodyFatSample.quantity.doubleValue(for: .percent())
            bodyFatPercent = Decimal(bodyFatRatio * 100)
            bodyFatMass = weight * (bodyFatPercent! / 100)
        }

        let date = weightSample.startDate
        let healthKitId = extractHealthKitId(from: weightSample)

        return BodyDataDTO(
            date: date,
            weight: weight,
            bodyFatMass: bodyFatMass,
            bodyFatPercent: bodyFatPercent,
            muscleMass: nil,
            healthKitId: healthKitId
        )
    }

    /// WorkoutData를 ExerciseDataDTO로 변환
    func mapToExerciseDataDTO(
        from workoutData: HealthKitReadService.WorkoutData
    ) -> ExerciseDataDTO {
        let healthKitId = workoutData.healthKitId.uuidString

        return ExerciseDataDTO(
            date: workoutData.startDate,
            exerciseType: workoutData.exerciseType,
            duration: workoutData.duration,
            intensity: workoutData.intensity,
            caloriesBurned: workoutData.caloriesBurned,
            healthKitId: healthKitId
        )
    }

    /// SleepData를 SleepDataDTO로 변환
    func mapToSleepDataDTO(
        from sleepData: HealthKitReadService.SleepData
    ) -> SleepDataDTO {
        let duration = Int32(sleepData.totalDurationMinutes)
        let status = SleepStatus.from(durationMinutes: duration)
        let date = sleepData.startDate ?? Date()
        let healthKitId = sleepData.segments.first.map { extractHealthKitId(from: $0) }

        return SleepDataDTO(
            date: date,
            duration: duration,
            status: status,
            healthKitId: healthKitId
        )
    }

    // MARK: - DTO → Core Data Entity Creation

    /// BodyDataDTO를 Core Data BodyRecord로 변환
    func createBodyRecord(
        from dto: BodyDataDTO,
        userId: UUID,
        user: User,
        context: NSManagedObjectContext
    ) -> BodyRecord {
        let record = BodyRecord(context: context)
        record.id = UUID()
        record.user = user
        record.date = dto.date
        record.weight = NSDecimalNumber(decimal: dto.weight)
        record.bodyFatMass = dto.bodyFatMass.map { NSDecimalNumber(decimal: $0) }
        record.bodyFatPercent = dto.bodyFatPercent.map { NSDecimalNumber(decimal: $0) }
        record.muscleMass = dto.muscleMass.map { NSDecimalNumber(decimal: $0) }
        record.healthKitId = dto.healthKitId
        record.createdAt = Date()
        return record
    }

    /// ExerciseDataDTO를 Core Data ExerciseRecord로 변환
    func createExerciseRecord(
        from dto: ExerciseDataDTO,
        userId: UUID,
        user: User,
        context: NSManagedObjectContext
    ) -> ExerciseRecord {
        let record = ExerciseRecord(context: context)
        record.id = UUID()
        record.user = user
        record.date = dto.date
        record.exerciseType = dto.exerciseType.rawValue
        record.duration = dto.duration
        record.intensity = dto.intensity.rawValue
        record.caloriesBurned = dto.caloriesBurned
        record.healthKitId = dto.healthKitId
        record.createdAt = Date()
        return record
    }

    /// SleepDataDTO를 Core Data SleepRecord로 변환
    func createSleepRecord(
        from dto: SleepDataDTO,
        userId: UUID,
        user: User,
        context: NSManagedObjectContext
    ) -> SleepRecord {
        let record = SleepRecord(context: context)
        record.id = UUID()
        record.user = user
        record.date = dto.date
        record.duration = dto.duration
        record.status = dto.status.rawValue
        record.healthKitId = dto.healthKitId
        record.createdAt = Date()
        record.updatedAt = Date()
        return record
    }

    // MARK: - Domain → HealthKit (Write Operations)

    /// BodyRecord를 체중 HKQuantitySample로 변환
    func createWeightSample(
        from record: BodyRecord,
        metadata: [String: Any]? = nil
    ) throws -> HKQuantitySample {
        guard let weightType = HealthKitDataTypes.QuantityType.weight.type else {
            throw MappingError.invalidDataType("bodyMass")
        }

        guard let weight = record.weight else {
            throw MappingError.missingRequiredField("weight")
        }

        let weightValue = weight.doubleValue

        let quantity = HKQuantity(
            unit: HealthKitDataTypes.QuantityType.weight.unit,
            doubleValue: weightValue
        )

        let sampleMetadata = createMetadata(
            source: "bodii_manual_entry",
            additionalMetadata: metadata
        )

        guard let date = record.date else {
            throw MappingError.missingRequiredField("date")
        }

        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: sampleMetadata
        )

        return sample
    }

    /// BodyRecord를 체지방률 HKQuantitySample로 변환
    func createBodyFatSample(
        from record: BodyRecord,
        metadata: [String: Any]? = nil
    ) throws -> HKQuantitySample {
        guard let bodyFatPercent = record.bodyFatPercent else {
            throw MappingError.missingRequiredField("bodyFatPercent")
        }

        guard let bodyFatType = HealthKitDataTypes.QuantityType.bodyFatPercentage.type else {
            throw MappingError.invalidDataType("bodyFatPercentage")
        }

        let percentValue = bodyFatPercent.doubleValue / 100.0

        let quantity = HKQuantity(
            unit: HealthKitDataTypes.QuantityType.bodyFatPercentage.unit,
            doubleValue: percentValue
        )

        let sampleMetadata = createMetadata(
            source: "bodii_manual_entry",
            additionalMetadata: metadata
        )

        guard let date = record.date else {
            throw MappingError.missingRequiredField("date")
        }

        let sample = HKQuantitySample(
            type: bodyFatType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: sampleMetadata
        )

        return sample
    }

    /// ExerciseRecord를 HKWorkout으로 변환
    func createWorkout(
        from record: ExerciseRecord,
        metadata: [String: Any]? = nil
    ) throws -> HKWorkout {
        guard let exerciseType = ExerciseType(rawValue: record.exerciseType) else {
            throw MappingError.unsupportedWorkoutType("Unknown type: \(record.exerciseType)")
        }

        let activityType = mapExerciseTypeToWorkoutActivityType(exerciseType)
        let durationInSeconds = TimeInterval(record.duration * 60)

        guard let date = record.date else {
            throw MappingError.missingRequiredField("date")
        }

        let endDate = date.addingTimeInterval(durationInSeconds)

        let caloriesQuantity = HKQuantity(
            unit: .kilocalorie(),
            doubleValue: Double(record.caloriesBurned)
        )

        var workoutMetadata = createMetadata(
            source: "bodii_manual_entry",
            additionalMetadata: metadata
        )

        if let intensity = Intensity(rawValue: record.intensity) {
            workoutMetadata["BodiiIntensity"] = intensity.rawValue
        }

        let workout = HKWorkout(
            activityType: activityType,
            start: date,
            end: endDate,
            duration: durationInSeconds,
            totalEnergyBurned: caloriesQuantity,
            totalDistance: nil,
            metadata: workoutMetadata
        )

        return workout
    }

    /// BodyRecord에서 체중과 체지방률 샘플을 함께 생성
    func createBodyCompositionSamples(
        from record: BodyRecord,
        metadata: [String: Any]? = nil
    ) throws -> [HKQuantitySample] {
        var samples: [HKQuantitySample] = []

        let weightSample = try createWeightSample(from: record, metadata: metadata)
        samples.append(weightSample)

        if record.bodyFatPercent != nil {
            do {
                let bodyFatSample = try createBodyFatSample(from: record, metadata: metadata)
                samples.append(bodyFatSample)
            } catch {
                // 체지방률 샘플 생성 실패 시 체중 샘플만 반환
            }
        }

        return samples
    }
}

// MARK: - Helper Extensions

extension HealthKitMapper {

    /// HealthKit UUID를 추출
    func extractHealthKitId(from sample: HKSample) -> String {
        return sample.uuid.uuidString
    }

    /// 체중과 체지방 샘플의 측정 시간이 가까운지 확인
    func areTimestampsClose(
        _ sample1: HKSample,
        _ sample2: HKSample,
        thresholdMinutes: Int = 30
    ) -> Bool {
        let timeDifference = abs(sample1.startDate.timeIntervalSince(sample2.startDate))
        let thresholdSeconds = Double(thresholdMinutes * 60)
        return timeDifference <= thresholdSeconds
    }

    /// ExerciseType을 HKWorkoutActivityType으로 변환
    private func mapExerciseTypeToWorkoutActivityType(
        _ exerciseType: ExerciseType
    ) -> HKWorkoutActivityType {
        switch exerciseType {
        case .walking:
            return .walking
        case .running:
            return .running
        case .cycling:
            return .cycling
        case .swimming:
            return .swimming
        case .weight:
            return .traditionalStrengthTraining
        case .crossfit:
            return .crossTraining
        case .yoga:
            return .yoga
        case .other:
            return .other
        }
    }

    /// Bodii 앱에서 생성한 샘플임을 표시하는 메타데이터 생성
    private func createMetadata(
        source: String = "Bodii",
        additionalMetadata: [String: Any]? = nil
    ) -> [String: Any] {
        var metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: "com.bodii.app",
            HKMetadataKeySyncVersion: 1
        ]

        metadata["BodiiSource"] = source

        if let additional = additionalMetadata {
            metadata.merge(additional) { _, new in new }
        }

        return metadata
    }
}
