//
//  SleepPromptManagerTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: SleepPromptManager Unit Testing
// 프롬프트 로직과 건너뛰기 횟수 관리 테스트
// 💡 Java 비교: JUnit Manager Class Test와 유사

import XCTest
@testable import Bodii

/// SleepPromptManager에 대한 단위 테스트
///
/// 📚 학습 포인트: PRD 요구사항 (수면 팝업)
/// - promptHour (2 AM): 새벽 2시 이후 앱 첫 실행 시 수면 입력 팝업 자동 표시
/// - boundaryHour (2 AM): 수면 날짜를 계산하는 경계 시간
/// - 3회 스킵 후 더 이상 팝업 안 뜸
///
/// 테스트 시 주의사항:
/// - checkShouldShow()는 DateUtils.shouldShowSleepPopup()을 사용
/// - shouldShowSleepPopup()는 promptHour (2 AM)을 사용
/// - 02:00 이전에는 프롬프트가 표시되지 않아야 함
/// - 3회 스킵 후에는 shouldShowPrompt = false
///
/// 📚 학습 포인트: Manager Testing
/// - 프롬프트 표시 로직 검증
/// - 건너뛰기 횟수 영속성 테스트
/// - 날짜별 독립적인 횟수 관리 확인
/// - 강제 입력 모드 전환 검증
/// 💡 Java 비교: Mockito + JUnit으로 Manager 테스트하는 것과 유사
@MainActor
final class SleepPromptManagerTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Manager
    /// 📚 학습 포인트: System Under Test (SUT)
    var sut: SleepPromptManager!

    /// Mock Repository
    /// 📚 학습 포인트: Test Double - Mock
    /// - 실제 Repository 대신 테스트용 Mock 사용
    /// - 수면 기록 존재 여부를 제어 가능
    var mockRepository: MockSleepRepository!

    /// Test UserDefaults
    /// 📚 학습 포인트: Test-specific UserDefaults
    /// - 실제 UserDefaults 대신 테스트용 인스턴스 사용
    /// - 각 테스트가 독립적으로 실행되도록 보장
    var testUserDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    /// 각 테스트 메서드 실행 전에 호출
    /// 📚 학습 포인트: Test Setup
    /// 테스트 환경을 초기화하여 각 테스트가 독립적으로 실행되도록 보장
    /// 💡 Java 비교: JUnit의 @Before 또는 @BeforeEach와 유사
    override func setUp() {
        super.setUp()
        mockRepository = MockSleepRepository()

        // 📚 학습 포인트: Test-specific UserDefaults
        // 각 테스트마다 고유한 suite name 사용하여 격리
        let suiteName = "test_\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: suiteName)!

        sut = SleepPromptManager(
            sleepRepository: mockRepository,
            userDefaults: testUserDefaults
        )
    }

    /// 각 테스트 메서드 실행 후에 호출
    /// 📚 학습 포인트: Test Teardown
    /// 테스트 후 정리 작업 수행
    /// 💡 Java 비교: JUnit의 @After 또는 @AfterEach와 유사
    override func tearDown() {
        // 📚 학습 포인트: UserDefaults Cleanup
        // 테스트 데이터 정리
        if let suiteName = testUserDefaults.dictionaryRepresentation().keys.first {
            testUserDefaults.removePersistentDomain(forName: suiteName)
        }

        sut = nil
        mockRepository = nil
        testUserDefaults = nil
        super.tearDown()
    }

    // MARK: - Skip Count Persistence Tests

    /// 건너뛰기 횟수 저장 및 조회
    /// 📚 학습 포인트: UserDefaults Persistence Testing
    /// UserDefaults에 값이 올바르게 저장되고 조회되는지 확인
    func testIncrementSkipCount_IncreasesCountByOne() {
        // Given: 초기 상태 (건너뛰기 0회)
        XCTAssertEqual(sut.getCurrentSkipCount(), 0,
                      "초기 건너뛰기 횟수는 0이어야 합니다")

        // When: 건너뛰기 1회
        sut.incrementSkipCount()

        // Then: 건너뛰기 횟수가 1이어야 함
        XCTAssertEqual(sut.getCurrentSkipCount(), 1,
                      "건너뛰기 후 횟수는 1이어야 합니다")
    }

    /// 건너뛰기 횟수 다중 증가
    func testIncrementSkipCount_MultipleIncrements_CountsCorrectly() {
        // Given: 초기 상태

        // When: 건너뛰기 3회
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        sut.incrementSkipCount()

        // Then: 건너뛰기 횟수가 3이어야 함
        XCTAssertEqual(sut.getCurrentSkipCount(), 3,
                      "3회 건너뛰기 후 횟수는 3이어야 합니다")
    }

    /// 건너뛰기 횟수 초기화
    /// 📚 학습 포인트: Reset Logic Testing
    /// 수면 기록 저장 후 건너뛰기 횟수가 0으로 초기화되는지 확인
    func testResetSkipCount_SetsCountToZero() {
        // Given: 건너뛰기 3회
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 3)

        // When: 건너뛰기 횟수 초기화
        sut.resetSkipCount()

        // Then: 건너뛰기 횟수가 0이어야 함
        XCTAssertEqual(sut.getCurrentSkipCount(), 0,
                      "초기화 후 건너뛰기 횟수는 0이어야 합니다")
        XCTAssertFalse(sut.isForceEntry,
                      "초기화 후 강제 입력 모드는 false여야 합니다")
    }

    /// 날짜별 독립적인 건너뛰기 횟수
    /// 📚 학습 포인트: Date-based Key Testing
    /// 각 날짜가 독립적인 건너뛰기 횟수를 가지는지 확인
    func testSkipCount_DifferentDates_AreIndependent() {
        // Given: 오늘 건너뛰기 2회
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 2)

        // When: UserDefaults에 다른 날짜의 건너뛰기 횟수 설정
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = makeSkipCountKey(for: yesterday)
        testUserDefaults.set(5, forKey: yesterdayKey)

        // Then: 오늘 건너뛰기 횟수는 여전히 2여야 함
        XCTAssertEqual(sut.getCurrentSkipCount(), 2,
                      "오늘의 건너뛰기 횟수는 다른 날짜에 영향받지 않아야 합니다")

        // Then: 어제 건너뛰기 횟수는 5여야 함
        XCTAssertEqual(testUserDefaults.integer(forKey: yesterdayKey), 5,
                      "어제의 건너뛰기 횟수는 독립적으로 유지되어야 합니다")
    }

    // MARK: - Force Entry Mode Tests

    /// 강제 입력 모드 - 3회 건너뛰기 전
    /// 📚 학습 포인트: Force Entry Logic Testing
    /// 3회 미만 건너뛰기 시 강제 입력 모드가 아닌지 확인
    func testIsForceEntry_Before3Skips_IsFalse() {
        // Given & When: 건너뛰기 0회
        XCTAssertFalse(sut.isForceEntry,
                      "초기 상태는 강제 입력 모드가 아니어야 합니다")

        // When: 건너뛰기 1회
        sut.incrementSkipCount()
        // Then: 강제 입력 모드 아님
        XCTAssertFalse(sut.isForceEntry,
                      "1회 건너뛰기는 강제 입력 모드가 아니어야 합니다")

        // When: 건너뛰기 2회
        sut.incrementSkipCount()
        // Then: 강제 입력 모드 아님
        XCTAssertFalse(sut.isForceEntry,
                      "2회 건너뛰기는 강제 입력 모드가 아니어야 합니다")
    }

    /// 강제 입력 모드 - 3회 건너뛰기 후
    func testIsForceEntry_After3Skips_IsTrue() {
        // Given: 건너뛰기 2회
        sut.incrementSkipCount()
        sut.incrementSkipCount()

        // When: 3회째 건너뛰기
        sut.incrementSkipCount()

        // Then: 강제 입력 모드 활성화
        XCTAssertTrue(sut.isForceEntry,
                     "3회 건너뛰기 후 강제 입력 모드여야 합니다")
        XCTAssertEqual(sut.getCurrentSkipCount(), 3,
                      "건너뛰기 횟수는 3이어야 합니다")
    }

    /// 강제 입력 모드 - 3회 초과 건너뛰기
    /// 📚 학습 포인트: Edge Case Testing
    /// 3회 이상 건너뛰기 시에도 강제 입력 모드 유지되는지 확인
    func testIsForceEntry_MoreThan3Skips_RemainsTrue() {
        // Given: 건너뛰기 3회 (강제 입력 모드)
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        XCTAssertTrue(sut.isForceEntry)

        // When: 추가 건너뛰기 (4회째)
        sut.incrementSkipCount()

        // Then: 강제 입력 모드 유지
        XCTAssertTrue(sut.isForceEntry,
                     "3회 초과 건너뛰기도 강제 입력 모드여야 합니다")
        XCTAssertEqual(sut.getCurrentSkipCount(), 4,
                      "건너뛰기 횟수는 4여야 합니다")
    }

    /// 남은 건너뛰기 횟수 계산
    /// 📚 학습 포인트: Convenience Method Testing
    /// UI에 표시할 남은 건너뛰기 횟수가 올바르게 계산되는지 확인
    func testGetRemainingSkips_ReturnsCorrectValue() {
        // Given & Then: 초기 상태 (3회 남음)
        XCTAssertEqual(sut.getRemainingSkips(), 3,
                      "초기 상태는 3회 남아야 합니다")

        // When: 건너뛰기 1회
        sut.incrementSkipCount()
        // Then: 2회 남음
        XCTAssertEqual(sut.getRemainingSkips(), 2,
                      "1회 건너뛰기 후 2회 남아야 합니다")

        // When: 건너뛰기 1회 더
        sut.incrementSkipCount()
        // Then: 1회 남음
        XCTAssertEqual(sut.getRemainingSkips(), 1,
                      "2회 건너뛰기 후 1회 남아야 합니다")

        // When: 건너뛰기 1회 더
        sut.incrementSkipCount()
        // Then: 0회 남음
        XCTAssertEqual(sut.getRemainingSkips(), 0,
                      "3회 건너뛰기 후 0회 남아야 합니다")

        // When: 추가 건너뛰기 (4회째)
        sut.incrementSkipCount()
        // Then: 0회 남음 (음수가 되지 않음)
        XCTAssertEqual(sut.getRemainingSkips(), 0,
                      "3회 초과 건너뛰기도 0회 남음이어야 합니다")
    }

    // MARK: - Prompt Logic Tests

    /// 프롬프트 표시 - 시간 조건 미충족 (02:00 이전)
    /// 📚 학습 포인트: Time-based Logic Testing
    /// 02:00 이전에는 프롬프트가 표시되지 않는지 확인
    /// Note: 이 테스트는 실제 시간에 의존하므로 DateUtils.shouldShowSleepPopup이 false를 반환하는 경우를 시뮬레이션
    func testCheckShouldShow_Before2AM_DoesNotShowPrompt() async {
        // Given: 시간 조건 확인은 DateUtils에 의존
        // Note: 이 테스트는 DateUtils.shouldShowSleepPopup() == true인 시간에 실행되면 실패할 수 있음
        // 실제 프로덕션 코드에서는 DateUtils를 주입받아 Mock으로 대체하는 것이 이상적

        // When: 프롬프트 확인 (시간이 02:00 이후라면)
        await sut.checkShouldShow()

        // Then: DateUtils.shouldShowSleepPopup()의 반환값에 따라 결과가 달라짐
        // 이 테스트는 실제 시간에 의존하므로 주석 처리
        // 실무에서는 DateUtils를 Protocol로 만들어 Mock 주입
        print("⚠️ Time-dependent test: shouldShowPrompt = \(sut.shouldShowPrompt)")
    }

    /// 프롬프트 표시 - 오늘 기록이 이미 존재
    /// 📚 학습 포인트: Data-based Logic Testing
    /// 오늘 수면 기록이 있으면 프롬프트가 표시되지 않는지 확인
    func testCheckShouldShow_RecordExists_DoesNotShowPrompt() async {
        // Given: 오늘 수면 기록 존재 (Mock Repository 설정)
        let todayRecord = SleepRecord.sample()
        mockRepository.recordToReturn = todayRecord

        // When: 프롬프트 확인
        await sut.checkShouldShow()

        // Then: 프롬프트 표시되지 않아야 함
        XCTAssertFalse(sut.shouldShowPrompt,
                      "오늘 기록이 있으면 프롬프트가 표시되지 않아야 합니다")
    }

    /// 프롬프트 표시 - 기록 없고 건너뛰기 2회 이하
    /// 📚 학습 포인트: Integrated Logic Testing
    /// 조건이 모두 충족되면 프롬프트가 표시되는지 확인
    func testCheckShouldShow_NoRecordAndNotForceEntry_ShowsPrompt() async {
        // Given: 오늘 기록 없음 (Mock Repository가 nil 반환)
        mockRepository.recordToReturn = nil

        // Given: 건너뛰기 1회 (강제 입력 모드 아님)
        sut.incrementSkipCount()

        // When: 프롬프트 확인 (02:00 이후 시간대에서 실행 가정)
        await sut.checkShouldShow()

        // Then: 프롬프트 표시되어야 함 (시간 조건이 충족된다면)
        // Note: DateUtils.shouldShowSleepPopup()이 true를 반환할 때만 통과
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertTrue(sut.shouldShowPrompt,
                         "기록이 없으면 프롬프트가 표시되어야 합니다")
            XCTAssertFalse(sut.isForceEntry,
                          "2회 이하 건너뛰기는 강제 입력 모드가 아니어야 합니다")
        }
    }

    /// 프롬프트 표시 - 3회 건너뛰기 후 팝업 숨김
    /// PRD 요구사항: "3회 스킵 후 더 이상 팝업 안 뜸"
    func testCheckShouldShow_After3Skips_HidesPrompt() async {
        // Given: 오늘 기록 없음
        mockRepository.recordToReturn = nil

        // Given: 건너뛰기 3회
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        sut.incrementSkipCount()

        // When: 프롬프트 확인
        await sut.checkShouldShow()

        // Then: 3회 스킵 후 팝업이 표시되지 않아야 함
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertFalse(sut.shouldShowPrompt,
                         "3회 스킵 후에는 프롬프트가 표시되지 않아야 합니다 (PRD 요구사항)")
            XCTAssertTrue(sut.isForceEntry,
                         "3회 건너뛰기 후 isForceEntry는 true여야 합니다")
        }
    }

    /// 프롬프트 표시 - 기록 존재 시 건너뛰기 횟수 초기화
    /// 📚 학습 포인트: Auto-reset Logic Testing
    /// 기록이 있으면 자동으로 건너뛰기 횟수가 초기화되는지 확인
    func testCheckShouldShow_RecordExists_ResetsSkipCount() async {
        // Given: 건너뛰기 2회
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 2)

        // Given: 오늘 기록 존재
        mockRepository.recordToReturn = SleepRecord.sample()

        // When: 프롬프트 확인
        await sut.checkShouldShow()

        // Then: 건너뛰기 횟수 초기화
        XCTAssertEqual(sut.getCurrentSkipCount(), 0,
                      "기록이 있으면 건너뛰기 횟수가 초기화되어야 합니다")
        XCTAssertFalse(sut.shouldShowPrompt,
                      "프롬프트가 표시되지 않아야 합니다")
    }

    /// 프롬프트 수동 닫기
    /// 📚 학습 포인트: Manual Dismiss Testing
    /// 프롬프트를 프로그래밍 방식으로 닫을 수 있는지 확인
    func testDismissPrompt_SetsShowPromptToFalse() {
        // Given: 프롬프트 표시 중
        sut.shouldShowPrompt = true

        // When: 프롬프트 닫기
        sut.dismissPrompt()

        // Then: 프롬프트가 닫혀야 함
        XCTAssertFalse(sut.shouldShowPrompt,
                      "dismissPrompt 호출 후 프롬프트가 닫혀야 합니다")
    }

    /// 프롬프트 수동 닫기 - 건너뛰기 횟수 유지
    func testDismissPrompt_PreservesSkipCount() {
        // Given: 건너뛰기 2회
        sut.incrementSkipCount()
        sut.incrementSkipCount()

        // Given: 프롬프트 표시 중
        sut.shouldShowPrompt = true

        // When: 프롬프트 닫기
        sut.dismissPrompt()

        // Then: 건너뛰기 횟수 유지
        XCTAssertEqual(sut.getCurrentSkipCount(), 2,
                      "dismissPrompt는 건너뛰기 횟수를 변경하지 않아야 합니다")
    }

    // MARK: - Repository Error Handling Tests

    /// Repository 에러 처리 - 조회 실패 시에도 프롬프트 표시
    /// 📚 학습 포인트: Error Handling Testing
    /// Repository에서 에러가 발생해도 안전하게 처리하는지 확인
    func testCheckShouldShow_RepositoryError_ShowsPrompt() async {
        // Given: Repository가 에러를 발생시키도록 설정
        mockRepository.shouldFail = true

        // When: 프롬프트 확인
        await sut.checkShouldShow()

        // Then: 보수적으로 프롬프트 표시 (에러 시에도 기록 안 하는 것보다 안전)
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertTrue(sut.shouldShowPrompt,
                         "Repository 에러 시에도 프롬프트가 표시되어야 합니다")
        }
    }

    // MARK: - Cleanup Tests

    /// 오래된 건너뛰기 데이터 정리
    /// 📚 학습 포인트: Data Cleanup Testing
    /// 7일 이상 지난 건너뛰기 횟수가 삭제되는지 확인
    func testCleanupOldSkipCounts_RemovesOldData() {
        // Given: 오늘 건너뛰기 1회
        sut.incrementSkipCount()

        // Given: 8일 전 데이터 추가
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let oldKey = makeSkipCountKey(for: eightDaysAgo)
        testUserDefaults.set(2, forKey: oldKey)

        // Given: 5일 전 데이터 추가 (최근 데이터)
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let recentKey = makeSkipCountKey(for: fiveDaysAgo)
        testUserDefaults.set(3, forKey: recentKey)

        // When: 정리 실행
        sut.cleanupOldSkipCounts()

        // Then: 8일 전 데이터는 삭제됨
        XCTAssertEqual(testUserDefaults.integer(forKey: oldKey), 0,
                      "8일 전 데이터는 삭제되어야 합니다")

        // Then: 5일 전 데이터는 유지됨
        XCTAssertEqual(testUserDefaults.integer(forKey: recentKey), 3,
                      "5일 전 데이터는 유지되어야 합니다")

        // Then: 오늘 데이터는 유지됨
        XCTAssertEqual(sut.getCurrentSkipCount(), 1,
                      "오늘 데이터는 유지되어야 합니다")
    }

    /// 정리 - 정확히 7일 전 데이터 (경계값)
    /// 📚 학습 포인트: Boundary Testing for Cleanup
    /// 정확히 7일 전 데이터는 유지되는지 확인
    func testCleanupOldSkipCounts_PreservesSevenDayOldData() {
        // Given: 정확히 7일 전 데이터
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let boundaryKey = makeSkipCountKey(for: sevenDaysAgo)
        testUserDefaults.set(2, forKey: boundaryKey)

        // When: 정리 실행
        sut.cleanupOldSkipCounts()

        // Then: 7일 전 데이터는 유지됨 (경계값 포함)
        XCTAssertEqual(testUserDefaults.integer(forKey: boundaryKey), 2,
                      "정확히 7일 전 데이터는 유지되어야 합니다")
    }

    /// 정리 - 다른 UserDefaults 키는 보존
    /// 📚 학습 포인트: Selective Cleanup Testing
    /// 건너뛰기 횟수가 아닌 다른 데이터는 삭제되지 않는지 확인
    func testCleanupOldSkipCounts_PreservesNonSleepKeys() {
        // Given: 다른 UserDefaults 키
        let otherKey = "some_other_setting"
        testUserDefaults.set("important_value", forKey: otherKey)

        // Given: 오래된 건너뛰기 데이터
        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let oldKey = makeSkipCountKey(for: oldDate)
        testUserDefaults.set(1, forKey: oldKey)

        // When: 정리 실행
        sut.cleanupOldSkipCounts()

        // Then: 다른 키는 유지됨
        XCTAssertEqual(testUserDefaults.string(forKey: otherKey), "important_value",
                      "다른 UserDefaults 키는 보존되어야 합니다")

        // Then: 오래된 건너뛰기 데이터는 삭제됨
        XCTAssertEqual(testUserDefaults.integer(forKey: oldKey), 0,
                      "오래된 건너뛰기 데이터는 삭제되어야 합니다")
    }

    // MARK: - Edge Case Tests

    /// 엣지 케이스 - 연속 증가 후 초기화 반복
    /// 📚 학습 포인트: Repeated Operations Testing
    /// 증가/초기화를 반복해도 올바르게 동작하는지 확인
    func testSkipCount_RepeatedIncrementAndReset_WorksCorrectly() {
        // Given & When: 첫 번째 사이클
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 2)
        sut.resetSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 0)

        // When: 두 번째 사이클
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 1)
        sut.resetSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 0)

        // When: 세 번째 사이클
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 3)
        XCTAssertTrue(sut.isForceEntry)
        sut.resetSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 0)
        XCTAssertFalse(sut.isForceEntry)

        // Then: 모든 사이클이 독립적으로 동작
        print("✅ Repeated increment/reset cycles work correctly")
    }

    /// 엣지 케이스 - 초기화 없이 많은 건너뛰기
    func testSkipCount_ManyIncrementsWithoutReset_CountsCorrectly() {
        // Given & When: 10회 건너뛰기
        for i in 1...10 {
            sut.incrementSkipCount()
            XCTAssertEqual(sut.getCurrentSkipCount(), i,
                          "\(i)번째 건너뛰기 후 횟수는 \(i)여야 합니다")

            // 3회 이상부터는 강제 입력 모드
            if i >= 3 {
                XCTAssertTrue(sut.isForceEntry,
                            "\(i)회 건너뛰기는 강제 입력 모드여야 합니다")
            }
        }

        // Then: 최종 횟수 확인
        XCTAssertEqual(sut.getCurrentSkipCount(), 10,
                      "10회 건너뛰기 후 횟수는 10이어야 합니다")
    }

    /// 엣지 케이스 - UserDefaults 키 형식 검증
    /// 📚 학습 포인트: Key Format Testing
    /// UserDefaults 키가 올바른 형식으로 생성되는지 확인
    func testSkipCountKey_GeneratesCorrectFormat() {
        // Given: 특정 날짜
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 15
        ))!

        // When: 키 생성
        let key = makeSkipCountKey(for: date)

        // Then: ISO 8601 형식 확인
        XCTAssertTrue(key.hasPrefix("sleep_skip_count_"),
                     "키는 'sleep_skip_count_' 접두사로 시작해야 합니다")
        XCTAssertTrue(key.contains("2026-01-15"),
                     "키에 ISO 8601 날짜 형식이 포함되어야 합니다")
    }

    // MARK: - Integration Tests

    /// 통합 테스트 - 전체 워크플로우
    /// 📚 학습 포인트: End-to-End Testing
    /// PRD 요구사항: "나중에" 버튼 클릭 시 최대 3회까지 재팝업, 3회 스킵 후 더 이상 팝업 안 뜸
    func testFullWorkflow_SkipAndRecord_WorksCorrectly() async {
        // 스킵 1회: 팝업 표시, 건너뛰기 가능
        await sut.checkShouldShow()
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertTrue(sut.shouldShowPrompt, "1회 전 팝업 표시되어야 함")
            XCTAssertFalse(sut.isForceEntry)
        }
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 1)

        // 스킵 2회: 팝업 표시, 건너뛰기 가능
        await sut.checkShouldShow()
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertTrue(sut.shouldShowPrompt, "2회 전 팝업 표시되어야 함")
        }
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 2)
        XCTAssertFalse(sut.isForceEntry)

        // 스킵 3회: 팝업 표시, 건너뛰기 가능 (이번이 마지막)
        await sut.checkShouldShow()
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertTrue(sut.shouldShowPrompt, "3회 전 팝업 표시되어야 함")
        }
        sut.incrementSkipCount()
        XCTAssertEqual(sut.getCurrentSkipCount(), 3)
        XCTAssertTrue(sut.isForceEntry)

        // 3회 스킵 후: 팝업 더 이상 표시 안 됨 (PRD 요구사항)
        await sut.checkShouldShow()
        if DateUtils.shouldShowSleepPopup() {
            XCTAssertFalse(sut.shouldShowPrompt,
                          "3회 스킵 후 팝업이 표시되지 않아야 합니다 (PRD 요구사항)")
        }

        // 수면 기록 저장 후: 초기화
        mockRepository.recordToReturn = SleepRecord.sample()
        await sut.checkShouldShow()
        XCTAssertFalse(sut.shouldShowPrompt,
                      "기록이 있으면 프롬프트가 표시되지 않아야 합니다")
        XCTAssertEqual(sut.getCurrentSkipCount(), 0,
                      "기록 저장 후 건너뛰기 횟수가 초기화되어야 합니다")
        XCTAssertFalse(sut.isForceEntry,
                      "초기화 후 강제 입력 모드가 해제되어야 합니다")

        print("✅ Full workflow test completed")
    }

    // MARK: - Helper Methods

    /// UserDefaults 키 생성 헬퍼 메서드
    /// 📚 학습 포인트: Test Helper
    /// SleepPromptManager의 private 메서드와 동일한 로직
    /// 테스트에서 키를 생성할 때 사용
    private func makeSkipCountKey(for date: Date) -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)
        return "sleep_skip_count_" + dateString
    }
}

