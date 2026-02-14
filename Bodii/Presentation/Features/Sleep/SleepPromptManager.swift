//
//  SleepPromptManager.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Sleep Prompt Manager
// 아침 수면 기록 프롬프트 로직과 건너뛰기 횟수 관리
// 💡 Java 비교: Android의 Preference Manager와 유사

import Foundation
import SwiftUI
import Combine

// MARK: - SleepPromptManager

/// 수면 기록 프롬프트 관리 클래스
/// 📚 학습 포인트: Manager Pattern
/// - 아침 프롬프트 표시 여부 결정
/// - 건너뛰기 횟수 추적 (날짜별)
/// - 강제 입력 모드 관리 (3회 건너뛰기 후)
/// - UserDefaults를 사용한 영속성
/// 💡 Java 비교: SharedPreferences + Manager 클래스와 유사
@MainActor
class SleepPromptManager: ObservableObject {

    // MARK: - Constants

    /// UserDefaults 키
    /// 📚 학습 포인트: Constants for Keys
    /// - 하드코딩된 문자열 대신 상수 사용
    /// - 오타 방지 및 리팩토링 용이
    private enum Keys {
        static let skipCountPrefix = "sleep_skip_count_"
        static let lastPromptDate = "sleep_last_prompt_date"
        static let lastPromptCheckDate = "sleep_last_prompt_check_date"
    }

    /// 최대 건너뛰기 횟수
    /// 📚 학습 포인트: Business Rule Constant
    /// - 3회 건너뛰기 후 강제 입력 모드
    private static let maxSkipCount = 3

    /// 건너뛰기 데이터 보관 기간 (일 단위)
    /// 📚 학습 포인트: Data Retention Policy Constant
    /// - 7일 이상 지난 건너뛰기 데이터는 자동 삭제
    private static let cleanupDaysThreshold = 7

    // MARK: - Published Properties

    /// 프롬프트 표시 여부
    /// 📚 학습 포인트: @Published
    /// - 값이 변경되면 자동으로 View 업데이트
    /// - Sheet 표시/숨김에 사용
    /// 💡 Java 비교: LiveData와 유사
    @Published var shouldShowPrompt: Bool = false

    /// 강제 입력 모드 여부
    /// 📚 학습 포인트: Force Entry Mode
    /// - 3회 건너뛰기 후 true
    /// - SleepInputSheet의 canSkip 파라미터로 전달
    @Published var isForceEntry: Bool = false

    // MARK: - Private Properties

    /// 수면 데이터 저장소
    /// 📚 학습 포인트: Dependency Injection
    /// - Repository를 외부에서 주입받아 사용
    /// - 오늘 수면 기록이 있는지 확인에 사용
    private let sleepRepository: SleepRepositoryProtocol

    /// UserDefaults 인스턴스
    /// 📚 학습 포인트: UserDefaults for Persistence
    /// - 간단한 Key-Value 저장소
    /// - 앱 종료 후에도 데이터 유지
    /// 💡 Java 비교: SharedPreferences와 유사
    private let userDefaults: UserDefaults

    /// 오늘 날짜 (캐시)
    /// 📚 학습 포인트: Date Caching
    /// - 반복적인 Date() 호출 방지
    /// - 논리적 날짜 (02:00 경계 적용)
    private var today: Date {
        DateUtils.getLogicalDate(for: Date())
    }

    // MARK: - Initialization

    /// SleepPromptManager 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 테스트 시 Mock Repository와 UserDefaults 주입 가능
    /// 💡 Java 비교: @Inject constructor와 유사
    ///
    /// - Parameters:
    ///   - sleepRepository: 수면 데이터 저장소
    ///   - userDefaults: UserDefaults 인스턴스 (기본값: .standard)
    init(
        sleepRepository: SleepRepositoryProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.sleepRepository = sleepRepository
        self.userDefaults = userDefaults
    }

    // MARK: - Public Methods

