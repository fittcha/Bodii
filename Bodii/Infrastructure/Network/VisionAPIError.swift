//
//  VisionAPIError.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Vision API Error Handling
// Vision API 작업에서 발생할 수 있는 다양한 에러를 열거형으로 정의
// 💡 Java 비교: Exception 클래스 대신 타입 안전한 enum 사용

import Foundation

/// Vision API operation errors
///
/// Vision API 작업에서 발생할 수 있는 에러 타입
///
/// 📚 학습 포인트: Error Protocol
/// Swift에서는 Error 프로토콜을 채택하면 throw/catch로 에러 처리 가능
/// 💡 Java 비교: Exception 대신 Error 프로토콜 + enum 사용
///
/// - Cases:
///   - quotaExceeded: API 할당량 초과 (월 1,000회 제한)
///   - recognitionFailed: 이미지 인식 실패
///   - noFoodDetected: 음식 감지되지 않음
///   - invalidImage: 유효하지 않은 이미지
///   - imageProcessingFailed: 이미지 처리 실패
///   - networkError: 네트워크 에러
///   - apiError: API 에러
///   - unknown: 알 수 없는 에러
///
/// - Example:
/// ```swift
/// do {
///     let labels = try await visionService.analyzeImage(image)
/// } catch VisionAPIError.quotaExceeded(let resetInDays) {
///     showAlert("월간 한도를 초과했습니다. \(resetInDays)일 후 초기화됩니다.")
/// } catch VisionAPIError.noFoodDetected {
///     showAlert("음식이 감지되지 않았습니다. 다시 촬영해주세요.")
/// }
/// ```
enum VisionAPIError: Error {

    // MARK: - Cases

    /// API 할당량 초과
    ///
    /// Google Cloud Vision API 무료 티어 한도(1,000회/월)를 초과했을 때 발생
    ///
    /// 📚 학습 포인트: Rate Limiting
    /// 무료 티어 한도를 초과하면 추가 요청이 차단됨
    /// 사용자에게 한도 초과를 알리고 다음 달까지 남은 일수 표시
    /// 💡 Java 비교: QuotaExceededException
    ///
    /// - Parameter resetInDays: 할당량 초기화까지 남은 일수
    ///
    /// - Example:
    /// ```swift
    /// guard tracker.canMakeRequest() else {
    ///     let daysUntilReset = tracker.getDaysUntilReset()
    ///     throw VisionAPIError.quotaExceeded(resetInDays: daysUntilReset)
    /// }
    /// ```
    case quotaExceeded(resetInDays: Int)

    /// 이미지 인식 실패
    ///
    /// Vision API가 이미지를 분석했지만 결과를 반환하지 못했을 때 발생
    ///
    /// 📚 학습 포인트: Wrapped Errors
    /// 원본 에러를 포함하여 디버깅에 도움이 되도록 함
    /// 💡 Java 비교: Caused by 체인과 유사
    ///
    /// - Parameter underlyingError: 원본 에러
    ///
    /// - Example:
    /// ```swift
    /// catch let error as DecodingError {
    ///     throw VisionAPIError.recognitionFailed(underlyingError: error)
    /// }
    /// ```
    case recognitionFailed(underlyingError: Error)

    /// 음식이 감지되지 않음
    ///
    /// Vision API가 이미지에서 음식 관련 라벨을 찾지 못했을 때 발생
    ///
    /// 📚 학습 포인트: Business Logic Error
    /// 기술적 에러는 아니지만 비즈니스 로직상 처리가 필요한 경우
    /// 💡 Java 비교: Custom Business Exception
    ///
    /// - Note: 사용자에게 다시 촬영하도록 안내
    ///
    /// - Example:
    /// ```swift
    /// let foodLabels = labels.filter { $0.isFoodRelated }
    /// if foodLabels.isEmpty {
    ///     throw VisionAPIError.noFoodDetected
    /// }
    /// ```
    case noFoodDetected

