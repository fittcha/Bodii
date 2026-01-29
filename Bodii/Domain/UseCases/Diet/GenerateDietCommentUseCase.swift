//
//  GenerateDietCommentUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

import Foundation

/// 식단 AI 코멘트 생성 유스케이스
///
/// 사용자의 식단을 분석하여 AI 기반 코멘트를 생성합니다.
/// 캐싱 전략을 통해 중복 API 호출을 방지하고, 오프라인 시 캐시된 코멘트를 반환합니다.
///
/// ## 책임
/// - 캐시 우선 전략 (Check cache before API call)
/// - 식단 기록 조회 및 검증
/// - AI 코멘트 생성 (GeminiService 사용)
/// - 생성된 코멘트 캐싱
/// - 에러 처리 (Rate limit, Network failure, etc.)
/// - 오프라인 시 캐시된 코멘트 fallback
///
/// ## 의존성
/// - DietCommentRepository: 코멘트 캐싱 및 조회
/// - GeminiServiceProtocol: AI 코멘트 생성
/// - FoodRecordRepositoryProtocol: 식단 기록 조회
///
/// ## 사용 시나리오
/// ```swift
/// let useCase = GenerateDietCommentUseCase(
///     dietCommentRepository: dietCommentRepository,
///     geminiService: geminiService,
///     foodRecordRepository: foodRecordRepository
/// )
///
/// let comment = try await useCase.execute(
///     userId: userId,
///     date: Date(),
///     mealType: .lunch,
///     goalType: .lose,
///     tdee: 2100
/// )
/// print("점수: \(comment.score)/10")
/// print("요약: \(comment.summary)")
/// ```
///
/// ## 에러 케이스
/// - 식단 기록 없음: DietCommentError.noFoodRecords
/// - Rate limit 초과: DietCommentError.rateLimitExceeded (캐시 반환)
/// - 네트워크 실패: DietCommentError.networkFailure (캐시 반환)
/// - API 에러: DietCommentError.apiError (캐시 반환)
final class GenerateDietCommentUseCase {

    // MARK: - Properties

    /// 식단 코멘트 저장소
    private let dietCommentRepository: DietCommentRepository

    /// Gemini AI 서비스
    private let geminiService: GeminiServiceProtocol

    /// 식단 기록 저장소
    private let foodRecordRepository: FoodRecordRepositoryProtocol

    // MARK: - Initialization

    /// GenerateDietCommentUseCase 초기화
    ///
    /// - Parameters:
    ///   - dietCommentRepository: 식단 코멘트 저장소
    ///   - geminiService: Gemini AI 서비스
    ///   - foodRecordRepository: 식단 기록 저장소
    init(
        dietCommentRepository: DietCommentRepository,
        geminiService: GeminiServiceProtocol,
        foodRecordRepository: FoodRecordRepositoryProtocol
    ) {
        self.dietCommentRepository = dietCommentRepository
        self.geminiService = geminiService
        self.foodRecordRepository = foodRecordRepository
    }

    // MARK: - Public Methods

