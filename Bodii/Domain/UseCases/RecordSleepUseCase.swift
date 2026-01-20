//
//  RecordSleepUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Sleep Recording Use Case
// 수면 기록과 자동 상태 계산을 처리하는 Use Case
// 💡 Java 비교: Service layer의 단일 메서드와 유사

import Foundation

// MARK: - RecordSleepUseCase

/// 수면 기록 저장 Use Case
/// 수면 시간을 입력받아 상태를 자동으로 계산하고 저장합니다.
/// 📚 학습 포인트: Clean Architecture - Use Case Layer
/// - 수면 기록이라는 특정 비즈니스 로직을 독립적인 유닛으로 캡슐화
/// - 02:00 경계 로직을 통한 날짜 처리
/// - SleepStatus 자동 계산
/// - DailyLog 자동 업데이트 (Repository를 통해)
/// 💡 Java 비교: Service 클래스의 단일 책임 메서드
struct RecordSleepUseCase {

    // MARK: - Types

    /// 수면 기록에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 RecordSleepUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 사용자 ID
        let userId: UUID

        /// 수면 기준일 (기본값: 현재 시간)
        /// 📚 학습 포인트: 02:00 Boundary Logic
        /// - 02:00 ~ 익일 01:59까지를 같은 날로 취급
        /// - DateUtils.getLogicalDate를 통해 처리됨
        let date: Date

        /// 수면 시간 (분 단위)
        /// 📚 학습 포인트: Duration in Minutes
        /// - 범위: 0-1440분 (0-24시간)
        /// - 밤샘의 경우 0분도 허용
        let duration: Int32

        /// Input 유효성 검증
        /// 📚 학습 포인트: Validation in Domain Layer
        /// 비즈니스 규칙 검증을 도메인 레이어에서 처리
        /// - Returns: 유효하면 true, 그렇지 않으면 false
        var isValid: Bool {
            // 수면 시간: 0-1440분 (0-24시간)
            // 0분도 허용 (밤샘의 경우)
            guard duration >= 0 && duration <= 1440 else { return false }

            return true
        }

