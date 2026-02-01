//
//  GeminiResponseDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Google Gemini API Response Structure
// Gemini API의 텍스트 생성 응답 구조
// 💡 Java 비교: ChatGPT API Response와 유사한 구조

import Foundation

/// Google Gemini API 응답 DTO
///
/// 📚 학습 포인트: AI Content Generation Response
/// Gemini API의 generateContent 엔드포인트 응답 구조
/// 💡 Java 비교: REST API 응답 바디와 동일
///
/// **API 응답 구조:**
/// ```json
/// {
///   "candidates": [
///     {
///       "content": {
///         "parts": [
///           {
///             "text": "생성된 텍스트 응답..."
///           }
///         ],
///         "role": "model"
///       },
///       "finishReason": "STOP",
///       "index": 0,
///       "safetyRatings": [...]
///     }
///   ],
///   "promptFeedback": {
///     "safetyRatings": [...]
///   },
///   "usageMetadata": {
///     "promptTokenCount": 10,
///     "candidatesTokenCount": 100,
///     "totalTokenCount": 110
///   }
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let response: GeminiResponseDTO = try JSONDecoder().decode(
///     GeminiResponseDTO.self,
///     from: jsonData
/// )
///
/// if let text = response.generatedText {
///     print("AI 응답: \(text)")
/// }
/// ```
///
/// **참고:**
/// - API 문서: https://ai.google.dev/api/rest/v1beta/GenerateContentResponse
/// - 모델: gemini-2.5-flash-lite (빠른 응답, 무료 티어)
struct GeminiResponseDTO: Codable {

    // MARK: - Properties

    /// 생성된 후보 응답 배열
    ///
    /// 📚 학습 포인트: Multiple Candidates
    /// Gemini는 여러 응답 후보를 생성할 수 있음
    /// 일반적으로 첫 번째 후보를 사용
    let candidates: [Candidate]?

    /// 프롬프트 피드백
    ///
    /// 프롬프트가 차단되었는지 등의 정보
    /// 안전 설정에 의해 요청이 차단된 경우 candidates가 nil일 수 있음
    let promptFeedback: PromptFeedback?

    /// 사용량 메타데이터 (선택적)
    ///
    /// 토큰 사용량 정보
    let usageMetadata: UsageMetadata?

    // MARK: - Nested Types

    /// 📚 학습 포인트: Candidate Structure
    /// 생성된 응답 후보
    /// 💡 Java 비교: Inner Class와 유사
    struct Candidate: Codable {
        /// 생성된 콘텐츠
        ///
        /// AI 모델이 생성한 응답 텍스트
        let content: Content?

        /// 완료 이유
        ///
        /// 📚 학습 포인트: Finish Reason
        /// - "STOP": 정상 완료
        /// - "MAX_TOKENS": 최대 토큰 수 도달
        /// - "SAFETY": 안전 필터에 의해 중단
        /// - "RECITATION": 인용 감지로 중단
        /// - "OTHER": 기타 이유
        let finishReason: String?

        /// 인덱스
        ///
        /// 후보 응답의 인덱스 (0부터 시작)
        let index: Int?

        /// 안전 평가 결과
        ///
        /// 응답의 안전성 평가 결과 배열
        let safetyRatings: [SafetyRating]?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case content = "content"
            case finishReason = "finishReason"
            case index = "index"
            case safetyRatings = "safetyRatings"
        }
    }

    /// 📚 학습 포인트: Content Structure
    /// Gemini API의 콘텐츠 구조
    /// 💡 Java 비교: Inner Class와 유사
    struct Content: Codable {
        /// 콘텐츠 파트 배열
        ///
        /// 텍스트, 이미지 등 여러 타입의 콘텐츠 포함 가능
        let parts: [Part]?

        /// 역할
        ///
        /// "model" (AI 응답) 또는 "user" (사용자 입력)
        let role: String?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case parts = "parts"
            case role = "role"
        }
    }

    /// 📚 학습 포인트: Part Structure
    /// 콘텐츠의 개별 파트 (텍스트)
    /// 💡 Java 비교: Union Type과 유사
    struct Part: Codable {
        /// 텍스트 콘텐츠
        ///
        /// AI가 생성한 텍스트 응답
        let text: String?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case text = "text"
        }
    }

    /// 📚 학습 포인트: Safety Rating
    /// 안전성 평가 결과
    /// 💡 Java 비교: Enum과 유사
    struct SafetyRating: Codable {
        /// 안전 카테고리
        ///
        /// 예: HARM_CATEGORY_HARASSMENT, HARM_CATEGORY_HATE_SPEECH
        let category: String?

        /// 확률 수준
        ///
        /// 📚 학습 포인트: Safety Probability
        /// - "NEGLIGIBLE": 무시할 수준
        /// - "LOW": 낮음
        /// - "MEDIUM": 중간
        /// - "HIGH": 높음
        let probability: String?

        /// 차단 여부 (선택적)
        ///
        /// 이 카테고리에 의해 차단되었는지 여부
        let blocked: Bool?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case category = "category"
            case probability = "probability"
            case blocked = "blocked"
        }
    }

    /// 📚 학습 포인트: Prompt Feedback
    /// 프롬프트 피드백 정보
    /// 💡 Java 비교: Inner Class와 유사
    struct PromptFeedback: Codable {
        /// 안전 평가 결과
        ///
        /// 프롬프트의 안전성 평가 결과
        let safetyRatings: [SafetyRating]?

        /// 차단 이유 (선택적)
        ///
        /// 프롬프트가 차단된 경우 이유
        /// 예: "SAFETY", "OTHER"
        let blockReason: String?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case safetyRatings = "safetyRatings"
            case blockReason = "blockReason"
        }
    }

    /// 📚 학습 포인트: Usage Metadata
    /// 토큰 사용량 정보
    /// 💡 Java 비교: Inner Class와 유사
    struct UsageMetadata: Codable {
        /// 프롬프트 토큰 수
        ///
        /// 입력(프롬프트)에 사용된 토큰 수
        let promptTokenCount: Int?

        /// 후보 토큰 수
        ///
        /// 생성된 응답에 사용된 토큰 수
        let candidatesTokenCount: Int?

        /// 총 토큰 수
        ///
        /// 프롬프트 + 응답 총 토큰 수
        let totalTokenCount: Int?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case promptTokenCount = "promptTokenCount"
            case candidatesTokenCount = "candidatesTokenCount"
            case totalTokenCount = "totalTokenCount"
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case candidates = "candidates"
        case promptFeedback = "promptFeedback"
        case usageMetadata = "usageMetadata"
    }
}

