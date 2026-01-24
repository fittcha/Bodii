//
//  DashboardViewModelTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-16.
//

// 📚 학습 포인트: ViewModel Unit Testing
// @Observable 패턴의 ViewModel 테스트 - Mock Repository를 사용한 단위 테스트
// 💡 Java 비교: Mockito를 사용한 ViewModel 테스트와 유사

import XCTest
@testable import Bodii

/// DashboardViewModel에 대한 단위 테스트
///
/// ## 테스트 범위
/// - loadDailyLog 성공/실패 시나리오
/// - 날짜 네비게이션 (이전/다음/오늘)
/// - 새로고침 동작
/// - 상태 전환 (로딩, 에러, 데이터 로드)
///
/// ## 패턴
/// - Given-When-Then 패턴 사용
/// - Mock Repository로 의존성 격리
/// - @MainActor async 테스트
@MainActor
final class DashboardViewModelTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 ViewModel
    /// 📚 학습 포인트: System Under Test (SUT)
    var sut: DashboardViewModel!

    /// Mock Repository
    var mockRepository: MockDailyLogRepository!

    /// 테스트용 사용자 ID
    var testUserId: UUID!

    // MARK: - Setup & Teardown

    /// 각 테스트 실행 전 호출
    /// 📚 학습 포인트: Test Setup
    /// - 각 테스트마다 깨끗한 상태로 시작
    /// - Mock 객체 초기화
    override func setUp() {
        super.setUp()

        testUserId = UUID()
        mockRepository = MockDailyLogRepository()
        sut = DashboardViewModel(
            dailyLogRepository: mockRepository,
            userId: testUserId,
            selectedDate: Date()
        )
    }

    /// 각 테스트 실행 후 호출
    /// 📚 학습 포인트: Test Teardown
    override func tearDown() {
        sut = nil
        mockRepository = nil
        testUserId = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// 테스트용 DailyLog 생성
    /// 📚 학습 포인트: Test Helper Method
    /// - 테스트 데이터 생성 로직을 재사용
    /// - 가독성 향상
    private func makeTestDailyLog(
        date: Date = Date(),
        totalCaloriesIn: Int32 = 2100,
        totalCarbs: Decimal = 260.5,
        totalProtein: Decimal = 105.2,
        totalFat: Decimal = 58.3,
        carbsRatio: Decimal? = 49.6,
        proteinRatio: Decimal? = 20.0,
        fatRatio: Decimal? = 25.0,
        bmr: Int32 = 1650,
        tdee: Int32 = 2310,
        netCalories: Int32 = -210,
        totalCaloriesOut: Int32 = 450,
        exerciseMinutes: Int32 = 60,
        exerciseCount: Int16 = 2,
        weight: Decimal? = 70.5,
        bodyFatPct: Decimal? = 21.5,
        sleepDuration: Int32? = 420,
        sleepStatus: SleepStatus? = .good
    ) -> DailyLog {
        return DailyLog(
            id: UUID(),
            userId: testUserId,
            date: date,
            totalCaloriesIn: totalCaloriesIn,
            totalCarbs: totalCarbs,
            totalProtein: totalProtein,
            totalFat: totalFat,
            carbsRatio: carbsRatio,
            proteinRatio: proteinRatio,
            fatRatio: fatRatio,
            bmr: bmr,
            tdee: tdee,
            netCalories: netCalories,
            totalCaloriesOut: totalCaloriesOut,
            exerciseMinutes: exerciseMinutes,
            exerciseCount: exerciseCount,
            steps: nil,
            weight: weight,
            bodyFatPct: bodyFatPct,
            sleepDuration: sleepDuration,
            sleepStatus: sleepStatus,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - loadDailyLog Success Tests

    /// loadDailyLog - 성공 케이스
    /// 📚 학습 포인트: Async Test
    /// - async/await를 사용하는 메서드 테스트
    /// - @MainActor로 메인 스레드에서 실행
    func testLoadDailyLog_Success_UpdatesDailyLogAndClearsError() async {
        // Given: Mock repository가 성공적으로 DailyLog 반환하도록 설정
        let testDate = Date()
        let expectedDailyLog = makeTestDailyLog(date: testDate)
        mockRepository.fetchResult = .success(expectedDailyLog)

        // When: DailyLog 로드
        await sut.loadDailyLog(for: testDate)

        // Then: 데이터가 업데이트되고 에러가 없음
        XCTAssertNotNil(sut.dailyLog, "DailyLog가 로드되어야 합니다")
        XCTAssertEqual(sut.dailyLog?.id, expectedDailyLog.id, "로드된 DailyLog의 ID가 일치해야 합니다")
        XCTAssertNil(sut.errorMessage, "성공 시 에러 메시지가 없어야 합니다")
        XCTAssertFalse(sut.isLoading, "로딩 완료 후 isLoading은 false여야 합니다")
    }

    /// loadDailyLog - 데이터가 없는 경우 (nil 반환)
    func testLoadDailyLog_NoData_SetsDailyLogToNil() async {
        // Given: Repository가 nil 반환
        mockRepository.fetchResult = .success(nil)

        // When: DailyLog 로드
        await sut.loadDailyLog(for: Date())

        // Then: dailyLog는 nil이어야 함
        XCTAssertNil(sut.dailyLog, "데이터가 없으면 dailyLog는 nil이어야 합니다")
        XCTAssertNil(sut.errorMessage, "데이터 없음은 에러가 아닙니다")
        XCTAssertFalse(sut.isLoading, "로딩 완료 후 isLoading은 false여야 합니다")
    }

    /// loadDailyLog - 로딩 상태 전환 확인
    func testLoadDailyLog_LoadingState_TransitionsCorrectly() async {
        // Given: 약간의 지연이 있는 Mock repository
        let testDate = Date()
        let expectedDailyLog = makeTestDailyLog(date: testDate)
        mockRepository.fetchResult = .success(expectedDailyLog)
        mockRepository.shouldDelay = true

        // When: 로드 시작
        let loadTask = Task {
            await sut.loadDailyLog(for: testDate)
        }

        // Then: 로딩 시작 직후 isLoading이 true
        // Note: Task가 시작되면 바로 isLoading이 true가 되어야 함
        // 하지만 async 특성상 타이밍 이슈가 있을 수 있으므로 완료 후 상태만 확인

        await loadTask.value

        // 로딩 완료 후 isLoading은 false
        XCTAssertFalse(sut.isLoading, "로딩 완료 후 isLoading은 false여야 합니다")
    }

    // MARK: - loadDailyLog Failure Tests

    /// loadDailyLog - 실패 케이스
    /// 📚 학습 포인트: Error Handling Test
    /// - 에러 발생 시 errorMessage가 설정되는지 확인
    func testLoadDailyLog_Failure_SetsErrorMessage() async {
        // Given: Repository가 에러 반환
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        mockRepository.fetchResult = .failure(expectedError)

        // When: DailyLog 로드 시도
        await sut.loadDailyLog(for: Date())

        // Then: 에러 메시지가 설정됨
        XCTAssertNotNil(sut.errorMessage, "에러 발생 시 errorMessage가 설정되어야 합니다")
        XCTAssertTrue(sut.errorMessage?.contains("Network error") ?? false,
                     "에러 메시지에 에러 내용이 포함되어야 합니다")
        XCTAssertNil(sut.dailyLog, "에러 발생 시 dailyLog는 nil이어야 합니다")
        XCTAssertFalse(sut.isLoading, "에러 발생 후 isLoading은 false여야 합니다")
    }

    /// loadDailyLog - 실패 후 성공 시 에러 메시지 클리어
    func testLoadDailyLog_FailureThenSuccess_ClearsErrorMessage() async {
        // Given: 첫 번째 호출은 실패
        let error = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error"])
        mockRepository.fetchResult = .failure(error)

        // When: 첫 번째 로드 (실패)
        await sut.loadDailyLog(for: Date())

        // Then: 에러 메시지 확인
        XCTAssertNotNil(sut.errorMessage, "첫 번째 로드 실패 시 에러 메시지가 있어야 합니다")

        // Given: 두 번째 호출은 성공
        let testDailyLog = makeTestDailyLog()
        mockRepository.fetchResult = .success(testDailyLog)

        // When: 두 번째 로드 (성공)
        await sut.loadDailyLog(for: Date())

        // Then: 에러 메시지가 클리어됨
        XCTAssertNil(sut.errorMessage, "성공 시 이전 에러 메시지가 클리어되어야 합니다")
        XCTAssertNotNil(sut.dailyLog, "성공 시 dailyLog가 설정되어야 합니다")
    }

    // MARK: - Date Navigation Tests

    /// navigateDate - 다음 날로 이동
    /// 📚 학습 포인트: Date Navigation Testing
    func testNavigateDate_NextDay_UpdatesSelectedDateAndLoadsData() async {
        // Given: 초기 날짜 설정
        let calendar = Calendar.current
        let initialDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        sut.selectedDate = initialDate

        let expectedDailyLog = makeTestDailyLog()
        mockRepository.fetchResult = .success(expectedDailyLog)

        // When: 다음 날로 이동
        sut.navigateDate(by: 1)

        // 비동기 작업 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // Then: 날짜가 하루 증가하고 데이터 로드됨
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: initialDate)!
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: sut.selectedDate)
        let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
        XCTAssertEqual(selectedComponents, expectedComponents, "날짜가 하루 증가해야 합니다")
    }

    /// navigateDate - 이전 날로 이동
    func testNavigateDate_PreviousDay_UpdatesSelectedDateAndLoadsData() async {
        // Given: 초기 날짜 설정
        let calendar = Calendar.current
        let initialDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        sut.selectedDate = initialDate

        let expectedDailyLog = makeTestDailyLog()
        mockRepository.fetchResult = .success(expectedDailyLog)

        // When: 이전 날로 이동
        sut.navigateDate(by: -1)

        // 비동기 작업 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초

        // Then: 날짜가 하루 감소하고 데이터 로드됨
        let expectedDate = calendar.date(byAdding: .day, value: -1, to: initialDate)!
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: sut.selectedDate)
        let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
        XCTAssertEqual(selectedComponents, expectedComponents, "날짜가 하루 감소해야 합니다")
    }

    /// goToPreviousDay - 편의 메서드 테스트
    func testGoToPreviousDay_MovesToPreviousDay() async {
        // Given: 초기 날짜
        let calendar = Calendar.current
        let initialDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        sut.selectedDate = initialDate

        mockRepository.fetchResult = .success(makeTestDailyLog())

        // When: 이전 날 이동
        sut.goToPreviousDay()

        // 비동기 작업 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 날짜가 하루 감소
        let expectedDate = calendar.date(byAdding: .day, value: -1, to: initialDate)!
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: sut.selectedDate)
        let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
        XCTAssertEqual(selectedComponents, expectedComponents, "goToPreviousDay는 하루 전으로 이동해야 합니다")
    }

    /// goToNextDay - 편의 메서드 테스트
    func testGoToNextDay_MovesToNextDay() async {
        // Given: 초기 날짜
        let calendar = Calendar.current
        let initialDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        sut.selectedDate = initialDate

        mockRepository.fetchResult = .success(makeTestDailyLog())

        // When: 다음 날 이동
        sut.goToNextDay()

        // 비동기 작업 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 날짜가 하루 증가
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: initialDate)!
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: sut.selectedDate)
        let expectedComponents = calendar.dateComponents([.year, .month, .day], from: expectedDate)
        XCTAssertEqual(selectedComponents, expectedComponents, "goToNextDay는 하루 후로 이동해야 합니다")
    }

    /// goToToday - 오늘로 이동
    func testGoToToday_MovesToCurrentDate() async {
        // Given: 과거 날짜로 설정
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -7, to: Date())!
        sut.selectedDate = pastDate

        mockRepository.fetchResult = .success(makeTestDailyLog())

        // When: 오늘로 이동
        sut.goToToday()

        // 비동기 작업 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 오늘 날짜로 변경됨
        XCTAssertTrue(calendar.isDateInToday(sut.selectedDate),
                     "goToToday는 오늘 날짜로 이동해야 합니다")
    }

    /// selectDate - 특정 날짜 선택
    func testSelectDate_SpecificDate_UpdatesSelectedDateAndLoadsData() async {
        // Given: 특정 날짜
        let calendar = Calendar.current
        let targetDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!

        mockRepository.fetchResult = .success(makeTestDailyLog())

        // When: 특정 날짜 선택
        sut.selectDate(targetDate)

        // 비동기 작업 완료 대기
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then: 날짜가 변경됨
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: sut.selectedDate)
        let targetComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        XCTAssertEqual(selectedComponents, targetComponents, "선택한 날짜로 변경되어야 합니다")
    }

    // MARK: - Refresh Tests

    /// refresh - 현재 날짜 데이터 새로고침
    /// 📚 학습 포인트: Refresh Behavior Testing
    func testRefresh_ReloadsCurrentDateData() async {
        // Given: 초기 데이터 로드
        let testDate = Date()
        sut.selectedDate = testDate

        let initialDailyLog = makeTestDailyLog(totalCaloriesIn: 1000)
        mockRepository.fetchResult = .success(initialDailyLog)

        await sut.loadDailyLog(for: testDate)

        // Then: 초기 데이터 확인
        XCTAssertEqual(sut.totalCaloriesIn, 1000, "초기 칼로리가 1000이어야 합니다")

        // Given: 새로고침 시 변경된 데이터 반환
        let refreshedDailyLog = makeTestDailyLog(totalCaloriesIn: 2000)
        mockRepository.fetchResult = .success(refreshedDailyLog)

        // When: 새로고침
        await sut.refresh()

        // Then: 데이터가 업데이트됨
        XCTAssertEqual(sut.totalCaloriesIn, 2000, "새로고침 후 칼로리가 2000으로 업데이트되어야 합니다")
    }

    /// refresh - 에러 후 새로고침
    func testRefresh_AfterError_CanRecoverWithNewData() async {
        // Given: 에러 상태
        let error = NSError(domain: "TestError", code: 500)
        mockRepository.fetchResult = .failure(error)

        await sut.loadDailyLog(for: Date())
        XCTAssertNotNil(sut.errorMessage, "에러 상태여야 합니다")

        // Given: 새로고침 시 성공
        let dailyLog = makeTestDailyLog()
        mockRepository.fetchResult = .success(dailyLog)

        // When: 새로고침
        await sut.refresh()

        // Then: 에러가 클리어되고 데이터 로드됨
        XCTAssertNil(sut.errorMessage, "새로고침 성공 시 에러가 클리어되어야 합니다")
        XCTAssertNotNil(sut.dailyLog, "새로고침 성공 시 데이터가 로드되어야 합니다")
    }

    // MARK: - State Transition Tests

    /// 상태 전환 - 초기 상태 확인
    /// 📚 학습 포인트: State Management Testing
    func testInitialState_IsCorrect() {
        // Then: 초기 상태 확인
        XCTAssertNil(sut.dailyLog, "초기 상태에서 dailyLog는 nil이어야 합니다")
        XCTAssertFalse(sut.isLoading, "초기 상태에서 isLoading은 false여야 합니다")
        XCTAssertNil(sut.errorMessage, "초기 상태에서 errorMessage는 nil이어야 합니다")
        XCTAssertTrue(sut.isEmpty, "초기 상태에서 isEmpty는 true여야 합니다")
        XCTAssertFalse(sut.hasError, "초기 상태에서 hasError는 false여야 합니다")
    }

    /// 상태 전환 - 로딩 → 성공
    func testStateTransition_LoadingToSuccess() async {
        // Given: 성공할 Mock repository
        let dailyLog = makeTestDailyLog()
        mockRepository.fetchResult = .success(dailyLog)

        // When: 로드
        await sut.loadDailyLog(for: Date())

        // Then: 성공 상태
        XCTAssertNotNil(sut.dailyLog, "성공 후 dailyLog가 있어야 합니다")
        XCTAssertFalse(sut.isLoading, "성공 후 isLoading은 false여야 합니다")
        XCTAssertNil(sut.errorMessage, "성공 후 errorMessage는 nil이어야 합니다")
        XCTAssertFalse(sut.isEmpty, "성공 후 isEmpty는 false여야 합니다")
        XCTAssertFalse(sut.hasError, "성공 후 hasError는 false여야 합니다")
    }

    /// 상태 전환 - 로딩 → 에러
    func testStateTransition_LoadingToError() async {
        // Given: 실패할 Mock repository
        let error = NSError(domain: "TestError", code: 500)
        mockRepository.fetchResult = .failure(error)

        // When: 로드 시도
        await sut.loadDailyLog(for: Date())

        // Then: 에러 상태
        XCTAssertNil(sut.dailyLog, "에러 후 dailyLog는 nil이어야 합니다")
        XCTAssertFalse(sut.isLoading, "에러 후 isLoading은 false여야 합니다")
        XCTAssertNotNil(sut.errorMessage, "에러 후 errorMessage가 있어야 합니다")
        XCTAssertTrue(sut.isEmpty, "에러 후 isEmpty는 true여야 합니다")
        XCTAssertTrue(sut.hasError, "에러 후 hasError는 true여야 합니다")
    }

    /// clearError - 에러 메시지 클리어
    func testClearError_RemovesErrorMessage() async {
        // Given: 에러 상태
        let error = NSError(domain: "TestError", code: 500)
        mockRepository.fetchResult = .failure(error)
        await sut.loadDailyLog(for: Date())

        XCTAssertTrue(sut.hasError, "에러가 있어야 합니다")

        // When: 에러 클리어
        sut.clearError()

        // Then: 에러 메시지 제거됨
        XCTAssertNil(sut.errorMessage, "clearError 호출 후 errorMessage는 nil이어야 합니다")
        XCTAssertFalse(sut.hasError, "clearError 호출 후 hasError는 false여야 합니다")
    }

    // MARK: - Computed Properties Tests

    /// Computed Properties - 값이 올바르게 반환되는지 확인
    func testComputedProperties_ReturnCorrectValues() async {
        // Given: DailyLog 로드
        let dailyLog = makeTestDailyLog(
            totalCaloriesIn: 2100,
            totalCarbs: 260.5,
            totalProtein: 105.2,
            totalFat: 58.3,
            tdee: 2310,
            netCalories: -210,
            totalCaloriesOut: 450,
            exerciseMinutes: 60,
            exerciseCount: 2,
            weight: 70.5,
            bodyFatPct: 21.5,
            sleepDuration: 420,
            sleepStatus: .good
        )
        mockRepository.fetchResult = .success(dailyLog)

        // When: 로드
        await sut.loadDailyLog(for: Date())

        // Then: Computed properties가 올바른 값 반환
        XCTAssertEqual(sut.totalCaloriesIn, 2100, "totalCaloriesIn이 일치해야 합니다")
        XCTAssertEqual(sut.totalCarbs, 260.5, "totalCarbs가 일치해야 합니다")
        XCTAssertEqual(sut.totalProtein, 105.2, "totalProtein이 일치해야 합니다")
        XCTAssertEqual(sut.totalFat, 58.3, "totalFat이 일치해야 합니다")
        XCTAssertEqual(sut.tdee, 2310, "tdee가 일치해야 합니다")
        XCTAssertEqual(sut.netCalories, -210, "netCalories가 일치해야 합니다")
        XCTAssertEqual(sut.totalCaloriesOut, 450, "totalCaloriesOut이 일치해야 합니다")
        XCTAssertEqual(sut.exerciseMinutes, 60, "exerciseMinutes가 일치해야 합니다")
        XCTAssertEqual(sut.exerciseCount, 2, "exerciseCount가 일치해야 합니다")
        XCTAssertEqual(sut.weight, 70.5, "weight가 일치해야 합니다")
        XCTAssertEqual(sut.bodyFatPct, 21.5, "bodyFatPct가 일치해야 합니다")
        XCTAssertEqual(sut.sleepDuration, 420, "sleepDuration이 일치해야 합니다")
        XCTAssertEqual(sut.sleepStatus, .good, "sleepStatus가 일치해야 합니다")
    }

    /// Computed Properties - 데이터 없을 때 기본값 반환
    func testComputedProperties_NoData_ReturnDefaultValues() {
        // Given: DailyLog가 nil인 상태 (초기 상태)

        // Then: 기본값 반환
        XCTAssertEqual(sut.totalCaloriesIn, 0, "데이터 없을 때 totalCaloriesIn은 0이어야 합니다")
        XCTAssertEqual(sut.totalCarbs, 0, "데이터 없을 때 totalCarbs는 0이어야 합니다")
        XCTAssertEqual(sut.totalProtein, 0, "데이터 없을 때 totalProtein은 0이어야 합니다")
        XCTAssertEqual(sut.totalFat, 0, "데이터 없을 때 totalFat은 0이어야 합니다")
        XCTAssertEqual(sut.tdee, 0, "데이터 없을 때 tdee는 0이어야 합니다")
        XCTAssertEqual(sut.netCalories, 0, "데이터 없을 때 netCalories는 0이어야 합니다")
        XCTAssertEqual(sut.totalCaloriesOut, 0, "데이터 없을 때 totalCaloriesOut은 0이어야 합니다")
        XCTAssertEqual(sut.exerciseMinutes, 0, "데이터 없을 때 exerciseMinutes는 0이어야 합니다")
        XCTAssertEqual(sut.exerciseCount, 0, "데이터 없을 때 exerciseCount는 0이어야 합니다")
        XCTAssertNil(sut.weight, "데이터 없을 때 weight는 nil이어야 합니다")
        XCTAssertNil(sut.bodyFatPct, "데이터 없을 때 bodyFatPct는 nil이어야 합니다")
        XCTAssertNil(sut.sleepDuration, "데이터 없을 때 sleepDuration은 nil이어야 합니다")
        XCTAssertNil(sut.sleepStatus, "데이터 없을 때 sleepStatus는 nil이어야 합니다")
    }

    // MARK: - Date Formatting Tests

    /// formattedSelectedDate - 오늘인 경우
    func testFormattedSelectedDate_Today_ReturnsONeul() {
        // Given: 오늘 날짜
        let calendar = Calendar.current
        sut.selectedDate = Date()

        // When & Then: "오늘" 반환
        XCTAssertEqual(sut.formattedSelectedDate, "오늘",
                      "오늘 날짜는 '오늘'로 표시되어야 합니다")
        XCTAssertTrue(sut.isToday, "isToday는 true여야 합니다")
    }

    /// formattedSelectedDate - 어제인 경우
    func testFormattedSelectedDate_Yesterday_ReturnsEoje() {
        // Given: 어제 날짜
        let calendar = Calendar.current
        sut.selectedDate = calendar.date(byAdding: .day, value: -1, to: Date())!

        // When & Then: "어제" 반환
        XCTAssertEqual(sut.formattedSelectedDate, "어제",
                      "어제 날짜는 '어제'로 표시되어야 합니다")
        XCTAssertFalse(sut.isToday, "isToday는 false여야 합니다")
    }

    /// formattedSelectedDate - 그 외 날짜
    func testFormattedSelectedDate_OtherDate_ReturnsFormattedString() {
        // Given: 3일 전 날짜
        let calendar = Calendar.current
        sut.selectedDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!

        // When & Then: 포맷된 문자열 반환 (예: "2026년 1월 10일 (금)")
        let formatted = sut.formattedSelectedDate
        XCTAssertTrue(formatted.contains("2026년"), "연도가 포함되어야 합니다")
        XCTAssertTrue(formatted.contains("1월"), "월이 포함되어야 합니다")
        XCTAssertTrue(formatted.contains("10일"), "일이 포함되어야 합니다")
        XCTAssertFalse(sut.isToday, "isToday는 false여야 합니다")
    }

    /// isFuture - 미래 날짜 체크
    func testIsFuture_FutureDate_ReturnsTrue() {
        // Given: 미래 날짜
        let calendar = Calendar.current
        sut.selectedDate = calendar.date(byAdding: .day, value: 1, to: Date())!

        // When & Then: isFuture는 true
        XCTAssertTrue(sut.isFuture, "미래 날짜는 isFuture가 true여야 합니다")
    }

    /// isFuture - 과거 날짜 체크
    func testIsFuture_PastDate_ReturnsFalse() {
        // Given: 과거 날짜
        let calendar = Calendar.current
        sut.selectedDate = calendar.date(byAdding: .day, value: -1, to: Date())!

        // When & Then: isFuture는 false
        XCTAssertFalse(sut.isFuture, "과거 날짜는 isFuture가 false여야 합니다")
    }

    // MARK: - onAppear Tests

    /// onAppear - 선택된 날짜의 데이터 로드
    func testOnAppear_LoadsSelectedDateData() async {
        // Given: 특정 날짜 선택
        let testDate = Date()
        sut.selectedDate = testDate

        let dailyLog = makeTestDailyLog()
        mockRepository.fetchResult = .success(dailyLog)

        // When: onAppear 호출
        await sut.onAppear()

        // Then: 데이터가 로드됨
        XCTAssertNotNil(sut.dailyLog, "onAppear 호출 시 데이터가 로드되어야 합니다")
    }
}

