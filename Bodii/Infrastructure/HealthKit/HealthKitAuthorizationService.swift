//
//  HealthKitAuthorizationService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Authorization Service
// HealthKit 권한 요청 및 상태 확인을 담당하는 서비스
// 💡 Java 비교: Permission Manager와 유사하지만 비동기 처리

import Foundation
import HealthKit

/// HealthKit authorization service
///
/// HealthKit 권한 요청 및 권한 상태 확인을 담당하는 서비스
///
/// 📚 학습 포인트: Authorization Management
/// - HKHealthStore를 통한 권한 요청
/// - 읽기/쓰기 권한 분리 관리
/// - 기기 HealthKit 지원 여부 확인
/// 💡 Java 비교: PermissionManager + AuthorizationService 조합
///
/// ## 책임
/// - HealthKit 사용 가능 여부 확인
/// - 읽기/쓰기 권한 요청
/// - 권한 상태 조회
///
/// ## 사용 시나리오
/// 1. **최초 권한 요청**: 설정 화면에서 HealthKit 활성화 시
/// 2. **권한 상태 확인**: 데이터 읽기/쓰기 전에 권한 확인
/// 3. **재요청**: 사용자가 권한 거부 후 다시 허용할 때
///
/// - Example:
/// ```swift
/// let service = HealthKitAuthorizationService()
///
/// // HealthKit 사용 가능 여부 확인
/// guard service.isHealthDataAvailable() else {
///     throw HealthKitError.healthKitNotAvailable
/// }
///
/// // 권한 요청
/// try await service.requestAuthorization()
///
/// // 특정 타입 권한 확인
/// let status = service.getAuthorizationStatus(for: weightType)
/// ```
final class HealthKitAuthorizationService {

    // MARK: - Properties

    /// HealthKit 데이터 저장소
    ///
    /// 📚 학습 포인트: HKHealthStore
    /// - HealthKit 데이터에 접근하기 위한 중앙 객체
    /// - 권한 요청, 데이터 읽기/쓰기, 쿼리 실행 담당
    /// 💡 Java 비교: EntityManager와 유사한 역할
    ///
    /// - Note: iPad에서는 HKHealthStore를 사용할 수 없음
    private let healthStore: HKHealthStore

    // MARK: - Initialization

    /// HealthKitAuthorizationService 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// - HKHealthStore를 외부에서 주입받아 테스트 가능하게 설계
    /// - 기본값으로 새 HKHealthStore 인스턴스 사용
    /// 💡 Java 비교: Constructor Injection
    ///
    /// - Parameter healthStore: HealthKit 데이터 저장소 (기본값: 새 인스턴스)
    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    // MARK: - Availability Check

    /// HealthKit 사용 가능 여부 확인
    ///
    /// 📚 학습 포인트: Device Capability Check
    /// - iPad는 HealthKit을 지원하지 않음
    /// - 권한 요청 전에 반드시 확인 필요
    /// 💡 Java 비교: Feature Availability Check
    ///
    /// - Returns: HealthKit을 사용할 수 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// if service.isHealthDataAvailable() {
    ///     try await service.requestAuthorization()
    /// } else {
    ///     showAlert("이 기기에서는 Apple Health를 사용할 수 없습니다")
    /// }
    /// ```
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization Request

