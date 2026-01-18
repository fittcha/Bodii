//
//  HealthKitError.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: HealthKit Error Handling
// HealthKit 연동에서 발생할 수 있는 다양한 에러를 열거형으로 정의
// 💡 Java 비교: Exception 클래스 대신 타입 안전한 enum 사용

import Foundation
import HealthKit

/// HealthKit operation errors
///
/// HealthKit 작업에서 발생할 수 있는 에러 타입
///
/// 📚 학습 포인트: Error Protocol
/// Swift에서는 Error 프로토콜을 채택하면 throw/catch로 에러 처리 가능
/// 💡 Java 비교: Exception 대신 Error 프로토콜 + enum 사용
///
/// - Cases:
///   - healthKitNotAvailable: 기기에서 HealthKit을 사용할 수 없음
///   - authorizationDenied: 사용자가 권한 요청을 거부함
///   - authorizationFailed: 권한 요청 과정에서 에러 발생
///   - dataTypeNotAuthorized: 특정 데이터 타입에 대한 권한이 없음
///   - dataUnavailable: 요청한 데이터가 존재하지 않음
///   - readFailed: 데이터 읽기 실패
///   - writeFailed: 데이터 쓰기 실패
///   - backgroundSyncFailed: 백그라운드 동기화 실패
///   - queryExecutionFailed: HealthKit 쿼리 실행 실패
///   - invalidSampleType: 유효하지 않은 샘플 타입
///   - invalidDateRange: 유효하지 않은 날짜 범위
///   - duplicateEntry: 중복된 데이터 항목
///   - mappingFailed: 데이터 변환 실패
///   - unknown: 알 수 없는 에러
///
/// - Example:
/// ```swift
/// do {
///     let weight = try await healthKitService.fetchLatestWeight()
/// } catch HealthKitError.authorizationDenied(let type) {
///     print("권한이 거부되었습니다: \(type)")
/// } catch HealthKitError.dataUnavailable {
///     print("데이터가 없습니다")
/// }
/// ```
enum HealthKitError: Error {

    // MARK: - Authorization Errors

    /// HealthKit을 사용할 수 없음
    ///
    /// 기기에서 HealthKit이 지원되지 않거나 활성화되지 않은 경우
    ///
    /// - Note: iPad에서는 HealthKit을 사용할 수 없음
    ///
    /// - Example:
    /// ```swift
    /// guard HKHealthStore.isHealthDataAvailable() else {
    ///     throw HealthKitError.healthKitNotAvailable
    /// }
    /// ```
    case healthKitNotAvailable

    /// 사용자가 권한 요청을 거부함
    ///
    /// 📚 학습 포인트: User Authorization
    /// HealthKit은 민감한 건강 데이터이므로 사용자의 명시적 동의가 필요
    /// 💡 Java 비교: SecurityException과 유사
    ///
    /// - Parameter dataType: 거부된 데이터 타입 (예: "체중", "체지방률")
    ///
    /// - Note: 설정 앱에서 권한을 다시 요청할 수 있음
    ///
    /// - Example:
    /// ```swift
    /// throw HealthKitError.authorizationDenied(dataType: "체중")
    /// ```
    case authorizationDenied(dataType: String)

    /// 권한 요청 과정에서 에러 발생
    ///
    /// requestAuthorization() 호출 중 예상치 못한 에러 발생
    ///
    /// - Parameter error: 원본 에러
    case authorizationFailed(Error)

    /// 특정 데이터 타입에 대한 권한이 없음
    ///
    /// 📚 학습 포인트: Granular Permissions
    /// HealthKit은 데이터 타입별로 읽기/쓰기 권한을 개별 설정 가능
    /// 💡 Java 비교: PermissionDeniedException
    ///
    /// - Parameter type: 권한이 없는 HKObjectType
    ///
    /// - Note: 읽기 권한은 사용자가 거부해도 앱에서 확인 불가 (프라이버시)
    ///
    /// - Example:
    /// ```swift
    /// if !canWrite(to: weightType) {
    ///     throw HealthKitError.dataTypeNotAuthorized(type: weightType)
    /// }
    /// ```
    case dataTypeNotAuthorized(type: HKObjectType)