    /// 프롬프트를 표시해야 하는지 확인
    /// 📚 학습 포인트: Main Check Logic
    /// - 시간 조건 확인 (02:00 이후)
    /// - 오늘 기록 존재 여부 확인
    /// - 강제 입력 모드 여부 확인
    /// - 결과를 @Published 프로퍼티에 반영
    ///
    /// 호출 시점:
    /// - 앱 시작 시 (BodiiApp.onAppear)
    /// - 앱이 포그라운드로 돌아올 때 (onReceive ScenePhase)
    func checkShouldShow() async {
        // 02:00 이전에는 프롬프트 표시 안 함
        guard DateUtils.shouldShowSleepPopup() else {
            shouldShowPrompt = false
            return
        }

        // 오늘 수면 기록이 이미 있으면 무조건 프롬프트 표시 안 함
        do {
            let todayRecord = try await sleepRepository.fetch(for: today)
            if todayRecord != nil {
                shouldShowPrompt = false
                return
            }
        } catch {
            print("⚠️ Failed to fetch today's sleep record: \(error.localizedDescription)")
        }

        // 오늘 이미 프롬프트를 띄운 적 있으면 다시 표시하지 않음 (하루 한 번만)
        let todayString = logicalDateString(for: today)
        let lastCheckDate = userDefaults.string(forKey: Keys.lastPromptCheckDate)
        if lastCheckDate == todayString {
            return
        }

        // 오늘 첫 체크 기록
        userDefaults.set(todayString, forKey: Keys.lastPromptCheckDate)

        isForceEntry = false
        shouldShowPrompt = true
    }

    /// 건너뛰기 횟수 증가
    /// 📚 학습 포인트: Skip Count Management
    /// - 사용자가 건너뛰기 버튼을 클릭했을 때 호출
    /// - 날짜별로 횟수 저장
    /// - 3회에 도달하면 다음번에 강제 입력 모드
    ///
    /// 호출 시점:
    /// - SleepInputSheet의 onSkip 콜백에서 호출
    func incrementSkipCount() {
        let currentCount = getSkipCount(for: today)
        let newCount = currentCount + 1
        setSkipCount(newCount, for: today)

        // 📚 학습 포인트: State Update
        // 강제 입력 모드 여부 업데이트
        isForceEntry = newCount >= Self.maxSkipCount

        print("ℹ️ Sleep prompt skipped. Count: \(newCount)/\(Self.maxSkipCount)")
    }

    /// 건너뛰기 횟수 초기화
    /// 📚 학습 포인트: Reset Logic
    /// - 사용자가 수면 기록을 입력했을 때 호출
    /// - 다음 날부터 다시 3회 건너뛰기 가능
    ///
    /// 호출 시점:
    /// - 수면 기록 저장 성공 시 (SleepInputViewModel.saveSleep 완료 후)
    /// - 자동으로 호출됨 (checkShouldShow에서 기록 확인 시)
    func resetSkipCount() {
        setSkipCount(0, for: today)
        isForceEntry = false

        print("ℹ️ Sleep prompt skip count reset for \(DateUtils.formatKorean(today))")
    }

    /// 프롬프트 닫기
    /// 📚 학습 포인트: Manual Dismiss
    /// - 프롬프트를 프로그래밍 방식으로 닫을 때 사용
    /// - 건너뛰기 횟수는 유지
    func dismissPrompt() {
        shouldShowPrompt = false
    }

    /// 오늘의 건너뛰기 횟수 조회
    /// 📚 학습 포인트: Public Query Method
    /// - 외부에서 현재 건너뛰기 상태 확인 가능
    /// - UI에 "앞으로 N회 건너뛰기 가능" 표시에 사용 가능
    ///
    /// - Returns: 오늘의 건너뛰기 횟수 (0-3)
    func getCurrentSkipCount() -> Int {
        return getSkipCount(for: today)
    }

    /// 남은 건너뛰기 횟수 조회
    /// 📚 학습 포인트: Convenience Method
    /// - 사용자에게 친화적인 정보 제공
    ///
    /// - Returns: 남은 건너뛰기 횟수 (0-3)
    func getRemainingSkips() -> Int {
        let current = getSkipCount(for: today)
        return max(0, Self.maxSkipCount - current)
    }

    // MARK: - Private Methods

    /// 특정 날짜의 건너뛰기 횟수 조회
    /// 📚 학습 포인트: Date-based UserDefaults Key
    /// - 날짜를 키에 포함하여 날짜별 관리
    /// - ISO 8601 형식으로 날짜 포맷팅 (yyyy-MM-dd)
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 건너뛰기 횟수 (0-3)
    private func getSkipCount(for date: Date) -> Int {
        let key = skipCountKey(for: date)
        let count = userDefaults.integer(forKey: key)
        return count
    }

