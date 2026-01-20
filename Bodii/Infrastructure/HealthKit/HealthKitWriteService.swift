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
        // HKSample로 캐스팅하여 sampleType에 접근 (HKObject에는 sampleType이 없음)
        if let hkSample = sample as? HKSample {
            let status = healthStore.authorizationStatus(for: hkSample.sampleType)
            guard status == .sharingAuthorized else {
                throw HealthKitError.dataTypeNotAuthorized(type: hkSample.sampleType)
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
            let typeName = (sample as? HKSample)?.sampleType.identifier ?? "unknown"
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
            if let hkSample = sample as? HKSample {
                let status = healthStore.authorizationStatus(for: hkSample.sampleType)
                guard status == .sharingAuthorized else {
                    throw HealthKitError.dataTypeNotAuthorized(type: hkSample.sampleType)
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
            let typeName = (samples.first as? HKSample)?.sampleType.identifier ?? "unknown"
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
        // HKSample로 캐스팅하여 sampleType에 접근 (HKObject에는 sampleType이 없음)
        if let hkSample = sample as? HKSample {
            let status = healthStore.authorizationStatus(for: hkSample.sampleType)
            guard status == .sharingAuthorized else {
                throw HealthKitError.dataTypeNotAuthorized(type: hkSample.sampleType)
            }
        }

        // 📚 학습 포인트: Delete Operation
        // HKHealthStore.delete()로 샘플 삭제
        // 💡 Java 비교: EntityManager.remove()와 유사
        do {
            try await healthStore.delete(sample)
        } catch {
            let typeName = (sample as? HKSample)?.sampleType.identifier ?? "unknown"
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
        // HKSample로 캐스팅하여 sampleType에 접근 (HKObject에는 sampleType이 없음)
        for sample in samples {
            if let hkSample = sample as? HKSample {
                let status = healthStore.authorizationStatus(for: hkSample.sampleType)
                guard status == .sharingAuthorized else {
                    throw HealthKitError.dataTypeNotAuthorized(type: hkSample.sampleType)
                }
            }
        }

        // 배치 삭제
        do {
            try await healthStore.delete(samples)
        } catch {
            let typeName = (samples.first as? HKSample)?.sampleType.identifier ?? "unknown"
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

// MARK: - Body Composition Write Methods

extension HealthKitWriteService {

    /// HealthKit에 체중 데이터 저장
    ///
    /// 📚 학습 포인트: Weight Sample Creation
    /// - 사용자가 입력한 체중을 HealthKit에 저장
    /// - HKQuantitySample로 변환하여 저장
    /// - Bodii 출처 메타데이터 포함
    /// 💡 Java 비교: Repository의 save() 메서드와 유사
    ///
    /// - Parameters:
    ///   - kg: 체중 (킬로그램 단위)
    ///   - date: 측정 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 체중 타입 생성 실패
    ///   - dataTypeNotAuthorized: 체중 쓰기 권한 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note: BodyRecord 저장 후 HealthKit 동기화에 사용
    ///
    /// - Example:
    /// ```swift
    /// // 사용자가 체중을 입력한 후
    /// let bodyRecord = BodyRecord(weight: 70.5, ...)
    /// try await bodyRepository.save(bodyRecord)
    ///
    /// // HealthKit에 동기화
    /// try await healthKitWriteService.saveWeight(
    ///     kg: bodyRecord.weight,
    ///     date: bodyRecord.date
    /// )
    /// ```
    func saveWeight(
        kg weight: Decimal,
        date: Date = Date(),
        metadata: [String: Any]? = nil
    ) async throws {
        // 📚 학습 포인트: HKQuantityType 가져오기
        // HealthKitDataTypes를 사용한 타입 안전한 접근
        // 💡 Java 비교: Enum-based Type Access
        guard let weightType = HealthKitDataTypes.QuantityType.weight.type else {
            throw HealthKitError.invalidSampleType(identifier: "bodyMass")
        }

        // 📚 학습 포인트: Decimal to Double 변환
        // Swift의 Decimal을 HKQuantity가 요구하는 Double로 변환
        // 💡 Java 비교: BigDecimal.doubleValue()와 유사
        let weightValue = NSDecimalNumber(decimal: weight).doubleValue

        // 📚 학습 포인트: HKQuantity 생성
        // 체중 수치와 단위(kg)를 조합하여 HealthKit 수량 객체 생성
        // 💡 Java 비교: Value Object 생성
        let quantity = HKQuantity(
            unit: HealthKitDataTypes.QuantityType.weight.unit, // kg
            doubleValue: weightValue
        )

        // 📚 학습 포인트: Metadata 생성
        // Bodii 출처 정보를 포함한 메타데이터 생성
        // 💡 Java 비교: @CreatedBy Auditing
        let sampleMetadata = createMetadata(
            source: "manual_entry",
            additionalMetadata: metadata
        )

        // 📚 학습 포인트: HKQuantitySample 생성
        // 체중 샘플 객체 생성 (타입, 수량, 시간, 메타데이터)
        // 💡 Java 비교: Entity 객체 생성
        let sample = HKQuantitySample(
            type: weightType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: sampleMetadata
        )

        // 📚 학습 포인트: Generic Save 메서드 재사용
        // 이미 구현된 save(sample:)를 사용하여 코드 중복 방지
        // 💡 Java 비교: Template Method Pattern
        try await save(sample: sample)
    }

    /// HealthKit에 체지방률 데이터 저장
    ///
    /// 📚 학습 포인트: Body Fat Percentage Sample Creation
    /// - 사용자가 입력한 체지방률을 HealthKit에 저장
    /// - HKQuantitySample로 변환하여 저장
    /// - Bodii 출처 메타데이터 포함
    /// 💡 Java 비교: Repository의 save() 메서드와 유사
    ///
    /// - Parameters:
    ///   - percent: 체지방률 (0-100 범위의 퍼센트)
    ///   - date: 측정 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 체지방률 타입 생성 실패
    ///   - dataTypeNotAuthorized: 체지방률 쓰기 권한 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note:
    ///   - HealthKit은 체지방률을 0-1 범위로 저장 (0.185 = 18.5%)
    ///   - Bodii는 0-100 범위로 관리하므로 변환 필요
    ///   - BodyRecord 저장 후 HealthKit 동기화에 사용
    ///
    /// - Example:
    /// ```swift
    /// // 사용자가 체지방률을 입력한 후
    /// let bodyRecord = BodyRecord(weight: 70.5, bodyFatPercent: 18.5, ...)
    /// try await bodyRepository.save(bodyRecord)
    ///
    /// // HealthKit에 동기화
    /// if let bodyFatPercent = bodyRecord.bodyFatPercent {
    ///     try await healthKitWriteService.saveBodyFatPercentage(
    ///         percent: bodyFatPercent,
    ///         date: bodyRecord.date
    ///     )
    /// }
    /// ```
    func saveBodyFatPercentage(
        percent: Decimal,
        date: Date = Date(),
        metadata: [String: Any]? = nil
    ) async throws {
        // 📚 학습 포인트: HKQuantityType 가져오기
        // HealthKitDataTypes를 사용한 타입 안전한 접근
        // 💡 Java 비교: Enum-based Type Access
        guard let bodyFatType = HealthKitDataTypes.QuantityType.bodyFatPercentage.type else {
            throw HealthKitError.invalidSampleType(identifier: "bodyFatPercentage")
        }

        // 📚 학습 포인트: Percentage 단위 변환
        // Bodii: 0-100 범위 (18.5% = 18.5)
        // HealthKit: 0-1 범위 (18.5% = 0.185)
        // 💡 Java 비교: Unit Conversion
        let percentValue = NSDecimalNumber(decimal: percent).doubleValue / 100.0

        // 📚 학습 포인트: HKQuantity 생성
        // 체지방률 수치와 단위(percent)를 조합하여 HealthKit 수량 객체 생성
        // 💡 Java 비교: Value Object 생성
        let quantity = HKQuantity(
            unit: HealthKitDataTypes.QuantityType.bodyFatPercentage.unit, // percent
            doubleValue: percentValue
        )

        // 📚 학습 포인트: Metadata 생성
        // Bodii 출처 정보를 포함한 메타데이터 생성
        // 💡 Java 비교: @CreatedBy Auditing
        let sampleMetadata = createMetadata(
            source: "manual_entry",
            additionalMetadata: metadata
        )

        // 📚 학습 포인트: HKQuantitySample 생성
        // 체지방률 샘플 객체 생성 (타입, 수량, 시간, 메타데이터)
        // 💡 Java 비교: Entity 객체 생성
        let sample = HKQuantitySample(
            type: bodyFatType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: sampleMetadata
        )

        // 📚 학습 포인트: Generic Save 메서드 재사용
        // 이미 구현된 save(sample:)를 사용하여 코드 중복 방지
        // 💡 Java 비교: Template Method Pattern
        try await save(sample: sample)
    }

    /// HealthKit에 체중과 체지방률을 동시에 저장
    ///
    /// 📚 학습 포인트: Batch Body Composition Save
    /// - 체중과 체지방률을 한 번에 저장하여 성능 향상
    /// - 같은 시간에 측정된 데이터로 저장
    /// - 트랜잭션 단위로 처리되어 전체 성공 또는 전체 실패
    /// 💡 Java 비교: Batch Insert Operation
    ///
    /// - Parameters:
    ///   - kg: 체중 (킬로그램 단위)
    ///   - percent: 체지방률 (0-100 범위의 퍼센트, 선택)
    ///   - date: 측정 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 타입 생성 실패
    ///   - dataTypeNotAuthorized: 쓰기 권한 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note:
    ///   - 체중은 필수, 체지방률은 선택 (nil 가능)
    ///   - 배치 저장으로 네트워크 호출 최소화
    ///   - BodyRecord 저장 후 HealthKit 동기화에 사용
    ///
    /// - Example:
    /// ```swift
    /// // 사용자가 체성분을 입력한 후
    /// let bodyRecord = BodyRecord(weight: 70.5, bodyFatPercent: 18.5, ...)
    /// try await bodyRepository.save(bodyRecord)
    ///
    /// // HealthKit에 동시 저장
    /// try await healthKitWriteService.saveBodyComposition(
    ///     kg: bodyRecord.weight,
    ///     percent: bodyRecord.bodyFatPercent,
    ///     date: bodyRecord.date
    /// )
    /// ```
    func saveBodyComposition(
        kg weight: Decimal,
        percent bodyFatPercent: Decimal? = nil,
        date: Date = Date(),
        metadata: [String: Any]? = nil
    ) async throws {
        var samples: [HKObject] = []

        // 📚 학습 포인트: Weight Sample 생성
        // 체중 샘플은 필수이므로 항상 생성
        // 💡 Java 비교: Required Field
        guard let weightType = HealthKitDataTypes.QuantityType.weight.type else {
            throw HealthKitError.invalidSampleType(identifier: "bodyMass")
        }

        let weightValue = NSDecimalNumber(decimal: weight).doubleValue
        let weightQuantity = HKQuantity(
            unit: HealthKitDataTypes.QuantityType.weight.unit,
            doubleValue: weightValue
        )

        let sampleMetadata = createMetadata(
            source: "manual_entry",
            additionalMetadata: metadata
        )

        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date,
            metadata: sampleMetadata
        )
        samples.append(weightSample)

        // 📚 학습 포인트: Optional Body Fat Sample 생성
        // 체지방률은 선택 사항이므로 nil 체크 후 생성
        // 💡 Java 비교: Optional Field Processing
        if let bodyFatPercent = bodyFatPercent {
            guard let bodyFatType = HealthKitDataTypes.QuantityType.bodyFatPercentage.type else {
                throw HealthKitError.invalidSampleType(identifier: "bodyFatPercentage")
            }

            let percentValue = NSDecimalNumber(decimal: bodyFatPercent).doubleValue / 100.0
            let bodyFatQuantity = HKQuantity(
                unit: HealthKitDataTypes.QuantityType.bodyFatPercentage.unit,
                doubleValue: percentValue
            )

            let bodyFatSample = HKQuantitySample(
                type: bodyFatType,
                quantity: bodyFatQuantity,
                start: date,
                end: date,
                metadata: sampleMetadata
            )
            samples.append(bodyFatSample)
        }

        // 📚 학습 포인트: Batch Save
        // 여러 샘플을 한 번에 저장하여 성능 향상
        // 💡 Java 비교: saveAll() 메서드
        try await save(samples: samples)
    }
}

// MARK: - Workout Write Methods

extension HealthKitWriteService {

    /// HealthKit에 운동 데이터 저장
    ///
    /// 📚 학습 포인트: HKWorkout Creation
    /// - 사용자가 입력한 운동 기록을 HealthKit에 저장
    /// - HKWorkout으로 변환하여 저장
    /// - ExerciseType을 HKWorkoutActivityType으로 매핑
    /// - Bodii 출처 메타데이터 포함
    /// 💡 Java 비교: Repository의 save() 메서드와 유사
    ///
    /// - Parameters:
    ///   - exerciseType: 운동 종류 (ExerciseType enum)
    ///   - duration: 운동 시간 (분 단위)
    ///   - caloriesBurned: 소모 칼로리 (kcal)
    ///   - intensity: 운동 강도 (저/중/고)
    ///   - startDate: 운동 시작 일시
    ///   - metadata: 추가 메타데이터 (선택)
    ///
    /// - Throws: HealthKitError
    ///   - unsupportedWorkoutType: 지원하지 않는 운동 종류
    ///   - dataTypeNotAuthorized: 운동 쓰기 권한 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note: ExerciseRecord 저장 후 HealthKit 동기화에 사용
    ///
    /// - Example:
    /// ```swift
    /// // 사용자가 운동을 기록한 후
    /// let exerciseRecord = ExerciseRecord(
    ///     exerciseType: .running,
    ///     duration: 30,
    ///     intensity: .high,
    ///     caloriesBurned: 350
    /// )
    /// try await exerciseRepository.save(exerciseRecord)
    ///
    /// // HealthKit에 동기화
    /// try await healthKitWriteService.saveWorkout(
    ///     exerciseType: exerciseRecord.exerciseType,
    ///     duration: exerciseRecord.duration,
    ///     caloriesBurned: exerciseRecord.caloriesBurned,
    ///     intensity: exerciseRecord.intensity,
    ///     startDate: exerciseRecord.date
    /// )
    /// ```
    func saveWorkout(
        exerciseType: ExerciseType,
        duration: Int32,
        caloriesBurned: Int32,
        intensity: Intensity,
        startDate: Date,
        metadata: [String: Any]? = nil
    ) async throws {
        // 📚 학습 포인트: ExerciseType to HKWorkoutActivityType 매핑
        // 앱의 운동 종류를 HealthKit의 운동 종류로 변환
        // 💡 Java 비교: Enum Mapping
        let activityType = mapExerciseTypeToWorkoutActivityType(exerciseType)

        // 📚 학습 포인트: Duration Conversion
        // 분 단위 → 초 단위 (TimeInterval)
        // HKWorkout.duration은 TimeInterval (초 단위)
        // 💡 Java 비교: Duration.ofMinutes().toSeconds()와 유사
        let durationInSeconds = TimeInterval(duration * 60)

        // 📚 학습 포인트: Date Range Calculation
        // 운동 시작 시간과 종료 시간 계산
        // 💡 Java 비교: LocalDateTime.plusMinutes()와 유사
        let endDate = startDate.addingTimeInterval(durationInSeconds)

        // 📚 학습 포인트: HKQuantity for Calories
        // 소모 칼로리를 HKQuantity로 변환
        // 💡 Java 비교: Value Object 생성
        let caloriesQuantity = HKQuantity(
            unit: .kilocalorie(),
            doubleValue: Double(caloriesBurned)
        )

        // 📚 학습 포인트: Metadata 생성
        // Bodii 출처 정보와 운동 강도를 포함한 메타데이터 생성
        // 💡 Java 비교: @CreatedBy Auditing
        var workoutMetadata = createMetadata(
            source: "manual_entry",
            additionalMetadata: metadata
        )

        // 운동 강도 정보를 메타데이터에 추가 (HealthKit에는 강도 필드가 없음)
        // 추후 읽기 시 강도 정보를 복원하기 위해 저장
        workoutMetadata["BodiiIntensity"] = intensity.rawValue

        // 📚 학습 포인트: HKWorkout 생성
        // 운동 객체 생성 (타입, 시작/종료 시간, 시간, 칼로리, 메타데이터)
        // 💡 Java 비교: Entity 객체 생성
        let workout = HKWorkout(
            activityType: activityType,
            start: startDate,
            end: endDate,
            duration: durationInSeconds,
            totalEnergyBurned: caloriesQuantity,
            totalDistance: nil,  // 거리 데이터는 별도 처리 (추후 확장 가능)
            metadata: workoutMetadata
        )

        // 📚 학습 포인트: Generic Save 메서드 재사용
        // 이미 구현된 save(sample:)를 사용하여 코드 중복 방지
        // 💡 Java 비교: Template Method Pattern
        try await save(sample: workout)
    }

    /// ExerciseType을 HKWorkoutActivityType으로 변환
    ///
    /// 📚 학습 포인트: Reverse Exercise Type Mapping
    /// - 앱의 8가지 운동 종류를 HealthKit의 운동 종류로 매핑
    /// - HealthKitReadService의 mapWorkoutActivityType과 반대 방향 매핑
    /// 💡 Java 비교: Enum to Enum Mapping Utility
    ///
    /// - Parameter exerciseType: 앱의 운동 종류
    ///
    /// - Returns: HealthKit 운동 종류
    ///
    /// - Note: 매핑 규칙
    ///   - .walking -> .walking
    ///   - .running -> .running
    ///   - .cycling -> .cycling
    ///   - .swimming -> .swimming
    ///   - .weight -> .traditionalStrengthTraining
    ///   - .crossfit -> .crossTraining
    ///   - .yoga -> .yoga
    ///   - .other -> .other
    ///
    /// - Example:
    /// ```swift
    /// let activityType1 = mapExerciseTypeToWorkoutActivityType(.running)
    /// // HKWorkoutActivityType.running
    ///
    /// let activityType2 = mapExerciseTypeToWorkoutActivityType(.weight)
    /// // HKWorkoutActivityType.traditionalStrengthTraining
    /// ```
    private func mapExerciseTypeToWorkoutActivityType(
        _ exerciseType: ExerciseType
    ) -> HKWorkoutActivityType {
        // 📚 학습 포인트: Exercise Type to HealthKit Mapping
        // 앱의 운동 카테고리를 HealthKit의 대표 운동 종류로 매핑
        // 💡 Java 비교: switch-case mapping과 유사
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
            // 📚 학습 포인트: Strength Training Mapping
            // 웨이트 운동은 HealthKit의 traditionalStrengthTraining으로 매핑
            // 💡 Java 비교: Specific Type Selection
            return .traditionalStrengthTraining
        case .crossfit:
            // 📚 학습 포인트: Cross Training Mapping
            // 크로스핏은 HealthKit의 crossTraining으로 매핑
            // 💡 Java 비교: Specific Type Selection
            return .crossTraining
        case .yoga:
            return .yoga
        case .other:
            return .other
        }
    }
}

// MARK: - Dietary Energy Write Methods

extension HealthKitWriteService {

    /// HealthKit에 섭취 칼로리 데이터 저장
    ///
    /// 📚 학습 포인트: Dietary Energy Sample Creation
    /// - 사용자가 입력한 식단(섭취 칼로리)을 HealthKit에 저장
    /// - HKQuantitySample로 변환하여 저장
    /// - 개별 식사 또는 일일 총량으로 저장 가능
    /// - Bodii 출처 메타데이터 포함
    /// 💡 Java 비교: Repository의 save() 메서드와 유사
    ///
    /// - Parameters:
    ///   - calories: 섭취 칼로리 (kcal 단위)
    ///   - date: 식사 일시 (기본값: 현재 시각)
    ///   - metadata: 추가 메타데이터 (선택, 예: 식사 종류 "breakfast", "lunch", "dinner")
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 섭취 칼로리 타입 생성 실패
    ///   - dataTypeNotAuthorized: 섭취 칼로리 쓰기 권한 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note:
    ///   - 개별 식사별로 저장하면 HealthKit이 자동으로 일일 합계 계산
    ///   - 하루 총 섭취량을 저장할 경우 date를 해당 날짜의 특정 시간으로 설정
    ///   - FoodRecord 저장 후 HealthKit 동기화에 사용
    ///
    /// - Example:
    /// ```swift
    /// // 개별 식사 저장 (아침 식사)
    /// try await healthKitWriteService.saveDietaryEnergy(
    ///     calories: 450.5,
    ///     date: breakfastTime,
    ///     metadata: ["meal_type": "breakfast"]
    /// )
    ///
    /// // 점심 식사
    /// try await healthKitWriteService.saveDietaryEnergy(
    ///     calories: 680.0,
    ///     date: lunchTime,
    ///     metadata: ["meal_type": "lunch"]
    /// )
    ///
    /// // 일일 총 섭취량 저장
    /// try await healthKitWriteService.saveDietaryEnergy(
    ///     calories: 1850.0,
    ///     date: Date()
    /// )
    /// ```
    func saveDietaryEnergy(
        calories: Decimal,
        date: Date = Date(),
        metadata: [String: Any]? = nil
    ) async throws {
        // 📚 학습 포인트: HKQuantityType 가져오기
        // HealthKitDataTypes를 사용한 타입 안전한 접근
        // 💡 Java 비교: Enum-based Type Access
        guard let dietaryType = HealthKitDataTypes.QuantityType.dietaryEnergyConsumed.type else {
            throw HealthKitError.invalidSampleType(identifier: "dietaryEnergyConsumed")
        }

        // 📚 학습 포인트: Decimal to Double 변환
        // Swift의 Decimal을 HKQuantity가 요구하는 Double로 변환
        // 💡 Java 비교: BigDecimal.doubleValue()와 유사
        let caloriesValue = NSDecimalNumber(decimal: calories).doubleValue

        // 📚 학습 포인트: HKQuantity 생성
        // 섭취 칼로리 수치와 단위(kcal)를 조합하여 HealthKit 수량 객체 생성
        // 💡 Java 비교: Value Object 생성
        let quantity = HKQuantity(
            unit: HealthKitDataTypes.QuantityType.dietaryEnergyConsumed.unit, // kcal
            doubleValue: caloriesValue
        )

        // 📚 학습 포인트: Metadata 생성
        // Bodii 출처 정보를 포함한 메타데이터 생성
        // 식사 종류 등 추가 정보 포함 가능
        // 💡 Java 비교: @CreatedBy Auditing
        let sampleMetadata = createMetadata(
            source: "manual_entry",
            additionalMetadata: metadata
        )

        // 📚 학습 포인트: HKQuantitySample 생성
        // 섭취 칼로리 샘플 객체 생성 (타입, 수량, 시간, 메타데이터)
        // 💡 Java 비교: Entity 객체 생성
        let sample = HKQuantitySample(
            type: dietaryType,
            quantity: quantity,
            start: date,
            end: date,
            metadata: sampleMetadata
        )

        // 📚 학습 포인트: Generic Save 메서드 재사용
        // 이미 구현된 save(sample:)를 사용하여 코드 중복 방지
        // 💡 Java 비교: Template Method Pattern
        try await save(sample: sample)
    }

    /// HealthKit에 여러 식사의 섭취 칼로리를 배치 저장
    ///
    /// 📚 학습 포인트: Batch Dietary Energy Save
    /// - 하루 동안의 여러 식사를 한 번에 저장하여 성능 향상
    /// - 각 식사는 개별 시간대를 가짐
    /// - 트랜잭션 단위로 처리되어 전체 성공 또는 전체 실패
    /// 💡 Java 비교: Batch Insert Operation
    ///
    /// - Parameter meals: 식사 정보 배열 (칼로리, 시간, 메타데이터)
    ///
    /// - Throws: HealthKitError
    ///   - invalidSampleType: 타입 생성 실패
    ///   - dataTypeNotAuthorized: 쓰기 권한 없음
    ///   - writeFailed: 저장 실패
    ///
    /// - Note:
    ///   - 배치 저장으로 네트워크 호출 최소화
    ///   - HealthKit이 자동으로 일일 합계 계산
    ///   - FoodRecord들을 한 번에 HealthKit에 동기화할 때 사용
    ///
    /// - Example:
    /// ```swift
    /// let meals: [(calories: Decimal, date: Date, metadata: [String: Any]?)] = [
    ///     (450.5, breakfastTime, ["meal_type": "breakfast"]),
    ///     (680.0, lunchTime, ["meal_type": "lunch"]),
    ///     (720.5, dinnerTime, ["meal_type": "dinner"])
    /// ]
    /// try await healthKitWriteService.saveDietaryEnergyBatch(meals: meals)
    /// ```
    func saveDietaryEnergyBatch(
        meals: [(calories: Decimal, date: Date, metadata: [String: Any]?)]
    ) async throws {
        // 📚 학습 포인트: Early Return Pattern
        // 빈 배열이면 바로 반환 (불필요한 작업 방지)
        // 💡 Java 비교: Guard Clause Pattern
        guard !meals.isEmpty else {
            return
        }

        // 📚 학습 포인트: HKQuantityType 가져오기
        guard let dietaryType = HealthKitDataTypes.QuantityType.dietaryEnergyConsumed.type else {
            throw HealthKitError.invalidSampleType(identifier: "dietaryEnergyConsumed")
        }

        var samples: [HKObject] = []

        // 📚 학습 포인트: Sample Array Creation
        // 각 식사를 HKQuantitySample로 변환
        // 💡 Java 비교: Stream.map().collect()와 유사
        for meal in meals {
            let caloriesValue = NSDecimalNumber(decimal: meal.calories).doubleValue
            let quantity = HKQuantity(
                unit: HealthKitDataTypes.QuantityType.dietaryEnergyConsumed.unit,
                doubleValue: caloriesValue
            )

            let sampleMetadata = createMetadata(
                source: "manual_entry",
                additionalMetadata: meal.metadata
            )

            let sample = HKQuantitySample(
                type: dietaryType,
                quantity: quantity,
                start: meal.date,
                end: meal.date,
                metadata: sampleMetadata
            )
            samples.append(sample)
        }

        // 📚 학습 포인트: Batch Save
        // 여러 샘플을 한 번에 저장하여 성능 향상
        // 💡 Java 비교: saveAll() 메서드
        try await save(samples: samples)
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