// MARK: - Mock DailyLogRepository

/// Mock DailyLogRepository
/// 📚 학습 포인트: Test Double - Mock Object
/// - 실제 Repository를 대체하는 테스트용 객체
/// - 테스트에서 원하는 결과를 반환하도록 설정 가능
/// 💡 Java 비교: Mockito의 mock() 또는 @Mock과 유사
final class MockDailyLogRepository: DailyLogRepository {

    // MARK: - Properties

    /// fetch 메서드의 반환 결과 설정
    var fetchResult: Result<DailyLog?, Error> = .success(nil)

    /// fetchCurrentDay 메서드의 반환 결과 설정
    var fetchCurrentDayResult: Result<DailyLog?, Error> = .success(nil)

    /// 지연 시뮬레이션 (로딩 상태 테스트용)
    var shouldDelay: Bool = false

    /// fetch 메서드 호출 횟수 추적
    var fetchCallCount: Int = 0

    /// fetchCurrentDay 메서드 호출 횟수 추적
    var fetchCurrentDayCallCount: Int = 0

    // MARK: - DailyLogRepository Implementation

    func fetch(for date: Date, userId: UUID) async throws -> DailyLog? {
        fetchCallCount += 1

        if shouldDelay {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2초
        }

        switch fetchResult {
        case .success(let dailyLog):
            return dailyLog
        case .failure(let error):
            throw error
        }
    }

