//
//  AppStateService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import Foundation
import SwiftUI

/// 앱 전역 상태 관리 서비스
/// UserDefaults 기반 상태 저장
///
/// **주요 기능**:
/// - 온보딩 완료 여부 관리
/// - 첫 실행 여부 확인
///
/// **Note**: 수면 프롬프트 관련 기능은 `SleepPromptManager`로 이전됨
/// - 날짜별 독립적인 스킵 횟수 관리
/// - PRD 요구사항 준수 (3회 스킵 후 팝업 숨김)
///
/// - Example:
/// ```swift
/// let appState = AppStateService()
/// if !appState.isOnboardingComplete {
///     // 온보딩 화면 표시
/// }
/// ```
final class AppStateService: ObservableObject {

    // MARK: - Keys

    private enum Keys {
        static let isOnboardingComplete = "isOnboardingComplete"
        static let isFirstLaunch = "isFirstLaunch"
        static let sleepPromptSkipCount = "sleepPromptSkipCount"
        static let lastSleepPromptDate = "lastSleepPromptDate"
    }

    // MARK: - Published Properties

    /// 온보딩 완료 여부
    @Published var isOnboardingComplete: Bool

    // MARK: - Private Properties

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    /// AppStateService 초기화
    /// - Parameter userDefaults: UserDefaults 인스턴스 (테스트용 주입 가능)
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // UserDefaults에서 상태 로드
        self.isOnboardingComplete = userDefaults.bool(forKey: Keys.isOnboardingComplete)
    }

    // MARK: - Onboarding Methods

    /// 온보딩 완료 처리
    /// 온보딩이 완료되면 플래그를 저장하고 메인 화면으로 전환
    func completeOnboarding() {
        userDefaults.set(true, forKey: Keys.isOnboardingComplete)
        isOnboardingComplete = true
    }

    /// 온보딩 상태 리셋 (테스트/디버그용)
    func resetOnboarding() {
        userDefaults.set(false, forKey: Keys.isOnboardingComplete)
        isOnboardingComplete = false
    }

    // MARK: - First Launch Methods

    /// 첫 실행 여부 확인
    /// - Returns: 앱이 처음 실행되었으면 true
    func isFirstLaunch() -> Bool {
        // "isFirstLaunch"가 설정되지 않았으면 첫 실행
        return !userDefaults.bool(forKey: Keys.isFirstLaunch)
    }

    /// 첫 실행 플래그 설정
    /// 앱이 처음 실행된 후 호출하여 첫 실행이 아님을 표시
    func markAsLaunched() {
        userDefaults.set(true, forKey: Keys.isFirstLaunch)
    }

    // MARK: - Sleep Prompt Methods (DEPRECATED)
    // Note: 수면 프롬프트 관련 기능은 SleepPromptManager로 이전됨
    // SleepPromptManager가 날짜별 키를 사용하여 더 견고하게 관리함
    // 이 메서드들은 하위 호환성을 위해 유지되지만, 사용하지 않음

    /// 오늘의 수면 프롬프트 스킵 횟수 조회
    /// - Returns: 오늘 스킵한 횟수 (0~3)
    /// - Note: **Deprecated** - `SleepPromptManager.getCurrentSkipCount()` 사용 권장
    @available(*, deprecated, message: "Use SleepPromptManager.getCurrentSkipCount() instead")
    func getSleepPromptSkipCount() -> Int {
        // 마지막 수면 프롬프트 날짜 확인
        guard let lastDate = userDefaults.object(forKey: Keys.lastSleepPromptDate) as? Date else {
            return 0
        }

        // 오늘 날짜와 비교 (Bodii 기준: 02:00 기준)
        let calendar = Calendar.current
        if calendar.isDateInToday(lastDate) || isInTodayBodiiDay(lastDate) {
            return userDefaults.integer(forKey: Keys.sleepPromptSkipCount)
        }

        // 날짜가 다르면 리셋
        return 0
    }

    /// 수면 프롬프트 스킵 횟수 증가
    /// - Note: **Deprecated** - `SleepPromptManager.incrementSkipCount()` 사용 권장
    @available(*, deprecated, message: "Use SleepPromptManager.incrementSkipCount() instead")
    func incrementSleepPromptSkipCount() {
        let currentCount = getSleepPromptSkipCount()
        userDefaults.set(currentCount + 1, forKey: Keys.sleepPromptSkipCount)
        userDefaults.set(Date(), forKey: Keys.lastSleepPromptDate)
    }

    /// 수면 프롬프트 스킵 횟수 리셋
    /// - Note: **Deprecated** - `SleepPromptManager.resetSkipCount()` 사용 권장
    @available(*, deprecated, message: "Use SleepPromptManager.resetSkipCount() instead")
    func resetSleepPromptSkipCount() {
        userDefaults.set(0, forKey: Keys.sleepPromptSkipCount)
    }

    // MARK: - Private Helpers

    /// Bodii 날짜 기준 (02:00)으로 오늘인지 확인
    private func isInTodayBodiiDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // 현재 시간이 02:00 이전이면 어제 날짜가 "오늘"
        let hour = calendar.component(.hour, from: now)

        if hour < 2 {
            // 새벽 2시 이전: date가 어제부터 지금 사이면 "오늘"
            let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            let startOfBodiiDay = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: yesterday)!
            return date >= startOfBodiiDay && date <= now
        } else {
            // 새벽 2시 이후: date가 오늘 02:00부터 지금 사이면 "오늘"
            let startOfBodiiDay = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: now)!
            return date >= startOfBodiiDay && date <= now
        }
    }
}

// MARK: - Preview Helper

extension AppStateService {
    /// SwiftUI Preview용 완료된 상태의 AppStateService
    static var completedOnboarding: AppStateService {
        let service = AppStateService(userDefaults: UserDefaults(suiteName: "preview")!)
        service.isOnboardingComplete = true
        return service
    }

    /// SwiftUI Preview용 미완료 상태의 AppStateService
    static var needsOnboarding: AppStateService {
        let service = AppStateService(userDefaults: UserDefaults(suiteName: "preview-onboarding")!)
        service.isOnboardingComplete = false
        return service
    }
}