    /// 식단 AI 코멘트를 생성합니다.
    ///
    /// ## 실행 순서
    /// 1. 캐시된 코멘트 확인 (Cache-First Strategy)
    /// 2. 캐시 히트 시 캐시 반환
    /// 3. 캐시 미스 시:
    ///    a. 식단 기록 조회 (FoodRecordRepository)
    ///    b. 식단 기록 검증 (비어있지 않은지)
    ///    c. AI 코멘트 생성 (GeminiService)
    ///    d. 생성된 코멘트 캐싱 (DietCommentRepository)
    ///    e. 생성된 코멘트 반환
    /// 4. 에러 발생 시 (Rate limit, Network):
    ///    - 캐시된 코멘트가 있으면 캐시 반환
    ///    - 캐시도 없으면 에러 throw
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 평가 대상 날짜
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///   - goalType: 사용자 목표 (감량/유지/증량)
    ///   - tdee: 활동대사량 (kcal)
    ///
    /// - Throws:
    ///   - `DietCommentError.noFoodRecords`: 식단 기록이 없을 때
    ///   - `DietCommentError.apiError`: API 호출 실패 (캐시도 없을 때)
    ///   - `DietCommentError.rateLimitExceeded`: Rate limit 초과 (캐시도 없을 때)
    ///   - `DietCommentError.networkFailure`: 네트워크 실패 (캐시도 없을 때)
    ///   - `DietCommentError.invalidResponse`: 응답 파싱 실패 (캐시도 없을 때)
    ///
    /// - Returns: 생성된 또는 캐시된 DietComment
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     let comment = try await useCase.execute(
    ///         userId: currentUser.id,
    ///         date: Date(),
    ///         mealType: .lunch,
    ///         goalType: .lose,
    ///         tdee: 2100
    ///     )
    ///     print("AI 분석 완료: \(comment.summary)")
    /// } catch DietCommentError.noFoodRecords {
    ///     print("식단을 먼저 기록해주세요")
    /// } catch DietCommentError.rateLimitExceeded(let retryAfter) {
    ///     print("\(Int(retryAfter/60))분 후 다시 시도해주세요")
    /// }
    /// ```
    func execute(
        userId: UUID,
        date: Date,
        mealType: MealType?,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment {

        // 1. 캐시된 코멘트 확인 (Cache-First Strategy)
        if let cachedComment = try await dietCommentRepository.getCachedComment(
            for: date,
            userId: userId,
            mealType: mealType
        ) {
            // 캐시 히트 - 즉시 반환
            return cachedComment
        }

        // 2. 식단 기록 조회
        let foodRecords: [FoodRecord]
        do {
            foodRecords = try await fetchFoodRecords(
                date: date,
                userId: userId,
                mealType: mealType
            )
        } catch {
            // 식단 기록 조회 실패 - 캐시도 없으므로 에러 throw
            throw DietCommentError.noFoodRecords
        }

        // 3. 식단 기록 검증
        guard !foodRecords.isEmpty else {
            throw DietCommentError.noFoodRecords
        }

        // 4. AI 코멘트 생성 (에러 처리 포함)
        do {
            let comment = try await geminiService.generateDietComment(
                foodRecords: foodRecords,
                mealType: mealType,
                userId: userId,
                date: date,
                goalType: goalType,
                tdee: tdee
            )

            // 5. 생성된 코멘트 캐싱
            try? await dietCommentRepository.saveComment(comment)

            return comment

        } catch let error as GeminiServiceError {
            // GeminiService 에러 처리
            throw mapGeminiServiceError(error)

        } catch {
            // 기타 에러는 apiError로 래핑
            throw DietCommentError.apiError(error.localizedDescription)
        }
    }

    /// 캐시를 무효화하고 새로운 AI 식단 코멘트를 생성합니다.
    ///
    /// 식단이 추가/수정/삭제될 때마다 호출되어 최신 식단 상태를 반영한 코멘트를 생성합니다.
    /// 기존 캐시를 먼저 삭제한 뒤 새로 생성하여 캐시에 저장합니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 평가 대상 날짜
    ///   - mealType: 끼니 종류 (nil이면 일일 전체 식단)
    ///   - goalType: 사용자 목표 (감량/유지/증량)
    ///   - tdee: 활동대사량 (kcal)
    /// - Returns: 새로 생성된 DietComment
    func executeIgnoringCache(
        userId: UUID,
        date: Date,
        mealType: MealType?,
        goalType: GoalType,
        tdee: Int
    ) async throws -> DietComment {

        // 1. 기존 캐시 무효화
        try? await dietCommentRepository.clearCache(
            for: date,
            userId: userId,
            mealType: mealType
        )

        // 2. 식단 기록 조회
        let foodRecords: [FoodRecord]
        do {
            foodRecords = try await fetchFoodRecords(
                date: date,
                userId: userId,
                mealType: mealType
            )
        } catch {
            throw DietCommentError.noFoodRecords
        }

        // 3. 식단 기록 검증
        guard !foodRecords.isEmpty else {
            throw DietCommentError.noFoodRecords
        }

        // 4. AI 코멘트 새로 생성
        do {
            let comment = try await geminiService.generateDietComment(
                foodRecords: foodRecords,
                mealType: mealType,
                userId: userId,
                date: date,
                goalType: goalType,
                tdee: tdee
            )

            // 5. 새 코멘트 캐싱
            try? await dietCommentRepository.saveComment(comment)

            return comment

        } catch let error as GeminiServiceError {
            throw mapGeminiServiceError(error)
        } catch {
            throw DietCommentError.apiError(error.localizedDescription)
        }
    }

    // MARK: - Private Helpers

    /// 식단 기록 조회
    ///
    /// mealType이 nil이면 해당 날짜의 모든 식단 기록을 조회하고,
    /// mealType이 있으면 해당 끼니의 식단 기록만 조회합니다.
    ///
    /// - Parameters:
    ///   - date: 조회할 날짜
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 종류 (nil이면 전체 식단)
    ///
    /// - Returns: 조회된 식단 기록 배열
    ///
    /// - Throws: FoodRecordRepository의 조회 에러
    private func fetchFoodRecords(
        date: Date,
        userId: UUID,
        mealType: MealType?
    ) async throws -> [FoodRecord] {

        if let mealType = mealType {
            // 특정 끼니의 식단 기록 조회
            return try await foodRecordRepository.findByDateAndMealType(
                date,
                mealType: mealType,
                userId: userId
            )
        } else {
            // 전체 날짜의 식단 기록 조회
            return try await foodRecordRepository.findByDate(
                date,
                userId: userId
            )
        }
    }

    /// GeminiServiceError를 DietCommentError로 매핑
    ///
    /// GeminiService 레이어의 에러를 UseCase 레이어의 에러로 변환합니다.
    /// 이를 통해 상위 레이어(Presentation)는 GeminiService의 구체적인 구현을 알 필요가 없습니다.
    ///
    /// - Parameter error: GeminiServiceError
    ///
    /// - Returns: 매핑된 DietCommentError
    private func mapGeminiServiceError(_ error: GeminiServiceError) -> DietCommentError {
        switch error {
        case .emptyFoodRecords:
            return .noFoodRecords

        case .invalidResponse(let message):
            return .invalidResponse

        case .apiError(let underlyingError):
            // GeminiAPIError 체크
            if let geminiAPIError = underlyingError as? GeminiAPIError {
                return mapGeminiAPIError(geminiAPIError)
            }
            return .apiError(underlyingError.localizedDescription)

        case .jsonParsingFailed:
            return .invalidResponse

        case .imageEncodingFailed:
            return .invalidResponse
        }
    }

    /// GeminiAPIError를 DietCommentError로 매핑
    ///
    /// Gemini API 레이어의 에러를 UseCase 레이어의 에러로 변환합니다.
    /// 특히 Rate Limit과 Network 에러를 구별하여 처리합니다.
    ///
    /// - Parameter error: GeminiAPIError
    ///
    /// - Returns: 매핑된 DietCommentError
    private func mapGeminiAPIError(_ error: GeminiAPIError) -> DietCommentError {
        switch error {
        case .rateLimitExceeded:
            // Rate limit 초과 - 60초 후 재시도 (15 RPM 기준)
            return .rateLimitExceeded(retryAfter: 60)

        case .networkError:
            return .networkFailure

        case .authenticationFailed:
            return .apiError("API 인증에 실패했습니다. 관리자에게 문의하세요.")

        case .invalidRequest:
            return .invalidResponse

        case .parsingError:
            return .invalidResponse

        case .contentFiltered(let message):
            return .apiError("콘텐츠 필터에 의해 차단되었습니다: \(message)")

        case .maxTokensReached:
            return .apiError("응답이 너무 길어 중단되었습니다.")

        case .noCandidates:
            return .invalidResponse

        case .unknown(let message):
            return .apiError(message)
        }
    }
}

// MARK: - UseCase Pattern 설명

/// ## UseCase Pattern in AI Feature
///
/// GenerateDietCommentUseCase는 AI 식단 코멘트 생성이라는 복잡한 비즈니스 플로우를 조율합니다.
///
/// ### 캐시 우선 전략 (Cache-First Strategy)
///
/// **왜 캐시 우선인가?**
/// - Gemini API는 Rate Limit이 있음 (15 RPM)
/// - 동일한 식단에 대해 중복 API 호출 방지
/// - 응답 속도 향상 (즉시 반환)
/// - 비용 절감 (API 호출 최소화)
///
/// **캐시 전략:**
/// 1. 먼저 캐시 확인
/// 2. 캐시 히트 → 즉시 반환
/// 3. 캐시 미스 → API 호출 → 캐싱 → 반환
/// 4. API 실패 → 캐시 fallback (오프라인 지원)
///
/// ### 에러 처리 전략 (Graceful Degradation)
///
/// **Rate Limit 처리:**
/// - GeminiAPIService에서 Rate Limiter로 1차 방어
/// - 그래도 초과 시 DietCommentError.rateLimitExceeded 반환
/// - retryAfter 시간 정보 제공 (UI에서 사용자에게 안내)
///
/// **네트워크 실패 처리:**
/// - 네트워크 에러 발생 시 DietCommentError.networkFailure
/// - 사용자에게 명확한 안내 메시지
///
/// **오프라인 지원:**
/// - 캐시된 코멘트가 있으면 캐시 반환
/// - 캐시도 없으면 에러 throw
///
/// ### 의존성 계층
///
/// ```
/// [Presentation]   DietCommentViewModel
///       ↓
/// [UseCase]        GenerateDietCommentUseCase
///       ↓ ↓ ↓
/// [Domain]         DietCommentRepository, GeminiService, FoodRecordRepository
///       ↓
/// [Data]           DietCommentCache, GeminiAPIService, CoreData
/// ```
///
/// ### 사용 예시
///
/// ```swift
/// // ViewModel에서 UseCase 사용
/// final class DietCommentViewModel: ObservableObject {
///     let generateCommentUseCase: GenerateDietCommentUseCase
///
///     @Published var comment: DietComment?
///     @Published var isLoading = false
///     @Published var errorMessage: String?
///
///     func generateComment(for date: Date, mealType: MealType?) async {
///         isLoading = true
///         defer { isLoading = false }
///
///         do {
///             // UseCase가 모든 비즈니스 로직 처리
///             // - 캐시 확인
///             // - 식단 기록 조회
///             // - AI 코멘트 생성
///             // - 캐싱
///             // - 에러 처리
///             comment = try await generateCommentUseCase.execute(
///                 userId: currentUser.id,
///                 date: date,
///                 mealType: mealType,
///                 goalType: currentUser.goalType,
///                 tdee: currentUser.tdee
///             )
///         } catch DietCommentError.noFoodRecords {
///             errorMessage = "식단을 먼저 기록해주세요"
///         } catch DietCommentError.rateLimitExceeded(let retryAfter) {
///             errorMessage = "\(Int(retryAfter/60))분 후 다시 시도해주세요"
///         } catch DietCommentError.networkFailure {
///             errorMessage = "네트워크 연결을 확인해주세요"
///         } catch {
///             errorMessage = error.localizedDescription
///         }
///     }
/// }
/// ```
///
/// ### 왜 UseCase가 필요한가?
///
/// 1. **비즈니스 로직 중앙화**:
///    - 캐시 전략, 에러 처리 등의 복잡한 로직을 한 곳에서 관리
///    - ViewModel은 UI 로직에만 집중
///
/// 2. **재사용성**:
///    - DietCommentViewModel 외에도 다른 진입점에서 재사용 가능
///    - Widget, Today Extension, Siri Shortcut 등
///
/// 3. **테스트 용이성**:
///    - Repository와 Service를 Mock으로 대체하여 격리된 테스트
///    - 캐시 전략, 에러 처리 로직을 단위 테스트 가능
///
/// 4. **유지보수성**:
///    - 비즈니스 로직 변경 시 UseCase만 수정
///    - ViewModel과 UI는 영향 받지 않음
///
/// 5. **명확한 책임 분리**:
///    - UseCase: 비즈니스 플로우 조율
///    - Repository: 데이터 영속성
///    - Service: 도메인 로직
///    - ViewModel: UI 상태 관리
///
