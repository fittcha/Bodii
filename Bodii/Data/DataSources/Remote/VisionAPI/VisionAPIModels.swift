//
//  VisionAPIModels.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Google Cloud Vision API Models
// Vision API Label Detection 요청/응답 모델
// 💡 Java 비교: DTO pattern - API 요청/응답 데이터 전송 객체

import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Request Models

/// Vision API 이미지 분석 요청
///
/// 📚 학습 포인트: Batch Request Pattern
/// Vision API는 여러 이미지를 한 번에 처리할 수 있도록 배열 구조 사용
/// 💡 Java 비교: BatchRequest wrapper
///
/// **요청 구조:**
/// ```json
/// {
///   "requests": [
///     {
///       "image": { "content": "base64-encoded-image" },
///       "features": [{ "type": "LABEL_DETECTION", "maxResults": 10 }]
///     }
///   ]
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let image = UIImage(named: "food")!
/// let request = VisionAnnotateRequest(image: image)
/// let jsonData = try JSONEncoder().encode(request)
/// ```
///
/// **참고:**
/// - API 문서: https://cloud.google.com/vision/docs/reference/rest/v1/images/annotate
struct VisionAnnotateRequest: Codable {

    // MARK: - Properties

    /// 이미지 분석 요청 배열
    ///
    /// 한 번에 여러 이미지를 처리할 수 있지만,
    /// 현재 구현에서는 하나의 이미지만 전송
    let requests: [ImageRequest]

    // MARK: - Initialization

    /// UIImage로부터 요청 생성
    ///
    /// 📚 학습 포인트: Convenience Initializer
    /// UIImage를 base64로 인코딩하여 요청 객체 생성
    /// 💡 Java 비교: Factory method pattern
    ///
    /// - Parameters:
    ///   - image: 분석할 이미지
    ///   - maxResults: 반환할 최대 라벨 수 (기본값: 10)
    ///
    /// - Throws: VisionAPIError.imageProcessingFailed - 이미지 인코딩 실패
    ///
    /// - Example:
    /// ```swift
    /// let request = try VisionAnnotateRequest(image: photo, maxResults: 15)
    /// ```
    init(image: UIImage, maxResults: Int = 10) throws {
        // 이미지를 base64로 인코딩
        guard let base64String = image.toBase64String() else {
            throw VisionAPIError.imageProcessingFailed("이미지를 base64로 인코딩할 수 없습니다")
        }

        let imageContent = ImageContent(content: base64String)
        let feature = Feature(type: .labelDetection, maxResults: maxResults)
        let imageRequest = ImageRequest(image: imageContent, features: [feature])

        self.requests = [imageRequest]
    }

    /// Base64 문자열로부터 직접 요청 생성 (테스트용)
    ///
    /// - Parameters:
    ///   - base64String: base64로 인코딩된 이미지 문자열
    ///   - maxResults: 반환할 최대 라벨 수
    init(base64String: String, maxResults: Int = 10) {
        let imageContent = ImageContent(content: base64String)
        let feature = Feature(type: .labelDetection, maxResults: maxResults)
        let imageRequest = ImageRequest(image: imageContent, features: [feature])

        self.requests = [imageRequest]
    }

    // MARK: - Nested Types

    /// 📚 학습 포인트: Nested Request Structure
    /// 개별 이미지 분석 요청
    /// 💡 Java 비교: Inner class for nested API structure
    struct ImageRequest: Codable {
        /// 이미지 데이터
        let image: ImageContent

        /// 요청할 Vision API 기능 목록
        let features: [Feature]
    }

    /// 📚 학습 포인트: Image Encoding
    /// Base64로 인코딩된 이미지 데이터
    /// 💡 Java 비교: Base64 encoded data wrapper
    struct ImageContent: Codable {
        /// Base64로 인코딩된 이미지 문자열
        ///
        /// JPEG 또는 PNG 형식의 이미지를 base64로 인코딩
        let content: String
    }

