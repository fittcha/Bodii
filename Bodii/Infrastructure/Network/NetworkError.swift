//
//  NetworkError.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Network Error Handling
// 네트워크 요청에서 발생할 수 있는 다양한 에러를 열거형으로 정의
// 💡 Java 비교: Exception 클래스 대신 타입 안전한 enum 사용

import Foundation

/// Network operation errors
///
/// 네트워크 작업에서 발생할 수 있는 에러 타입
///
/// 📚 학습 포인트: Error Protocol
/// Swift에서는 Error 프로토콜을 채택하면 throw/catch로 에러 처리 가능
/// 💡 Java 비교: Exception 대신 Error 프로토콜 + enum 사용
///
/// - Cases:
///   - invalidURL: URL 형식이 잘못됨
///   - noData: 서버 응답에 데이터가 없음
///   - decodingFailed: JSON 디코딩 실패
///   - invalidResponse: HTTP 응답 형식이 잘못됨
///   - httpError: HTTP 에러 (상태 코드와 메시지 포함)
///   - timeout: 요청 시간 초과
///   - networkUnavailable: 네트워크 연결 없음
///   - unknown: 알 수 없는 에러
///
/// - Example:
/// ```swift
/// do {
///     let data = try await networkManager.request(...)
/// } catch NetworkError.timeout {
///     print("요청 시간이 초과되었습니다")
/// } catch NetworkError.httpError(let statusCode, let message) {
///     print("HTTP 에러 \(statusCode): \(message)")
/// }
/// ```
enum NetworkError: Error {

    // MARK: - Cases

    /// URL이 유효하지 않음
    ///
    /// URL 문자열을 URL 객체로 변환할 수 없을 때 발생
    case invalidURL(String)

    /// 응답 데이터가 없음
    ///
    /// 서버가 응답을 보냈지만 데이터가 비어있을 때 발생
    case noData

    /// JSON 디코딩 실패
    ///
    /// 서버 응답을 지정된 타입으로 디코딩할 수 없을 때 발생
    case decodingFailed(Error)

    /// HTTP 응답 형식이 잘못됨
    ///
    /// URLResponse를 HTTPURLResponse로 캐스팅할 수 없을 때 발생
    case invalidResponse

    /// HTTP 에러 응답
    ///
    /// HTTP 상태 코드가 200-299 범위를 벗어났을 때 발생
    /// - Parameters:
    ///   - statusCode: HTTP 상태 코드 (예: 404, 500)
    ///   - message: 에러 메시지
    case httpError(statusCode: Int, message: String)

    /// 요청 시간 초과
    ///
    /// 설정된 timeout 시간 내에 응답을 받지 못했을 때 발생
    case timeout

    /// 네트워크 연결 불가
    ///
    /// 인터넷 연결이 없거나 서버에 접근할 수 없을 때 발생
    case networkUnavailable

    /// 알 수 없는 에러
    ///
    /// 위의 경우에 해당하지 않는 기타 에러
    case unknown(Error)
}

// MARK: - LocalizedError

/// 사용자 친화적인 에러 메시지 제공
///
/// 📚 학습 포인트: LocalizedError Protocol
/// 에러에 대한 지역화된(한국어) 메시지를 제공
/// 💡 Java 비교: getMessage()와 유사하지만 프로토콜 기반
extension NetworkError: LocalizedError {

    /// 사용자에게 표시할 에러 설명 (한국어)
    ///
    /// 📚 학습 포인트: Computed Property
    /// 저장 프로퍼티가 아닌 계산 프로퍼티로 필요할 때마다 생성
    /// 💡 Java 비교: getter 메서드와 유사하지만 더 간결
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "잘못된 URL입니다: \(url)"

        case .noData:
            return "서버 응답에 데이터가 없습니다"

        case .decodingFailed(let error):
            return "응답 데이터를 처리할 수 없습니다: \(error.localizedDescription)"

        case .invalidResponse:
            return "서버 응답 형식이 올바르지 않습니다"

        case .httpError(let statusCode, let message):
            return "서버 에러 (코드 \(statusCode)): \(message)"

        case .timeout:
            return "요청 시간이 초과되었습니다"

        case .networkUnavailable:
            return "네트워크 연결을 확인해주세요"

        case .unknown(let error):
            return "알 수 없는 에러가 발생했습니다: \(error.localizedDescription)"
        }
    }
}

// MARK: - Equatable

/// 에러 비교 지원 (테스트에 유용)
///
/// 📚 학습 포인트: Equatable Protocol
/// 두 에러 값을 비교할 수 있게 만듦 (특히 테스트에서 유용)
/// 💡 Java 비교: equals() 메서드와 유사
extension NetworkError: Equatable {

    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL(let lhsURL), .invalidURL(let rhsURL)):
            return lhsURL == rhsURL

        case (.noData, .noData):
            return true

        case (.decodingFailed, .decodingFailed):
            // Note: Error는 Equatable이 아니므로 타입만 비교
            return true

        case (.invalidResponse, .invalidResponse):
            return true

        case (.httpError(let lhsCode, let lhsMsg), .httpError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg

        case (.timeout, .timeout):
            return true

        case (.networkUnavailable, .networkUnavailable):
            return true

        case (.unknown, .unknown):
            // Note: Error는 Equatable이 아니므로 타입만 비교
            return true

        default:
            return false
        }
    }
}