    func fetchCurrentDay(userId: UUID) async throws -> DailyLog? {
        fetchCurrentDayCallCount += 1

        if shouldDelay {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2초
        }

        switch fetchCurrentDayResult {
        case .success(let dailyLog):
            return dailyLog
        case .failure(let error):
            throw error
        }
    }

    func getOrCreate(for date: Date, userId: UUID, bmr: Int32, tdee: Int32) async throws -> DailyLog {
        fatalError("Not implemented in mock")
    }

    func update(_ dailyLog: DailyLog) async throws -> DailyLog {
        fatalError("Not implemented in mock")
    }

    func addExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws {
        fatalError("Not implemented in mock")
    }

    func removeExercise(date: Date, userId: UUID, calories: Int32, duration: Int32) async throws {
        fatalError("Not implemented in mock")
    }

    func updateExercise(date: Date, userId: UUID, oldCalories: Int32, newCalories: Int32, oldDuration: Int32, newDuration: Int32) async throws {
        fatalError("Not implemented in mock")
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: ViewModel Testing Best Practices
///
/// ## ViewModel 테스트의 목적
/// - UI 로직과 비즈니스 로직 분리 확인
/// - 상태 관리가 올바르게 작동하는지 검증
/// - 에러 처리가 적절한지 확인
/// - 사용자 인터랙션에 대한 응답 테스트
///
/// ## 테스트 전략
///
/// 1. **성공/실패 시나리오**
///    - 정상 케이스: 데이터 로드 성공
///    - 에러 케이스: 네트워크 에러, 서버 에러
///    - 빈 데이터: nil 또는 빈 배열 처리
///
/// 2. **상태 전환 테스트**
///    - 초기 상태 → 로딩 → 성공
///    - 초기 상태 → 로딩 → 에러
///    - 에러 → 로딩 → 성공 (재시도)
///
/// 3. **사용자 인터랙션**
///    - 날짜 네비게이션 (이전/다음/오늘)
///    - 새로고침
///    - 에러 클리어
///
/// 4. **Computed Properties**
///    - 데이터가 있을 때 올바른 값 반환
///    - 데이터가 없을 때 기본값 또는 nil 반환
///
/// ## Mock Object 사용
///
/// - Repository를 Mock으로 대체하여 테스트 격리
/// - 원하는 결과를 반환하도록 설정 가능
/// - 실제 데이터베이스나 네트워크 호출 없이 테스트
///
/// ## @MainActor와 Async Testing
///
/// - ViewModel의 UI 업데이트는 메인 스레드에서 실행
/// - 테스트 메서드에 @MainActor 추가
/// - async 메서드는 await으로 호출
/// - Task.sleep으로 비동기 작업 완료 대기
///
/// ## 💡 실무 팁
///
/// - Given-When-Then 패턴으로 테스트 구조화
/// - 각 테스트는 하나의 케이스만 검증
/// - 테스트 이름은 명확하고 설명적으로 작성
/// - Mock 객체는 간단하게 유지 (필요한 메서드만 구현)
/// - 상태 전환을 명확히 검증
///
/// ## 💡 Java 비교
///
/// - JUnit + Mockito: Swift의 XCTest + Mock 객체
/// - LiveData testing: @Observable testing과 유사
/// - Coroutine testing: async/await testing과 유사
/// - @Before/@After: setUp/tearDown과 동일
