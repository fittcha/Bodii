//
//  DietCommentRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Repository Pattern for AI Service
// AI 코멘트 생성 및 캐싱을 추상화하여 도메인 레이어가 구체적인 데이터 소스에 의존하지 않도록 함
// 💡 Java 비교: Spring Data Repository 인터페이스와 유사한 역할

import Foundation

/// 식단 코멘트 저장소 프로토콜
///
/// 📚 학습 포인트: Dependency Inversion Principle (SOLID)
/// 도메인 레이어가 데이터 레이어의 구체적인 구현에 의존하지 않도록
/// 프로토콜을 통해 추상화된 인터페이스 제공
/// 💡 Java 비교: Repository 인터페이스 (JpaRepository, CrudRepository 등)
///
/// **역할:**
/// - AI 식단 코멘트 생성 및 캐싱 기능의 추상화된 인터페이스 정의
/// - 도메인 레이어와 데이터 레이어 간의 경계 (Boundary)
/// - Gemini API 호출 및 응답 캐싱 관리
///
/// **캐싱 전략:**
/// - 캐시 키: date + userId + mealType 조합
/// - 캐시 만료: 24시간
/// - 식단 변경 시 캐시 무효화 (invalidation)
/// - 오프라인 시 캐시된 코멘트 반환
///
/// **사용 예시:**
/// ```swift
/// // DIContainer에서 주입받음
/// let repository: DietCommentRepository = container.resolve()
///
/// // 캐시 확인
/// if let cached = try await repository.getCachedComment(
///     for: Date(),
///     userId: userId,
///     mealType: .lunch
/// ) {
///     print("캐시된 코멘트: \(cached.summary)")
/// }
///
/// // 코멘트 생성 (API 호출)
/// let comment = try await repository.generateComment(
///     for: Date(),
///     userId: userId,
///     mealType: .lunch,
///     goalType: .weightLoss,
///     tdee: 2100
/// )
///
/// // 코멘트 저장 (캐싱)
/// try await repository.saveComment(comment)
/// ```
protocol DietCommentRepository {

    // MARK: - Comment Generation

