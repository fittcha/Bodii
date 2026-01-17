//
//  VisionAPIUsageTracker.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: API Usage Tracking with UserDefaults
// Vision API의 무료 티어 한도(1,000 요청/월)를 추적하고 관리하는 서비스
// 💡 Java 비교: SharedPreferences를 사용한 데이터 영구 저장과 유사

import Foundation

/// Vision API 사용량 추적 서비스 구현
///
/// 📚 학습 포인트: Singleton Pattern with UserDefaults
/// UserDefaults를 사용하여 API 사용량을 영구 저장하고, 싱글톤 패턴으로 일관된 추적을 보장합니다.
/// 💡 Java 비교: SharedPreferences + Singleton과 유사
///
/// ## 저장 구조
/// UserDefaults에 다음 키로 데이터를 저장합니다:
/// - `vision_api_usage_count`: 현재 월의 API 호출 횟수
/// - `vision_api_usage_month`: 마지막 호출이 기록된 월 (YYYY-MM 형식)
///
/// ## 월 자동 초기화 로직
/// 새로운 달이 시작되면 자동으로 카운터를 0으로 초기화합니다.
/// 예) 저장된 월: "2026-01", 현재 월: "2026-02" → 카운터 초기화
///
/// - Example:
/// ```swift
/// let tracker = VisionAPIUsageTracker.shared
///
/// // 요청 전 확인
/// guard tracker.canMakeRequest() else {
///     let daysUntilReset = tracker.getDaysUntilReset()
///     throw VisionAPIError.quotaExceeded(resetInDays: daysUntilReset)
/// }
///
/// // Vision API 호출
/// let labels = try await visionService.analyzeImage(image)
///
/// // 호출 기록
/// tracker.recordAPICall()
/// ```
final class VisionAPIUsageTracker: VisionAPIUsageTrackerProtocol {

    // MARK: - Singleton

    /// 공유 인스턴스
    ///
    /// 📚 학습 포인트: Singleton Pattern
    /// 앱 전역에서 동일한 추적 인스턴스 사용
    /// 💡 Java 비교: getInstance()와 동일
    static let shared = VisionAPIUsageTracker()

    // MARK: - Constants

    /// UserDefaults 키: API 호출 횟수
    private let usageCountKey = "vision_api_usage_count"

    /// UserDefaults 키: 사용량이 기록된 월
    private let usageMonthKey = "vision_api_usage_month"

    /// 월간 할당량 한도
    ///
    /// 📚 학습 포인트: Constants for Business Logic
    /// Google Cloud Vision API 무료 티어는 월 1,000 요청까지 무료
    /// 💡 Java 비교: public static final int MONTHLY_LIMIT = 1000;
    private let monthlyLimit = 1000

    /// 경고 임계값 비율 (90%)
    ///
    /// 📚 학습 포인트: Threshold-based Warnings
    /// 사용량이 90%를 넘으면 사용자에게 경고 표시
    /// 💡 Java 비교: private static final double WARNING_THRESHOLD = 0.9;
    private let warningThresholdRatio = 0.9

    /// UserDefaults 인스턴스
    ///
    /// 📚 학습 포인트: Dependency Injection for Testing
    /// 테스트에서 다른 UserDefaults 인스턴스를 주입할 수 있도록 설계
    /// 💡 Java 비교: Constructor Injection과 유사
    private let userDefaults: UserDefaults

    /// Thread-safe 접근을 위한 Queue
    ///
    /// 📚 학습 포인트: Thread Safety with Dispatch Queue
    /// 여러 스레드에서 동시에 접근해도 안전하도록 serial queue 사용
    /// 💡 Java 비교: synchronized block 또는 ReentrantLock과 유사
    private let queue = DispatchQueue(label: "com.bodii.visionapi.usagetracker", qos: .userInitiated)

    // MARK: - Initialization

    /// VisionAPIUsageTracker를 초기화합니다.
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// UserDefaults를 주입받아 테스트 가능하도록 설계
    /// 💡 Java 비교: Constructor Injection과 동일
    ///
    /// - Parameter userDefaults: UserDefaults 인스턴스 (기본값: .standard)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Request Management

    func canMakeRequest() -> Bool {
        queue.sync {
            // 월 변경 체크 및 필요시 초기화
            resetIfNewMonth()

            // 현재 사용량이 한도 미만인지 확인
            let currentUsage = getCurrentUsageUnsafe()
            return currentUsage < monthlyLimit
        }
    }

    func recordAPICall() {
        queue.sync {
            // 월 변경 체크 및 필요시 초기화
            resetIfNewMonth()

            // 현재 사용량 조회
            let currentUsage = getCurrentUsageUnsafe()

            // 카운터 증가
            let newUsage = currentUsage + 1
            userDefaults.set(newUsage, forKey: usageCountKey)

            // 현재 월 저장 (이미 저장되어 있지만 일관성 유지)
            let currentMonth = getCurrentMonth()
            userDefaults.set(currentMonth, forKey: usageMonthKey)
        }
    }

    // MARK: - Quota Information

    func getRemainingQuota() -> Int {
        queue.sync {
            // 월 변경 체크 및 필요시 초기화
            resetIfNewMonth()

            let currentUsage = getCurrentUsageUnsafe()
            let remaining = monthlyLimit - currentUsage

            // 음수 반환 방지
            return max(0, remaining)
        }
    }

    func getCurrentUsage() -> Int {
        queue.sync {
            // 월 변경 체크 및 필요시 초기화
            resetIfNewMonth()

            return getCurrentUsageUnsafe()
        }
    }

