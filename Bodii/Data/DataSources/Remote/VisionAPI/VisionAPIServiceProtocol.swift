//
//  VisionAPIServiceProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Vision API 서비스 인터페이스
///
/// Google Cloud Vision API를 사용하여 음식 사진에서 라벨을 추출하는 서비스입니다.
///
/// ## 주요 기능
/// - 이미지 분석 및 라벨 추출 (Label Detection)
/// - 이미지 자동 리사이징 및 압축 (최대 1024px, JPEG 0.8)
/// - 음식 관련 라벨만 필터링
/// - API 사용량 추적 및 할당량 관리
/// - 30초 타임아웃 처리
/// - 네트워크 에러 및 API 에러 처리
///
/// ## 사용 예시
/// ```swift
/// let service: VisionAPIServiceProtocol = VisionAPIService()
///
/// do {
///     // 이미지 분석
///     let foodLabels = try await service.analyzeImage(photo)
///
///     // 결과 처리
///     foodLabels.forEach { label in
///         print("\(label.description): \(label.scorePercentage)%")
///     }
/// } catch VisionAPIError.quotaExceeded(let resetInDays) {
///     showAlert("월간 한도를 초과했습니다. \(resetInDays)일 후 초기화됩니다.")
/// } catch VisionAPIError.noFoodDetected {
///     showAlert("음식이 감지되지 않았습니다. 다시 촬영해주세요.")
/// } catch {
///     showAlert("이미지 분석 실패: \(error.localizedDescription)")
/// }
/// ```
///
/// - Note: Vision API는 월 1,000 요청 무료 티어 제한이 있습니다.
/// - Note: 이미지는 자동으로 최적화되어 API 비용과 응답 속도를 개선합니다.
///
/// - Important: analyzeImage 호출 전 VisionAPIUsageTracker로 할당량을 확인합니다.
protocol VisionAPIServiceProtocol {

    /// 이미지를 분석하여 음식 관련 라벨을 추출합니다.
    ///
    /// 📚 학습 포인트: Vision API Label Detection
    /// Google Cloud Vision API의 Label Detection 기능을 사용하여
    /// 이미지에서 객체, 장소, 활동 등의 라벨을 감지합니다.
    /// 💡 Java 비교: REST API 호출 후 DTO 파싱과 유사
    ///
    /// **처리 과정:**
    /// 1. API 할당량 확인 (canMakeRequest)
    /// 2. 이미지 전처리 (리사이징, 압축, base64 인코딩)
    /// 3. Vision API POST 요청
    /// 4. 응답 파싱
    /// 5. 음식 관련 라벨만 필터링
    /// 6. API 사용량 기록 (recordAPICall)
    ///
    /// - Parameter image: 분석할 이미지 (UIImage)
    ///
    /// - Returns: 음식 관련 라벨 목록 (정확도 순으로 정렬)
    ///
    /// - Throws:
    ///   - VisionAPIError.quotaExceeded: API 월간 한도 초과
    ///   - VisionAPIError.invalidImage: 유효하지 않은 이미지
    ///   - VisionAPIError.imageProcessingFailed: 이미지 전처리 실패
    ///   - VisionAPIError.noFoodDetected: 음식 라벨이 감지되지 않음
    ///   - VisionAPIError.networkError: 네트워크 에러
    ///   - VisionAPIError.apiError: Vision API 에러 응답
    ///
    /// - Example:
    /// ```swift
    /// let photo = UIImage(named: "food_photo")!
    /// let labels = try await service.analyzeImage(photo)
    ///
    /// // 높은 확신도의 라벨만 사용
    /// let highConfidenceLabels = labels.filter { $0.isHighConfidence }
    ///
    /// // 결과 출력
    /// highConfidenceLabels.forEach { label in
    ///     print("\(label.description): \(label.scorePercentage)%")
    /// }
    /// // 출력:
    /// // "Food: 95%"
    /// // "Dish: 92%"
    /// // "Cuisine: 88%"
    /// ```
    ///
    /// - Note: 이미지는 자동으로 최대 1024px로 리사이징되고 JPEG 0.8 품질로 압축됩니다.
    /// - Note: 음식과 관련 없는 라벨은 자동으로 필터링됩니다.
    /// - Note: 타임아웃은 30초로 설정되어 있습니다.
    ///
    /// - Important: 이 메서드는 성공 시 자동으로 API 사용량을 기록합니다.
    func analyzeImage(_ image: UIImage) async throws -> [VisionLabel]
}