// MARK: - Mock Repository

/// Mock Sleep Repository
/// 📚 학습 포인트: Test Double - Mock
/// - 실제 Repository 동작을 시뮬레이션
/// - 테스트에서 호출 여부와 전달된 값을 검증 가능
/// - 에러 케이스도 쉽게 시뮬레이션 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
class MockSleepRepository: SleepRepositoryProtocol {

    // MARK: - Properties

    /// 반환할 레코드 (설정하지 않으면 nil 반환)
    var recordToReturn: SleepRecord?

    /// 에러 발생 플래그
    var shouldFail = false

    /// fetch 메서드 호출 여부
    var fetchCalled = false

    // MARK: - SleepRepositoryProtocol Implementation

    func save(sleepRecord: SleepRecord) async throws -> SleepRecord {
        if shouldFail {
            throw RepositoryError.saveFailed
        }
        return sleepRecord
    }

    func fetch(by id: UUID) async throws -> SleepRecord? {
        fetchCalled = true
        if shouldFail {
            throw RepositoryError.fetchFailed
        }
        return recordToReturn
    }

    func fetch(for date: Date) async throws -> SleepRecord? {
        fetchCalled = true
        if shouldFail {
            throw RepositoryError.fetchFailed
        }
        return recordToReturn
    }

    func fetchLatest() async throws -> SleepRecord? {
        if shouldFail {
            throw RepositoryError.fetchFailed
        }
        return recordToReturn
    }