    func getMonthlyLimit() -> Int {
        return monthlyLimit
    }

    // MARK: - Warning Threshold

    func shouldShowWarning() -> Bool {
        queue.sync {
            // 월 변경 체크 및 필요시 초기화
            resetIfNewMonth()

            let currentUsage = getCurrentUsageUnsafe()
            let threshold = getWarningThreshold()

            return currentUsage >= threshold
        }
    }

    func getWarningThreshold() -> Int {
        return Int(Double(monthlyLimit) * warningThresholdRatio)
    }

    // MARK: - Reset Information

    func getDaysUntilReset() -> Int {
        let calendar = Calendar.current
        let now = Date()

        // 다음 달 1일 계산
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let firstDayOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            return 1  // 에러 시 최소 1일 반환
        }

        // 남은 일수 계산
        let components = calendar.dateComponents([.day], from: now, to: firstDayOfNextMonth)
        let daysUntilReset = components.day ?? 1

        // 최소 1일 반환
        return max(1, daysUntilReset)
    }

    func getResetDate() -> Date {
        let calendar = Calendar.current
        let now = Date()

        // 다음 달 1일 계산
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let firstDayOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            // 에러 시 내일 반환
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }

        return firstDayOfNextMonth
    }

    // MARK: - Testing Support

    func reset() {
        queue.sync {
            userDefaults.removeObject(forKey: usageCountKey)
            userDefaults.removeObject(forKey: usageMonthKey)
        }
    }

    // MARK: - Private Helpers

    /// 현재 사용량을 조회합니다. (thread-unsafe, 내부 사용 전용)
    ///
    /// 📚 학습 포인트: Private Helper Methods
    /// queue.sync 내부에서만 호출되므로 별도의 동기화 불필요
    /// 💡 Java 비교: private helper method와 동일
    ///
    /// - Returns: 현재 월의 API 호출 횟수
    private func getCurrentUsageUnsafe() -> Int {
        return userDefaults.integer(forKey: usageCountKey)
    }

    /// 저장된 사용량의 월을 조회합니다.
    ///
    /// 📚 학습 포인트: Date Formatting for Comparison
    /// "YYYY-MM" 형식의 문자열로 월을 비교
    /// 💡 Java 비교: SimpleDateFormat("yyyy-MM")과 유사
    ///
    /// - Returns: 저장된 월 (YYYY-MM 형식), 저장되지 않았으면 nil
    private func getSavedMonth() -> String? {
        return userDefaults.string(forKey: usageMonthKey)
    }

    /// 현재 월을 문자열로 반환합니다.
    ///
    /// 📚 학습 포인트: DateFormatter for Month Comparison
    /// DateFormatter를 사용하여 안전한 날짜 형식화
    /// 💡 Java 비교: SimpleDateFormat("yyyy-MM")과 동일
    ///
    /// - Returns: 현재 월 (YYYY-MM 형식, 예: "2026-01")
    private func getCurrentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    /// 새로운 달이 시작되었는지 확인하고, 필요시 사용량을 초기화합니다.
    ///
    /// 📚 학습 포인트: Automatic Monthly Reset Logic
    /// 저장된 월과 현재 월을 비교하여 자동으로 카운터 초기화
    /// 💡 Java 비교: Auto-reset pattern with date comparison
    ///
    /// ## 초기화 조건
    /// 1. 저장된 월이 없음 (첫 실행)
    /// 2. 저장된 월 != 현재 월 (새로운 달 시작)
    ///
    /// - Note: 이 메서드는 queue.sync 내부에서만 호출되어야 합니다.
    private func resetIfNewMonth() {
        let currentMonth = getCurrentMonth()
        let savedMonth = getSavedMonth()

        // 저장된 월이 없거나 현재 월과 다르면 초기화
        if savedMonth == nil || savedMonth != currentMonth {
            userDefaults.set(0, forKey: usageCountKey)
            userDefaults.set(currentMonth, forKey: usageMonthKey)
        }
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Vision API Usage Tracker
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 UserDefaults 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockVisionAPIUsageTracker: VisionAPIUsageTrackerProtocol {

    /// 현재 사용량 (테스트용)
    var currentUsage: Int = 0

    /// 월간 한도 (테스트용, 기본값: 1000)
    var monthlyLimit: Int = 1000

    /// 경고 임계값 비율 (테스트용, 기본값: 0.9)
    var warningThresholdRatio: Double = 0.9

    /// 다음 달까지 남은 일수 (테스트용, 기본값: 7)
    var daysUntilReset: Int = 7

    /// 초기화 날짜 (테스트용)
    var resetDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    func canMakeRequest() -> Bool {
        return currentUsage < monthlyLimit
    }

    func recordAPICall() {
        currentUsage += 1
    }

    func getRemainingQuota() -> Int {
        return max(0, monthlyLimit - currentUsage)
    }

    func getCurrentUsage() -> Int {
        return currentUsage
    }

    func getMonthlyLimit() -> Int {
        return monthlyLimit
    }

    func shouldShowWarning() -> Bool {
        let threshold = getWarningThreshold()
        return currentUsage >= threshold
    }

    func getWarningThreshold() -> Int {
        return Int(Double(monthlyLimit) * warningThresholdRatio)
    }

    func getDaysUntilReset() -> Int {
        return daysUntilReset
    }

    func getResetDate() -> Date {
        return resetDate
    }

    func reset() {
        currentUsage = 0
    }
}
#endif
