//
//  VisionAPIService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Vision API Service Layer
// Google Cloud Vision API를 사용하여 음식 사진 분석
// 💡 Java 비교: REST API Service 구현체와 유사

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Vision API 서비스 구현체
///
/// 📚 학습 포인트: Service Layer Pattern
/// 네트워크 요청 로직을 분리하여 재사용성과 테스트 용이성 향상
/// 💡 Java 비교: Repository 패턴의 Remote DataSource와 유사
///
/// **주요 기능:**
/// - Google Cloud Vision API Label Detection
/// - 이미지 자동 최적화 (리사이징, 압축, base64 인코딩)
/// - 음식 관련 라벨 필터링
/// - API 사용량 추적 및 할당량 관리
/// - 타임아웃 및 에러 처리
///
/// **API 정보:**
/// - Provider: Google Cloud
/// - API 문서: https://cloud.google.com/vision/docs/reference/rest
/// - Free Tier: 1,000 requests/month
/// - Timeout: 30 seconds
///
/// **사용 예시:**
/// ```swift
/// let service = VisionAPIService()
///
/// // 이미지 분석
/// let photo = UIImage(named: "food")!
/// let labels = try await service.analyzeImage(photo)
///
/// // 높은 확신도의 라벨만 사용
/// let topLabels = labels.filter { $0.isHighConfidence }
/// topLabels.forEach { label in
///     print("\(label.description): \(label.scorePercentage)%")
/// }
/// ```
final class VisionAPIService: VisionAPIServiceProtocol {

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

    /// 사용량 추적기
    ///
    /// 📚 학습 포인트: Usage Tracking
    /// API 호출 횟수를 추적하여 무료 티어 한도 관리
    /// 💡 Java 비교: Rate Limiter 패턴
    private let usageTracker: VisionAPIUsageTrackerProtocol

    /// Vision API 요청 타임아웃 (초)
    ///
    /// 📚 학습 포인트: Timeout Configuration
    /// 이미지 업로드 및 분석에 충분한 시간 확보
    /// 💡 30초로 설정 (이미지 인코딩 + 네트워크 + 분석 시간)
    private let requestTimeout: TimeInterval = 30

    /// 최소 라벨 점수 (0.0 ~ 1.0)
    ///
    /// 📚 학습 포인트: Threshold-based Filtering
    /// 낮은 확신도의 라벨을 필터링하여 품질 향상
    /// 💡 0.5 이상이면 중간 이상의 확신도
    private let minimumScore: Double = 0.5

    // MARK: - Initialization

    /// VisionAPIService 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 의존성을 주입받아 테스트와 유연성 향상
    /// 💡 Java 비교: @Inject 어노테이션과 유사한 패턴
    ///
    /// - Parameters:
    ///   - networkManager: 네트워크 요청을 처리할 매니저 (기본값: 30초 타임아웃)
    ///   - apiConfig: API 설정 (기본값: APIConfig.shared)
    ///   - usageTracker: API 사용량 추적기 (기본값: VisionAPIUsageTracker.shared)
    init(
        networkManager: NetworkManager = NetworkManager(timeout: 30, maxRetries: 1),
        apiConfig: APIConfigProtocol = APIConfig.shared,
        usageTracker: VisionAPIUsageTrackerProtocol = VisionAPIUsageTracker.shared
    ) {
        self.networkManager = networkManager
        self.apiConfig = apiConfig
        self.usageTracker = usageTracker
    }

    // MARK: - Public Methods