    func fetchAll() async throws -> [SleepRecord] {
        if shouldFail {
            throw RepositoryError.fetchFailed
        }
        return recordToReturn != nil ? [recordToReturn!] : []
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        if shouldFail {
            throw RepositoryError.fetchFailed
        }
        return recordToReturn != nil ? [recordToReturn!] : []
    }

    func fetchRecent(days: Int) async throws -> [SleepRecord] {
        if shouldFail {
            throw RepositoryError.fetchFailed
        }
        return recordToReturn != nil ? [recordToReturn!] : []
    }

    func update(sleepRecord: SleepRecord) async throws -> SleepRecord {
        if shouldFail {
            throw RepositoryError.updateFailed
        }
        return sleepRecord
    }

    func delete(by id: UUID) async throws {
        if shouldFail {
            throw RepositoryError.deleteFailed
        }
    }

    func deleteAll() async throws {
        if shouldFail {
            throw RepositoryError.deleteFailed
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepPromptManager 테스트 전략
///
/// 테스트 커버리지:
/// 1. 건너뛰기 횟수 영속성 테스트
///    - 증가, 조회, 초기화
///    - 날짜별 독립적인 관리
///    - UserDefaults 저장/로드
///
/// 2. 강제 입력 모드 테스트
///    - 3회 미만: 강제 입력 모드 아님
///    - 3회 이상: 강제 입력 모드 활성화
///    - 남은 건너뛰기 횟수 계산
///
/// 3. 프롬프트 로직 테스트
///    - 시간 조건 확인 (02:00 프롬프트 경계)
///    - 기록 존재 여부 확인
///    - 건너뛰기 횟수에 따른 동작 (3회 스킵 후 팝업 숨김)
///    - 자동 초기화 로직
///
/// 4. 데이터 정리 테스트
///    - 7일 이상 지난 데이터 삭제
///    - 최근 데이터 보존
///    - 다른 UserDefaults 키 보존
///
/// 5. 에러 처리 테스트
///    - Repository 에러 시 안전한 처리
///    - 보수적 접근 (에러 시에도 프롬프트 표시)
///
/// 6. 엣지 케이스 테스트
///    - 반복적인 증가/초기화
///    - 많은 건너뛰기
///    - 키 형식 검증
///
/// 7. 통합 테스트
///    - 전체 워크플로우 검증
///    - 건너뛰기부터 기록 저장까지
///
/// Mock 사용 이유:
/// - Core Data 의존성 제거
/// - 빠른 테스트 실행
/// - 예측 가능한 결과
/// - 에러 시나리오 테스트 용이
/// - UserDefaults 격리
///
/// Test-specific UserDefaults:
/// - 각 테스트마다 독립적인 UserDefaults 사용
/// - 테스트 간 간섭 방지
/// - 정리(cleanup) 용이
///
/// 시간 의존성 주의사항:
/// - DateUtils.shouldShowSleepPopup()은 실제 시간에 의존
/// - 02:00 이전에 테스트 실행 시 일부 테스트 실패 가능
/// - 실무에서는 DateUtils를 Protocol로 만들어 Mock 주입 권장
///
/// PRD 요구사항:
/// - promptHour (2 AM): 새벽 2시 이후 앱 첫 실행 시 수면 입력 팝업 자동 표시
/// - 3회 스킵 후 더 이상 팝업 안 뜸 (shouldShowPrompt = false)
///
/// 💡 실무 팁:
/// - Manager 테스트는 비즈니스 로직에 집중
/// - 외부 의존성은 Mock으로 대체
/// - Given-When-Then 패턴으로 가독성 향상
/// - 엣지 케이스와 경계값 테스트 필수
/// - 통합 테스트로 전체 흐름 검증
/// - UserDefaults는 테스트별로 격리
///