    /// HealthKit 권한 요청
    ///
    /// 📚 학습 포인트: Permission Request
    /// - 읽기 권한과 쓰기 권한을 동시에 요청
    /// - iOS가 시스템 권한 다이얼로그 표시
    /// - 사용자가 개별 데이터 타입별로 허용/거부 선택
    /// 💡 Java 비교: Runtime Permission Request (Android)
    ///
    /// **요청하는 읽기 권한:**
    /// - 체중 (bodyMass)
    /// - 체지방률 (bodyFatPercentage)
    /// - 활동 칼로리 (activeEnergyBurned)
    /// - 걸음 수 (stepCount)
    /// - 수면 분석 (sleepAnalysis)
    /// - 운동 (workout)
    ///
    /// **요청하는 쓰기 권한:**
    /// - 체중 (bodyMass)
    /// - 체지방률 (bodyFatPercentage)
    /// - 섭취 칼로리 (dietaryEnergyConsumed)
    /// - 운동 (workout)
    ///
    /// - Throws: HealthKitError
    ///   - healthKitNotAvailable: 기기에서 HealthKit 사용 불가
    ///   - authorizationFailed: 권한 요청 과정에서 에러 발생
    ///
    /// - Note: 읽기 권한 거부 여부는 프라이버시 보호를 위해 확인 불가
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     try await service.requestAuthorization()
    ///     print("HealthKit 권한 요청 완료")
    /// } catch HealthKitError.healthKitNotAvailable {
    ///     print("이 기기에서는 HealthKit을 사용할 수 없습니다")
    /// } catch {
    ///     print("권한 요청 실패: \(error)")
    /// }
    /// ```
    func requestAuthorization() async throws {
        // 📚 학습 포인트: Precondition Check
        // 권한 요청 전에 HealthKit 사용 가능 여부 확인
        guard isHealthDataAvailable() else {
            throw HealthKitError.healthKitNotAvailable
        }

        // HealthKitDataTypes에서 읽기/쓰기 타입 가져오기
        let readTypes = HealthKitDataTypes.readTypes
        let writeTypes = HealthKitDataTypes.writeTypes

        do {
            // 📚 학습 포인트: Async/Await Authorization
            // iOS 15+에서는 async/await 지원
            // withCheckedThrowingContinuation으로 콜백을 async/await로 변환
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                    if let error = error {
                        // 권한 요청 중 에러 발생
                        continuation.resume(throwing: HealthKitError.authorizationFailed(error))
                    } else {
                        // 권한 요청 완료 (success가 false여도 에러는 아님)
                        // 사용자가 일부만 허용해도 success는 true
                        continuation.resume(returning: ())
                    }
                }
            }
        } catch let error as HealthKitError {
            // 이미 HealthKitError로 변환된 에러는 그대로 throw
            throw error
        } catch {
            // 예상치 못한 에러는 authorizationFailed로 래핑
            throw HealthKitError.authorizationFailed(error)
        }
    }

    // MARK: - Authorization Status Check

    /// 특정 데이터 타입에 대한 권한 상태 조회
    ///
    /// 📚 학습 포인트: Authorization Status
    /// - HKAuthorizationStatus: notDetermined, sharingDenied, sharingAuthorized
    /// - 쓰기 권한은 상태 확인 가능
    /// - 읽기 권한은 프라이버시 보호를 위해 확인 불가 (항상 notDetermined 반환 가능)
    /// 💡 Java 비교: Permission Status Check
    ///
    /// - Parameter type: 확인할 HKObjectType (HKQuantityType, HKCategoryType, HKWorkoutType 등)
    ///
    /// - Returns: HKAuthorizationStatus
    ///   - notDetermined: 아직 권한 요청하지 않음
    ///   - sharingDenied: 사용자가 권한 거부함 (쓰기만 확인 가능)
    ///   - sharingAuthorized: 사용자가 권한 허용함 (쓰기만 확인 가능)
    ///
    /// - Note: 읽기 권한 상태는 프라이버시 이슈로 정확히 확인 불가
    ///
    /// - Example:
    /// ```swift
    /// guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
    ///     return
    /// }
    ///
    /// let status = service.getAuthorizationStatus(for: weightType)
    /// switch status {
    /// case .notDetermined:
    ///     print("아직 권한 요청하지 않음")
    /// case .sharingDenied:
    ///     print("사용자가 권한 거부함")
    /// case .sharingAuthorized:
    ///     print("사용자가 권한 허용함")
    /// @unknown default:
    ///     print("알 수 없는 상태")
    /// }
    /// ```
    func getAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }

    /// 특정 데이터 타입에 쓰기 권한이 있는지 확인
    ///
    /// 📚 학습 포인트: Write Permission Check
    /// - 데이터 저장 전에 쓰기 권한 확인
    /// - sharingAuthorized인 경우만 true 반환
    /// 💡 Java 비교: hasPermission() 메서드
    ///
    /// - Parameter type: 확인할 HKSampleType
    ///
    /// - Returns: 쓰기 권한이 있으면 true
    ///
    /// - Example:
    /// ```swift
    /// guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
    ///     return
    /// }
    ///
    /// if service.canWrite(to: weightType) {
    ///     // 체중 데이터 저장 가능
    ///     try await writeService.saveWeight(kg: 70.5, date: Date())
    /// } else {
    ///     print("체중 저장 권한이 없습니다")
    /// }
    /// ```
    func canWrite(to type: HKSampleType) -> Bool {
        return healthStore.authorizationStatus(for: type) == .sharingAuthorized
    }

    /// 모든 쓰기 타입에 대한 권한이 있는지 확인
    ///
    /// 📚 학습 포인트: Bulk Permission Check
    /// - 앱에서 필요한 모든 쓰기 권한이 허용되었는지 확인
    /// - 하나라도 거부되면 false 반환
    /// 💡 Java 비교: allMatch() predicate
    ///
    /// - Returns: 모든 쓰기 권한이 허용되었으면 true
    ///
    /// - Example:
    /// ```swift
    /// if service.isFullyAuthorized {
    ///     print("모든 HealthKit 권한 허용됨")
    /// } else {
    ///     print("일부 권한이 거부되었거나 아직 요청하지 않음")
    ///     // 권한 재요청 UI 표시
    /// }
    /// ```
    var isFullyAuthorized: Bool {
        let writeTypes = HealthKitDataTypes.writeTypes

        // 📚 학습 포인트: allSatisfy
        // 모든 요소가 조건을 만족하는지 확인
        // 💡 Java 비교: Stream.allMatch()
        return writeTypes.allSatisfy { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }
    }
}

// MARK: - HealthStore Access

extension HealthKitAuthorizationService {

    /// HKHealthStore 인스턴스 반환
    ///
    /// 📚 학습 포인트: Internal API
    /// - Read/Write 서비스에서 동일한 HKHealthStore 사용하기 위해 제공
    /// - internal 접근 제어로 모듈 내부에서만 접근 가능
    /// 💡 Java 비교: package-private getter
    ///
    /// - Returns: HKHealthStore 인스턴스
    ///
    /// - Note: Read/Write 서비스는 이 메서드로 healthStore를 공유받아 사용
    ///
    /// - Example:
    /// ```swift
    /// let authService = HealthKitAuthorizationService()
    /// let readService = HealthKitReadService(healthStore: authService.getHealthStore())
    /// let writeService = HealthKitWriteService(healthStore: authService.getHealthStore())
    /// ```
    func getHealthStore() -> HKHealthStore {
        return healthStore
    }
}