    // MARK: - Data Access Errors

    /// 요청한 데이터가 존재하지 않음
    ///
    /// 📚 학습 포인트: Empty Results
    /// HealthKit에 해당 기간의 데이터가 없는 경우
    /// 💡 Java 비교: NoSuchElementException
    ///
    /// - Parameter message: 데이터 부재 상세 설명
    ///
    /// - Example:
    /// ```swift
    /// if samples.isEmpty {
    ///     throw HealthKitError.dataUnavailable(message: "최근 7일간 체중 데이터가 없습니다")
    /// }
    /// ```
    case dataUnavailable(message: String)

    /// 데이터 읽기 실패
    ///
    /// HKQuery 실행 중 에러 발생
    ///
    /// - Parameters:
    ///   - type: 읽기를 시도한 데이터 타입
    ///   - error: 원본 에러
    ///
    /// - Example:
    /// ```swift
    /// healthStore.execute(query) { samples, error in
    ///     if let error = error {
    ///         throw HealthKitError.readFailed(type: "체중", error: error)
    ///     }
    /// }
    /// ```
    case readFailed(type: String, error: Error)

    /// 데이터 쓰기 실패
    ///
    /// 📚 학습 포인트: Write Operations
    /// HealthKit에 데이터를 저장하는 과정에서 실패
    /// 💡 Java 비교: PersistenceException
    ///
    /// - Parameters:
    ///   - type: 쓰기를 시도한 데이터 타입
    ///   - error: 원본 에러
    ///
    /// - Note: 쓰기 권한이 없거나 데이터 형식이 잘못된 경우 발생
    ///
    /// - Example:
    /// ```swift
    /// try await healthStore.save(sample)
    /// } catch {
    ///     throw HealthKitError.writeFailed(type: "운동", error: error)
    /// }
    /// ```
    case writeFailed(type: String, error: Error)

    // MARK: - Background Sync Errors

    /// 백그라운드 동기화 실패
    ///
    /// 📚 학습 포인트: Background Delivery
    /// 앱이 닫혀있을 때 HealthKit 데이터가 업데이트되면 알림을 받아 동기화
    /// 💡 Java 비교: Background Job Failure
    ///
    /// - Parameters:
    ///   - type: 동기화를 시도한 데이터 타입
    ///   - error: 원본 에러
    ///
    /// - Note: enableBackgroundDelivery() 실패 또는 옵저버 쿼리 에러
    ///
    /// - Example:
    /// ```swift
    /// healthStore.enableBackgroundDelivery(for: type) { success, error in
    ///     if !success {
    ///         throw HealthKitError.backgroundSyncFailed(type: "체중", error: error)
    ///     }
    /// }
    /// ```
    case backgroundSyncFailed(type: String, error: Error?)

    /// HKObserverQuery 등록 실패
    ///
    /// 백그라운드에서 데이터 변경을 감지하기 위한 옵저버 등록 실패
    ///
    /// - Parameters:
    ///   - type: 옵저버를 등록하려던 데이터 타입
    ///   - error: 원본 에러
    case observerRegistrationFailed(type: String, error: Error)

    // MARK: - Query Errors

    /// HealthKit 쿼리 실행 실패
    ///
    /// 📚 학습 포인트: HKQuery
    /// HealthKit에서 데이터를 가져오기 위해 쿼리 실행
    /// 💡 Java 비교: SQLException과 유사
    ///
    /// - Parameters:
    ///   - queryType: 실행한 쿼리 타입 (예: "HKSampleQuery", "HKStatisticsQuery")
    ///   - error: 원본 에러
    ///
    /// - Example:
    /// ```swift
    /// healthStore.execute(query) { results, error in
    ///     if let error = error {
    ///         throw HealthKitError.queryExecutionFailed(
    ///             queryType: "HKStatisticsQuery",
    ///             error: error
    ///         )
    ///     }
    /// }
    /// ```
    case queryExecutionFailed(queryType: String, error: Error)

