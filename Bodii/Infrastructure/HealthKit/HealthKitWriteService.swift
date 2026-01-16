//
//  HealthKitWriteService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Write Service
// HealthKit에 데이터를 쓰는(저장하는) 서비스
// 💡 Java 비교: Repository의 Save 메서드와 유사하지만 비동기 처리

import Foundation
import HealthKit

/// HealthKit write service
///
/// HealthKit에 건강 데이터를 저장하는 서비스
///
/// 📚 학습 포인트: Write Operations
/// - HKHealthStore.save()를 사용한 데이터 저장
/// - 쓰기 권한 확인 후 저장
/// - 배치 저장 지원
/// 💡 Java 비교: Repository의 save() 메서드와 유사
///
/// ## 책임
/// - HealthKit에 샘플 데이터 저장
/// - 쓰기 권한 검증
/// - 배치 저장 지원
/// - HKQuantitySample, HKCategorySample, HKWorkout 저장
///
/// ## 사용 시나리오
/// 1. **체중/체지방 저장**: 사용자가 입력한 체성분 데이터를 HealthKit에 저장
/// 2. **운동 기록 저장**: Bodii에서 기록한 운동을 HealthKit에 저장
/// 3. **섭취 칼로리 저장**: 식단 기록을 HealthKit에 저장
///
/// - Example:
/// ```swift
/// let service = HealthKitWriteService(healthStore: authService.getHealthStore())
///
/// // 체중 저장
/// let weightSample = HKQuantitySample(...)
/// try await service.save(sample: weightSample)
///
/// // 배치 저장
/// let samples = [weightSample, bodyFatSample]
/// try await service.save(samples: samples)
/// ```
final class HealthKitWriteService {

    // MARK: - Properties

    /// HealthKit 데이터 저장소
    ///
    /// 📚 학습 포인트: HKHealthStore
    /// - HealthKit 데이터 읽기/쓰기를 위한 중앙 객체
    /// - 데이터 저장 담당
    /// 💡 Java 비교: EntityManager와 유사한 역할
    ///
    /// - Note: HealthKitAuthorizationService에서 공유받아 사용
    private let healthStore: HKHealthStore

    // MARK: - Initialization

    /// HealthKitWriteService 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - HKHealthStore를 외부에서 주입받아 테스트 가능하게 설계
    /// - AuthorizationService와 동일한 HKHealthStore 인스턴스 공유
    /// 💡 Java 비교: Constructor Injection
    ///
    /// - Parameter healthStore: HealthKit 데이터 저장소
    ///
    /// - Example:
    /// ```swift
    /// let authService = HealthKitAuthorizationService()
    /// let writeService = HealthKitWriteService(healthStore: authService.getHealthStore())
    /// ```
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    // MARK: - Generic Save Methods

    /// HealthKit에 샘플 저장 (단일)
    ///
    /// 📚 학습 포인트: Generic Save Method
    /// - HKObject의 모든 하위 타입(HKQuantitySample, HKCategorySample, HKWorkout 등)에 사용 가능
    /// - 타입 안전성을 유지하면서 코드 재사용성 향상
    /// 💡 Java 비교: <T extends HKObject> 제네릭 메서드와 유사
    ///
    /// - Parameter sample: 저장할 HKObject (HKQuantitySample, HKCategorySample, HKWorkout 등)
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 데이터 저장 실패
    ///
    /// - Note: 저장하기 전에 쓰기 권한이 있는지 자동으로 확인
    ///
    /// - Example:
    /// ```swift
    /// // 체중 샘플 저장
    /// let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
    /// let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: 70.5)
    /// let weightSample = HKQuantitySample(
    ///     type: weightType,
    ///     quantity: weightQuantity,
    ///     start: Date(),
    ///     end: Date()
    /// )
    /// try await service.save(sample: weightSample)
    ///
    /// // 운동 저장
    /// let workout = HKWorkout(...)
    /// try await service.save(sample: workout)
    /// ```
    func save(sample: HKObject) async throws {
        // 📚 학습 포인트: Authorization Check Before Write
        // 쓰기 권한이 없으면 에러를 던짐
        // 💡 Java 비교: @PreAuthorize 어노테이션과 유사
        if let sampleType = sample.sampleType {
            let status = healthStore.authorizationStatus(for: sampleType)
            guard status == .sharingAuthorized else {
                throw HealthKitError.dataTypeNotAuthorized(type: sampleType)
            }
        }

        // 📚 학습 포인트: async/await Save
        // HKHealthStore.save()는 비동기 메서드
        // 💡 Java 비교: CompletableFuture.supplyAsync()와 유사
        do {
            try await healthStore.save(sample)
        } catch {
            // 📚 학습 포인트: Error Wrapping
            // 시스템 에러를 HealthKitError로 래핑하여 통일된 에러 처리
            // 💡 Java 비교: Custom Exception Wrapping
            let typeName = sample.sampleType?.identifier ?? "unknown"
            throw HealthKitError.writeFailed(type: typeName, error: error)
        }
    }