    /// 유효하지 않은 이미지
    ///
    /// 이미지가 nil이거나, 형식이 잘못되었거나, 너무 작을 때 발생
    ///
    /// 📚 학습 포인트: Input Validation
    /// API 호출 전에 입력 데이터 유효성 검증
    /// 💡 Java 비교: IllegalArgumentException
    ///
    /// - Parameter message: 유효성 검증 실패 사유
    ///
    /// - Example:
    /// ```swift
    /// guard let image = image, image.size.width > 100, image.size.height > 100 else {
    ///     throw VisionAPIError.invalidImage("이미지가 너무 작습니다 (최소 100x100)")
    /// }
    /// ```
    case invalidImage(String)

    /// 이미지 처리 실패
    ///
    /// 이미지 압축, 리사이징, base64 인코딩 등 전처리 과정에서 실패했을 때 발생
    ///
    /// 📚 학습 포인트: Image Processing
    /// Vision API에 전송하기 전 이미지 최적화 과정이 필요
    /// 💡 Java 비교: ImageProcessingException
    ///
    /// - Parameter message: 처리 실패 사유
    ///
    /// - Example:
    /// ```swift
    /// guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else {
    ///     throw VisionAPIError.imageProcessingFailed("JPEG 압축 실패")
    /// }
    /// ```
    case imageProcessingFailed(String)

    /// 네트워크 에러
    ///
    /// Vision API 요청 중 네트워크 문제가 발생했을 때 발생
    ///
    /// 📚 학습 포인트: Error Wrapping
    /// 하위 레벨의 NetworkError를 Vision API 레벨의 에러로 래핑
    /// 💡 Java 비교: Exception wrapping/translation
    ///
    /// - Parameter error: 원본 네트워크 에러
    ///
    /// - Example:
    /// ```swift
    /// catch let error as NetworkError {
    ///     throw VisionAPIError.networkError(error)
    /// }
    /// ```
    case networkError(NetworkError)

    /// API 에러 응답
    ///
    /// Vision API가 에러 응답을 반환했을 때 발생
    ///
    /// 📚 학습 포인트: API Error Handling
    /// API 에러 코드와 메시지를 함께 전달하여 구체적인 에러 정보 제공
    /// 💡 Java 비교: ApiException with code and message
    ///
    /// - Parameters:
    ///   - code: Vision API 에러 코드 (예: "INVALID_ARGUMENT", "PERMISSION_DENIED")
    ///   - message: Vision API 에러 메시지
    ///
    /// - Example:
    /// ```swift
    /// if let errorCode = response.error?.code {
    ///     throw VisionAPIError.apiError(code: errorCode, message: response.error?.message ?? "Unknown error")
    /// }
    /// ```
    case apiError(code: String, message: String)

    /// 알 수 없는 에러
    ///
    /// 위의 경우에 해당하지 않는 기타 에러
    ///
    /// 📚 학습 포인트: Catch-all Error
    /// 예상하지 못한 에러를 처리하기 위한 catch-all 케이스
    /// 💡 Java 비교: Generic Exception handling
    ///
    /// - Parameter error: 원본 에러
    case unknown(Error)
}

// MARK: - LocalizedError

/// 사용자 친화적인 에러 메시지 제공
///
/// 📚 학습 포인트: LocalizedError Protocol
/// 에러에 대한 지역화된(한국어) 메시지를 제공
/// 💡 Java 비교: getMessage()와 유사하지만 프로토콜 기반
extension VisionAPIError: LocalizedError {

