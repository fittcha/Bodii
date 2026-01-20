//
//  SleepRecordMapper.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Mapper Pattern for Sleep Data
// Core Data 엔티티의 유효성을 검증하는 매퍼
// SleepRecord는 Core Data 엔티티 자체를 사용 (별도의 Domain 엔티티 없음)

import Foundation
import CoreData

// MARK: - SleepRecordMapper

/// SleepRecord (Core Data) 유효성 검증 및 변환 매퍼
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
            case .invalidEnumValue(let value):
                return "잘못된 enum 값입니다: \(value)"
            }
        }
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Validation

    /// SleepRecord 엔티티의 유효성을 검증합니다.
    /// - Parameter entity: Core Data SleepRecord 엔티티
    /// - Throws: MappingError - 필수 필드 누락 또는 잘못된 값
    func validate(_ entity: SleepRecord) throws {
        guard entity.id != nil else {
            throw MappingError.missingRequiredField("id")
        }

        guard entity.date != nil else {
            throw MappingError.missingRequiredField("date")
        }

        guard entity.createdAt != nil else {
            throw MappingError.missingRequiredField("createdAt")
        }

        guard entity.updatedAt != nil else {
            throw MappingError.missingRequiredField("updatedAt")
        }

        // status 값 범위 검증 (SleepStatus enum)
        guard entity.status >= 0 && entity.status <= 4 else {
            throw MappingError.invalidEnumValue("status: \(entity.status)")
        }
    }

    /// 여러 SleepRecord 엔티티의 유효성을 검증합니다.
    /// - Parameter entities: Core Data SleepRecord 배열
    /// - Throws: MappingError - 유효하지 않은 엔티티 발견 시
    func validate(_ entities: [SleepRecord]) throws {
        for entity in entities {
            try validate(entity)
        }
    }

    // MARK: - Helper Methods

    /// SleepStatus Int16 값을 SleepStatus enum으로 변환
    /// - Parameter value: Int16 값
    /// - Returns: SleepStatus (nil if invalid)
    func statusFromInt16(_ value: Int16) -> SleepStatus? {
        return SleepStatus(rawValue: value)
    }

    /// SleepStatus enum을 Int16 값으로 변환
    /// - Parameter status: SleepStatus enum
    /// - Returns: Int16 값
    func int16FromStatus(_ status: SleepStatus) -> Int16 {
        return status.rawValue
    }
}
