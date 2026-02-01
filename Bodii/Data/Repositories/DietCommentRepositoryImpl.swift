//
//  DietCommentRepositoryImpl.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: AI Service Repository Implementation
// AI 식단 코멘트 저장소 구현 - 캐싱 및 API 호출 조정
// 💡 Java 비교: Spring Data Repository 구현체와 유사

import Foundation

/// DietCommentRepository 프로토콜 구현체
///
/// 📚 학습 포인트: Repository Pattern for AI Service
/// AI 코멘트 생성과 캐싱을 조정하는 Repository 구현
/// 💡 Java 비교: @Repository 클래스와 유사
///
/// **주요 책임:**
/// - DietCommentRepository 프로토콜 구현
/// - GeminiService와 DietCommentCache 조정
/// - FoodRecordRepository를 통한 식단 데이터 조회
/// - API 응답 → 도메인 엔티티 변환
/// - 에러 처리 및 폴백 로직
///
/// **캐싱 전략:**
/// - Cache-First: 캐시 먼저 확인 후 API 호출
/// - 캐시 키: date + userId + mealType
/// - 캐시 만료: 24시간
/// - 식단 변경 시 자동 무효화
///
/// **의존성:**
/// - GeminiServiceProtocol: AI 코멘트 생성
/// - DietCommentCache: 인메모리 캐싱
/// - FoodRecordRepositoryProtocol: 식단 데이터 조회
///
/// **사용 예시:**
/// ```swift
/// let repository = DietCommentRepositoryImpl(
///     geminiService: geminiService,
///     cache: cache,
///     foodRecordRepository: foodRecordRepo
/// )
///
/// // 캐시 확인
/// if let cached = try await repository.getCachedComment(
///     for: Date(),
///     userId: userId,
///     mealType: .lunch
/// ) {
///     print("캐시 히트!")
/// }
///
/// // 코멘트 생성 (API 호출)
/// let comment = try await repository.generateComment(
///     for: Date(),
///     userId: userId,
///     mealType: .lunch,
///     goalType: .lose,
///     tdee: 2100
/// )
/// ```
final class DietCommentRepositoryImpl: DietCommentRepository {

    // MARK: - Properties

    /// Gemini AI 서비스
    ///
    /// 📚 학습 포인트: Protocol-Based Dependency
    /// 구체 타입이 아닌 프로토콜에 의존하여 테스트 가능성 향상
    /// 💡 Java 비교: @Autowired private Service interface
    private let geminiService: GeminiServiceProtocol

    /// 식단 코멘트 캐시
    ///
    /// 📚 학습 포인트: Actor for Thread-Safe Caching
    /// Actor를 사용하여 동시성 환경에서 안전한 캐싱
    /// 💡 Java 비교: ConcurrentHashMap 또는 Caffeine Cache와 유사
    private let cache: DietCommentCache

    /// 식단 기록 저장소
    private let foodRecordRepository: FoodRecordRepositoryProtocol

    /// DailyLog 로컬 데이터 소스 (L2 영구 저장소)
    private let dailyLogLocalDataSource: DailyLogLocalDataSource

    // MARK: - Initialization

    init(
        geminiService: GeminiServiceProtocol,
        cache: DietCommentCache,
        foodRecordRepository: FoodRecordRepositoryProtocol,
        dailyLogLocalDataSource: DailyLogLocalDataSource
    ) {
        self.geminiService = geminiService
        self.cache = cache
        self.foodRecordRepository = foodRecordRepository
        self.dailyLogLocalDataSource = dailyLogLocalDataSource
    }

    // MARK: - Comment Generation

    func generateComment(
        for date: Date,
        userId: UUID,
        mealType: MealType?,
        goalType: GoalType,
        tdee: Int,
        targetCalories: Int
    ) async throws -> DietComment {

        // 1. 식단 데이터 조회
        let foodRecords: [FoodRecord]
        do {
            foodRecords = try await fetchFoodRecords(
                for: date,
                userId: userId,
                mealType: mealType
            )
        } catch {
            // 식단 조회 실패는 noFoodRecords로 변환
            throw DietCommentError.noFoodRecords
        }

        // 2. 식단 기록 검증
        guard !foodRecords.isEmpty else {
            throw DietCommentError.noFoodRecords
        }

        // 3. AI 코멘트 생성
        do {
            let comment = try await geminiService.generateDietComment(
                foodRecords: foodRecords,
                mealType: mealType,
                userId: userId,
                date: date,
                goalType: goalType,
                tdee: tdee,
                targetCalories: targetCalories
            )

            // 4. 생성된 코멘트를 L1 캐시 + L2 Core Data에 저장
            await cache.set(comment)
            await persistComment(comment)

            return comment

        } catch let error as GeminiServiceError {
            // GeminiServiceError를 DietCommentError로 변환
            throw mapServiceError(error)
        } catch {
            // 기타 에러는 apiError로 래핑
            throw DietCommentError.apiError(error.localizedDescription)
        }
    }