    /// 통계 쿼리 결과 없음
    ///
    /// HKStatisticsQuery에서 결과를 가져오지 못함
    ///
    /// - Parameter type: 쿼리한 데이터 타입
    case statisticsUnavailable(type: String)

    // MARK: - Validation Errors

    /// 유효하지 않은 샘플 타입
    ///
    /// 📚 학습 포인트: Type Safety
    /// HealthKit은 타입 안정성을 위해 HKQuantityType, HKCategoryType 등을 구분
    /// 💡 Java 비교: IllegalArgumentException
    ///
    /// - Parameter identifier: 유효하지 않은 타입 식별자
    ///
    /// - Example:
    /// ```swift
    /// guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
    ///     throw HealthKitError.invalidSampleType(identifier: "bodyMass")
    /// }
    /// ```
    case invalidSampleType(identifier: String)

    /// 유효하지 않은 날짜 범위
    ///
    /// 시작 날짜가 종료 날짜보다 늦거나 미래 날짜인 경우
    ///
    /// - Parameter message: 날짜 범위 에러 설명
    ///
    /// - Example:
    /// ```swift
    /// if startDate > endDate {
    ///     throw HealthKitError.invalidDateRange(
    ///         message: "시작 날짜가 종료 날짜보다 늦습니다"
    ///     )
    /// }
    /// ```
    case invalidDateRange(message: String)

    /// 유효하지 않은 단위
    ///
    /// HKQuantity 생성 시 잘못된 단위 사용
    ///
    /// - Parameters:
    ///   - unit: 사용하려던 단위
    ///   - type: 데이터 타입
    case invalidUnit(unit: HKUnit, type: String)

    // MARK: - Duplicate & Conflict Errors

    /// 중복된 데이터 항목
    ///
    /// 📚 학습 포인트: Duplicate Detection
    /// 동일한 HealthKit UUID를 가진 데이터가 이미 존재
    /// 💡 Java 비교: DuplicateKeyException
    ///
    /// - Parameter uuid: 중복된 HealthKit UUID
    ///
    /// - Note: 중복 데이터 임포트를 방지하기 위해 사용
    ///
    /// - Example:
    /// ```swift
    /// if existingRecord.healthKitId == sample.uuid {
    ///     throw HealthKitError.duplicateEntry(uuid: sample.uuid)
    /// }
    /// ```
    case duplicateEntry(uuid: UUID)

    /// 데이터 충돌
    ///
    /// 같은 날짜/시간에 Bodii 데이터와 HealthKit 데이터가 모두 존재
    ///
    /// - Parameter message: 충돌 상세 설명
    case conflictDetected(message: String)

    // MARK: - Mapping Errors

    /// 데이터 변환 실패
    ///
    /// 📚 학습 포인트: Data Mapping
    /// HealthKit 샘플을 도메인 엔티티로 변환하는 과정에서 실패
    /// 💡 Java 비교: MappingException
    ///
    /// - Parameters:
    ///   - from: 변환 원본 타입
    ///   - to: 변환 대상 타입
    ///   - reason: 실패 사유
    ///
    /// - Example:
    /// ```swift
    /// guard let calories = sample.quantity.doubleValue(for: .kilocalorie()) else {
    ///     throw HealthKitError.mappingFailed(
    ///         from: "HKQuantitySample",
    ///         to: "ExerciseRecord",
    ///         reason: "칼로리 값을 추출할 수 없습니다"
    ///     )
    /// }
    /// ```
    case mappingFailed(from: String, to: String, reason: String)

    /// 운동 타입 매핑 실패
    ///
    /// HKWorkoutActivityType을 ExerciseType으로 변환할 수 없음
    ///
    /// - Parameter activityType: 변환할 수 없는 HKWorkoutActivityType
    case unsupportedWorkoutType(activityType: HKWorkoutActivityType)