    /// 사용자에게 표시할 에러 설명 (한국어)
    ///
    /// 📚 학습 포인트: Computed Property
    /// 저장 프로퍼티가 아닌 계산 프로퍼티로 필요할 때마다 생성
    /// 💡 Java 비교: getter 메서드와 유사하지만 더 간결
    var errorDescription: String? {
        switch self {
        case .quotaExceeded(let resetInDays):
            return "월간 사용 한도(1,000회)를 초과했습니다. \(resetInDays)일 후에 다시 시도해주세요."

        case .recognitionFailed(let underlyingError):
            return "이미지 인식에 실패했습니다: \(underlyingError.localizedDescription)"

        case .noFoodDetected:
            return "음식이 감지되지 않았습니다. 음식이 잘 보이도록 다시 촬영해주세요."

        case .invalidImage(let message):
            return "유효하지 않은 이미지입니다: \(message)"

        case .imageProcessingFailed(let message):
            return "이미지 처리에 실패했습니다: \(message)"

        case .networkError(let networkError):
            // NetworkError의 localizedDescription 활용
            return "네트워크 에러: \(networkError.localizedDescription)"

        case .apiError(let code, let message):
            return "Vision API 에러 (코드 \(code)): \(message)"

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
extension VisionAPIError: Equatable {

    static func == (lhs: VisionAPIError, rhs: VisionAPIError) -> Bool {
        switch (lhs, rhs) {
        case (.quotaExceeded(let lhsDays), .quotaExceeded(let rhsDays)):
            return lhsDays == rhsDays

        case (.recognitionFailed, .recognitionFailed):
            // Note: Error는 Equatable이 아니므로 타입만 비교
            return true

        case (.noFoodDetected, .noFoodDetected):
            return true

        case (.invalidImage(let lhsMsg), .invalidImage(let rhsMsg)):
            return lhsMsg == rhsMsg

        case (.imageProcessingFailed(let lhsMsg), .imageProcessingFailed(let rhsMsg)):
            return lhsMsg == rhsMsg

        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError == rhsError

        case (.apiError(let lhsCode, let lhsMsg), .apiError(let rhsCode, let rhsMsg)):
            return lhsCode == rhsCode && lhsMsg == rhsMsg

        case (.unknown, .unknown):
            // Note: Error는 Equatable이 아니므로 타입만 비교
            return true

        default:
            return false
        }
    }
}

// MARK: - Recovery Strategy

extension VisionAPIError {

    /// 복구 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Recoverable vs Non-Recoverable Errors
    /// 에러 유형에 따라 재시도, 폴백 등의 복구 전략을 결정
    /// 💡 Java 비교: Checked vs Unchecked Exception과 유사한 개념
    ///
    /// **복구 전략:**
    /// - **복구 가능**: 재시도 또는 대체 방법 제공
    ///   * networkError → 재시도
    ///   * recognitionFailed → 재시도 또는 수동 입력
    ///   * noFoodDetected → 재촬영 또는 수동 입력
    ///
    /// - **복구 불가**: 사용자에게 에러 메시지 표시
    ///   * quotaExceeded → 수동 입력으로 대체
    ///   * invalidImage → 다시 촬영 필요
    ///
    /// - Returns: 복구 가능하면 true, 불가능하면 false
    ///
    /// - Example:
    /// ```swift
    /// catch let error as VisionAPIError {
    ///     if error.isRecoverable {
    ///         // 재시도 또는 대체 방법 제공
    ///         showRetryButton()
    ///     } else {
    ///         // 사용자에게 에러 메시지 표시
    ///         showAlert(error.errorDescription)
    ///     }
    /// }
    /// ```
    var isRecoverable: Bool {
        switch self {
        // Recoverable Errors (재시도 또는 대체 가능)
        case .recognitionFailed,
             .noFoodDetected,
             .networkError,
             .apiError:
            return true

        // Non-Recoverable Errors (사용자 개입 필요)
        case .quotaExceeded,
             .invalidImage,
             .imageProcessingFailed,
             .unknown:
            return false
        }
    }

    /// 재시도 가능한 에러인지 여부
    ///
    /// 📚 학습 포인트: Retry Strategy
    /// 일시적인 네트워크 문제 등은 재시도로 해결 가능
    /// 💡 Java 비교: @Retryable 어노테이션 조건
    ///
    /// - Returns: 재시도 가능하면 true
    ///
    /// - Example:
    /// ```swift
    /// var retryCount = 0
    /// while retryCount < maxRetries {
    ///     do {
    ///         return try await analyzeImage()
    ///     } catch let error as VisionAPIError {
    ///         if error.canRetry {
    ///             retryCount += 1
    ///             await Task.sleep(retryCount * 1_000_000_000)
    ///         } else {
    ///             throw error
    ///         }
    ///     }
    /// }
    /// ```
    var canRetry: Bool {
        switch self {
        case .networkError,
             .apiError,
             .recognitionFailed:
            return true

        default:
            return false
        }
    }
}
