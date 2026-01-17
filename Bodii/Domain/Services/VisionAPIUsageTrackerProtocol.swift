//
//  VisionAPIUsageTrackerProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

import Foundation

/// Vision API 사용량 추적 서비스 인터페이스
///
/// Google Cloud Vision API의 월간 사용량을 추적하고 무료 티어 한도(1,000 요청/월)를 관리합니다.
/// UserDefaults를 사용하여 사용량을 영구 저장하며, 매월 자동으로 초기화됩니다.
///
/// ## 주요 기능
/// - 월간 API 호출 횟수 추적
/// - 매월 자동 초기화 (새 달이 시작되면 카운터 리셋)
/// - 남은 할당량 조회
/// - 요청 가능 여부 확인
/// - 90% 사용 시 경고 (900/1000)
///
/// ## 사용 예시
/// ```swift
/// let tracker: VisionAPIUsageTrackerProtocol = VisionAPIUsageTracker.shared
///
/// // API 호출 전 확인
/// if tracker.canMakeRequest() {
///     // Vision API 호출
///     let labels = try await visionService.analyzeImage(image)
///
///     // 호출 성공 후 카운터 증가
///     tracker.recordAPICall()
/// } else {
///     // 할당량 초과 에러 처리
///     let remainingDays = tracker.getDaysUntilReset()
///     throw VisionAPIError.quotaExceeded(resetInDays: remainingDays)
/// }
///
/// // 경고 표시 여부 확인
/// if tracker.shouldShowWarning() {
///     let remaining = tracker.getRemainingQuota()
///     showWarning("남은 할당량: \(remaining)회")
/// }
/// ```
///
/// - Note: 이 서비스는 싱글톤으로 사용하여 앱 전역에서 일관된 사용량 추적을 보장합니다.
/// - Note: UserDefaults를 사용하므로 앱 재시작 후에도 사용량이 유지됩니다.
///
/// - Important: 월간 한도는 1,000 요청으로 고정되어 있으며, Google Cloud 무료 티어 기준입니다.
protocol VisionAPIUsageTrackerProtocol {

    // MARK: - Request Management

    /// API 요청이 가능한지 확인합니다.
    ///
    /// 현재 월의 사용량이 월간 한도(1,000)를 초과하지 않았는지 확인합니다.
    /// 새로운 달이 시작되었다면 자동으로 카운터를 초기화한 후 확인합니다.
    ///
    /// - Returns: 요청 가능하면 `true`, 할당량 초과 시 `false`
    ///
    /// - Example:
    /// ```swift
    /// if tracker.canMakeRequest() {
    ///     // Vision API 호출 가능
    ///     let labels = try await visionService.analyzeImage(image)
    ///     tracker.recordAPICall()
    /// } else {
    ///     // 할당량 초과 - 에러 처리
    ///     showError("월간 할당량을 초과했습니다.")
    /// }
    /// ```
    ///
    /// - Note: 이 메서드를 호출하면 자동으로 월 변경 체크가 수행됩니다.
    func canMakeRequest() -> Bool

    /// API 호출을 기록합니다.
    ///
    /// Vision API 호출이 성공했을 때 호출하여 사용량 카운터를 1 증가시킵니다.
    /// 증가된 값은 UserDefaults에 즉시 저장됩니다.
    ///
    /// - Example:
    /// ```swift
    /// // Vision API 호출 성공 후
    /// let labels = try await visionService.analyzeImage(image)
    /// tracker.recordAPICall()  // 카운터 증가
    /// ```
    ///
    /// - Note: 실패한 요청은 기록하지 않아야 합니다.
    /// - Note: 이 메서드는 thread-safe하게 구현되어야 합니다.
    func recordAPICall()

    // MARK: - Quota Information

    /// 남은 할당량을 조회합니다.
    ///
    /// 월간 한도(1,000)에서 현재 월의 사용량을 뺀 값을 반환합니다.
    /// 새로운 달이 시작되었다면 자동으로 카운터를 초기화한 후 반환합니다.
    ///
    /// - Returns: 남은 API 호출 가능 횟수 (0 이상)
    ///
    /// - Example:
    /// ```swift
    /// let remaining = tracker.getRemainingQuota()
    /// print("남은 할당량: \(remaining)회")
    /// // 출력: "남은 할당량: 850회"
    /// ```
    ///
    /// - Note: 음수는 반환하지 않으며, 할당량을 초과한 경우 0을 반환합니다.
    func getRemainingQuota() -> Int

