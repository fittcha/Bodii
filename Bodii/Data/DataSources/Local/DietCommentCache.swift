//
//  DietCommentCache.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: In-Memory Cache with Actor
// Actor를 사용하여 thread-safe한 in-memory cache 구현
// 💡 Java 비교: ConcurrentHashMap + @Cacheable과 유사하지만 더 안전

import Foundation

/// 식단 코멘트 인메모리 캐시
///
/// 📚 학습 포인트: Actor for Thread-Safe Caching
/// Actor를 사용하여 동시성 환경에서 안전한 캐싱 메커니즘 구현
/// 💡 Java 비교: Caffeine Cache + synchronized와 유사하지만 더 간결하고 안전
///
/// **캐싱 전략:**
/// - 메모리 기반 (앱 재시작 시 초기화됨)
/// - LRU (Least Recently Used) 정책
/// - 만료 시간: 24시간
/// - 최대 엔트리 수: 100개
///
/// **캐시 키 생성:**
/// - 날짜(yyyy-MM-dd) + 사용자ID + 끼니타입
/// - 예: "2026-01-18_550e8400-e29b-41d4-a716-446655440000_lunch"
/// - nil mealType은 "all"로 표현
///
/// **캐시 무효화:**
/// - 식단 기록 추가/수정/삭제 시 자동 무효화
/// - 수동 새로고침 요청 시
/// - 24시간 경과 시 자동 만료
///
/// - Example:
/// ```swift
/// let cache = DietCommentCache()
///
/// // 코멘트 저장
/// await cache.set(comment)
///
/// // 코멘트 조회
/// if let cached = await cache.get(
///     for: Date(),
///     userId: userId,
///     mealType: .lunch
/// ) {
///     print("캐시 히트: \(cached.summary)")
/// }
///
/// // 캐시 무효화
/// await cache.clear(
///     for: Date(),
///     userId: userId,
///     mealType: .lunch
/// )
/// ```
actor DietCommentCache {

    // MARK: - Cache Entry

    /// 캐시 엔트리
    ///
    /// 📚 학습 포인트: Cache Entry with Expiration
    /// 캐시 데이터와 만료 시간을 함께 저장하여 자동 만료 처리
    /// 💡 Java 비교: Caffeine의 Entry와 유사
    private struct CacheEntry {
        let comment: DietComment
        let expiresAt: Date

        /// 캐시 엔트리 유효성 확인
        var isValid: Bool {
            Date() < expiresAt
        }
    }

    // MARK: - Properties

    /// 캐시 스토리지
    ///
    /// 📚 학습 포인트: Dictionary as Cache Storage
    /// 캐시 키를 기반으로 빠른 조회를 위해 Dictionary 사용
    /// 💡 Java 비교: ConcurrentHashMap과 유사하지만 Actor로 thread-safe 보장
    private var cache: [String: CacheEntry] = [:]

    /// 캐시 만료 시간 (24시간)
    private let expirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    /// 최대 캐시 엔트리 수 (LRU 정책)
    private let maxCacheSize: Int = 100

    /// 캐시 접근 순서 추적 (LRU 구현용)
    ///
    /// 📚 학습 포인트: LRU Implementation with Array
    /// 배열을 사용하여 최근 사용 순서를 추적
    /// 💡 Java 비교: LinkedHashMap의 accessOrder와 유사
    private var accessOrder: [String] = []

    // MARK: - Public Methods

    /// 캐시에서 식단 코멘트 조회
    ///
    /// 📚 학습 포인트: Cache Get with Expiration Check
    /// 캐시 조회 시 만료 여부를 확인하고 만료된 항목은 자동 제거
    /// 💡 Java 비교: Caffeine의 getIfPresent()와 유사
    ///
    /// - Parameters:
    ///   - date: 조회 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///
    /// - Returns: 캐시된 DietComment (없거나 만료되었으면 nil)
    ///
    /// - Note: 만료된 캐시는 자동으로 제거됨
    ///
    /// - Example:
    /// ```swift
    /// if let cached = await cache.get(
    ///     for: Date(),
    ///     userId: userId,
    ///     mealType: .lunch
    /// ) {
    ///     print("캐시 히트!")
    /// } else {
    ///     print("캐시 미스 - API 호출 필요")
    /// }
    /// ```
    func get(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) -> DietComment? {
        let key = makeCacheKey(date: date, userId: userId, mealType: mealType)

        guard let entry = cache[key] else {
            return nil
        }

        // 📚 학습 포인트: Automatic Expiration
        // 만료된 캐시는 조회 시점에 자동으로 제거
        guard entry.isValid else {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
            return nil
        }

        // 📚 학습 포인트: LRU Access Order Update
        // 캐시 조회 시 접근 순서를 업데이트하여 최근 사용 항목으로 표시
        updateAccessOrder(for: key)

        return entry.comment
    }

    /// 캐시에 식단 코멘트 저장
    ///
    /// 📚 학습 포인트: Cache Put with LRU Eviction
    /// 캐시 저장 시 LRU 정책에 따라 오래된 항목을 제거
    /// 💡 Java 비교: Caffeine의 put()과 유사
    ///
    /// - Parameter comment: 저장할 DietComment
    ///
    /// - Note: 캐시 크기 제한(100개)을 초과하면 가장 오래된 항목 제거
    ///
    /// - Example:
    /// ```swift
    /// let comment = DietComment(...)
    /// await cache.set(comment)
    /// ```
    func set(_ comment: DietComment) {
        let key = makeCacheKey(
            date: comment.date,
            userId: comment.userId,
            mealType: comment.mealType
        )

        // 📚 학습 포인트: Cache Entry with Expiration Time
        // 현재 시간 + 만료 시간으로 만료 타임스탬프 계산
        let expiresAt = Date().addingTimeInterval(expirationInterval)
        let entry = CacheEntry(comment: comment, expiresAt: expiresAt)

        // 캐시에 저장
        cache[key] = entry

        // 접근 순서 업데이트
        updateAccessOrder(for: key)

        // 📚 학습 포인트: LRU Eviction
        // 캐시 크기 제한을 초과하면 가장 오래된 항목 제거
        evictOldestIfNeeded()
    }

    /// 특정 식단 코멘트 캐시 무효화
    ///
    /// 📚 학습 포인트: Cache Invalidation
    /// 식단 데이터 변경 시 관련 캐시를 무효화하여 일관성 유지
    /// 💡 Java 비교: @CacheEvict와 유사
    ///
    /// - Parameters:
    ///   - date: 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 해당 날짜의 모든 끼니 캐시 무효화)
    ///
    /// - Note: mealType이 nil이면 해당 날짜의 모든 캐시를 무효화함
    ///
    /// - Example:
    /// ```swift
    /// // 특정 끼니 캐시 무효화
    /// await cache.clear(
    ///     for: Date(),
    ///     userId: userId,
    ///     mealType: .lunch
    /// )
    ///
    /// // 전체 날짜 캐시 무효화
    /// await cache.clear(
    ///     for: Date(),
    ///     userId: userId,
    ///     mealType: nil
    /// )
    /// ```
    func clear(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) {
        if let mealType = mealType {
            // 📚 학습 포인트: Single Entry Removal
            // 특정 끼니의 캐시만 제거
            let key = makeCacheKey(date: date, userId: userId, mealType: mealType)
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
        } else {
            // 📚 학습 포인트: Multiple Entries Removal
            // 해당 날짜의 모든 끼니 캐시 제거
            let dateString = formatDateForKey(date)
            let userIdString = userId.uuidString
            let prefix = "\(dateString)_\(userIdString)_"

            // prefix로 시작하는 모든 키 제거
            let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }
            for key in keysToRemove {
                cache.removeValue(forKey: key)
                accessOrder.removeAll { $0 == key }
            }
        }
    }

    /// 모든 캐시 삭제
    ///
    /// 📚 학습 포인트: Cache Clear All
    /// 전체 캐시를 삭제하여 메모리 확보 및 데이터 일관성 보장
    /// 💡 Java 비교: @CacheEvict(allEntries=true)와 유사
    ///
    /// - Note: 모든 사용자의 모든 캐시를 삭제함
    ///
    /// - Example:
    /// ```swift
    /// // 로그아웃 시 캐시 전체 삭제
    /// await cache.clearAll()
    /// ```
    func clearAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    /// 만료된 캐시 항목 정리
    ///
    /// 📚 학습 포인트: Proactive Cache Cleanup
    /// 주기적으로 만료된 항목을 제거하여 메모리 효율성 향상
    /// 💡 Java 비교: Caffeine의 cleanUp()과 유사
    ///
    /// - Note: 백그라운드에서 주기적으로 호출하거나 필요 시 수동 호출
    ///
    /// - Example:
    /// ```swift
    /// // 주기적으로 만료된 캐시 정리
    /// await cache.evictExpired()
    /// ```
    func evictExpired() {
        let now = Date()
        let expiredKeys = cache.compactMap { key, entry in
            entry.expiresAt < now ? key : nil
        }

        for key in expiredKeys {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
        }
    }

    /// 캐시 통계 조회
    ///
    /// 📚 학습 포인트: Cache Statistics
    /// 캐시 사용 현황을 모니터링하여 성능 최적화
    /// 💡 Java 비교: CacheStats와 유사
    ///
    /// - Returns: (총 항목 수, 유효 항목 수)
    ///
    /// - Example:
    /// ```swift
    /// let (total, valid) = await cache.getStats()
    /// print("캐시 통계 - 총: \(total), 유효: \(valid)")
    /// ```
    func getStats() -> (total: Int, valid: Int) {
        let total = cache.count
        let valid = cache.values.filter { $0.isValid }.count
        return (total, valid)
    }
}