    /// HealthKit에 샘플 배치 저장
    ///
    /// 📚 학습 포인트: Batch Save
    /// - 여러 샘플을 한 번에 저장하여 성능 향상
    /// - 트랜잭션 단위로 처리되어 전체 성공 또는 전체 실패
    /// 💡 Java 비교: saveAll() 또는 batchInsert()와 유사
    ///
    /// - Parameter samples: 저장할 HKObject 배열
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 쓰기 권한이 없음
    ///   - writeFailed: 데이터 저장 실패
    ///
    /// - Note:
    ///   - 배열이 비어있으면 아무 작업도 하지 않음
    ///   - 하나라도 저장 실패 시 전체 롤백
    ///
    /// - Example:
    /// ```swift
    /// // 체중과 체지방률을 동시에 저장
    /// let weightSample = HKQuantitySample(...)
    /// let bodyFatSample = HKQuantitySample(...)
    /// try await service.save(samples: [weightSample, bodyFatSample])
    ///
    /// // 여러 운동 기록을 배치 저장
    /// let workouts = [workout1, workout2, workout3]
    /// try await service.save(samples: workouts)
    /// ```
    func save(samples: [HKObject]) async throws {
        // 📚 학습 포인트: Early Return Pattern
        // 빈 배열이면 바로 반환 (불필요한 작업 방지)
        // 💡 Java 비교: Guard Clause Pattern
        guard !samples.isEmpty else {
            return
        }

        // 📚 학습 포인트: Authorization Check for All Samples
        // 모든 샘플의 쓰기 권한을 확인
        // 하나라도 권한이 없으면 전체 저장 취소
        // 💡 Java 비교: Pre-validation before batch operation
        for sample in samples {
            if let sampleType = sample.sampleType {
                let status = healthStore.authorizationStatus(for: sampleType)
                guard status == .sharingAuthorized else {
                    throw HealthKitError.dataTypeNotAuthorized(type: sampleType)
                }
            }
        }

        // 📚 학습 포인트: Batch Save Operation
        // 여러 샘플을 한 번의 API 호출로 저장
        // 💡 Java 비교: JPA의 saveAll()과 유사
        do {
            try await healthStore.save(samples)
        } catch {
            // 배치 저장 실패 시 첫 번째 샘플의 타입 이름 사용
            let typeName = samples.first?.sampleType?.identifier ?? "unknown"
            throw HealthKitError.writeFailed(type: typeName, error: error)
        }
    }

    // MARK: - Delete Methods

    /// HealthKit에서 샘플 삭제 (단일)
    ///
    /// 📚 학습 포인트: Delete Operation
    /// - HealthKit에서 특정 샘플을 삭제
    /// - 앱이 생성한 데이터만 삭제 가능 (다른 앱의 데이터는 삭제 불가)
    /// 💡 Java 비교: Repository의 delete() 메서드와 유사
    ///
    /// - Parameter sample: 삭제할 HKObject
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 삭제 권한이 없음
    ///   - writeFailed: 삭제 실패
    ///
    /// - Note: 삭제는 쓰기 권한이 필요
    ///
    /// - Example:
    /// ```swift
    /// // 잘못 입력한 체중 데이터 삭제
    /// let weightSample = try await readService.fetchLatestWeight()
    /// if let sample = weightSample {
    ///     try await writeService.delete(sample: sample)
    /// }
    /// ```
    func delete(sample: HKObject) async throws {
        // 쓰기 권한 확인 (삭제는 쓰기 권한 필요)
        if let sampleType = sample.sampleType {
            let status = healthStore.authorizationStatus(for: sampleType)
            guard status == .sharingAuthorized else {
                throw HealthKitError.dataTypeNotAuthorized(type: sampleType)
            }
        }

        // 📚 학습 포인트: Delete Operation
        // HKHealthStore.delete()로 샘플 삭제
        // 💡 Java 비교: EntityManager.remove()와 유사
        do {
            try await healthStore.delete(sample)
        } catch {
            let typeName = sample.sampleType?.identifier ?? "unknown"
            throw HealthKitError.writeFailed(type: typeName, error: error)
        }
    }

