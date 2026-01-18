//
//  GeminiAPIService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: AI API Service with Rate Limiting
// Gemini API 호출을 관리하는 서비스 클래스 with 15 RPM rate limiting
// 💡 Java 비교: Retrofit의 Service Interface + Rate Limiter와 유사한 역할

import Foundation

/// Google Gemini API 서비스
///
/// 📚 학습 포인트: AI API Service Layer with Rate Limiting
/// AI API 호출을 캡슐화하고 rate limiting을 통해 API 제한 준수
/// 💡 Java 비교: Repository 패턴의 Remote DataSource + Resilience4j RateLimiter와 유사
///
/// **주요 기능:**
/// - AI 텍스트 생성 (Diet Comment)
/// - Rate limiting (15 requests/minute)
/// - 자동 재시도 (transient failures)
/// - 에러 처리 및 타임아웃
/// - API 키 주입 및 관리
///
/// **API 정보:**
/// - Provider: Google Generative AI
/// - Model: gemini-1.5-flash
/// - API 문서: https://ai.google.dev/api/rest
/// - Rate Limit: 15 requests/minute (무료 티어)
///
/// **사용 예시:**
/// ```swift
/// let service = GeminiAPIService()
///
/// // 식단 분석 요청
/// let request = GeminiRequestDTO(
///     prompt: "다음 식단을 분석해주세요: 아침 - 김치찌개, 공기밥",
///     temperature: 0.7,
///     maxOutputTokens: 1024
/// )
///
/// let response = try await service.generateContent(request: request)
/// if let text = response.generatedText {
///     print("AI 응답: \(text)")
/// }
/// ```
final class GeminiAPIService {

    // MARK: - Properties

    /// 네트워크 매니저
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// NetworkManager를 주입받아 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: Constructor Injection 패턴
    private let networkManager: NetworkManager

    /// API 설정
    ///
    /// API URL과 인증 키를 제공하는 설정 객체
    private let apiConfig: APIConfigProtocol

    /// Rate limiter
    ///
    /// 📚 학습 포인트: Rate Limiting with Actor
    /// Actor를 사용한 thread-safe rate limiting
    /// 💡 Java 비교: Resilience4j의 RateLimiter와 유사
    private let rateLimiter: GeminiRateLimiter

    // MARK: - Initialization

    /// GeminiAPIService 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 의존성을 주입받아 테스트와 유연성 향상
    /// 💡 Java 비교: @Inject 어노테이션과 유사한 패턴
    ///
    /// - Parameters:
    ///   - networkManager: 네트워크 요청을 처리할 매니저 (기본값: Gemini용 설정)
    ///   - apiConfig: API 설정 (기본값: APIConfig.shared)
    ///   - rateLimiter: Rate limiter (기본값: 15 RPM)
    init(
        networkManager: NetworkManager = NetworkManager(
            timeout: Constants.API.Gemini.timeout,
            maxRetries: Constants.API.Gemini.maxRetries
        ),
        apiConfig: APIConfigProtocol = APIConfig.shared,
        rateLimiter: GeminiRateLimiter = GeminiRateLimiter()
    ) {
        self.networkManager = networkManager
        self.apiConfig = apiConfig
        self.rateLimiter = rateLimiter
    }

    // MARK: - Public Methods