    /// 📚 학습 포인트: Feature Type Enum
    /// Vision API 기능 타입
    /// 💡 Java 비교: Enum for API feature types
    struct Feature: Codable {
        /// 기능 타입
        let type: FeatureType

        /// 최대 결과 수 (선택적)
        let maxResults: Int?

        /// Vision API 기능 타입 열거형
        enum FeatureType: String, Codable {
            /// 라벨 감지 (객체, 장소, 활동 등 인식)
            case labelDetection = "LABEL_DETECTION"

            /// 텍스트 감지 (OCR)
            case textDetection = "TEXT_DETECTION"

            /// 얼굴 감지
            case faceDetection = "FACE_DETECTION"

            /// 랜드마크 감지
            case landmarkDetection = "LANDMARK_DETECTION"

            /// 로고 감지
            case logoDetection = "LOGO_DETECTION"
        }
    }
}

// MARK: - Response Models

/// Vision API 이미지 분석 응답
///
/// 📚 학습 포인트: Batch Response Pattern
/// 요청과 마찬가지로 여러 이미지의 결과를 배열로 반환
/// 💡 Java 비교: BatchResponse wrapper
///
/// **응답 구조:**
/// ```json
/// {
///   "responses": [
///     {
///       "labelAnnotations": [
///         { "description": "Food", "score": 0.95, "topicality": 0.93 }
///       ]
///     }
///   ]
/// }
/// ```
///
/// **사용 예시:**
/// ```swift
/// let response: VisionAnnotateResponse = try JSONDecoder().decode(
///     VisionAnnotateResponse.self,
///     from: responseData
/// )
///
/// if let labels = response.labels {
///     labels.forEach { label in
///         print("\(label.description): \(label.score)")
///     }
/// }
/// ```
struct VisionAnnotateResponse: Codable {

    // MARK: - Properties

    /// 이미지 분석 응답 배열
    ///
    /// 요청한 이미지 수만큼의 응답 반환
    let responses: [ImageResponse]

    // MARK: - Convenience Properties

    /// 첫 번째 응답의 라벨 목록
    ///
    /// 📚 학습 포인트: Convenience Accessor
    /// 단일 이미지 요청의 경우 쉽게 라벨에 접근
    /// 💡 Java 비교: Getter with default value
    ///
    /// - Returns: 라벨 목록 (없으면 빈 배열)
    var labels: [VisionLabel]? {
        return responses.first?.labelAnnotations
    }

    /// 에러 정보
    ///
    /// 첫 번째 응답의 에러 정보 반환
    var error: VisionError? {
        return responses.first?.error
    }

    // MARK: - Nested Types

    /// 📚 학습 포인트: Response Structure
    /// 개별 이미지 분석 응답
    /// 💡 Java 비교: Inner class for nested response
    struct ImageResponse: Codable {
        /// 라벨 감지 결과
        ///
        /// 이미지에서 감지된 객체, 장소, 활동 등의 라벨 목록
        let labelAnnotations: [VisionLabel]?

        /// 에러 정보 (선택적)
        ///
        /// API 요청 중 에러 발생 시 포함
        let error: VisionError?
    }

    /// 📚 학습 포인트: API Error Response
    /// Vision API 에러 응답 구조
    /// 💡 Java 비교: Error response DTO
    struct VisionError: Codable {
        /// 에러 코드
        ///
        /// HTTP 상태 코드 (예: 400, 403, 429)
        let code: Int?

        /// 에러 메시지
        let message: String?

        /// 에러 상태 (선택적)
        ///
        /// 에러 타입 (예: "INVALID_ARGUMENT", "PERMISSION_DENIED")
        let status: String?
    }
}

// MARK: - Vision Label Model

