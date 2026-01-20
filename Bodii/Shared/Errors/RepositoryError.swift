//
//  RepositoryError.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// Repository 레이어에서 발생하는 에러
/// 모든 Repository에서 공통으로 사용
enum RepositoryError: Error, LocalizedError {
    /// Core Data context가 해제됨
    case contextDeallocated

    /// 데이터를 찾을 수 없음
    case notFound

    /// ID로 데이터를 찾을 수 없음
    case notFoundWithId(UUID)

    /// 유효하지 않은 데이터 형식
    case invalidData

    /// 유효하지 않은 입력
    case invalidInput(String)

    /// 저장 실패
    case saveFailed(String)

    /// 조회 실패
    case fetchFailed(String)

    /// 업데이트 실패
    case updateFailed(String)

    /// 삭제 실패
    case deleteFailed(String)

    /// 성능 타임아웃 (0.5초 초과)
    case timeout

    /// 알 수 없는 에러
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .contextDeallocated:
            return "Core Data context has been deallocated"
        case .notFound:
            return "Entity not found"
        case .notFoundWithId(let id):
            return "데이터를 찾을 수 없습니다 (ID: \(id))"
        case .invalidData:
            return "Invalid data format"
        case .invalidInput(let message):
            return "유효하지 않은 입력: \(message)"
        case .saveFailed(let message):
            return "저장 실패: \(message)"
        case .fetchFailed(let message):
            return "조회 실패: \(message)"
        case .updateFailed(let message):
            return "수정 실패: \(message)"
        case .deleteFailed(let message):
            return "삭제 실패: \(message)"
        case .timeout:
            return "작업 시간이 초과되었습니다 (성능 요구사항: 0.5초 이내)"
        case .unknown(let error):
            return "알 수 없는 에러: \(error.localizedDescription)"
        }
    }
}