// MARK: - Convenience Methods

extension GeminiResponseDTO {

    /// 생성된 텍스트 추출
    ///
    /// 📚 학습 포인트: Computed Property
    /// 복잡한 응답 구조에서 필요한 값을 간편하게 추출
    /// 💡 Java 비교: getter 메서드와 동일하지만 더 간결
    ///
    /// - Returns: 첫 번째 후보의 텍스트 (없으면 nil)
    ///
    /// - Example:
    /// ```swift
    /// if let text = response.generatedText {
    ///     print("AI 응답: \(text)")
    /// } else {
    ///     print("응답 없음")
    /// }
    /// ```
    var generatedText: String? {
        return candidates?.first?.content?.parts?.first?.text
    }

    /// 응답이 성공적으로 생성되었는지 확인
    ///
    /// 📚 학습 포인트: Response Validation
    /// API 응답의 성공 여부 확인
    /// 💡 Java 비교: isSuccessful() 메서드와 유사
    ///
    /// - Returns: 정상 완료되었으면 true
    ///
    /// **성공 조건:**
    /// - candidates가 비어있지 않음
    /// - 첫 번째 candidate에 content가 있음
    /// - finishReason이 "STOP"임
    var isSuccess: Bool {
        guard let candidate = candidates?.first else {
            return false
        }

        guard candidate.content != nil else {
            return false
        }

        return candidate.finishReason == "STOP"
    }

    /// 완료 이유 반환
    ///
    /// - Returns: 첫 번째 후보의 완료 이유 (없으면 nil)
    var finishReason: String? {
        return candidates?.first?.finishReason
    }

    /// 안전 필터에 의해 차단되었는지 확인
    ///
    /// 📚 학습 포인트: Safety Check
    /// 유해 콘텐츠 필터에 의해 응답이 차단되었는지 확인
    /// 💡 Java 비교: isBlocked() 메서드와 유사
    ///
    /// - Returns: 차단되었으면 true
    ///
    /// - Example:
    /// ```swift
    /// if response.isBlocked {
    ///     print("안전 필터에 의해 차단된 응답입니다.")
    /// }
    /// ```
    var isBlocked: Bool {
        // 프롬프트가 차단된 경우
        if promptFeedback?.blockReason != nil {
            return true
        }

        // 응답이 안전 필터로 중단된 경우
        if let finishReason = candidates?.first?.finishReason,
           finishReason == "SAFETY" {
            return true
        }

        return false
    }