/// Vision API 라벨 정보
///
/// 📚 학습 포인트: Label Detection Result
/// 이미지에서 감지된 객체, 장소, 활동 등의 라벨 정보
/// 💡 Java 비교: Label entity/DTO
///
/// **라벨 구조:**
/// - mid: 머신러닝 ID (Google Knowledge Graph ID)
/// - description: 라벨 설명 (영문)
/// - score: 정확도 점수 (0.0 ~ 1.0)
/// - topicality: 주제 관련성 점수 (0.0 ~ 1.0)
///
/// **사용 예시:**
/// ```swift
/// let foodLabels = labels.filter { $0.isFoodRelated }
/// foodLabels.sorted(by: { $0.score > $1.score }).forEach { label in
///     print("\(label.description): \(Int(label.score * 100))%")
/// }
/// ```
struct VisionLabel: Codable, Identifiable {

    // MARK: - Properties

    /// 고유 ID (머신러닝 ID)
    ///
    /// 📚 학습 포인트: Machine-readable ID
    /// Google Knowledge Graph의 고유 식별자
    /// 💡 예: "/m/02wbm" (Food), "/m/01ykh" (Pizza)
    let mid: String?

    /// 라벨 설명 (영문)
    ///
    /// 감지된 객체, 장소, 활동 등의 이름
    let description: String

    /// 정확도 점수 (0.0 ~ 1.0)
    ///
    /// 📚 학습 포인트: Confidence Score
    /// 모델이 해당 라벨을 얼마나 확신하는지 나타냄
    /// 💡 0.8 이상이면 높은 확신도
    let score: Double

    /// 주제 관련성 점수 (0.0 ~ 1.0)
    ///
    /// 📚 학습 포인트: Topicality Score
    /// 이미지의 주요 주제와 얼마나 관련이 있는지 나타냄
    /// 💡 score와 다르게 이미지의 핵심 내용인지를 판단
    let topicality: Double?

    // MARK: - Identifiable

    /// SwiftUI Identifiable을 위한 ID
    ///
    /// 📚 학습 포인트: Identifiable Protocol
    /// SwiftUI List에서 사용하기 위해 필요
    /// 💡 Java 비교: Entity의 getId()와 유사
    var id: String {
        return mid ?? description
    }

    // MARK: - Computed Properties

    /// 식품 관련 라벨인지 확인
    ///
    /// 📚 학습 포인트: Business Logic in Model
    /// 음식 관련 라벨을 필터링하는 로직
    /// 💡 Java 비교: Entity의 비즈니스 메서드
    ///
    /// - Returns: 식품 관련 키워드가 포함되어 있으면 true
    ///
    /// - Note: 이 로직은 VisionAPIService에서도 사용됨
    ///
    /// - Example:
    /// ```swift
    /// let foodLabels = allLabels.filter { $0.isFoodRelated }
    /// ```
    var isFoodRelated: Bool {
        let foodKeywords = [
            // 일반 음식 키워드
            "food", "dish", "meal", "cuisine", "recipe",
            // 음식 카테고리
            "fruit", "vegetable", "meat", "seafood", "dairy",
            "bread", "dessert", "snack", "beverage", "drink",
            // 조리 방법
            "cooked", "fried", "baked", "grilled", "boiled",
            "roasted", "steamed", "raw",
            // 식사
            "breakfast", "lunch", "dinner", "brunch",
            // 특정 음식
            "pizza", "burger", "pasta", "rice", "noodle",
            "salad", "soup", "sandwich", "sushi", "curry",
            "steak", "chicken", "fish", "egg", "cheese",
            // 한식
            "korean", "kimchi", "bibimbap", "bulgogi",
            // 기타
            "ingredient", "produce", "staple food"
        ]

        let lowercaseDescription = description.lowercased()
        return foodKeywords.contains { lowercaseDescription.contains($0) }
    }

    /// 높은 확신도를 가진 라벨인지 확인
    ///
    /// 📚 학습 포인트: Threshold-based Validation
    /// 점수 기반 필터링
    /// 💡 0.7 이상이면 높은 확신도로 판단
    ///
    /// - Returns: score가 0.7 이상이면 true
    var isHighConfidence: Bool {
        return score >= 0.7
    }