    /// 현재 월의 API 사용량을 조회합니다.
    ///
    /// 이번 달에 호출된 Vision API 총 횟수를 반환합니다.
    /// 새로운 달이 시작되었다면 자동으로 0으로 초기화한 후 반환합니다.
    ///
    /// - Returns: 현재 월의 API 호출 횟수
    ///
    /// - Example:
    /// ```swift
    /// let currentUsage = tracker.getCurrentUsage()
    /// print("이번 달 사용량: \(currentUsage)/1000")
    /// // 출력: "이번 달 사용량: 150/1000"
    /// ```
    func getCurrentUsage() -> Int

    /// 월간 할당량 한도를 조회합니다.
    ///
    /// Google Cloud Vision API 무료 티어의 월간 한도인 1,000을 반환합니다.
    ///
    /// - Returns: 월간 할당량 한도 (현재: 1,000)
    ///
    /// - Example:
    /// ```swift
    /// let monthlyLimit = tracker.getMonthlyLimit()
    /// print("월간 한도: \(monthlyLimit)회")
    /// // 출력: "월간 한도: 1000회"
    /// ```
    func getMonthlyLimit() -> Int

    // MARK: - Warning Threshold

    /// 경고를 표시해야 하는지 확인합니다.
    ///
    /// 사용량이 경고 임계값(90%, 즉 900회)을 초과했는지 확인합니다.
    /// UI에서 사용자에게 경고 메시지를 표시할지 결정하는 데 사용됩니다.
    ///
    /// - Returns: 경고를 표시해야 하면 `true`, 아니면 `false`
    ///
    /// - Example:
    /// ```swift
    /// if tracker.shouldShowWarning() {
    ///     let remaining = tracker.getRemainingQuota()
    ///     showWarning("API 할당량이 90%를 초과했습니다. 남은 횟수: \(remaining)")
    /// }
    /// ```
    ///
    /// - Note: 경고 임계값은 월간 한도의 90% (900/1000)입니다.
    func shouldShowWarning() -> Bool

    /// 경고 임계값을 조회합니다.
    ///
    /// 경고가 표시되기 시작하는 사용량 값을 반환합니다.
    /// 현재는 월간 한도의 90% (900회)로 고정되어 있습니다.
    ///
    /// - Returns: 경고 임계값 (현재: 900)
    ///
    /// - Example:
    /// ```swift
    /// let threshold = tracker.getWarningThreshold()
    /// print("경고 임계값: \(threshold)회")
    /// // 출력: "경고 임계값: 900회"
    /// ```
    func getWarningThreshold() -> Int

    // MARK: - Reset Information

    /// 할당량이 초기화되기까지 남은 일수를 계산합니다.
    ///
    /// 다음 달 1일까지 남은 일수를 반환합니다.
    /// 할당량 초과 시 사용자에게 언제 다시 사용할 수 있는지 알려주는 데 사용됩니다.
    ///
    /// - Returns: 다음 달까지 남은 일수 (1일 이상)
    ///
    /// - Example:
    /// ```swift
    /// if !tracker.canMakeRequest() {
    ///     let daysUntilReset = tracker.getDaysUntilReset()
    ///     showError("할당량이 \(daysUntilReset)일 후에 초기화됩니다.")
    /// }
    /// ```
    ///
    /// - Note: 오늘이 12월 25일이면 7을 반환 (1월 1일까지 7일)
    func getDaysUntilReset() -> Int

    /// 할당량이 초기화되는 날짜를 조회합니다.
    ///
    /// 다음 달 1일 00:00:00을 반환합니다.
    /// UI에서 정확한 초기화 시점을 표시하는 데 사용됩니다.
    ///
    /// - Returns: 다음 달 1일 자정
    ///
    /// - Example:
    /// ```swift
    /// let resetDate = tracker.getResetDate()
    /// let formatter = DateFormatter()
    /// formatter.dateStyle = .medium
    /// print("초기화 날짜: \(formatter.string(from: resetDate))")
    /// // 출력: "초기화 날짜: 2026년 2월 1일"
    /// ```
    func getResetDate() -> Date

    // MARK: - Testing Support

    /// 사용량 데이터를 초기화합니다.
    ///
    /// 테스트 또는 디버그 목적으로 사용량을 강제로 초기화합니다.
    /// UserDefaults에 저장된 모든 사용량 데이터가 삭제됩니다.
    ///
    /// - Example:
    /// ```swift
    /// // 테스트 전 초기화
    /// tracker.reset()
    /// assert(tracker.getCurrentUsage() == 0)
    /// ```
    ///
    /// - Warning: 프로덕션 환경에서는 사용하지 말아야 합니다.
    /// - Note: 이 메서드는 주로 단위 테스트에서 사용됩니다.
    func reset()
}