    /// 필수 데이터 누락
    ///
    /// HealthKit 샘플에 필수 필드가 없음
    ///
    /// - Parameters:
    ///   - field: 누락된 필드 이름
    ///   - type: 데이터 타입
    case missingRequiredData(field: String, type: String)

    // MARK: - Unknown Error

    /// 알 수 없는 에러
    ///
    /// 위의 카테고리에 해당하지 않는 예기치 않은 에러
    ///
    /// - Parameter error: 원본 에러
    ///
    /// - Note: 개발 중 발견되면 적절한 에러 타입으로 분류 필요
    case unknown(Error)
}

// MARK: - LocalizedError

/// 사용자 친화적인 에러 메시지 제공
///
/// 📚 학습 포인트: LocalizedError Protocol
/// 에러에 대한 지역화된(한국어) 메시지를 제공
/// 💡 Java 비교: getMessage()와 유사하지만 프로토콜 기반
extension HealthKitError: LocalizedError {

    /// 사용자에게 표시할 에러 설명 (한국어)
    ///
    /// 📚 학습 포인트: Computed Property
    /// 저장 프로퍼티가 아닌 계산 프로퍼티로 필요할 때마다 생성
    /// 💡 Java 비교: getter 메서드와 유사하지만 더 간결
    var errorDescription: String? {
        switch self {
        // Authorization Errors
        case .healthKitNotAvailable:
            return "이 기기에서는 Apple Health를 사용할 수 없습니다"

        case .authorizationDenied(let dataType):
            return "Apple Health 권한이 거부되었습니다: \(dataType)"

        case .authorizationFailed(let error):
            return "Apple Health 권한 요청에 실패했습니다: \(error.localizedDescription)"

        case .dataTypeNotAuthorized(let type):
            return "'\(type.identifier)' 데이터에 대한 권한이 없습니다"

        // Data Access Errors
        case .dataUnavailable(let message):
            return "데이터를 사용할 수 없습니다: \(message)"

        case .readFailed(let type, let error):
            return "\(type) 데이터를 읽을 수 없습니다: \(error.localizedDescription)"

        case .writeFailed(let type, let error):
            return "\(type) 데이터를 저장할 수 없습니다: \(error.localizedDescription)"

        // Background Sync Errors
        case .backgroundSyncFailed(let type, let error):
            if let error = error {
                return "\(type) 백그라운드 동기화에 실패했습니다: \(error.localizedDescription)"
            } else {
                return "\(type) 백그라운드 동기화에 실패했습니다"
            }

        case .observerRegistrationFailed(let type, let error):
            return "\(type) 옵저버 등록에 실패했습니다: \(error.localizedDescription)"

        // Query Errors
        case .queryExecutionFailed(let queryType, let error):
            return "\(queryType) 쿼리 실행에 실패했습니다: \(error.localizedDescription)"

        case .statisticsUnavailable(let type):
            return "\(type) 통계 데이터를 가져올 수 없습니다"

        // Validation Errors
        case .invalidSampleType(let identifier):
            return "유효하지 않은 데이터 타입입니다: \(identifier)"

        case .invalidDateRange(let message):
            return "유효하지 않은 날짜 범위입니다: \(message)"

        case .invalidUnit(let unit, let type):
            return "\(type)에 사용할 수 없는 단위입니다: \(unit.unitString)"

        // Duplicate & Conflict Errors
        case .duplicateEntry(let uuid):
            return "중복된 데이터입니다 (UUID: \(uuid.uuidString))"

        case .conflictDetected(let message):
            return "데이터 충돌이 발생했습니다: \(message)"

        // Mapping Errors
        case .mappingFailed(let from, let to, let reason):
            return "\(from)을(를) \(to)(으)로 변환할 수 없습니다: \(reason)"

        case .unsupportedWorkoutType(let activityType):
            return "지원하지 않는 운동 타입입니다: \(activityType.rawValue)"

        case .missingRequiredData(let field, let type):
            return "\(type)에 필수 데이터가 없습니다: \(field)"

        // Unknown
        case .unknown(let error):
            return "알 수 없는 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}

// MARK: - Recovery Strategy

extension HealthKitError {

    /// 복구 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Recoverable vs Non-Recoverable Errors
    /// 에러 유형에 따라 재시도, 폴백 등의 복구 전략을 결정
    /// 💡 Java 비교: Checked vs Unchecked Exception과 유사한 개념
    ///
    /// **복구 전략:**
    /// - **복구 가능**: 재시도, 캐시 사용, graceful degradation
    ///   * readFailed → 재시도 또는 로컬 데이터 사용
    ///   * writeFailed → 재시도 또는 나중에 동기화
    ///   * backgroundSyncFailed → 수동 동기화로 대체
    ///   * queryExecutionFailed → 재시도
    ///
    /// - **복구 불가**: 사용자에게 에러 메시지 표시
    ///   * healthKitNotAvailable → 기기 제한사항
    ///   * authorizationDenied → 사용자가 설정에서 권한 부여 필요
    ///   * invalidSampleType → 개발자 에러
    ///
    /// - Returns: 복구 가능하면 true, 불가능하면 false
    ///
    /// - Example:
    /// ```swift
    /// catch let error as HealthKitError {
    ///     if error.isRecoverable {
    ///         // 재시도 또는 폴백 전략 실행
    ///         useLocalData()
    ///     } else {
    ///         // 사용자에게 에러 메시지 표시
    ///         showAlert(error.errorDescription)
    ///     }
    /// }
    /// ```
    var isRecoverable: Bool {
        switch self {
        // Recoverable Errors (재시도 또는 폴백 가능)
        case .readFailed,
             .writeFailed,
             .backgroundSyncFailed,
             .observerRegistrationFailed,
             .queryExecutionFailed,
             .statisticsUnavailable,
             .dataUnavailable,
             .conflictDetected:
            return true

        // Non-Recoverable Errors (사용자 또는 개발자 개입 필요)
        case .healthKitNotAvailable,
             .authorizationDenied,
             .authorizationFailed,
             .dataTypeNotAuthorized,
             .invalidSampleType,
             .invalidDateRange,
             .invalidUnit,
             .duplicateEntry,
             .mappingFailed,
             .unsupportedWorkoutType,
             .missingRequiredData,
             .unknown:
            return false
        }
    }

    /// 재시도 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Retry Strategy
    /// 일시적인 문제는 재시도로 해결 가능
    /// 💡 Java 비교: @Retryable 어노테이션 조건
    ///
    /// - Returns: 재시도 가능하면 true
    ///
    /// - Example:
    /// ```swift
    /// var retryCount = 0
    /// while retryCount < maxRetries {
    ///     do {
    ///         return try await fetchWeight()
    ///     } catch let error as HealthKitError {
    ///         if error.canRetry {
    ///             retryCount += 1
    ///             await Task.sleep(retryCount * 1_000_000_000)
    ///         } else {
    ///             throw error
    ///         }
    ///     }
    /// }
    /// ```
    var canRetry: Bool {
        switch self {
        case .readFailed,
             .writeFailed,
             .queryExecutionFailed,
             .backgroundSyncFailed,
             .observerRegistrationFailed:
            return true

        default:
            return false
        }
    }

    /// 권한 관련 에러인지 여부
    ///
    /// 📚 학습 포인트: Permission Handling
    /// 권한 에러는 사용자를 설정 화면으로 안내해야 함
    /// 💡 Java 비교: SecurityException 체크
    ///
    /// - Returns: 권한 관련 에러면 true
    ///
    /// - Example:
    /// ```swift
    /// catch let error as HealthKitError {
    ///     if error.isAuthorizationError {
    ///         showSettingsAlert()
    ///     }
    /// }
    /// ```
    var isAuthorizationError: Bool {
        switch self {
        case .healthKitNotAvailable,
             .authorizationDenied,
             .authorizationFailed,
             .dataTypeNotAuthorized:
            return true

        default:
            return false
        }
    }
}