        /// 수면 시간을 시:분 형식으로 반환
        /// 📚 학습 포인트: Convenience Property
        /// UI에서 표시할 때 사용하기 쉬운 형태로 제공
        /// - Returns: (hours, minutes) 튜플
        var durationFormatted: (hours: Int, minutes: Int) {
            let hours = Int(duration) / 60
            let minutes = Int(duration) % 60
            return (hours, minutes)
        }
    }

    /// 수면 기록 저장 결과
    /// 📚 학습 포인트: Result Type
    /// 성공 시 저장된 수면 기록 정보를 반환
    /// 💡 Java 비교: DTO (Data Transfer Object)와 유사
    struct Output {
        /// 저장된 수면 기록 데이터
        let sleepRecord: SleepRecord

        /// 계산된 수면 상태
        /// 📚 학습 포인트: Convenience Property
        /// sleepRecord에서 추출한 값을 직접 접근 가능하게 함
        /// Core Data의 Int16 값을 SleepStatus enum으로 변환
        var status: SleepStatus {
            SleepStatus(rawValue: sleepRecord.status) ?? .soso
        }

        /// 수면 시간 (분)
        var duration: Int32 {
            sleepRecord.duration
        }

        /// 수면 시간을 시:분 형식으로 반환
        /// 📚 학습 포인트: Computed Property
        /// UI에서 표시할 때 사용하기 쉬운 형태로 제공
        /// - Returns: (hours, minutes) 튜플
        var durationFormatted: (hours: Int, minutes: Int) {
            let hours = Int(duration) / 60
            let minutes = Int(duration) % 60
            return (hours, minutes)
        }

        /// 포맷된 요약 정보
        /// 📚 학습 포인트: Computed String Property
        /// UI에서 바로 사용할 수 있는 포맷된 문자열 제공
        func summary() -> String {
            let (hours, minutes) = durationFormatted
            return """
            Duration: \(hours)h \(minutes)m
            Status: \(status.displayName) \(status.iconName)
            """
        }
    }

    // MARK: - Error

    /// 수면 기록 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum RecordError: Error, LocalizedError {
        /// 유효하지 않은 입력 값
        case invalidInput(String)

        /// 저장 실패
        case saveFailed(Error)

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .invalidInput(let message):
                return "유효하지 않은 입력: \(message)"
            case .saveFailed(let error):
                return "저장 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Dependencies

    /// 수면 데이터 저장소
    /// 📚 학습 포인트: Protocol-Oriented Programming
    /// 구현체가 아닌 프로토콜에 의존하여 유연성 확보
    /// 💡 Java 비교: Interface에 의존하는 것과 동일
    private let sleepRepository: SleepRepositoryProtocol

    // MARK: - Initialization

    /// RecordSleepUseCase 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Autowired constructor injection과 유사
    ///
    /// - Parameter sleepRepository: 수면 데이터 저장소 (필수)
    init(sleepRepository: SleepRepositoryProtocol) {
        self.sleepRepository = sleepRepository
    }

    // MARK: - Execute

    /// 수면 기록 저장 실행
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// 📚 학습 포인트: Business Logic Flow
    /// 수면 기록 비즈니스 로직을 순차적으로 실행:
    /// 1. 입력 검증
    /// 2. 수면 상태 자동 계산 (duration → status)
    /// 3. SleepRecord 도메인 엔티티 생성
    /// 4. Repository를 통해 저장
    /// 5. DailyLog 자동 업데이트 (Repository/DataSource에서 처리)
    ///
    /// - Parameter input: 수면 기록 입력 데이터
    /// - Returns: 저장된 수면 기록 정보
    /// - Throws: RecordError - 각 단계에서 실패 시
    func execute(input: Input) async throws -> Output {
        // 📚 학습 포인트: Guard Statement
        // 조건이 false일 때 early return
        // 💡 Java 비교: if (!condition) throw와 유사하지만 더 명시적
        guard input.isValid else {
            throw RecordError.invalidInput("수면 시간은 0-1440분(0-24시간) 범위여야 합니다.")
        }

        // Step 1: 수면 상태 자동 계산
        // 📚 학습 포인트: Automatic Status Calculation
        // duration 값에 따라 SleepStatus를 자동으로 결정
        // - Bad: < 5.5h (330분)
        // - Soso: 5.5-6.5h (330-390분)
        // - Good: 6.5-7.5h (390-450분)
        // - Excellent: 7.5-9h (450-540분)
        // - Oversleep: > 9h (540분)
        let status = SleepStatus.from(durationMinutes: input.duration)

        // Step 2: Repository를 통해 생성 및 저장
        // 📚 학습 포인트: Repository Factory Pattern
        // - Core Data 엔티티는 context 없이 생성 불가
        // - Repository의 create 메서드를 통해 엔티티 생성
        // - UseCase는 데이터만 전달하고 생성 세부사항은 Repository에서 처리
        // 📚 학습 포인트: 02:00 Boundary Logic
        // Repository/DataSource에서 자동으로 처리:
        // - 02:00 이전 입력 시 전날로 처리
        // - DateUtils.getLogicalDate 사용
        // 📚 학습 포인트: DailyLog Auto-Update
        // Repository/DataSource에서 자동으로 처리:
        // - 해당 날짜의 DailyLog.sleepDuration 업데이트
        // - 해당 날짜의 DailyLog.sleepStatus 업데이트
        // - DailyLog가 없으면 자동 생성
        let savedRecord: SleepRecord
        do {
            savedRecord = try await sleepRepository.create(
                userId: input.userId,
                date: input.date,
                duration: input.duration,
                status: status
            )
        } catch {
            throw RecordError.saveFailed(error)
        }

        // Step 4: 결과 반환
        // 📚 학습 포인트: Successful Completion
        // 모든 작업이 성공하면 저장된 수면 기록 정보 반환
        return Output(sleepRecord: savedRecord)
    }

    // MARK: - Convenience Methods

    /// 개별 파라미터를 사용한 편의 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 개별 파라미터를 받아서 Input으로 변환하는 헬퍼 메서드
    /// 💡 사용처: ViewModel에서 쉽게 호출 가능
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 수면 기준일 (기본값: 현재 시간)
    ///   - duration: 수면 시간 (분 단위)
    /// - Returns: 저장된 수면 기록 정보
    /// - Throws: RecordError
    func execute(
        userId: UUID,
        date: Date = Date(),
        duration: Int32
    ) async throws -> Output {
        let input = Input(
            userId: userId,
            date: date,
            duration: duration
        )
        return try await execute(input: input)
    }

    /// 시:분 형식을 받는 편의 메서드
    /// 📚 학습 포인트: Method Overloading
    /// 다른 형식의 입력을 받아 동일한 결과를 반환
    /// 💡 사용처: UI 피커에서 시간과 분을 따로 받을 때
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 수면 기준일 (기본값: 현재 시간)
    ///   - hours: 수면 시간 (시간)
    ///   - minutes: 수면 시간 (분)
    /// - Returns: 저장된 수면 기록 정보
    /// - Throws: RecordError
    func execute(
        userId: UUID,
        date: Date = Date(),
        hours: Int,
        minutes: Int
    ) async throws -> Output {
        let totalMinutes = Int32(hours * 60 + minutes)
        let input = Input(
            userId: userId,
            date: date,
            duration: totalMinutes
        )
        return try await execute(input: input)
    }
}

// MARK: - Sample Usage