    // MARK: - Cache Retrieval

    func getCachedComment(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) async throws -> DietComment? {
        // L1: 인메모리 캐시 확인
        if let cached = await cache.get(
            for: date,
            userId: userId,
            mealType: mealType
        ) {
            return cached
        }

        // L2: Core Data 확인 (일일 전체 코멘트만 저장됨)
        if mealType == nil,
           let persisted = await getPersistedComment(userId: userId, date: date) {
            // L2 → L1으로 채움
            await cache.set(persisted)
            return persisted
        }

        return nil
    }

    // MARK: - Cache Management

    func saveComment(_ comment: DietComment) async throws {
        // L1: 인메모리 캐시 저장
        await cache.set(comment)
        // L2: Core Data 영구 저장
        await persistComment(comment)
    }

    func clearCache(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) async throws {
        // 📚 학습 포인트: Cache Invalidation
        // 식단 변경 시 관련 캐시를 무효화하여 일관성 유지
        // 💡 Java 비교: @CacheEvict와 유사
        await cache.clear(
            for: date,
            userId: userId,
            mealType: mealType
        )
    }

    func clearAllCache() async throws {
        await cache.clearAll()
    }

    // MARK: - Persistent Storage (L2)

    func getPersistedComment(userId: UUID, date: Date) async -> DietComment? {
        do {
            return try await dailyLogLocalDataSource.fetchAIComment(for: date, userId: userId)
        } catch {
            #if DEBUG
            print("⚠️ L2 코멘트 조회 실패: \(error)")
            #endif
            return nil
        }
    }

    func persistComment(_ comment: DietComment) async {
        // 일일 전체 코멘트(mealType == nil)만 Core Data에 저장
        guard comment.mealType == nil else { return }
        do {
            try await dailyLogLocalDataSource.saveAIComment(
                comment,
                for: comment.date,
                userId: comment.userId
            )
        } catch {
            #if DEBUG
            print("⚠️ L2 코멘트 저장 실패: \(error)")
            #endif
        }
    }

    // MARK: - Private Helpers

