//
//  RecentFoodsServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation

/// 최근/자주 사용한 음식을 관리하는 서비스 인터페이스
///
/// 빠른 추가(quick-add) 기능을 위한 최근 사용 음식과 자주 사용하는 음식을 조회합니다.
/// 사용자의 식단 기록(FoodRecord)을 분석하여 최적화된 음식 목록을 제공합니다.
///
/// - Note: 모든 메서드는 Swift Concurrency를 사용하여 비동기로 동작합니다.
/// - Note: 반환되는 음식 목록은 빠른 추가 UI에 최적화되어 제한된 개수만 반환됩니다.
///
/// - Example:
/// ```swift
/// let service: RecentFoodsServiceProtocol = RecentFoodsService(
///     foodRepository: foodRepository
/// )
/// let recentFoods = try await service.getRecentFoods(userId: userId)
/// // 최대 10개의 최근 사용 음식 반환
/// ```
protocol RecentFoodsServiceProtocol {

    // MARK: - Recent Foods

    /// 최근 사용한 음식을 조회합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. FoodRepository를 사용하여 최근 30일 이내 사용된 음식 조회
    /// 2. 중복 제거 (같은 음식을 여러 번 먹었어도 1개만 표시)
    /// 3. 사용 시간 역순 정렬 (가장 최근 사용한 음식이 먼저)
    /// 4. 최대 10개로 제한
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 최근 사용한 음식 목록 (최대 10개)
    /// - Throws: 조회 중 에러 발생 시
    ///
    /// - Note: 빈 결과는 빈 배열을 반환합니다.
    func getRecentFoods(userId: UUID) async throws -> [Food]

    /// 자주 사용하는 음식을 조회합니다.
    ///
    /// 이 메서드는 다음 작업을 수행합니다:
    /// 1. FoodRepository를 사용하여 전체 기간 동안의 음식 사용 기록 조회
    /// 2. 음식별 사용 횟수 집계
    /// 3. 사용 횟수 내림차순 정렬
    /// 4. 최대 10개로 제한
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 자주 사용하는 음식 목록 (최대 10개)
    /// - Throws: 조회 중 에러 발생 시
    ///
    /// - Note: 빈 결과는 빈 배열을 반환합니다.
    func getFrequentFoods(userId: UUID) async throws -> [Food]

    /// 빠른 추가를 위한 추천 음식을 조회합니다.
    ///
    /// 이 메서드는 최근 사용 음식과 자주 사용하는 음식을 합쳐서 반환합니다.
    /// 중복 제거를 수행하며, 최근 사용 음식을 우선적으로 포함합니다.
    ///
    /// - Parameter userId: 사용자 ID
    /// - Returns: 추천 음식 목록 (최대 15개)
    /// - Throws: 조회 중 에러 발생 시
    ///
    /// - Note: 최근 사용 음식(최대 10개) + 자주 사용 음식(중복 제거 후 최대 5개 추가)
    func getQuickAddFoods(userId: UUID) async throws -> [Food]
}