    /// HealthKit에서 샘플 배치 삭제
    ///
    /// 📚 학습 포인트: Batch Delete
    /// - 여러 샘플을 한 번에 삭제
    /// 💡 Java 비교: deleteAll() 또는 batchDelete()와 유사
    ///
    /// - Parameter samples: 삭제할 HKObject 배열
    ///
    /// - Throws: HealthKitError
    ///   - dataTypeNotAuthorized: 삭제 권한이 없음
    ///   - writeFailed: 삭제 실패
    ///
    /// - Example:
    /// ```swift
    /// // 특정 기간의 데이터를 모두 삭제
    /// let samples = try await readService.fetchWeight(from: startDate, to: endDate)
    /// try await writeService.delete(samples: samples)
    /// ```
    func delete(samples: [HKObject]) async throws {
        // 빈 배열이면 바로 반환
        guard !samples.isEmpty else {
            return
        }

        // 모든 샘플의 쓰기 권한 확인
        for sample in samples {
            if let sampleType = sample.sampleType {
                let status = healthStore.authorizationStatus(for: sampleType)
                guard status == .sharingAuthorized else {
                    throw HealthKitError.dataTypeNotAuthorized(type: sampleType)
                }
            }
        }

        // 배치 삭제
        do {
            try await healthStore.delete(samples)
        } catch {
            let typeName = samples.first?.sampleType?.identifier ?? "unknown"
            throw HealthKitError.writeFailed(type: typeName, error: error)
        }
    }
}

// MARK: - Authorization Check Helpers

extension HealthKitWriteService {

    /// 특정 샘플 타입에 쓰기 권한이 있는지 확인
    ///
    /// 📚 학습 포인트: Permission Validation
    /// - 데이터 저장 전에 권한 확인
    /// - 권한이 없으면 사용자에게 권한 요청 UI 표시
    /// 💡 Java 비교: hasPermission() 메서드
    ///
    /// - Parameter sampleType: 확인할 HKSampleType
    ///
    /// - Returns: 쓰기 권한이 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// if service.canWrite(to: weightType) {
    ///     try await service.save(sample: weightSample)
    /// } else {
    ///     showPermissionRequestView()
    /// }
    /// ```
    func canWrite(to sampleType: HKSampleType) -> Bool {
        return healthStore.authorizationStatus(for: sampleType) == .sharingAuthorized
    }

    /// QuantityType에 쓰기 권한이 있는지 확인 (타입 안전)
    ///
    /// 📚 학습 포인트: Type-Safe Permission Check
    /// - HealthKitDataTypes enum을 사용한 타입 안전한 권한 확인
    /// 💡 Java 비교: Enum-based Permission Check
    ///
    /// - Parameter quantityType: 확인할 QuantityType
    ///
    /// - Returns: 쓰기 권한이 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// if service.canWrite(to: .weight) {
    ///     // 체중 데이터 저장 가능
    /// }
    /// ```
    func canWrite(to quantityType: HealthKitDataTypes.QuantityType) -> Bool {
        guard let type = quantityType.type else {
            return false
        }
        return canWrite(to: type)
    }

    /// Workout 타입에 쓰기 권한이 있는지 확인
    ///
    /// 📚 학습 포인트: Workout Write Permission
    /// - 운동 데이터 저장 가능 여부 확인
    /// 💡 Java 비교: Boolean Permission Check
    ///
    /// - Returns: 운동 데이터 쓰기 권한이 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// if service.canWriteWorkouts {
    ///     try await service.save(sample: workout)
    /// }
    /// ```
    var canWriteWorkouts: Bool {
        return canWrite(to: HealthKitDataTypes.workoutType)
    }
}

// MARK: - Metadata Helper

extension HealthKitWriteService {

    /// Bodii 앱에서 생성한 샘플임을 표시하는 메타데이터 생성
    ///
    /// 📚 학습 포인트: Sample Metadata
    /// - HealthKit 샘플에 메타데이터를 추가하여 출처 추적
    /// - 다른 앱과 구분하기 위한 식별자 포함
    /// 💡 Java 비교: Entity Auditing (createdBy, source 등)
    ///
    /// - Parameters:
    ///   - source: 데이터 출처 (예: "manual_entry", "sync", "import")
    ///   - additionalMetadata: 추가 메타데이터 (선택)
    ///
    /// - Returns: 메타데이터 딕셔너리
    ///
    /// - Note: HealthKit 샘플 생성 시 metadata 파라미터로 전달
    ///
    /// - Example:
    /// ```swift
    /// let metadata = service.createMetadata(source: "manual_entry")
    /// let sample = HKQuantitySample(
    ///     type: weightType,
    ///     quantity: quantity,
    ///     start: date,
    ///     end: date,
    ///     metadata: metadata
    /// )
    /// ```
    func createMetadata(
        source: String = "Bodii",
        additionalMetadata: [String: Any]? = nil
    ) -> [String: Any] {
        // 📚 학습 포인트: HKMetadataKey
        // HealthKit에서 정의한 표준 메타데이터 키 사용
        // 💡 Java 비교: Standard Property Names
        var metadata: [String: Any] = [
            HKMetadataKeySyncIdentifier: "com.bodii.app",
            HKMetadataKeySyncVersion: 1
        ]

        // 데이터 출처 추가 (커스텀 키)
        metadata["BodiiSource"] = source

        // 추가 메타데이터 병합
        if let additional = additionalMetadata {
            metadata.merge(additional) { _, new in new }
        }

        return metadata
    }
}