    /// AI 식단 코멘트 생성
    ///
    /// 📚 학습 포인트: Protocol Method with Async/Throws
    /// 비동기 작업과 에러 처리를 프로토콜 레벨에서 명시
    /// 💡 Java 비교: CompletableFuture를 반환하는 메서드와 유사
    ///
    /// **동작 방식:**
    /// 1. 해당 날짜 및 끼니의 식단 데이터 조회
    /// 2. 사용자의 목표 및 TDEE 정보 수집
    /// 3. Gemini API를 통한 AI 코멘트 생성
    /// 4. 응답 파싱 및 DietComment 도메인 엔티티로 변환
    /// 5. 생성된 코멘트 캐시에 저장
    ///
    /// **프롬프트 엔지니어링:**
    /// - 한국 음식 맥락 고려
    /// - 사용자 목표(감량/유지/증량) 반영
    /// - TDEE 대비 섭취량 분석
    /// - 영양소 균형 평가
    /// - 구체적이고 실행 가능한 개선점 제안
    ///
    /// - Parameters:
    ///   - date: 평가 대상 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///   - goalType: 사용자 목표 (감량/유지/증량)
    ///   - tdee: 활동대사량 (kcal)
    ///
    /// - Returns: 생성된 DietComment 엔티티
    ///
    /// - Throws:
    ///   - `DietCommentError.noFoodRecords`: 해당 날짜/끼니에 식단 데이터 없음
    ///   - `DietCommentError.apiError`: Gemini API 호출 실패
    ///   - `DietCommentError.rateLimitExceeded`: API 요청 한도 초과 (15 RPM)
    ///   - `DietCommentError.networkFailure`: 네트워크 연결 실패
    ///   - `DietCommentError.invalidResponse`: API 응답 파싱 실패
    ///
    /// - Note: Rate limiting은 GeminiAPIService에서 처리됨
    ///
    /// - Example:
    /// ```swift
    /// // 점심 식단에 대한 코멘트 생성
    /// let comment = try await generateComment(
    ///     for: Date(),
    ///     userId: currentUser.id,
    ///     mealType: .lunch,
    ///     goalType: .weightLoss,
    ///     tdee: 2100
    /// )
    /// print("점수: \(comment.score)/10")
    /// print("요약: \(comment.summary)")
    /// ```
    func generateComment(
        for date: Date,
        userId: UUID,
        mealType: MealType?,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment

    // MARK: - Cache Retrieval

    /// 캐시된 식단 코멘트 조회
    ///
    /// 📚 학습 포인트: Cache-First Strategy
    /// API 호출 전 캐시를 먼저 확인하여 중복 요청 방지 및 응답 속도 향상
    /// 💡 Java 비교: @Cacheable 어노테이션과 유사
    ///
    /// **캐시 키 생성:**
    /// - 날짜(yyyy-MM-dd) + 사용자ID + 끼니타입
    /// - 예: "2026-01-18_user123_lunch"
    ///
    /// **캐시 유효성:**
    /// - 캐시 만료 시간: 24시간
    /// - 식단 변경 시 자동 무효화
    ///
    /// - Parameters:
    ///   - date: 조회 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///
    /// - Returns: 캐시된 DietComment (없거나 만료되었으면 nil)
    ///
    /// - Note: 에러가 발생하지 않음 (캐시 조회 실패 시 nil 반환)
    ///
    /// - Example:
    /// ```swift
    /// // 캐시 확인
    /// if let cached = try await getCachedComment(
    ///     for: Date(),
    ///     userId: userId,
    ///     mealType: .lunch
    /// ) {
    ///     // 캐시된 코멘트 사용
    ///     showComment(cached)
    /// } else {
    ///     // API 호출하여 새 코멘트 생성
    ///     let new = try await generateComment(...)
    ///     showComment(new)
    /// }
    /// ```
    func getCachedComment(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) async throws -> DietComment?

    // MARK: - Cache Management

    /// 식단 코멘트 저장 (캐싱)
    ///
    /// 📚 학습 포인트: Cache Population
    /// 생성된 코멘트를 캐시에 저장하여 동일한 요청 시 API 호출 방지
    /// 💡 Java 비교: @CachePut과 유사
    ///
    /// **저장 전략:**
    /// - 메모리 캐시 (in-memory)
    /// - 캐시 키: date + userId + mealType
    /// - 만료 시간: 24시간
    /// - 저장 공간 제한: 최대 100개 (LRU 정책)
    ///
    /// - Parameter comment: 저장할 DietComment
    ///
    /// - Note: 동일한 키가 이미 존재하면 덮어씀
    ///
    /// - Example:
    /// ```swift
    /// // 코멘트 생성 후 캐싱
    /// let comment = try await generateComment(...)
    /// try await saveComment(comment)
    /// ```
    func saveComment(_ comment: DietComment) async throws

    /// 특정 식단 코멘트 캐시 무효화
    ///
    /// 📚 학습 포인트: Cache Invalidation
    /// 식단 데이터가 변경되면 해당 코멘트 캐시를 제거하여 일관성 유지
    /// 💡 Java 비교: @CacheEvict와 유사
    ///
    /// **무효화 시나리오:**
    /// - 식단 기록 추가/수정/삭제 시
    /// - 사용자 목표 변경 시
    /// - 수동 새로고침 요청 시
    ///
    /// - Parameters:
    ///   - date: 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 해당 날짜의 모든 끼니 캐시 무효화)
    ///
    /// - Note: 캐시가 없어도 에러가 발생하지 않음
    ///
    /// - Example:
    /// ```swift
    /// // 점심 식단 변경 시 캐시 무효화
    /// try await clearCache(
    ///     for: Date(),
    ///     userId: userId,
    ///     mealType: .lunch
    /// )
    ///
    /// // 전체 날짜의 캐시 무효화
    /// try await clearCache(
    ///     for: Date(),
    ///     userId: userId,
    ///     mealType: nil
    /// )
    /// ```
    func clearCache(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) async throws

    /// 모든 캐시 삭제
    ///
    /// 📚 학습 포인트: Cache Clear All
    /// 전체 캐시를 삭제하여 메모리 확보 및 데이터 일관성 보장
    /// 💡 Java 비교: @CacheEvict(allEntries=true)와 유사
    ///
    /// **사용 시나리오:**
    /// - 앱 재시작 시
    /// - 사용자 로그아웃 시
    /// - 메모리 부족 시
    /// - 설정 변경 시 (목표, TDEE 등)
    ///
    /// - Note: 모든 사용자의 모든 캐시를 삭제함
    ///
    /// - Example:
    /// ```swift
    /// // 로그아웃 시 캐시 전체 삭제
    /// try await clearAllCache()
    /// ```
    func clearAllCache() async throws
}

// MARK: - DietCommentError

/// 식단 코멘트 관련 에러
///
/// 📚 학습 포인트: Domain-Specific Error Types
/// 도메인 로직에서 발생할 수 있는 에러를 명확하게 정의
/// 💡 Java 비교: Custom Exception 클래스와 유사
enum DietCommentError: LocalizedError {
    case noFoodRecords
    case apiError(String)
    case rateLimitExceeded(retryAfter: TimeInterval)
    case networkFailure
    case invalidResponse
    case cachingFailed

    var errorDescription: String? {
        switch self {
        case .noFoodRecords:
            return "식단 기록이 없습니다. 식사를 먼저 기록해주세요."
        case .apiError(let message):
            return "AI 코멘트 생성 실패: \(message)"
        case .rateLimitExceeded(let retryAfter):
            let minutes = Int(retryAfter / 60)
            return "요청 한도를 초과했습니다. \(minutes)분 후에 다시 시도해주세요."
        case .networkFailure:
            return "네트워크 연결을 확인해주세요."
        case .invalidResponse:
            return "AI 응답을 처리할 수 없습니다. 다시 시도해주세요."
        case .cachingFailed:
            return "코멘트 저장에 실패했습니다."
        }
    }
}
