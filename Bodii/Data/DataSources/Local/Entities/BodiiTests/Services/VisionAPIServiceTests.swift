//
//  VisionAPIServiceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-17.
//

import XCTest
@testable import Bodii
#if canImport(UIKit)
import UIKit
#endif

/// Unit tests for VisionAPIService
///
/// VisionAPIService의 이미지 분석, 에러 처리, 할당량 관리 단위 테스트
///
/// **테스트 범위:**
/// - Image analysis and label detection
/// - Image compression and base64 encoding
/// - Food label filtering logic
/// - Usage tracker integration
/// - Quota exceeded handling
/// - Network error handling
final class VisionAPIServiceTests: XCTestCase {

    // MARK: - Properties

    var service: VisionAPIService!
    var mockNetworkManager: MockNetworkManager!
    var mockAPIConfig: MockAPIConfig!
    var mockUsageTracker: MockVisionAPIUsageTracker!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Initialize mocks
        mockNetworkManager = MockNetworkManager()
        mockAPIConfig = MockAPIConfig()
        mockUsageTracker = MockVisionAPIUsageTracker()

        // Initialize service with mocks
        service = VisionAPIService(
            networkManager: mockNetworkManager,
            apiConfig: mockAPIConfig,
            usageTracker: mockUsageTracker
        )
    }

    override func tearDown() {
        service = nil
        mockNetworkManager = nil
        mockAPIConfig = nil
        mockUsageTracker = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    /// Test: Analyze image returns food labels
    ///
    /// 테스트: 이미지 분석 시 음식 라벨 반환
    func testAnalyzeImage_SuccessfulResponse_ReturnsFoodLabels() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Mock successful response with food labels
        let mockResponse = createSuccessfulVisionResponse(
            labels: [
                VisionLabel(mid: "/m/02wbm", description: "Food", score: 0.95, topicality: 0.93),
                VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.92, topicality: 0.90),
                VisionLabel(mid: "/m/0krfg", description: "Cheese", score: 0.85, topicality: 0.82)
            ]
        )
        mockNetworkManager.mockResponse = mockResponse

        // When: Analyzing image
        let labels = try await service.analyzeImage(image)

        // Then: Should return food labels
        XCTAssertEqual(labels.count, 3, "Should return 3 food labels")
        XCTAssertEqual(labels[0].description, "Food")
        XCTAssertEqual(labels[1].description, "Pizza")
        XCTAssertEqual(labels[2].description, "Cheese")
    }

    /// Test: Analyze image filters by minimum score
    ///
    /// 테스트: 이미지 분석 시 최소 점수로 필터링
    func testAnalyzeImage_FiltersLowScoreLabels() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Mock response with mixed scores
        let mockResponse = createSuccessfulVisionResponse(
            labels: [
                VisionLabel(mid: "/m/02wbm", description: "Food", score: 0.95, topicality: 0.93),
                VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.60, topicality: 0.58),
                VisionLabel(mid: "/m/0krfg", description: "Cheese", score: 0.30, topicality: 0.28)  // Below min score
            ]
        )
        mockNetworkManager.mockResponse = mockResponse

        // When: Analyzing image
        let labels = try await service.analyzeImage(image)

        // Then: Should filter out low score labels (< 0.5)
        XCTAssertEqual(labels.count, 2, "Should filter labels with score < 0.5")
        XCTAssertTrue(labels.allSatisfy { $0.score >= 0.5 }, "All labels should have score >= 0.5")
    }

    /// Test: Analyze image filters non-food labels
    ///
    /// 테스트: 이미지 분석 시 비음식 라벨 필터링
    func testAnalyzeImage_FiltersNonFoodLabels() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Mock response with non-food labels
        let mockResponse = createSuccessfulVisionResponse(
            labels: [
                VisionLabel(mid: "/m/02wbm", description: "Food", score: 0.95, topicality: 0.93),
                VisionLabel(mid: "/m/0kq3g", description: "Table", score: 0.90, topicality: 0.88),
                VisionLabel(mid: "/m/04_3p", description: "Plate", score: 0.85, topicality: 0.82)
            ]
        )
        mockNetworkManager.mockResponse = mockResponse

        // When: Analyzing image
        let labels = try await service.analyzeImage(image)

        // Then: Should only return food-related labels
        XCTAssertEqual(labels.count, 1, "Should only return food labels")
        XCTAssertEqual(labels[0].description, "Food")
    }

    /// Test: Analyze image records API usage on success
    ///
    /// 테스트: 이미지 분석 성공 시 API 사용량 기록
    func testAnalyzeImage_RecordsAPIUsageOnSuccess() async throws {
        // Given: Valid image and successful response
        let image = createTestImage()
        let mockResponse = createSuccessfulVisionResponse(
            labels: [
                VisionLabel(mid: "/m/02wbm", description: "Food", score: 0.95, topicality: 0.93)
            ]
        )
        mockNetworkManager.mockResponse = mockResponse

        // When: Analyzing image
        _ = try await service.analyzeImage(image)

        // Then: Should record API usage
        XCTAssertEqual(mockUsageTracker.currentUsage, 1, "Should record one API call")
    }

    // MARK: - Quota Tests

    /// Test: Quota exceeded throws error
    ///
    /// 테스트: 할당량 초과 시 에러 발생
    func testAnalyzeImage_QuotaExceeded_ThrowsError() async throws {
        // Given: Quota exceeded
        mockUsageTracker.currentUsage = 1000
        mockUsageTracker.monthlyLimit = 1000
        mockUsageTracker.daysUntilReset = 5

        // Given: Valid image
        let image = createTestImage()

        // When/Then: Should throw quota exceeded error
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw quotaExceeded error")
        } catch let error as VisionAPIError {
            if case .quotaExceeded(let resetInDays) = error {
                XCTAssertEqual(resetInDays, 5, "Should include days until reset")
            } else {
                XCTFail("Should throw quotaExceeded error, got \(error)")
            }
        }
    }

    /// Test: Quota exceeded does not record usage
    ///
    /// 테스트: 할당량 초과 시 사용량 기록하지 않음
    func testAnalyzeImage_QuotaExceeded_DoesNotRecordUsage() async throws {
        // Given: Quota exceeded
        mockUsageTracker.currentUsage = 1000
        mockUsageTracker.monthlyLimit = 1000

        // Given: Valid image
        let image = createTestImage()

        // When: Trying to analyze image
        do {
            _ = try await service.analyzeImage(image)
        } catch {
            // Expected to fail
        }

        // Then: Should not increment usage
        XCTAssertEqual(mockUsageTracker.currentUsage, 1000, "Should not record usage when quota exceeded")
    }

    // MARK: - Image Validation Tests

    /// Test: Invalid image throws error
    ///
    /// 테스트: 유효하지 않은 이미지는 에러 발생
    func testAnalyzeImage_TooSmallImage_ThrowsError() async throws {
        // Given: Too small image (5x5)
        let image = createTestImage(size: CGSize(width: 5, height: 5))

        // When/Then: Should throw invalidImage error
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw invalidImage error")
        } catch let error as VisionAPIError {
            if case .invalidImage = error {
                // Expected error
                XCTAssertTrue(true, "Should throw invalidImage error")
            } else {
                XCTFail("Should throw invalidImage error, got \(error)")
            }
        }
    }

    // MARK: - No Food Detected Tests

    /// Test: No labels throws noFoodDetected error
    ///
    /// 테스트: 라벨 없으면 noFoodDetected 에러 발생
    func testAnalyzeImage_NoLabels_ThrowsNoFoodDetected() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Response with no labels
        let mockResponse = createSuccessfulVisionResponse(labels: [])
        mockNetworkManager.mockResponse = mockResponse

        // When/Then: Should throw noFoodDetected error
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw noFoodDetected error")
        } catch let error as VisionAPIError {
            if case .noFoodDetected = error {
                // Expected error
                XCTAssertTrue(true, "Should throw noFoodDetected error")
            } else {
                XCTFail("Should throw noFoodDetected error, got \(error)")
            }
        }
    }

    /// Test: Only non-food labels throws noFoodDetected error
    ///
    /// 테스트: 비음식 라벨만 있으면 noFoodDetected 에러 발생
    func testAnalyzeImage_OnlyNonFoodLabels_ThrowsNoFoodDetected() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Response with only non-food labels
        let mockResponse = createSuccessfulVisionResponse(
            labels: [
                VisionLabel(mid: "/m/0kq3g", description: "Table", score: 0.90, topicality: 0.88),
                VisionLabel(mid: "/m/04_3p", description: "Plate", score: 0.85, topicality: 0.82)
            ]
        )
        mockNetworkManager.mockResponse = mockResponse

        // When/Then: Should throw noFoodDetected error
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw noFoodDetected error")
        } catch let error as VisionAPIError {
            if case .noFoodDetected = error {
                // Expected error
                XCTAssertTrue(true, "Should throw noFoodDetected error")
            } else {
                XCTFail("Should throw noFoodDetected error, got \(error)")
            }
        }
    }

    // MARK: - Network Error Tests

    /// Test: Network error is wrapped in VisionAPIError
    ///
    /// 테스트: 네트워크 에러는 VisionAPIError로 래핑됨
    func testAnalyzeImage_NetworkError_ThrowsWrappedError() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Network error
        mockNetworkManager.errorToThrow = NetworkError.timeout

        // When/Then: Should throw networkError
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw networkError")
        } catch let error as VisionAPIError {
            if case .networkError(let networkError) = error {
                XCTAssertEqual(networkError, NetworkError.timeout, "Should wrap network error")
            } else {
                XCTFail("Should throw networkError, got \(error)")
            }
        }
    }

    /// Test: Network unavailable error
    ///
    /// 테스트: 네트워크 연결 불가 에러
    func testAnalyzeImage_NetworkUnavailable_ThrowsError() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Network unavailable
        mockNetworkManager.errorToThrow = NetworkError.networkUnavailable

        // When/Then: Should throw networkError
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw networkError")
        } catch let error as VisionAPIError {
            if case .networkError(let networkError) = error {
                XCTAssertEqual(networkError, NetworkError.networkUnavailable)
            } else {
                XCTFail("Should throw networkError, got \(error)")
            }
        }
    }

    // MARK: - API Error Tests

    /// Test: API error response throws apiError
    ///
    /// 테스트: API 에러 응답은 apiError 발생
    func testAnalyzeImage_APIErrorResponse_ThrowsAPIError() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: API error response
        let mockResponse = createErrorVisionResponse(
            code: 403,
            status: "PERMISSION_DENIED",
            message: "API key not valid"
        )
        mockNetworkManager.mockResponse = mockResponse

        // When/Then: Should throw apiError
        do {
            _ = try await service.analyzeImage(image)
            XCTFail("Should throw apiError")
        } catch let error as VisionAPIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, "PERMISSION_DENIED")
                XCTAssertEqual(message, "API key not valid")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        }
    }

    // MARK: - Label Sorting Tests

    /// Test: Labels are sorted by score descending
    ///
    /// 테스트: 라벨은 점수 내림차순으로 정렬됨
    func testAnalyzeImage_SortsLabelsByScoreDescending() async throws {
        // Given: Valid image
        let image = createTestImage()

        // Given: Mock response with unsorted labels
        let mockResponse = createSuccessfulVisionResponse(
            labels: [
                VisionLabel(mid: "/m/0krfg", description: "Cheese", score: 0.75, topicality: 0.72),
                VisionLabel(mid: "/m/02wbm", description: "Food", score: 0.95, topicality: 0.93),
                VisionLabel(mid: "/m/0663v", description: "Pizza", score: 0.85, topicality: 0.82)
            ]
        )
        mockNetworkManager.mockResponse = mockResponse

        // When: Analyzing image
        let labels = try await service.analyzeImage(image)

        // Then: Should be sorted by score descending
        XCTAssertEqual(labels[0].description, "Food", "Highest score should be first")
        XCTAssertEqual(labels[1].description, "Pizza", "Second highest score should be second")
        XCTAssertEqual(labels[2].description, "Cheese", "Lowest score should be last")
        XCTAssertGreaterThanOrEqual(labels[0].score, labels[1].score)
        XCTAssertGreaterThanOrEqual(labels[1].score, labels[2].score)
    }

    // MARK: - Helper Methods

    /// Create test image
    ///
    /// 테스트용 이미지 생성
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Create successful Vision API response
    ///
    /// 성공 응답 생성
    private func createSuccessfulVisionResponse(labels: [VisionLabel]) -> VisionAnnotateResponse {
        let imageResponse = VisionAnnotateResponse.ImageResponse(
            labelAnnotations: labels,
            error: nil
        )
        return VisionAnnotateResponse(responses: [imageResponse])
    }

    /// Create error Vision API response
    ///
    /// 에러 응답 생성
    private func createErrorVisionResponse(code: Int, status: String, message: String) -> VisionAnnotateResponse {
        let error = VisionAnnotateResponse.VisionError(
            code: code,
            message: message,
            status: status
        )
        let imageResponse = VisionAnnotateResponse.ImageResponse(
            labelAnnotations: nil,
            error: error
        )
        return VisionAnnotateResponse(responses: [imageResponse])
    }
}