// MARK: - Private Helpers

extension DietCommentCache {

    /// 캐시 키 생성
    ///
    /// 📚 학습 포인트: Cache Key Generation
    /// 날짜, 사용자ID, 끼니타입을 조합하여 고유한 캐시 키 생성
    /// 💡 Java 비교: @Cacheable의 key 표현식과 유사
    ///
    /// **키 형식:**
    /// - "{yyyy-MM-dd}_{userId}_{mealType}"
    /// - 예: "2026-01-18_550e8400-e29b-41d4-a716-446655440000_lunch"
    /// - mealType이 nil이면: "2026-01-18_550e8400-e29b-41d4-a716-446655440000_all"
    ///
    /// - Parameters:
    ///   - date: 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류
    ///
    /// - Returns: 캐시 키 문자열
    private func makeCacheKey(
        date: Date,
        userId: UUID,
        mealType: MealType?
    ) -> String {
        let dateString = formatDateForKey(date)
        let userIdString = userId.uuidString
        let mealTypeString = mealType.map { String($0.rawValue) } ?? "all"

        return "\(dateString)_\(userIdString)_\(mealTypeString)"
    }

    /// 날짜를 캐시 키용 문자열로 포맷팅
    ///
    /// 📚 학습 포인트: Date Formatting for Key
    /// 날짜를 yyyy-MM-dd 형식으로 변환하여 일관된 키 생성
    /// 💡 Java 비교: DateTimeFormatter와 유사
    ///
    /// - Parameter date: 포맷팅할 날짜
    /// - Returns: yyyy-MM-dd 형식의 문자열
    private func formatDateForKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// 접근 순서 업데이트 (LRU)
    ///
    /// 📚 학습 포인트: LRU Access Order Management
    /// 캐시 접근 시 해당 키를 가장 최근 사용 항목으로 이동
    /// 💡 Java 비교: LinkedHashMap의 accessOrder=true와 유사
    ///
    /// - Parameter key: 접근한 캐시 키
    private func updateAccessOrder(for key: String) {
        // 기존 순서에서 제거
        accessOrder.removeAll { $0 == key }
        // 가장 최근 항목으로 추가
        accessOrder.append(key)
    }

    /// LRU 정책에 따라 오래된 항목 제거
    ///
    /// 📚 학습 포인트: LRU Eviction Policy
    /// 캐시 크기가 최대치를 초과하면 가장 오래된 항목부터 제거
    /// 💡 Java 비교: Caffeine의 maximumSize와 유사
    ///
    /// - Note: 최대 100개 항목 유지
    private func evictOldestIfNeeded() {
        while cache.count > maxCacheSize {
            // 📚 학습 포인트: Remove Least Recently Used
            // accessOrder의 첫 번째 항목이 가장 오래된 항목
            guard let oldestKey = accessOrder.first else {
                break
            }

            cache.removeValue(forKey: oldestKey)
            accessOrder.removeFirst()
        }
    }
}