    /// 최대 토큰 수에 도달했는지 확인
    ///
    /// - Returns: 최대 토큰 수에 도달했으면 true
    var isMaxTokensReached: Bool {
        return candidates?.first?.finishReason == "MAX_TOKENS"
    }

    /// 총 토큰 사용량
    ///
    /// - Returns: 총 토큰 수 (정보 없으면 nil)
    var totalTokens: Int? {
        return usageMetadata?.totalTokenCount
    }
}

// MARK: - Error Handling

extension GeminiResponseDTO {

    /// 응답 에러 타입 반환
    ///
    /// 📚 학습 포인트: Error Mapping
    /// API 응답을 앱 내부 에러 타입으로 변환
    /// 💡 Java 비교: Exception mapping과 유사
    ///
    /// - Returns: 에러 타입 (성공 시 nil)
    var errorType: GeminiAPIError? {
        // 성공한 경우
        if isSuccess {
            return nil
        }

        // 안전 필터에 의해 차단된 경우
        if isBlocked {
            return .contentFiltered("안전 필터에 의해 차단되었습니다.")
        }

        // 최대 토큰 수에 도달한 경우
        if isMaxTokensReached {
            return .maxTokensReached
        }

        // 후보가 없는 경우
        if candidates?.isEmpty ?? true {
            return .noCandidates
        }

        // 기타 에러
        if let finishReason = finishReason {
            return .unknown(finishReason)
        }

        return .unknown("UNKNOWN")
    }

    /// 에러 메시지 반환
    ///
    /// - Returns: 에러 메시지 (성공 시 nil)
    var errorMessage: String? {
        return errorType?.localizedDescription
    }
}

// MARK: - Gemini API Error Types

/// Gemini API 에러 타입
///
/// 📚 학습 포인트: Domain-Specific Error Types
/// API 에러를 명확한 타입으로 정의하여 에러 처리 개선
/// 💡 Java 비교: Custom Exception 계층 구조와 유사
enum GeminiAPIError: Error {
    /// 콘텐츠 필터에 의해 차단됨
    case contentFiltered(String)

    /// 최대 토큰 수 도달
    case maxTokensReached

    /// 후보 응답 없음
    case noCandidates

    /// 네트워크 에러
    case networkError(Error)

    /// 파싱 에러
    case parsingError(String)

    /// 인증 실패 (API 키 문제)
    case authenticationFailed

    /// 요청 제한 초과 (15 RPM)
    case rateLimitExceeded

    /// 잘못된 요청
    case invalidRequest(String)

    /// 기타 에러
    case unknown(String)

    /// 사용자 친화적 에러 메시지
    ///
    /// 📚 학습 포인트: Localized Error Message
    /// 사용자에게 표시할 한글 에러 메시지
    /// 💡 Java 비교: getMessage()와 유사
    var localizedDescription: String {
        switch self {
        case .contentFiltered(let message):
            return "부적절한 콘텐츠가 감지되어 응답이 차단되었습니다: \(message)"
        case .maxTokensReached:
            return "응답이 너무 길어 중단되었습니다. 더 짧은 요청으로 다시 시도해주세요."
        case .noCandidates:
            return "AI 응답을 생성할 수 없습니다. 다시 시도해주세요."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        case .parsingError(let message):
            return "응답 처리 중 오류가 발생했습니다: \(message)"
        case .authenticationFailed:
            return "API 인증에 실패했습니다. API 키를 확인해주세요."
        case .rateLimitExceeded:
            return "요청 횟수 제한(분당 15회)을 초과했습니다. 잠시 후 다시 시도해주세요."
        case .invalidRequest(let message):
            return "잘못된 요청입니다: \(message)"
        case .unknown(let reason):
            return "알 수 없는 오류가 발생했습니다: \(reason)"
        }
    }
}

// MARK: - Validation

extension GeminiResponseDTO {

    /// 응답 데이터가 유효한지 검증
    ///
    /// 📚 학습 포인트: Response Validation
    /// API 응답의 일관성 검증
    /// 💡 Java 비교: Response validation pattern
    ///
    /// - Returns: 유효하면 true
    ///
    /// **검증 항목:**
    /// - candidates 또는 promptFeedback 중 하나는 있어야 함
    /// - candidates가 있으면 비어있지 않아야 함
    var isValid: Bool {
        // candidates 또는 promptFeedback 중 하나는 있어야 함
        if candidates == nil && promptFeedback == nil {
            return false
        }

        // candidates가 있으면 비어있지 않아야 함
        if let candidates = candidates, candidates.isEmpty {
            return false
        }

        return true
    }
}