    /// 백분율로 표시된 정확도
    ///
    /// - Returns: 0 ~ 100 사이의 정수 (예: 95)
    var scorePercentage: Int {
        return Int(score * 100)
    }
}

// MARK: - UIImage Extension

#if canImport(UIKit)
extension UIImage {

    /// 이미지를 base64 문자열로 인코딩
    ///
    /// 📚 학습 포인트: Image Encoding for API
    /// Vision API에 전송하기 위해 이미지를 base64로 인코딩
    /// JPEG 압축을 사용하여 파일 크기 최적화
    /// 💡 Java 비교: Base64.getEncoder().encodeToString()
    ///
    /// **처리 과정:**
    /// 1. 이미지 리사이징 (최대 1024px)
    /// 2. JPEG 압축 (quality 0.8)
    /// 3. Base64 인코딩
    ///
    /// - Parameter compressionQuality: JPEG 압축 품질 (0.0 ~ 1.0, 기본값 0.8)
    ///
    /// - Returns: Base64로 인코딩된 문자열 (실패 시 nil)
    ///
    /// - Note: Vision API는 base64로 인코딩된 이미지를 요구함
    ///         최대 이미지 크기: 20MB (base64 인코딩 전)
    ///
    /// - Example:
    /// ```swift
    /// let image = UIImage(named: "food")!
    /// if let base64 = image.toBase64String() {
    ///     print("Encoded image size: \(base64.count) bytes")
    /// }
    /// ```
    func toBase64String(compressionQuality: CGFloat = 0.8) -> String? {
        // 이미지 리사이징 (최대 1024px)
        let resized = resizeForVisionAPI()

        // JPEG로 압축
        guard let jpegData = resized.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }

        // Base64 인코딩
        return jpegData.base64EncodedString()
    }

    /// Vision API를 위한 이미지 리사이징
    ///
    /// 📚 학습 포인트: Image Optimization
    /// API 요청 속도와 비용을 최적화하기 위해 이미지 크기 조정
    /// 💡 1024px 이상의 이미지는 비용 대비 정확도 향상이 미미함
    ///
    /// - Parameter maxSize: 최대 크기 (기본값: 1024)
    ///
    /// - Returns: 리사이징된 이미지
    ///
    /// - Note: 가로/세로 중 긴 쪽을 maxSize로 맞추고 비율 유지
    private func resizeForVisionAPI(maxSize: CGFloat = 1024) -> UIImage {
        // 이미 작은 이미지는 그대로 반환
        let currentSize = max(size.width, size.height)
        if currentSize <= maxSize {
            return self
        }

        // 비율 유지하며 리사이징
        let scale = maxSize / currentSize
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        // 새로운 크기로 이미지 그리기
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#endif

// MARK: - Food Label Filtering

extension Array where Element == VisionLabel {

    /// 음식 관련 라벨만 필터링
    ///
    /// 📚 학습 포인트: Collection Extension
    /// 배열에 특화된 편의 메서드 제공
    /// 💡 Java 비교: Stream API의 filter()와 유사
    ///
    /// - Parameter minScore: 최소 정확도 점수 (기본값: 0.5)
    ///
    /// - Returns: 음식 관련 라벨 목록 (정확도 순으로 정렬)
    ///
    /// - Example:
    /// ```swift
    /// let allLabels = response.labels ?? []
    /// let foodLabels = allLabels.filterFoodLabels(minScore: 0.7)
    /// ```
    func filterFoodLabels(minScore: Double = 0.5) -> [VisionLabel] {
        return self
            .filter { $0.isFoodRelated && $0.score >= minScore }
            .sorted { $0.score > $1.score }
    }

    /// 높은 확신도를 가진 라벨만 필터링
    ///
    /// - Returns: score가 0.7 이상인 라벨 목록
    func highConfidenceLabels() -> [VisionLabel] {
        return self
            .filter { $0.isHighConfidence }
            .sorted { $0.score > $1.score }
    }
}