// MARK: - Mock Network Manager

/// Mock NetworkManager for testing
///
/// 테스트용 Mock NetworkManager
class MockNetworkManager: NetworkManager {

    /// Mock response to return
    var mockResponse: VisionAnnotateResponse?

    /// Error to throw
    var errorToThrow: Error?

    /// Call count
    var requestCallCount = 0

    /// Last request URL
    var lastURL: String?

    override func request<Request: Encodable, Response: Decodable>(
        url: String,
        method: HTTPMethod,
        body: Request? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> Response {
        requestCallCount += 1
        lastURL = url

        // Throw error if set
        if let error = errorToThrow {
            throw error
        }

        // Return mock response
        guard let response = mockResponse as? Response else {
            throw NetworkError.decodingError(NSError(domain: "Test", code: -1))
        }

        return response
    }

    func reset() {
        mockResponse = nil
        errorToThrow = nil
        requestCallCount = 0
        lastURL = nil
    }
}

// MARK: - Mock API Config

/// Mock APIConfig for testing
///
/// 테스트용 Mock APIConfig
class MockAPIConfig: APIConfigProtocol {

    var visionAPIBaseURL: String {
        return "https://vision.googleapis.com/v1"
    }

    var visionAPIKey: String {
        return "TEST_API_KEY"
    }

    func buildVisionURL(endpoint: APIConfig.VisionEndpoint) -> URL? {
        switch endpoint {
        case .annotate:
            return URL(string: "\(visionAPIBaseURL)/images:annotate?key=\(visionAPIKey)")
        }
    }
}