    /// 특정 날짜의 건너뛰기 횟수 설정
    /// 📚 학습 포인트: UserDefaults Write
    /// - integer(forKey:)는 기본값 0 반환
    /// - 명시적으로 0을 저장하여 의도 명확화
    ///
    /// - Parameters:
    ///   - count: 설정할 건너뛰기 횟수
    ///   - date: 대상 날짜
    private func setSkipCount(_ count: Int, for date: Date) {
        let key = skipCountKey(for: date)
        userDefaults.set(count, forKey: key)
    }

    /// 날짜에 대한 UserDefaults 키 생성
    /// 📚 학습 포인트: Key Generation
    /// - 날짜를 문자열로 변환하여 고유 키 생성
    /// - ISO8601 형식 사용 (yyyy-MM-dd)
    ///
    /// - Parameter date: 대상 날짜
    /// - Returns: UserDefaults 키 (예: "sleep_skip_count_2026-01-14")
    private func skipCountKey(for date: Date) -> String {
        return Keys.skipCountPrefix + logicalDateString(for: date)
    }

    /// 논리적 날짜를 ISO8601 문자열로 변환합니다.
    private func logicalDateString(for date: Date) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        return dateFormatter.string(from: date)
    }

    /// 오래된 건너뛰기 횟수 정리
    /// 📚 학습 포인트: Data Cleanup
    /// - cleanupDaysThreshold일 이상 지난 건너뛰기 횟수는 삭제
    /// - 메모리 및 저장 공간 관리
    /// - 백그라운드에서 실행 가능
    ///
    /// 호출 시점:
    /// - 앱 시작 시 (선택적)
    /// - 주기적으로 (예: 하루에 한 번)
    func cleanupOldSkipCounts() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -Self.cleanupDaysThreshold, to: today) ?? today

        // 📚 학습 포인트: UserDefaults Key Iteration
        // 모든 키를 순회하며 오래된 항목 삭제
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(Keys.skipCountPrefix) {
                // 날짜 추출
                let dateString = key.replacingOccurrences(of: Keys.skipCountPrefix, with: "")
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate]

                if let date = dateFormatter.date(from: dateString),
                   date < cutoffDate {
                    userDefaults.removeObject(forKey: key)
                    print("🗑️ Cleaned up old skip count for \(dateString)")
                }
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension SleepPromptManager {
    /// 📚 학습 포인트: Preview Helper
    /// SwiftUI Preview를 위한 Mock Manager
    /// 💡 Java 비교: Test fixture와 유사
    static func makePreview(
        shouldShowPrompt: Bool = false,
        isForceEntry: Bool = false
    ) -> SleepPromptManager {
        // Mock Repository 필요 (실제로는 DIContainer에서 주입)
        fatalError("Preview support not yet implemented. Use DIContainer for real instance.")
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: SleepPromptManager 이해
///
/// SleepPromptManager의 역할:
/// - 아침 수면 기록 프롬프트 표시 여부 결정
/// - 날짜별 건너뛰기 횟수 추적 및 관리
/// - 강제 입력 모드 판단 (3회 건너뛰기 후)
/// - UserDefaults를 사용한 건너뛰기 횟수 영속화
///
/// 비즈니스 규칙:
/// 1. 프롬프트 표시 조건:
///    - 현재 시간이 02:00 이후 (DateUtils.shouldShowSleepPopup)
///    - 오늘 날짜의 수면 기록이 없음
///    - 앱이 실행되거나 포그라운드로 돌아올 때
///
/// 2. 건너뛰기 로직:
///    - 하루에 최대 3회까지 건너뛰기 가능
///    - 3회 건너뛰기 후에는 팝업이 더 이상 표시되지 않음 (PRD 요구사항)
///    - 수면 탭에서 직접 입력 가능
///    - 수면 기록을 입력하면 건너뛰기 횟수 초기화
///
/// 3. 날짜 경계:
///    - 02:00 경계 로직 적용
///    - 00:00-01:59는 전날로 처리
///    - DateUtils.getLogicalDate 사용
///
/// 4. 데이터 정리:
///    - 7일 이상 지난 건너뛰기 데이터는 자동 삭제
///    - cleanupOldSkipCounts() 주기적 호출 권장
///
/// UserDefaults 키 구조:
/// - "sleep_skip_count_2026-01-14" → 오늘의 건너뛰기 횟수
/// - "sleep_skip_count_2026-01-13" → 어제의 건너뛰기 횟수
/// - ISO 8601 날짜 형식 사용 (yyyy-MM-dd)
///
/// 상태 관리:
/// - shouldShowPrompt: 프롬프트 표시 여부 (@Published)
/// - isForceEntry: 강제 입력 모드 여부 (@Published)
/// - View에서 이 프로퍼티들을 관찰하여 UI 업데이트
///
/// 사용 예시:
/// ```swift
/// // BodiiApp.swift
/// struct BodiiApp: App {
///     @StateObject private var sleepPromptManager: SleepPromptManager
///
///     init() {
///         let container = DIContainer.shared
///         _sleepPromptManager = StateObject(wrappedValue: SleepPromptManager(
///             sleepRepository: container.sleepRepository
///         ))
///     }
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .sheet(isPresented: $sleepPromptManager.shouldShowPrompt) {
///                     SleepInputSheet(
///                         viewModel: DIContainer.shared.makeSleepInputViewModel(),
///                         canSkip: !sleepPromptManager.isForceEntry,
///                         onSkip: {
///                             sleepPromptManager.incrementSkipCount()
///                         }
///                     )
///                 }
///                 .onAppear {
///                     Task {
///                         await sleepPromptManager.checkShouldShow()
///                     }
///                 }
///                 .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
///                     Task {
///                         await sleepPromptManager.checkShouldShow()
///                     }
///                 }
///         }
///     }
/// }
/// ```
///
/// 건너뛰기 횟수 표시 예시:
/// ```swift
/// struct SleepPromptInfoView: View {
///     @ObservedObject var manager: SleepPromptManager
///
///     var body: some View {
///         if manager.isForceEntry {
///             Text("오늘은 꼭 입력해주세요")
///                 .foregroundColor(.red)
///         } else {
///             Text("앞으로 \(manager.getRemainingSkips())회 건너뛰기 가능")
///                 .foregroundColor(.secondary)
///         }
///     }
/// }
/// ```
///
/// 수동 프롬프트 트리거:
/// ```swift
/// Button("수면 기록 입력") {
///     Task {
///         await sleepPromptManager.checkShouldShow()
///         sleepPromptManager.shouldShowPrompt = true
///     }
/// }
/// ```
///
/// 💡 Android 비교:
/// - Android: SharedPreferences + Manager 클래스
/// - SwiftUI: UserDefaults + ObservableObject
/// - Android: SharedPreferences.Editor.apply()
/// - SwiftUI: UserDefaults.set()
/// - Android: SharedPreferences.getInt(key, defaultValue)
/// - SwiftUI: UserDefaults.integer(forKey:) // 기본값 0
///
/// 💡 실무 팁:
/// - UserDefaults는 간단한 데이터에만 사용
/// - 복잡한 데이터는 Core Data 또는 파일 시스템 사용
/// - 날짜 기반 키는 ISO 8601 형식 사용 권장
/// - 주기적으로 오래된 데이터 정리
/// - @Published로 View와 자동 동기화
/// - Repository 주입으로 테스트 가능성 확보
///
/// 보안 고려사항:
/// - UserDefaults는 암호화되지 않음
/// - 민감한 정보는 Keychain 사용
/// - 건너뛰기 횟수는 민감하지 않으므로 UserDefaults 적합
///
/// 테스트 가능성:
/// - sleepRepository를 Mock으로 주입 가능
/// - userDefaults를 별도 인스턴스로 주입 가능
/// - 날짜별 건너뛰기 횟수 검증 가능
///
/// 향후 개선 사항:
/// - 사용자 설정으로 프롬프트 시간 조정 가능 (현재 02:00 고정)
/// - 주말에는 프롬프트 비활성화 옵션
/// - 프롬프트 알림 (Local Notification)
/// - 연속 기록 일수 추적 및 배지 시스템
///
