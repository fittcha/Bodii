//
//  RecordSleepUseCaseTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: RecordSleepUseCase Unit Testing
// Use Case의 비즈니스 로직을 테스트
// 💡 Java 비교: JUnit Service Layer Test와 유사

import XCTest
@testable import Bodii

/// RecordSleepUseCase에 대한 단위 테스트
/// 📚 학습 포인트: Use Case Testing
/// - 비즈니스 로직 검증 (상태 자동 계산, 입력 검증)
/// - Mock Repository를 사용하여 의존성 격리
/// - 다양한 케이스 테스트 (정상, 경계값, 에러)
/// 💡 Java 비교: Mockito를 사용한 Service 테스트와 유사
final class RecordSleepUseCaseTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Use Case
    /// 📚 학습 포인트: System Under Test (SUT)
    var sut: RecordSleepUseCase!

    /// Mock Repository
    /// 📚 학습 포인트: Test Double - Mock
    /// - 실제 Repository 대신 테스트용 Mock 사용
    /// - 외부 의존성 제거 (Core Data 불필요)
    /// - 빠르고 예측 가능한 테스트
    var mockRepository: MockSleepRepository!

    // MARK: - Setup & Teardown

    /// 각 테스트 메서드 실행 전에 호출
    /// 📚 학습 포인트: Test Setup
    /// 테스트 환경을 초기화하여 각 테스트가 독립적으로 실행되도록 보장
    /// 💡 Java 비교: JUnit의 @Before 또는 @BeforeEach와 유사
    override func setUp() {
        super.setUp()
        mockRepository = MockSleepRepository()
        sut = RecordSleepUseCase(sleepRepository: mockRepository)
    }

    /// 각 테스트 메서드 실행 후에 호출
    /// 📚 학습 포인트: Test Teardown
    /// 테스트 후 정리 작업 수행
    /// 💡 Java 비교: JUnit의 @After 또는 @AfterEach와 유사
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Status Calculation Tests

    /// 수면 상태 자동 계산 - Bad (5시간 미만)
    /// 📚 학습 포인트: Business Logic Testing
    /// duration 값에 따라 status가 자동으로 계산되는지 확인
    /// 💡 Given-When-Then 패턴 사용
    func testExecute_Duration300Minutes_CalculatesBadStatus() async throws {
        // Given: 5시간 (300분) 수면 입력
        // 예상: Bad 상태 (< 5.5h = 330분)
        let userId = UUID()
        let input = RecordSleepUseCase.Input(
            userId: userId,
            date: Date(),
            duration: 300
        )

        // When: Use Case 실행
        let result = try await sut.execute(input: input)

        // Then: Bad 상태로 계산되어야 함
        XCTAssertEqual(result.status, .bad,
                      "300분(5시간)은 Bad 상태여야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.status, .bad,
                      "Repository에 Bad 상태로 저장되어야 합니다")
    }

    /// 수면 상태 자동 계산 - Soso (5.5~6.5시간)
    func testExecute_Duration360Minutes_CalculatesSosoStatus() async throws {
        // Given: 6시간 (360분) 수면 입력
        // 예상: Soso 상태 (330~390분 범위)
        let userId = UUID()
        let input = RecordSleepUseCase.Input(
            userId: userId,
            date: Date(),
            duration: 360
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Soso 상태로 계산되어야 함
        XCTAssertEqual(result.status, .soso,
                      "360분(6시간)은 Soso 상태여야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.status, .soso)
    }

    /// 수면 상태 자동 계산 - Good (6.5~7.5시간)
    func testExecute_Duration420Minutes_CalculatesGoodStatus() async throws {
        // Given: 7시간 (420분) 수면 입력
        // 예상: Good 상태 (390~450분 범위)
        let userId = UUID()
        let input = RecordSleepUseCase.Input(
            userId: userId,
            date: Date(),
            duration: 420
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Good 상태로 계산되어야 함
        XCTAssertEqual(result.status, .good,
                      "420분(7시간)은 Good 상태여야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.status, .good)
    }

    /// 수면 상태 자동 계산 - Excellent (7.5~9시간)
    func testExecute_Duration480Minutes_CalculatesExcellentStatus() async throws {
        // Given: 8시간 (480분) 수면 입력
        // 예상: Excellent 상태 (450~540분 범위)
        let userId = UUID()
        let input = RecordSleepUseCase.Input(
            userId: userId,
            date: Date(),
            duration: 480
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Excellent 상태로 계산되어야 함
        XCTAssertEqual(result.status, .excellent,
                      "480분(8시간)은 Excellent 상태여야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.status, .excellent)
    }

    /// 수면 상태 자동 계산 - Oversleep (9시간 초과)
    func testExecute_Duration600Minutes_CalculatesOversleepStatus() async throws {
        // Given: 10시간 (600분) 수면 입력
        // 예상: Oversleep 상태 (> 540분)
        let userId = UUID()
        let input = RecordSleepUseCase.Input(
            userId: userId,
            date: Date(),
            duration: 600
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Oversleep 상태로 계산되어야 함
        XCTAssertEqual(result.status, .oversleep,
                      "600분(10시간)은 Oversleep 상태여야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.status, .oversleep)
    }

    // MARK: - Boundary Value Tests

    /// 경계값 테스트 - Bad/Soso 경계 (330분)
    /// 📚 학습 포인트: Boundary Value Analysis
    /// 상태 변경 경계값에서 올바르게 동작하는지 확인
    func testExecute_Duration330Minutes_IsSosoStatus() async throws {
        // Given: 5.5시간 (330분) - Bad/Soso 경계
        // SleepStatus.from 구현에 따라 330분은 Soso
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 330
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Soso 상태여야 함 (330분 이상)
        XCTAssertEqual(result.status, .soso,
                      "330분은 Soso 상태 시작점이어야 합니다")
    }

    /// 경계값 테스트 - Soso/Good 경계 (390분)
    func testExecute_Duration390Minutes_IsGoodStatus() async throws {
        // Given: 6.5시간 (390분) - Soso/Good 경계
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 390
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Good 상태여야 함 (390분 이상)
        XCTAssertEqual(result.status, .good,
                      "390분은 Good 상태 시작점이어야 합니다")
    }

    /// 경계값 테스트 - Good/Excellent 경계 (450분)
    func testExecute_Duration450Minutes_IsExcellentStatus() async throws {
        // Given: 7.5시간 (450분) - Good/Excellent 경계
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 450
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Excellent 상태여야 함 (450분 이상)
        XCTAssertEqual(result.status, .excellent,
                      "450분은 Excellent 상태 시작점이어야 합니다")
    }

    /// 경계값 테스트 - Excellent/Oversleep 경계 (540분)
    func testExecute_Duration540Minutes_IsExcellentStatus() async throws {
        // Given: 9시간 (540분) - Excellent/Oversleep 경계
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 540
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Excellent 상태여야 함 (540분 이하)
        XCTAssertEqual(result.status, .excellent,
                      "540분은 Excellent 상태 끝점이어야 합니다")
    }

    /// 경계값 테스트 - Oversleep 시작 (541분)
    func testExecute_Duration541Minutes_IsOversleepStatus() async throws {
        // Given: 9시간 1분 (541분) - Oversleep 시작
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 541
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Oversleep 상태여야 함 (540분 초과)
        XCTAssertEqual(result.status, .oversleep,
                      "541분은 Oversleep 상태여야 합니다")
    }

    // MARK: - Edge Case Tests

    /// 엣지 케이스 - 0분 수면 (밤샘)
    /// 📚 학습 포인트: Edge Case Testing
    /// 극단적인 케이스에서의 동작 확인
    func testExecute_ZeroDuration_SavesSuccessfully() async throws {
        // Given: 0분 수면 (밤샘)
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 0
        )

        // When & Then: 정상적으로 저장되어야 함
        let result = try await sut.execute(input: input)
        XCTAssertEqual(result.duration, 0,
                      "0분 수면도 허용되어야 합니다")
        XCTAssertEqual(result.status, .bad,
                      "0분은 Bad 상태여야 합니다")
    }

    /// 엣지 케이스 - 최대 수면 시간 (24시간 = 1440분)
    func testExecute_MaxDuration1440Minutes_SavesSuccessfully() async throws {
        // Given: 24시간 (1440분) 수면
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 1440
        )

        // When & Then: 정상적으로 저장되어야 함
        let result = try await sut.execute(input: input)
        XCTAssertEqual(result.duration, 1440,
                      "1440분(24시간) 수면도 허용되어야 합니다")
        XCTAssertEqual(result.status, .oversleep,
                      "1440분은 Oversleep 상태여야 합니다")
    }

    /// 엣지 케이스 - 매우 짧은 수면 (30분)
    func testExecute_VeryShortDuration30Minutes_CalculatesBadStatus() async throws {
        // Given: 30분 수면
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 30
        )

        // When
        let result = try await sut.execute(input: input)

        // Then: Bad 상태로 저장
        XCTAssertEqual(result.status, .bad,
                      "30분은 Bad 상태여야 합니다")
    }

    // MARK: - Input Validation Tests

    /// 입력 검증 - 음수 수면 시간
    /// 📚 학습 포인트: Input Validation Testing
    /// 잘못된 입력에 대한 에러 처리 확인
    func testExecute_NegativeDuration_ThrowsInvalidInputError() async throws {
        // Given: 음수 수면 시간
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: -100
        )

        // When & Then: invalidInput 에러가 발생해야 함
        do {
            _ = try await sut.execute(input: input)
            XCTFail("음수 수면 시간은 에러를 발생시켜야 합니다")
        } catch let error as RecordSleepUseCase.RecordError {
            XCTAssertEqual(error, .invalidInput("수면 시간은 0-1440분(0-24시간) 범위여야 합니다."),
                          "invalidInput 에러여야 합니다")
        } catch {
            XCTFail("예상치 못한 에러 타입: \(error)")
        }
    }

    /// 입력 검증 - 범위 초과 (24시간 초과)
    func testExecute_DurationOver1440Minutes_ThrowsInvalidInputError() async throws {
        // Given: 25시간 (1500분) 수면
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 1500
        )

        // When & Then: invalidInput 에러가 발생해야 함
        do {
            _ = try await sut.execute(input: input)
            XCTFail("1440분 초과는 에러를 발생시켜야 합니다")
        } catch let error as RecordSleepUseCase.RecordError {
            if case .invalidInput = error {
                // Success
            } else {
                XCTFail("invalidInput 에러여야 합니다")
            }
        } catch {
            XCTFail("예상치 못한 에러 타입: \(error)")
        }
    }

    // MARK: - Repository Integration Tests

    /// Repository 통합 - 저장 호출 확인
    /// 📚 학습 포인트: Mock Verification
    /// Mock을 사용하여 Repository 호출 확인
    func testExecute_ValidInput_CallsRepositorySave() async throws {
        // Given
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 420
        )

        // When
        _ = try await sut.execute(input: input)

        // Then: Repository의 save가 호출되었는지 확인
        XCTAssertTrue(mockRepository.saveCalled,
                     "Repository의 save 메서드가 호출되어야 합니다")
        XCTAssertNotNil(mockRepository.savedRecord,
                       "저장할 레코드가 전달되어야 합니다")
    }

    /// Repository 통합 - 저장 데이터 검증
    func testExecute_ValidInput_PassesCorrectDataToRepository() async throws {
        // Given
        let userId = UUID()
        let date = Date()
        let duration: Int32 = 420
        let input = RecordSleepUseCase.Input(
            userId: userId,
            date: date,
            duration: duration
        )

        // When
        _ = try await sut.execute(input: input)

        // Then: Repository에 올바른 데이터가 전달되었는지 확인
        XCTAssertEqual(mockRepository.savedRecord?.userId, userId,
                      "userId가 일치해야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.duration, duration,
                      "duration이 일치해야 합니다")
        XCTAssertEqual(mockRepository.savedRecord?.status, .good,
                      "420분은 Good 상태여야 합니다")
    }

    /// Repository 통합 - 저장 실패 처리
    func testExecute_RepositoryFails_ThrowsSaveFailedError() async throws {
        // Given: Repository가 에러를 발생시키도록 설정
        mockRepository.shouldFail = true
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 420
        )

        // When & Then: saveFailed 에러가 발생해야 함
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Repository 실패 시 에러를 발생시켜야 합니다")
        } catch let error as RecordSleepUseCase.RecordError {
            if case .saveFailed = error {
                // Success
            } else {
                XCTFail("saveFailed 에러여야 합니다")
            }
        } catch {
            XCTFail("예상치 못한 에러 타입: \(error)")
        }
    }

    // MARK: - Convenience Method Tests

    /// 편의 메서드 - 개별 파라미터
    /// 📚 학습 포인트: Convenience Method Testing
    /// 편의 메서드가 기본 메서드와 동일한 결과를 반환하는지 확인
    func testExecute_ConvenienceMethodWithParameters_WorksCorrectly() async throws {
        // Given
        let userId = UUID()
        let date = Date()
        let duration: Int32 = 420

        // When: 편의 메서드 사용
        let result = try await sut.execute(
            userId: userId,
            date: date,
            duration: duration
        )

        // Then: 정상적으로 저장되어야 함
        XCTAssertEqual(result.duration, duration)
        XCTAssertEqual(result.status, .good)
        XCTAssertTrue(mockRepository.saveCalled)
    }

    /// 편의 메서드 - 시:분 형식
    func testExecute_ConvenienceMethodWithHoursMinutes_WorksCorrectly() async throws {
        // Given
        let userId = UUID()
        let date = Date()
        let hours = 7
        let minutes = 30

        // When: 시:분 형식 편의 메서드 사용
        let result = try await sut.execute(
            userId: userId,
            date: date,
            hours: hours,
            minutes: minutes
        )

        // Then: 7시간 30분 = 450분으로 변환되어야 함
        XCTAssertEqual(result.duration, 450,
                      "7시간 30분은 450분이어야 합니다")
        XCTAssertEqual(result.status, .excellent,
                      "450분은 Excellent 상태여야 합니다")
    }

    /// 편의 메서드 - 다양한 시:분 조합
    func testExecute_HoursMinutesConversion_ConvertsCorrectly() async throws {
        // Given: 다양한 시:분 조합
        let testCases: [(hours: Int, minutes: Int, expectedDuration: Int32, expectedStatus: SleepStatus)] = [
            (5, 0, 300, .bad),          // 5시간 = 300분 = Bad
            (6, 0, 360, .soso),         // 6시간 = 360분 = Soso
            (7, 0, 420, .good),         // 7시간 = 420분 = Good
            (8, 0, 480, .excellent),    // 8시간 = 480분 = Excellent
            (10, 0, 600, .oversleep),   // 10시간 = 600분 = Oversleep
            (7, 15, 435, .good),        // 7시간 15분 = 435분 = Good
            (8, 30, 510, .excellent)    // 8시간 30분 = 510분 = Excellent
        ]

        for testCase in testCases {
            // When
            let result = try await sut.execute(
                userId: UUID(),
                date: Date(),
                hours: testCase.hours,
                minutes: testCase.minutes
            )

            // Then
            XCTAssertEqual(result.duration, testCase.expectedDuration,
                          "\(testCase.hours)시간 \(testCase.minutes)분은 \(testCase.expectedDuration)분이어야 합니다")
            XCTAssertEqual(result.status, testCase.expectedStatus,
                          "\(testCase.expectedDuration)분은 \(testCase.expectedStatus) 상태여야 합니다")
        }
    }

    // MARK: - Output Formatting Tests

    /// 출력 포맷 - durationFormatted
    /// 📚 학습 포인트: Output Formatting Testing
    /// UI에 표시될 포맷된 데이터가 올바른지 확인
    func testOutput_DurationFormatted_ReturnsCorrectTuple() async throws {
        // Given: 7시간 30분 (450분)
        let result = try await sut.execute(
            userId: UUID(),
            duration: 450
        )

        // When
        let formatted = result.durationFormatted

        // Then: (7, 30) 튜플이어야 함
        XCTAssertEqual(formatted.hours, 7,
                      "hours는 7이어야 합니다")
        XCTAssertEqual(formatted.minutes, 30,
                      "minutes는 30이어야 합니다")
    }

    /// 출력 포맷 - summary
    func testOutput_Summary_ReturnsFormattedString() async throws {
        // Given
        let result = try await sut.execute(
            userId: UUID(),
            duration: 420
        )

        // When
        let summary = result.summary()

        // Then: 포맷된 문자열 확인
        XCTAssertTrue(summary.contains("7h 0m"),
                     "summary에 시간 정보가 포함되어야 합니다")
        XCTAssertTrue(summary.contains("Duration:"),
                     "summary에 Duration 레이블이 포함되어야 합니다")
        XCTAssertTrue(summary.contains("Status:"),
                     "summary에 Status 레이블이 포함되어야 합니다")
    }

    // MARK: - Input Validation Property Tests

    /// 입력 검증 속성 - isValid
    func testInput_IsValid_ValidatesCorrectly() {
        // Given & When & Then: 유효한 케이스
        let validInput = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 420
        )
        XCTAssertTrue(validInput.isValid,
                     "유효한 입력은 isValid가 true여야 합니다")

        // Given & When & Then: 0분 (유효)
        let zeroInput = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 0
        )
        XCTAssertTrue(zeroInput.isValid,
                     "0분은 유효한 입력입니다")

        // Given & When & Then: 1440분 (유효)
        let maxInput = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 1440
        )
        XCTAssertTrue(maxInput.isValid,
                     "1440분은 유효한 입력입니다")

        // Given & When & Then: 음수 (무효)
        let negativeInput = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: -1
        )
        XCTAssertFalse(negativeInput.isValid,
                      "음수는 무효한 입력입니다")

        // Given & When & Then: 1440분 초과 (무효)
        let overInput = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 1441
        )
        XCTAssertFalse(overInput.isValid,
                      "1440분 초과는 무효한 입력입니다")
    }

    /// 입력 포맷 - durationFormatted
    func testInput_DurationFormatted_ReturnsCorrectTuple() {
        // Given: 7시간 30분 (450분)
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 450
        )

        // When
        let formatted = input.durationFormatted

        // Then: (7, 30) 튜플이어야 함
        XCTAssertEqual(formatted.hours, 7)
        XCTAssertEqual(formatted.minutes, 30)
    }

    // MARK: - Date Handling Tests

    /// 날짜 처리 - 다양한 시간대 테스트
    /// 📚 학습 포인트: Date Boundary Testing
    /// 02:00 경계 로직은 Repository에서 처리되지만,
    /// Use Case가 날짜를 올바르게 전달하는지 확인
    func testExecute_DifferentDates_PassesCorrectDateToRepository() async throws {
        // Given: 특정 날짜
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(
            year: 2026,
            month: 1,
            day: 15,
            hour: 10,
            minute: 0
        ))!

        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: date,
            duration: 420
        )

        // When
        _ = try await sut.execute(input: input)

        // Then: Repository에 전달된 날짜 확인
        XCTAssertNotNil(mockRepository.savedRecord?.date)
        // 날짜 비교 (초 단위 차이는 무시)
        let timeDifference = abs(mockRepository.savedRecord!.date.timeIntervalSince(date))
        XCTAssertLessThan(timeDifference, 1.0,
                         "전달된 날짜가 입력 날짜와 일치해야 합니다")
    }

    // MARK: - Sample Data Tests

    /// 샘플 데이터 - Good 상태
    func testSampleInputGood_CreatesGoodStatusRecord() async throws {
        // Given: 샘플 Good 입력
        let input = RecordSleepUseCase.sampleInputGood()

        // When
        let result = try await sut.execute(input: input)

        // Then: Good 상태여야 함
        XCTAssertEqual(result.status, .good,
                      "샘플 Good 입력은 Good 상태여야 합니다")
        XCTAssertEqual(result.duration, 420,
                      "샘플 Good 입력은 420분이어야 합니다")
    }

    /// 샘플 데이터 - Bad 상태
    func testSampleInputBad_CreatesBadStatusRecord() async throws {
        // Given: 샘플 Bad 입력
        let input = RecordSleepUseCase.sampleInputBad()

        // When
        let result = try await sut.execute(input: input)

        // Then: Bad 상태여야 함
        XCTAssertEqual(result.status, .bad,
                      "샘플 Bad 입력은 Bad 상태여야 합니다")
        XCTAssertEqual(result.duration, 300,
                      "샘플 Bad 입력은 300분이어야 합니다")
    }

    /// 샘플 데이터 - Excellent 상태
    func testSampleInputExcellent_CreatesExcellentStatusRecord() async throws {
        // Given: 샘플 Excellent 입력
        let input = RecordSleepUseCase.sampleInputExcellent()

        // When
        let result = try await sut.execute(input: input)

        // Then: Excellent 상태여야 함
        XCTAssertEqual(result.status, .excellent,
                      "샘플 Excellent 입력은 Excellent 상태여야 합니다")
        XCTAssertEqual(result.duration, 480,
                      "샘플 Excellent 입력은 480분이어야 합니다")
    }

    // MARK: - Performance Tests

    /// 성능 테스트 - 단일 저장
    /// 📚 학습 포인트: Performance Testing
    /// Use Case 실행 성능 측정
    func testExecute_Performance_CompletesQuickly() {
        // Given
        let input = RecordSleepUseCase.Input(
            userId: UUID(),
            date: Date(),
            duration: 420
        )

        // When & Then: 성능 측정
        measure {
            _ = try? Task {
                _ = try await sut.execute(input: input)
            }.value
        }
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

    /// save 메서드 호출 여부
    var saveCalled = false

    /// 저장된 레코드
    var savedRecord: SleepRecord?

    /// 에러 발생 플래그
    var shouldFail = false

    /// 반환할 레코드 (설정하지 않으면 입력값 그대로 반환)
    var recordToReturn: SleepRecord?

    // MARK: - SleepRepositoryProtocol Implementation

    func save(sleepRecord: SleepRecord) async throws -> SleepRecord {
        saveCalled = true
        savedRecord = sleepRecord

        if shouldFail {
            throw RepositoryError.saveFailed
        }

        return recordToReturn ?? sleepRecord
    }

    func fetch(by id: UUID) async throws -> SleepRecord? {
        return savedRecord
    }

    func fetch(for date: Date) async throws -> SleepRecord? {
        return savedRecord
    }

    func fetchLatest() async throws -> SleepRecord? {
        return savedRecord
    }

    func fetchAll() async throws -> [SleepRecord] {
        return savedRecord != nil ? [savedRecord!] : []
    }

    func fetch(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        return savedRecord != nil ? [savedRecord!] : []
    }

    func fetchRecent(days: Int) async throws -> [SleepRecord] {
        return savedRecord != nil ? [savedRecord!] : []
    }

    func update(sleepRecord: SleepRecord) async throws -> SleepRecord {
        savedRecord = sleepRecord
        return sleepRecord
    }

    func delete(by id: UUID) async throws {
        savedRecord = nil
    }

    func deleteAll() async throws {
        savedRecord = nil
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: RecordSleepUseCase 테스트 전략
///
/// 테스트 커버리지:
/// 1. 비즈니스 로직 테스트
///    - 수면 상태 자동 계산 (5가지 상태)
///    - 상태 경계값 테스트 (330, 390, 450, 540분)
///
/// 2. 입력 검증 테스트
///    - 유효한 범위 (0-1440분)
///    - 범위 초과 (음수, 1440분 초과)
///    - isValid 속성 동작
///
/// 3. Repository 통합 테스트
///    - save 메서드 호출 확인
///    - 전달된 데이터 검증
///    - 에러 처리
///
/// 4. 편의 메서드 테스트
///    - 개별 파라미터 메서드
///    - 시:분 형식 메서드
///    - 다양한 조합 테스트
///
/// 5. 출력 포맷 테스트
///    - durationFormatted 튜플
///    - summary 문자열
///
/// 6. 엣지 케이스 테스트
///    - 0분 (밤샘)
///    - 1440분 (24시간)
///    - 매우 짧은 수면 (30분)
///
/// Mock 사용 이유:
/// - Core Data 의존성 제거
/// - 빠른 테스트 실행
/// - 예측 가능한 결과
/// - 에러 시나리오 테스트 용이
///
/// 💡 실무 팁:
/// - Use Case 테스트는 비즈니스 로직에 집중
/// - Repository는 Mock으로 대체하여 격리
/// - Given-When-Then 패턴으로 가독성 향상
/// - 경계값 테스트로 버그 사전 발견
/// - 샘플 데이터로 일관성 있는 테스트
///