    /// AI 텍스트 생성 요청
    ///
    /// 📚 학습 포인트: Async/Await AI API Call
    /// 비동기 AI API 요청을 동기 코드처럼 작성
    /// 💡 Java 비교: CompletableFuture와 유사하지만 더 간결
    ///
    /// 📚 학습 포인트: Rate Limiting
    /// 요청 전에 rate limiter를 통해 15 RPM 제한 준수
    /// 💡 Java 비교: Resilience4j의 @RateLimiter와 유사
    ///
    /// - Parameters:
    ///   - request: Gemini API 요청 DTO
    ///   - model: 사용할 Gemini 모델 (기본값: gemini-1.5-flash)
    ///
    /// - Returns: AI 응답 DTO
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - GeminiAPIError: API 에러 (rate limit, authentication 등)
    ///
    /// - Example:
    /// ```swift
    /// let request = GeminiRequestDTO(
    ///     prompt: "Analyze this meal: breakfast - kimchi stew, rice",
    ///     temperature: 0.7
    /// )
    ///
    /// let response = try await service.generateContent(request: request)
    /// if response.isSuccess, let text = response.generatedText {
    ///     print("AI response: \(text)")
    /// }
    /// ```
    func generateContent(
        request: GeminiRequestDTO,
        model: String = "gemini-1.5-flash"
    ) async throws -> GeminiResponseDTO {

        // 요청 유효성 검증
        guard request.isValid else {
            throw GeminiAPIError.invalidRequest("요청 데이터가 유효하지 않습니다.")
        }

        // Rate limiting: 15 RPM 제한 확인
        try await rateLimiter.acquirePermit()

        // URL 생성
        let endpoint = APIConfig.GeminiEndpoint.generateContent(model: model)

        guard let url = apiConfig.buildGeminiURL(endpoint: endpoint) else {
            throw NetworkError.invalidURL("Gemini API URL 생성 실패")
        }

        // API 요청
        do {
            let response: GeminiResponseDTO = try await networkManager.request(
                url: url.absoluteString,
                method: .post,
                body: request,
                timeout: Constants.API.Gemini.timeout
            )

            // API 응답 검증
            guard response.isValid else {
                throw GeminiAPIError.invalidRequest("응답 데이터가 유효하지 않습니다.")
            }

            // 에러 체크
            if let error = response.errorType {
                throw error
            }

            // 성공 응답 확인
            guard response.isSuccess else {
                // finishReason이 STOP이 아닌 경우
                if let finishReason = response.finishReason {
                    throw GeminiAPIError.unknown(finishReason)
                } else {
                    throw GeminiAPIError.noCandidates
                }
            }

            return response

        } catch let error as GeminiAPIError {
            // Gemini API 에러는 그대로 전달
            throw error

        } catch let error as NetworkError {
            // 네트워크 에러를 Gemini 에러로 변환
            if case .httpError(let statusCode, let message) = error {
                // HTTP 에러 코드별 처리
                switch statusCode {
                case 401, 403:
                    throw GeminiAPIError.authenticationFailed
                case 429:
                    throw GeminiAPIError.rateLimitExceeded
                case 400:
                    throw GeminiAPIError.invalidRequest(message)
                default:
                    throw GeminiAPIError.networkError(error)
                }
            } else {
                throw GeminiAPIError.networkError(error)
            }

        } catch {
            // 기타 에러
            throw GeminiAPIError.unknown(error.localizedDescription)
        }
    }

    /// 간단한 텍스트 프롬프트로 AI 응답 생성
    ///
    /// 📚 학습 포인트: Convenience Method
    /// 자주 사용하는 패턴을 간편하게 사용
    /// 💡 Java 비교: Overloaded method와 유사
    ///
    /// - Parameters:
    ///   - prompt: 사용자 프롬프트 텍스트
    ///   - temperature: AI 응답의 창의성 (0.0-1.0, 기본값: 0.7)
    ///   - maxOutputTokens: 최대 출력 토큰 수 (기본값: 1024)
    ///
    /// - Returns: AI가 생성한 텍스트 (없으면 nil)
    ///
    /// - Throws:
    ///   - NetworkError: 네트워크 요청 실패
    ///   - GeminiAPIError: API 에러
    ///
    /// - Example:
    /// ```swift
    /// let text = try await service.generateText(
    ///     prompt: "다음 식단을 분석해주세요: 아침 - 김치찌개, 공기밥"
    /// )
    /// print("AI 응답: \(text ?? "응답 없음")")
    /// ```
    func generateText(
        prompt: String,
        temperature: Double = 0.7,
        maxOutputTokens: Int = 1024
    ) async throws -> String? {

        // 요청 생성
        let request = GeminiRequestDTO(
            prompt: prompt,
            temperature: temperature,
            maxOutputTokens: maxOutputTokens
        )

        // API 호출
        let response = try await generateContent(request: request)

        // 생성된 텍스트 반환
        return response.generatedText
    }
}

// MARK: - Rate Limiter

