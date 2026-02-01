//
//  GeminiRequestDTO.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Google Gemini API Request Structure
// Gemini API의 텍스트 생성 요청 구조
// 💡 Java 비교: ChatGPT API Request와 유사한 구조

import Foundation

/// Google Gemini API 요청 DTO
///
/// 📚 학습 포인트: AI Content Generation Request
/// Gemini API의 generateContent 엔드포인트 요청 구조
/// 💡 Java 비교: REST API POST 요청 바디와 동일
///
/// **API 요청 구조:**
/// ```json
/// {
///   "contents": [
///     {
///       "parts": [
///         {
///           "text": "Analyze this meal..."
///         }
///       ]
///     }
///   ],
///   "generationConfig": {
///     "temperature": 0.7,
///     "maxOutputTokens": 1024
///   }
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let request = GeminiRequestDTO(
///     prompt: "분석해주세요: 아침 - 김치찌개, 공기밥",
///     temperature: 0.7,
///     maxOutputTokens: 1024
/// )
///
/// let jsonData = try JSONEncoder().encode(request)
/// ```
///
/// **참고:**
/// - API 문서: https://ai.google.dev/api/rest/v1beta/models/generateContent
/// - 모델: gemini-2.5-flash-lite (빠른 응답, 무료 티어)
struct GeminiRequestDTO: Codable {

    // MARK: - Properties

    /// 요청 내용 배열
    ///
    /// Gemini API는 대화 형식을 지원하기 위해 배열 구조 사용
    /// 단일 요청의 경우 1개 요소만 포함
    let contents: [Content]

    /// 생성 설정 (선택적)
    ///
    /// AI 응답의 창의성, 길이 등을 제어하는 파라미터
    let generationConfig: GenerationConfig?

    /// 안전 설정 (선택적)
    ///
    /// 유해 콘텐츠 필터링 설정
    /// 기본값 사용 시 nil로 설정 가능
    let safetySettings: [SafetySetting]?

    // MARK: - Nested Types

    /// 📚 학습 포인트: Content Structure
    /// Gemini API의 콘텐츠 구조 (대화의 한 턴)
    /// 💡 Java 비교: Inner Class와 유사
    struct Content: Codable {
        /// 콘텐츠 파트 배열
        ///
        /// 텍스트, 이미지 등 여러 타입의 콘텐츠 포함 가능
        /// 텍스트만 사용하는 경우 1개 요소
        let parts: [Part]

        /// 역할 (선택적)
        ///
        /// "user" 또는 "model"
        /// 요청 시에는 보통 생략 (기본값: user)
        let role: String?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case parts = "parts"
            case role = "role"
        }
    }

    /// 📚 학습 포인트: Part Structure
    /// 콘텐츠의 개별 파트 (텍스트, 이미지 등)
    /// 💡 Java 비교: Union Type과 유사
    struct Part: Codable {
        /// 텍스트 콘텐츠
        ///
        /// 사용자 프롬프트 또는 AI 응답 텍스트
        let text: String?

        /// 인라인 이미지 데이터 (Multimodal 요청용)
        ///
        /// 📚 학습 포인트: Gemini Multimodal Input
        /// 이미지를 base64로 인코딩하여 텍스트와 함께 전송
        let inlineData: InlineData?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case text = "text"
            case inlineData = "inline_data"
        }
    }

    /// 인라인 데이터 (이미지 등 바이너리 콘텐츠)
    ///
    /// Gemini API의 multimodal 요청에서 이미지를 전달하는 구조체
    struct InlineData: Codable {
        /// MIME 타입 (예: "image/jpeg", "image/png")
        let mimeType: String

        /// Base64 인코딩된 데이터
        let data: String

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case mimeType = "mime_type"
            case data = "data"
        }
    }

    /// 📚 학습 포인트: Generation Configuration
    /// AI 응답 생성 파라미터 설정
    /// 💡 Java 비교: Configuration DTO와 유사
    ///
    /// **파라미터 설명:**
    /// - temperature: 응답의 무작위성 (0.0-1.0, 높을수록 창의적)
    /// - topK: 상위 K개 토큰에서 샘플링
    /// - topP: 누적 확률 P 이하의 토큰에서 샘플링
    /// - maxOutputTokens: 최대 출력 토큰 수
    struct GenerationConfig: Codable {
        /// 온도 (0.0-1.0)
        ///
        /// 📚 학습 포인트: AI Temperature
        /// 0에 가까울수록 일관된 응답, 1에 가까울수록 창의적 응답
        /// 💡 식단 분석: 0.7 권장 (적절한 창의성 + 일관성)
        let temperature: Double?

        /// Top K 샘플링
        ///
        /// 상위 K개 확률 토큰에서만 선택
        /// 기본값: 40
        let topK: Int?

        /// Top P 샘플링
        ///
        /// 누적 확률 P 이하의 토큰에서 선택
        /// 기본값: 0.95
        let topP: Double?

        /// 최대 출력 토큰 수
        ///
        /// 응답 길이 제한 (1 토큰 ≈ 4자)
        /// 기본값: 1024
        let maxOutputTokens: Int?

        /// 중지 시퀀스 (선택적)
        ///
        /// 이 문자열이 나오면 생성 중단
        let stopSequences: [String]?

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case temperature = "temperature"
            case topK = "topK"
            case topP = "topP"
            case maxOutputTokens = "maxOutputTokens"
            case stopSequences = "stopSequences"
        }
    }

    /// 📚 학습 포인트: Safety Settings
    /// 유해 콘텐츠 필터링 설정
    /// 💡 Java 비교: Configuration DTO와 유사
    struct SafetySetting: Codable {
        /// 유해 카테고리
        ///
        /// 예: HARM_CATEGORY_HARASSMENT, HARM_CATEGORY_HATE_SPEECH
        let category: String

        /// 차단 임계값
        ///
        /// 예: BLOCK_NONE, BLOCK_ONLY_HIGH, BLOCK_MEDIUM_AND_ABOVE
        let threshold: String

        /// CodingKeys for API field mapping
        enum CodingKeys: String, CodingKey {
            case category = "category"
            case threshold = "threshold"
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case contents = "contents"
        case generationConfig = "generationConfig"
        case safetySettings = "safetySettings"
    }
}