    func analyzeImage(_ image: UIImage) async throws -> [VisionLabel] {
        // 1. API 할당량 확인
        guard usageTracker.canMakeRequest() else {
            let daysUntilReset = usageTracker.getDaysUntilReset()
            throw VisionAPIError.quotaExceeded(resetInDays: daysUntilReset)
        }

        // 2. 이미지 유효성 검증
        try validateImage(image)

        // 3. Vision API 요청 객체 생성
        let request: VisionAnnotateRequest
        do {
            request = try VisionAnnotateRequest(image: image)
        } catch {
            throw VisionAPIError.imageProcessingFailed("이미지 인코딩 실패")
        }

        // 4. API URL 생성
        guard let url = apiConfig.buildVisionURL(endpoint: .annotate) else {
            throw VisionAPIError.apiError(code: "INVALID_URL", message: "Vision API URL 생성 실패")
        }

        // 5. Vision API 호출
        let response: VisionAnnotateResponse
        do {
            response = try await networkManager.request(
                url: url.absoluteString,
                method: .post,
                body: request,
                timeout: requestTimeout
            )
        } catch let error as NetworkError {
            // 네트워크 에러를 Vision API 에러로 변환
            throw VisionAPIError.networkError(error)
        } catch {
            // 기타 에러
            throw VisionAPIError.recognitionFailed(underlyingError: error)
        }

        // 6. API 에러 응답 확인
        if let apiError = response.error {
            throw VisionAPIError.apiError(
                code: apiError.status ?? "UNKNOWN",
                message: apiError.message ?? "알 수 없는 API 에러"
            )
        }

        // 7. 라벨 추출
        guard let labels = response.labels, !labels.isEmpty else {
            throw VisionAPIError.noFoodDetected
        }

        // 8. 음식 관련 라벨만 필터링
        let foodLabels = labels.filterFoodLabels(minScore: minimumScore)

        // 9. 음식 라벨이 없으면 에러
        guard !foodLabels.isEmpty else {
            throw VisionAPIError.noFoodDetected
        }

        // 10. API 사용량 기록 (성공 시에만)
        usageTracker.recordAPICall()

        // 11. 결과 반환
        return foodLabels
    }

    // MARK: - Private Methods

    /// 이미지 유효성 검증
    ///
    /// 📚 학습 포인트: Input Validation
    /// API 호출 전에 입력 데이터의 유효성을 검증하여 불필요한 요청 방지
    /// 💡 Java 비교: @Valid 어노테이션과 유사한 역할
    ///
    /// - Parameter image: 검증할 이미지
    ///
    /// - Throws: VisionAPIError.invalidImage - 유효하지 않은 이미지
    ///
    /// - Example:
    /// ```swift
    /// try validateImage(photo)  // 정상
    /// try validateImage(tinyImage)  // 에러: 너무 작음
    /// ```
    private func validateImage(_ image: UIImage) throws {
        // 이미지 크기 확인 (최소 10x10)
        let minSize: CGFloat = 10
        guard image.size.width >= minSize && image.size.height >= minSize else {
            throw VisionAPIError.invalidImage(
                "이미지가 너무 작습니다 (최소 \(Int(minSize))x\(Int(minSize)))"
            )
        }

        // CGImage가 유효한지 확인
        guard image.cgImage != nil || image.ciImage != nil else {
            throw VisionAPIError.invalidImage("유효하지 않은 이미지 형식입니다")
        }
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Vision API Service
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 API 호출 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockVisionAPIService: VisionAPIServiceProtocol {

    /// 반환할 라벨 목록 (테스트용)
    var labelsToReturn: [VisionLabel] = []

    /// 던질 에러 (테스트용, 설정 시 analyzeImage에서 에러 발생)
    var errorToThrow: Error?

    /// analyzeImage 호출 횟수 (테스트 검증용)
    var analyzeImageCallCount = 0

    /// 마지막으로 전달받은 이미지 (테스트 검증용)
    var lastImage: UIImage?

    func analyzeImage(_ image: UIImage) async throws -> [VisionLabel] {
        analyzeImageCallCount += 1
        lastImage = image

        // 에러가 설정되어 있으면 던지기
        if let error = errorToThrow {
            throw error
        }

        // 설정된 라벨 목록 반환
        return labelsToReturn
    }

    /// 테스트용 초기화
    func reset() {
        labelsToReturn = []
        errorToThrow = nil
        analyzeImageCallCount = 0
        lastImage = nil
    }
}
#endif