/// Gemini API Rate Limiter (15 requests per minute)
///
/// 📚 학습 포인트: Actor for Thread-Safe Rate Limiting
/// Actor를 사용하여 thread-safe한 rate limiting 구현
/// 💡 Java 비교: Synchronized class + Semaphore와 유사하지만 더 안전
///
/// **알고리즘:**
/// - Token Bucket 방식 사용
/// - 매분 최대 15개 토큰 사용 가능
/// - 토큰 소진 시 다음 토큰까지 대기
///
/// **구현 세부사항:**
/// - 슬라이딩 윈도우 방식으로 요청 타임스탬프 관리
/// - 1분 이상 지난 요청은 자동 제거
/// - 요청 시점에 토큰 확보 (acquirePermit)
actor GeminiRateLimiter {

    // MARK: - Properties

    /// 요청 타임스탬프 기록
    ///
    /// 📚 학습 포인트: Sliding Window Rate Limiting
    /// 최근 1분간의 요청 타임스탬프를 저장
    /// 💡 Java 비교: Queue<Instant>와 유사
    private var requestTimestamps: [Date] = []

    /// 분당 최대 요청 수
    private let maxRequestsPerMinute: Int

    /// Rate limit 윈도우 시간 (초)
    private let windowSeconds: TimeInterval

    // MARK: - Initialization

    /// Rate limiter 초기화
    ///
    /// - Parameters:
    ///   - maxRequestsPerMinute: 분당 최대 요청 수 (기본값: 15)
    ///   - windowSeconds: Rate limit 윈도우 시간 (기본값: 60초)
    init(
        maxRequestsPerMinute: Int = Constants.API.Gemini.requestsPerMinute,
        windowSeconds: TimeInterval = Constants.API.Gemini.rateLimitWindow
    ) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
        self.windowSeconds = windowSeconds
    }

    // MARK: - Public Methods

    /// 요청 허가 획득 (rate limit 체크)
    ///
    /// 📚 학습 포인트: Async Rate Limiting
    /// Rate limit 초과 시 자동으로 대기 후 진행
    /// 💡 Java 비교: Semaphore.acquire()와 유사하지만 async
    ///
    /// - Throws: GeminiAPIError.rateLimitExceeded (대기 불가능한 경우)
    ///
    /// - Note: 이 메서드는 rate limit 범위 내일 때까지 대기함
    func acquirePermit() async throws {
        // 현재 시간
        let now = Date()

        // 윈도우 시작 시간 (현재 시간 - 60초)
        let windowStart = now.addingTimeInterval(-windowSeconds)

        // 윈도우 범위 밖의 요청 제거
        requestTimestamps = requestTimestamps.filter { $0 > windowStart }

        // Rate limit 체크
        if requestTimestamps.count >= maxRequestsPerMinute {
            // Rate limit 초과: 가장 오래된 요청이 윈도우를 벗어날 때까지 대기
            if let oldestRequest = requestTimestamps.first {
                let waitUntil = oldestRequest.addingTimeInterval(windowSeconds)
                let waitTime = waitUntil.timeIntervalSince(now)

                if waitTime > 0 {
                    // 대기 시간이 너무 길면 에러 발생 (1분 초과)
                    if waitTime > windowSeconds {
                        throw GeminiAPIError.rateLimitExceeded
                    }

                    // 대기
                    let nanoseconds = UInt64(waitTime * 1_000_000_000)
                    try await Task.sleep(nanoseconds: nanoseconds)

                    // 재귀 호출로 다시 확인
                    try await acquirePermit()
                    return
                }
            }
        }

        // 요청 타임스탬프 기록
        requestTimestamps.append(now)
    }

    /// 현재 사용 가능한 요청 수 확인
    ///
    /// 📚 학습 포인트: Rate Limit Status Check
    /// 현재 사용 가능한 요청 수 조회 (UI 표시용)
    /// 💡 Java 비교: Semaphore.availablePermits()와 유사
    ///
    /// - Returns: 사용 가능한 요청 수
    func availablePermits() -> Int {
        let now = Date()
        let windowStart = now.addingTimeInterval(-windowSeconds)

        // 윈도우 범위 내의 요청 수 계산
        let recentRequestCount = requestTimestamps.filter { $0 > windowStart }.count

        return max(0, maxRequestsPerMinute - recentRequestCount)
    }

    /// Rate limiter 초기화 (테스트용)
    ///
    /// 📚 학습 포인트: Test Helper
    /// 테스트에서 rate limiter 상태를 초기화
    /// 💡 Java 비교: @Before에서 호출하는 reset() 메서드와 유사
    func reset() {
        requestTimestamps.removeAll()
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Gemini API 서비스
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockGeminiAPIService {

    /// Mock 응답 데이터
    var mockResponse: GeminiResponseDTO?

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// Rate limiter 호출 여부 추적
    var rateLimiterCalled: Bool = false

    /// 생성 메서드 Mock
    func generateContent(
        request: GeminiRequestDTO,
        model: String = "gemini-1.5-flash"
    ) async throws -> GeminiResponseDTO {

        rateLimiterCalled = true

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 응답 반환
        guard let response = mockResponse else {
            throw GeminiAPIError.noCandidates
        }

        return response
    }

    /// 텍스트 생성 메서드 Mock
    func generateText(
        prompt: String,
        temperature: Double = 0.7,
        maxOutputTokens: Int = 1024
    ) async throws -> String? {

        rateLimiterCalled = true

        // 에러 시뮬레이션
        if let error = shouldThrowError {
            throw error
        }

        // Mock 응답에서 텍스트 추출
        return mockResponse?.generatedText
    }
}
#endif