// MARK: - Convenience Initializers

extension GeminiRequestDTO {

    /// 단순 텍스트 프롬프트로 요청 생성
    ///
    /// 📚 학습 포인트: Convenience Initializer
    /// 자주 사용하는 패턴을 간편하게 생성
    /// 💡 Java 비교: Builder 패턴과 유사
    ///
    /// - Parameters:
    ///   - prompt: 사용자 프롬프트 (식단 분석 요청 텍스트)
    ///   - temperature: 응답의 창의성 (0.0-1.0, 기본값: 0.7)
    ///   - maxOutputTokens: 최대 출력 토큰 수 (기본값: 1024)
    ///
    /// - Returns: GeminiRequestDTO 인스턴스
    ///
    /// - Example:
    /// ```swift
    /// let request = GeminiRequestDTO(
    ///     prompt: "다음 식단을 분석해주세요:\n아침: 김치찌개, 공기밥\n칼로리: 650kcal"
    /// )
    /// ```
    init(
        prompt: String,
        temperature: Double = 0.7,
        maxOutputTokens: Int = 1024
    ) {
        let part = Part(text: prompt, inlineData: nil)
        let content = Content(parts: [part], role: nil)

        let config = GenerationConfig(
            temperature: temperature,
            topK: nil,
            topP: nil,
            maxOutputTokens: maxOutputTokens,
            stopSequences: nil
        )

        self.contents = [content]
        self.generationConfig = config
        self.safetySettings = nil
    }

    /// 이미지 + 텍스트 프롬프트로 Multimodal 요청 생성
    ///
    /// - Parameters:
    ///   - imageBase64: Base64 인코딩된 이미지 데이터
    ///   - mimeType: 이미지 MIME 타입 (기본값: "image/jpeg")
    ///   - prompt: 분석 요청 텍스트
    ///   - temperature: 응답의 창의성 (0.0-1.0, 기본값: 0.3)
    ///   - maxOutputTokens: 최대 출력 토큰 수 (기본값: 2048)
    init(
        imageBase64: String,
        mimeType: String = "image/jpeg",
        prompt: String,
        temperature: Double = 0.3,
        maxOutputTokens: Int = 2048
    ) {
        let imagePart = Part(text: nil, inlineData: InlineData(mimeType: mimeType, data: imageBase64))
        let textPart = Part(text: prompt, inlineData: nil)
        let content = Content(parts: [imagePart, textPart], role: nil)

        let config = GenerationConfig(
            temperature: temperature,
            topK: nil,
            topP: nil,
            maxOutputTokens: maxOutputTokens,
            stopSequences: nil
        )

        self.contents = [content]
        self.generationConfig = config
        self.safetySettings = nil
    }
}

// MARK: - Validation

extension GeminiRequestDTO {

    /// 요청이 유효한지 검증
    ///
    /// 📚 학습 포인트: Request Validation
    /// API 요청 전에 데이터 유효성 검증
    /// 💡 Java 비교: @Valid 어노테이션과 유사
    ///
    /// - Returns: 유효하면 true
    ///
    /// **검증 항목:**
    /// - contents가 비어있지 않은지
    /// - 각 content에 최소 1개의 part가 있는지
    /// - part의 text가 비어있지 않은지
    /// - temperature가 0.0-1.0 범위인지
    var isValid: Bool {
        // contents가 비어있지 않은지 확인
        guard !contents.isEmpty else {
            return false
        }

        // 각 content에 part가 있고, text가 비어있지 않은지 확인
        for content in contents {
            guard !content.parts.isEmpty else {
                return false
            }

            for part in content.parts {
                let hasText = part.text.map { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
                let hasImage = part.inlineData != nil
                guard hasText || hasImage else {
                    return false
                }
            }
        }

        // temperature 범위 확인 (있는 경우)
        if let temperature = generationConfig?.temperature {
            guard temperature >= 0.0 && temperature <= 1.0 else {
                return false
            }
        }

        // maxOutputTokens가 양수인지 확인 (있는 경우)
        if let maxTokens = generationConfig?.maxOutputTokens {
            guard maxTokens > 0 else {
                return false
            }
        }

        return true
    }

    /// 프롬프트 텍스트 추출
    ///
    /// - Returns: 첫 번째 content의 첫 번째 part의 텍스트
    var promptText: String? {
        return contents.first?.parts.first?.text
    }
}