    /// 식단 기록 조회
    ///
    /// 📚 학습 포인트: Data Fetching Abstraction
    /// Repository를 통한 데이터 조회로 일관성 보장
    /// 💡 Java 비교: Repository.findBy* 메서드와 유사
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 전체 식단)
    ///
    /// - Returns: 식단 기록 배열
    ///
    /// - Throws: Repository 조회 에러
    ///
    /// - Note: mealType이 nil이면 전체 날짜의 식단을 반환
    private func fetchFoodRecords(
        for date: Date,
        userId: UUID,
        mealType: MealType?
    ) async throws -> [FoodRecord] {
        if let mealType = mealType {
            // 📚 학습 포인트: Specific Meal Query
            // 특정 끼니의 식단만 조회
            return try await foodRecordRepository.findByDateAndMealType(
                date,
                mealType: mealType,
                userId: userId
            )
        } else {
            // 📚 학습 포인트: Full Day Query
            // 전체 날짜의 모든 식단 조회
            return try await foodRecordRepository.findByDate(
                date,
                userId: userId
            )
        }
    }

    /// GeminiServiceError를 DietCommentError로 변환
    ///
    /// 📚 학습 포인트: Error Mapping between Layers
    /// 하위 레이어의 에러를 도메인 에러로 변환하여 추상화 유지
    /// 💡 Java 비교: Custom Exception Mapping과 유사
    ///
    /// - Parameter error: GeminiServiceError
    ///
    /// - Returns: 변환된 DietCommentError
    private func mapServiceError(_ error: GeminiServiceError) -> DietCommentError {
        switch error {
        case .emptyFoodRecords:
            return .noFoodRecords

        case .invalidResponse(let message):
            return .invalidResponse

        case .apiError(let underlyingError):
            // 📚 학습 포인트: Nested Error Handling
            // API 에러 내부의 실제 에러를 확인하여 세밀한 매핑
            if let geminiAPIError = underlyingError as? GeminiAPIError {
                return mapAPIError(geminiAPIError)
            } else {
                return .apiError(underlyingError.localizedDescription)
            }

        case .jsonParsingFailed:
            return .invalidResponse

        case .imageEncodingFailed:
            return .invalidResponse
        }
    }

    /// GeminiAPIError를 DietCommentError로 변환
    ///
    /// 📚 학습 포인트: Specific API Error Mapping
    /// API 레벨 에러를 도메인 에러로 세밀하게 매핑
    /// 💡 Java 비교: HttpStatus → Custom Exception 변환과 유사
    ///
    /// - Parameter error: GeminiAPIError
    ///
    /// - Returns: 변환된 DietCommentError
    private func mapAPIError(_ error: GeminiAPIError) -> DietCommentError {
        switch error {
        case .rateLimitExceeded:
            // 📚 학습 포인트: Rate Limit Handling
            // Rate limit 초과 시 재시도 시간 전달
            // 15 RPM 제한이므로 60초 후 재시도
            return .rateLimitExceeded(retryAfter: 60)

        case .authenticationFailed:
            return .apiError("인증 실패: API 키를 확인해주세요.")

        case .networkError:
            return .networkFailure

        case .invalidRequest(let message):
            return .apiError("잘못된 요청: \(message)")

        case .unknown(let message):
            return .apiError(message)

        case .contentFiltered:
            return .apiError("안전 필터에 의해 차단되었습니다. 다시 시도해주세요.")

        case .maxTokensReached:
            return .apiError("응답 길이 제한을 초과했습니다. 다시 시도해주세요.")

        case .noCandidates:
            return .invalidResponse

        case .parsingError(let message):
            return .apiError("응답 파싱 오류: \(message)")
        }
    }
}

// MARK: - Implementation Notes

/// ## DietCommentRepositoryImpl 구현 설명
///
/// ### 역할 및 책임
/// 1. **Protocol Implementation**: DietCommentRepository 프로토콜의 구현체
/// 2. **Service Coordination**: GeminiService, Cache, FoodRecordRepository 조정
/// 3. **Error Mapping**: 하위 레이어 에러를 도메인 에러로 변환
/// 4. **Caching Strategy**: Cache-First 전략으로 API 호출 최소화
///
/// ### 데이터 흐름
/// ```
/// UseCase
///    ↓ calls
/// DietCommentRepositoryImpl (이 클래스)
///    ↓ uses
/// ┌─────────────────────┬──────────────────────┬─────────────────────┐
/// GeminiService         DietCommentCache       FoodRecordRepository
/// (AI 생성)              (캐싱)                  (식단 조회)
/// ```
///
/// ### 에러 매핑 전략
/// ```
/// GeminiServiceError
///    ↓ mapServiceError()
/// GeminiAPIError (if nested)
///    ↓ mapAPIError()
/// DietCommentError
///    ↓ thrown to
/// UseCase
/// ```
///
/// ### 캐싱 워크플로우
/// 1. **캐시 조회**: getCachedComment() → 캐시 히트 시 즉시 반환
/// 2. **API 호출**: generateComment() → 새 코멘트 생성
/// 3. **캐시 저장**: 생성 후 자동으로 캐시에 저장
/// 4. **캐시 무효화**: 식단 변경 시 clearCache() 호출
///
/// ### 테스트 전략
/// ```swift
/// // Mock 의존성 주입으로 테스트
/// let mockGeminiService = MockGeminiService()
/// let mockCache = DietCommentCache()
/// let mockFoodRepo = MockFoodRecordRepository()
///
/// let repository = DietCommentRepositoryImpl(
///     geminiService: mockGeminiService,
///     cache: mockCache,
///     foodRecordRepository: mockFoodRepo
/// )
///
/// // 각 의존성을 독립적으로 테스트 가능
/// ```
///
/// ### 향후 확장 가능성
/// 1. **Persistent Cache**: 디스크 기반 캐싱 추가 (UserDefaults, Core Data)
/// 2. **Offline Support**: 네트워크 실패 시 오래된 캐시라도 반환
/// 3. **Analytics**: 캐시 히트율, API 호출 빈도 추적
/// 4. **Retry Logic**: 일시적 실패 시 자동 재시도
/// 5. **Background Sync**: 백그라운드에서 캐시 갱신
///