extension RecordSleepUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - 7시간 수면 (Good)
    static func sampleInputGood(userId: UUID = UUID()) -> Input {
        return Input(
            userId: userId,
            date: Date(),
            duration: 420 // 7시간 = 420분
        )
    }

    /// 샘플 입력 - 5시간 수면 (Bad)
    static func sampleInputBad(userId: UUID = UUID()) -> Input {
        return Input(
            userId: userId,
            date: Date(),
            duration: 300 // 5시간 = 300분
        )
    }

    /// 샘플 입력 - 8시간 수면 (Excellent)
    static func sampleInputExcellent(userId: UUID = UUID()) -> Input {
        return Input(
            userId: userId,
            date: Date(),
            duration: 480 // 8시간 = 480분
        )
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: RecordSleepUseCase 이해
///
/// RecordSleepUseCase의 역할:
/// - 수면 시간을 입력받아 수면 상태를 자동으로 계산
/// - 02:00 경계 로직을 적용한 날짜 처리
/// - SleepRecord 엔티티 생성 및 저장
/// - DailyLog 자동 업데이트 (Repository를 통해)
///
/// 비즈니스 플로우:
/// 1. 입력 검증: 수면 시간이 0-1440분(0-24시간) 범위인지 확인
/// 2. 상태 계산: SleepStatus.from(durationMinutes:)를 사용하여 자동 계산
/// 3. 엔티티 생성: SleepRecord 도메인 엔티티 생성
/// 4. 저장: Repository를 통해 Core Data에 저장
/// 5. DailyLog 업데이트: 해당 날짜의 DailyLog에 수면 정보 업데이트
///
/// 02:00 경계 로직:
/// - 02:00 ~ 익일 01:59까지를 같은 날로 취급
/// - 예: 2026-01-11 03:00 입력 → date = 2026-01-11
/// - 예: 2026-01-11 01:00 입력 → date = 2026-01-10
/// - DateUtils.getLogicalDate를 통해 처리 (Repository/DataSource에서)
///
/// SleepStatus 자동 계산 기준:
/// - Bad (🔴): 330분 미만 (5시간 30분 미만)
/// - Soso (🟡): 330~390분 (5시간 30분 ~ 6시간 30분)
/// - Good (🟢): 390~450분 (6시간 30분 ~ 7시간 30분)
/// - Excellent (🔵): 450~540분 (7시간 30분 ~ 9시간)
/// - Oversleep (🟠): 540분 초과 (9시간 초과)
///
/// DailyLog 자동 업데이트:
/// - SleepRecord 저장 시 해당 날짜의 DailyLog가 자동으로 업데이트됨
/// - DailyLog.sleepDuration: 수면 시간 (분)
/// - DailyLog.sleepStatus: 수면 상태
/// - DailyLog가 없으면 자동 생성됨
///
/// 에러 처리:
/// - 입력 검증 실패: RecordError.invalidInput
/// - 저장 실패: RecordError.saveFailed
///
/// Clean Architecture에서의 위치:
/// - Domain Layer의 Use Case
/// - SleepRepository에 의존
/// - Presentation Layer (ViewModel)에서 호출됨
///
/// 💡 Java Spring과의 비교:
/// - Spring: @Service class with @Transactional
/// - Swift: Struct with async/await
/// - Spring: Repository를 @Autowired로 주입
/// - Swift: 생성자로 의존성 주입
///
/// 사용 예시:
/// ```swift
/// let useCase = RecordSleepUseCase(sleepRepository: repository)
///
/// do {
///     // 7시간 수면 기록
///     let result = try await useCase.execute(
///         userId: user.id,
///         duration: 420  // 7시간 = 420분
///     )
///
///     print("저장 완료!")
///     print("수면 시간: \(result.duration)분")
///     print("수면 상태: \(result.status.displayName)")
///
///     // 또는 시:분 형식으로
///     let result2 = try await useCase.execute(
///         userId: user.id,
///         hours: 7,
///         minutes: 30
///     )
/// } catch {
///     print("에러 발생: \(error.localizedDescription)")
/// }
/// ```
///
/// 💡 실무 팁:
/// - UI 피커에서 시간과 분을 따로 받을 때는 execute(hours:minutes:) 사용
/// - 계산된 status를 미리 보여주고 싶다면 SleepStatus.from(durationMinutes:) 직접 호출
/// - 02:00 경계 로직은 Repository/DataSource에서 자동 처리되므로 Use Case에서 신경쓰지 않아도 됨
/// - DailyLog 업데이트도 자동이므로 별도 로직 불필요
///
/// RecordBodyCompositionUseCase와의 비교:
/// - RecordBodyCompositionUseCase: 여러 Use Case를 조합하는 오케스트레이션
/// - RecordSleepUseCase: 단일 비즈니스 로직 (상태 계산 + 저장)
/// - RecordBodyCompositionUseCase: BMR/TDEE 계산 후 저장
/// - RecordSleepUseCase: Status 계산 후 저장 (더 단순)
///
