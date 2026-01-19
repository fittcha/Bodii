//
//  SleepRecordMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Mapper Pattern for Sleep Data
// Core Data SleepRecord의 Int16 상태 값과 SleepStatus enum 간의 변환을 담당
// 💡 Java 비교: ModelMapper 또는 MapStruct와 유사한 역할

import Foundation
import CoreData

// MARK: - SleepRecordMapper

/// SleepRecord 관련 매핑 유틸리티
///
/// Core Data의 SleepRecord 엔티티에서 사용하는 Int16 상태 값과
/// SleepStatus enum 간의 변환을 처리합니다.
///
/// 📚 학습 포인트: Clean Architecture - Data Layer
/// - Core Data의 primitive 타입을 enum으로 변환
/// - 양방향 변환 지원 (Int16 ↔ SleepStatus)
///
/// - Note: SleepRecord는 Core Data 엔티티(codeGenerationType="class")로
///   자동 생성되므로 별도의 도메인 모델 struct 없이 직접 사용합니다.
struct SleepRecordMapper {

    // MARK: - Types

    /// 매핑 중 발생할 수 있는 에러
    enum MappingError: Error, LocalizedError {
        /// 필수 필드 누락
        case missingRequiredField(String)

        /// 잘못된 데이터 타입
        case invalidDataType(String)

        /// 잘못된 enum 값
        case invalidEnumValue(String)

        var errorDescription: String? {
            switch self {
            case .missingRequiredField(let field):
                return "필수 필드가 누락되었습니다: \(field)"
            case .invalidDataType(let field):
                return "잘못된 데이터 타입입니다: \(field)"
            case .invalidEnumValue(let field):
                return "잘못된 enum 값입니다: \(field)"
            }
        }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Status Conversion Methods

    /// SleepStatus enum을 Int16로 변환
    ///
    /// 📚 학습 포인트: Enum → Int16 Conversion
    /// Core Data는 enum을 직접 저장할 수 없으므로 Int16로 변환 필요
    /// 💡 Java 비교: enum.ordinal()과 유사하지만 rawValue 사용
    ///
    /// - Parameter status: SleepStatus enum 값
    /// - Returns: Int16 값
    func int16FromStatus(_ status: SleepStatus) -> Int16 {
        return status.rawValue
    }

    /// Int16을 SleepStatus enum으로 변환
    ///
    /// 📚 학습 포인트: Int16 → Enum Conversion
    /// Core Data의 Int16 값을 SleepStatus enum으로 안전하게 변환
    /// 💡 Java 비교: Enum.valueOf()와 유사하지만 optional 반환
    ///
    /// - Parameter value: Int16 값
    /// - Returns: SleepStatus enum 또는 nil (잘못된 값인 경우)
    func statusFromInt16(_ value: Int16) -> SleepStatus? {
        return SleepStatus(rawValue: value)
    }

    /// Int16을 SleepStatus enum으로 변환 (에러 throw 버전)
    ///
    /// - Parameter value: Int16 값
    /// - Returns: SleepStatus enum
    /// - Throws: MappingError.invalidEnumValue - 잘못된 값인 경우
    func statusFromInt16Throwing(_ value: Int16) throws -> SleepStatus {
        guard let status = SleepStatus(rawValue: value) else {
            throw MappingError.invalidEnumValue("status: \(value)")
        }
        return status
    }

    // MARK: - Entity Update Methods

    /// 기존 SleepRecord 엔티티 업데이트
    ///
    /// 📚 학습 포인트: Partial Update
    /// ID와 관계(user)는 변경하지 않고 데이터 필드만 업데이트
    ///
    /// - Parameters:
    ///   - entity: 업데이트할 Core Data SleepRecord
    ///   - date: 수면 날짜
    ///   - duration: 수면 시간 (분)
    ///   - status: 수면 상태
    func updateEntity(
        _ entity: SleepRecord,
        date: Date,
        duration: Int32,
        status: SleepStatus
    ) {
        entity.date = date
        entity.duration = duration
        entity.status = int16FromStatus(status)
        entity.updatedAt = Date()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepRecordMapper의 역할
///
/// Core Data의 SleepRecord는 자동 생성 클래스이므로:
/// - 별도의 도메인 struct가 필요 없음
/// - SleepRecord Core Data 엔티티를 직접 사용
/// - 이 Mapper는 Int16 ↔ SleepStatus 변환만 담당
///
/// SleepRecord Core Data 엔티티 구조:
/// - id: UUID
/// - date: Date
/// - duration: Int32 (분 단위)
/// - status: Int16 (SleepStatus.rawValue)
/// - healthKitId: String? (HealthKit 동기화용)
/// - createdAt: Date
/// - updatedAt: Date
/// - user: User (관계)
///
/// 사용 예시:
/// ```swift
/// let mapper = SleepRecordMapper()
///
/// // enum → Int16
/// let int16Value = mapper.int16FromStatus(.good)
/// entity.status = int16Value
///
/// // Int16 → enum
/// if let status = mapper.statusFromInt16(entity.status) {
///     print("Sleep status: \(status)")
/// }
/// ```
///
/// 💡 실무 팁:
/// - Enum 변환 시 항상 실패 가능성을 고려
/// - 수면 시간은 Int32(분 단위)로 저장하여 정밀도 유지
/// - 날짜 경계 로직은 DateUtils에서 처리
