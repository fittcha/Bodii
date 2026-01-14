//
//  NetworkManager.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Network Manager
// HTTP 네트워크 요청을 처리하는 중앙 관리 클래스
// 💡 Java 비교: Retrofit의 RestClient와 유사한 역할

import Foundation

/// HTTP 네트워크 요청을 처리하는 매니저 클래스
///
/// 📚 학습 포인트: Actor vs Class for Network Layer
/// URLSession은 thread-safe하므로 class 사용 가능
/// 💡 Java 비교: Singleton pattern의 OkHttpClient와 유사
///
/// **Features:**
/// - GET/POST 요청 지원
/// - Async/await 기반 비동기 처리
/// - 자동 JSON 디코딩
/// - 타임아웃 설정
/// - 재시도 로직
/// - 상세한 에러 처리
///
/// **Usage:**
/// ```swift
/// let networkManager = NetworkManager()
///
/// // GET 요청
/// struct Food: Decodable {
///     let name: String
///     let calories: Int
/// }
///
/// let foods: [Food] = try await networkManager.request(
///     url: "https://api.example.com/foods",
///     method: .get
/// )
///
/// // POST 요청
/// struct LoginRequest: Encodable {
///     let email: String
///     let password: String
/// }
///
/// let response: AuthResponse = try await networkManager.request(
///     url: "https://api.example.com/login",
///     method: .post,
///     body: LoginRequest(email: "user@example.com", password: "password")
/// )
/// ```
final class NetworkManager {

    // MARK: - Properties

    /// URLSession 인스턴스
    ///
    /// 📚 학습 포인트: URLSession
    /// iOS에서 네트워크 요청을 처리하는 기본 API
    /// 💡 Java 비교: HttpClient와 유사
    private let session: URLSession

    /// JSON 디코더
    ///
    /// 📚 학습 포인트: JSONDecoder
    /// JSON 데이터를 Swift 타입으로 자동 변환
    /// 💡 Java 비교: Gson, Jackson과 유사
    private let decoder: JSONDecoder

    /// JSON 인코더
    ///
    /// 📚 학습 포인트: JSONEncoder
    /// Swift 타입을 JSON 데이터로 변환
    /// 💡 Java 비교: Gson, Jackson의 serializer와 유사
    private let encoder: JSONEncoder

    /// 기본 타임아웃 시간 (초)
    ///
    /// 요청이 이 시간 내에 완료되지 않으면 timeout 에러 발생
    private let defaultTimeout: TimeInterval

    /// 최대 재시도 횟수
    ///
    /// 네트워크 에러 발생 시 자동으로 재시도할 최대 횟수
    private let maxRetries: Int

    // MARK: - Initialization

    /// NetworkManager 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// URLSession을 주입받아 테스트 시 Mock으로 교체 가능
    /// 💡 Java 비교: Constructor Injection 패턴
    ///
    /// - Parameters:
    ///   - session: URLSession 인스턴스 (기본값: .shared)
    ///   - timeout: 타임아웃 시간 (기본값: 30초)
    ///   - maxRetries: 최대 재시도 횟수 (기본값: 2)
    init(
        session: URLSession = .shared,
        timeout: TimeInterval = 30,
        maxRetries: Int = 2
    ) {
        self.session = session
        self.defaultTimeout = timeout
        self.maxRetries = maxRetries

        // JSONDecoder 설정
        self.decoder = JSONDecoder()
        // API 응답의 snake_case를 Swift의 camelCase로 자동 변환
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        // JSONEncoder 설정
        self.encoder = JSONEncoder()
        // Swift의 camelCase를 API의 snake_case로 자동 변환
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Public Methods

    /// HTTP 요청을 수행하고 결과를 디코딩합니다
    ///
    /// 📚 학습 포인트: Async/Await
    /// 비동기 작업을 동기 코드처럼 작성 가능
    /// 💡 Java 비교: CompletableFuture와 유사하지만 더 간결
    ///
    /// 📚 학습 포인트: Generics
    /// 다양한 응답 타입을 하나의 함수로 처리
    /// 💡 Java 비교: <T extends Decodable>와 동일
    ///
    /// - Parameters:
    ///   - url: 요청할 URL 문자열
    ///   - method: HTTP 메서드 (GET, POST 등)
    ///   - headers: HTTP 헤더 (기본값: nil)
    ///   - body: POST 요청 바디 (기본값: nil)
    ///   - timeout: 타임아웃 시간 (기본값: defaultTimeout)
    ///   - retries: 현재 재시도 횟수 (내부용, 기본값: 0)
    ///
    /// - Returns: 디코딩된 응답 데이터
    ///
    /// - Throws: NetworkError
    ///
    /// - Example:
    /// ```swift
    /// // GET 요청
    /// let foods: [Food] = try await networkManager.request(
    ///     url: "https://api.example.com/foods",
    ///     method: .get
    /// )
    ///
    /// // POST 요청 with body
    /// let response: AuthResponse = try await networkManager.request(
    ///     url: "https://api.example.com/login",
    ///     method: .post,
    ///     body: LoginRequest(email: "test@example.com", password: "pass")
    /// )
    /// ```
    func request<T: Decodable, B: Encodable>(
        url urlString: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: B? = nil,
        timeout: TimeInterval? = nil,
        retries: Int = 0
    ) async throws -> T {

        // URL 검증
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL(urlString)
        }

        // URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout ?? defaultTimeout

        // 헤더 설정
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 추가 헤더 설정
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        // POST 바디 설정
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        }

        // 요청 수행
        do {
            let (data, response) = try await session.data(for: request)

            // HTTP 응답 검증
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // HTTP 상태 코드 검증
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, message: message)
            }

            // 데이터 검증
            guard !data.isEmpty else {
                throw NetworkError.noData
            }

            // JSON 디코딩
            do {
                let decodedData = try decoder.decode(T.self, from: data)
                return decodedData
            } catch {
                throw NetworkError.decodingFailed(error)
            }

        } catch let error as NetworkError {
            // NetworkError는 그대로 throw
            throw error

        } catch let error as URLError {
            // URLError 처리
            return try await handleURLError(
                error,
                urlString: urlString,
                method: method,
                headers: headers,
                body: body,
                timeout: timeout,
                retries: retries
            )

        } catch {
            // 기타 에러
            throw NetworkError.unknown(error)
        }
    }

    /// 바디가 없는 GET 요청을 위한 편의 메서드
    ///
    /// 📚 학습 포인트: Method Overloading
    /// 같은 이름의 함수를 다른 파라미터로 여러 개 정의
    /// 💡 Java 비교: Method overloading과 동일
    ///
    /// - Parameters:
    ///   - url: 요청할 URL 문자열
    ///   - method: HTTP 메서드 (기본값: .get)
    ///   - headers: HTTP 헤더 (기본값: nil)
    ///   - timeout: 타임아웃 시간 (기본값: nil)
    ///
    /// - Returns: 디코딩된 응답 데이터
    ///
    /// - Throws: NetworkError
    func request<T: Decodable>(
        url urlString: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> T {
        return try await request(
            url: urlString,
            method: method,
            headers: headers,
            body: EmptyBody?.none,
            timeout: timeout
        )
    }

    // MARK: - Private Methods

    /// URLError 처리 및 재시도 로직
    ///
    /// 📚 학습 포인트: Error Handling & Retry Logic
    /// 일시적 네트워크 오류는 자동으로 재시도
    /// 💡 Java 비교: Retrofit의 Retry Interceptor와 유사
    ///
    /// - Parameters:
    ///   - error: URLError
    ///   - urlString: 요청 URL
    ///   - method: HTTP 메서드
    ///   - headers: HTTP 헤더
    ///   - body: 요청 바디
    ///   - timeout: 타임아웃
    ///   - retries: 현재 재시도 횟수
    ///
    /// - Returns: 재시도 성공 시 디코딩된 응답
    ///
    /// - Throws: NetworkError
    private func handleURLError<T: Decodable, B: Encodable>(
        _ error: URLError,
        urlString: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: B?,
        timeout: TimeInterval?,
        retries: Int
    ) async throws -> T {

        // 타임아웃 에러 처리
        if error.code == .timedOut {
            throw NetworkError.timeout
        }

        // 네트워크 연결 에러 처리
        if error.code == .notConnectedToInternet ||
           error.code == .networkConnectionLost ||
           error.code == .cannotConnectToHost {

            // 재시도 가능한 경우
            if retries < maxRetries {
                // 지수 백오프: 1초, 2초, 4초...
                let delay = pow(2.0, Double(retries))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // 재시도
                return try await request(
                    url: urlString,
                    method: method,
                    headers: headers,
                    body: body,
                    timeout: timeout,
                    retries: retries + 1
                )
            }

            throw NetworkError.networkUnavailable
        }

        // 기타 URLError
        throw NetworkError.unknown(error)
    }
}

// MARK: - Supporting Types

/// HTTP 메서드 열거형
///
/// 📚 학습 포인트: String RawValue Enum
/// rawValue를 통해 문자열과 enum을 쉽게 변환
/// 💡 Java 비교: Enum with String value와 동일
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// 빈 요청 바디를 위한 타입
///
/// 📚 학습 포인트: Empty Encodable Type
/// GET 요청처럼 바디가 없는 경우를 위한 타입
private struct EmptyBody: Encodable {}
