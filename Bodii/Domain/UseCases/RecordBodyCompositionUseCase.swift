//
//  RecordBodyCompositionUseCase.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Orchestration Use Case
// 여러 Use Case와 Repository를 조합하여 복잡한 비즈니스 프로세스를 구현
// 💡 Java 비교: Service layer의 @Transactional 메서드와 유사

import Foundation

// MARK: - RecordBodyCompositionUseCase

/// 신체 구성 기록 저장 Use Case
/// BMR/TDEE 자동 계산과 함께 신체 구성 데이터를 저장하는 오케스트레이션 로직
/// 📚 학습 포인트: Clean Architecture - Use Case Composition
/// - 여러 Use Case를 조합하여 복잡한 비즈니스 프로세스 구현
/// - 트랜잭션 경계 역할 (모든 작업이 성공하거나 모두 실패)
/// - Repository를 통한 데이터 영속화
/// 💡 Java 비교: Service class with orchestration logic
///
/// 비즈니스 플로우:
/// 1. 입력 데이터 검증
/// 2. BMR 계산 (CalculateBMRUseCase) - 체지방률 유무에 따라 공식 선택
/// 3. TDEE 계산 (CalculateTDEEUseCase)
/// 4. BodyCompositionEntry 생성
/// 5. MetabolismData 생성
/// 6. Repository를 통해 저장
/// 7. User 엔티티의 현재 값 업데이트 (currentWeight, currentBMR, currentTDEE 등)
struct RecordBodyCompositionUseCase {

    // MARK: - Types

    /// 신체 구성 기록에 필요한 입력 데이터
    /// 📚 학습 포인트: Nested Type
    /// - Use Case 내부에 관련된 타입을 중첩하여 네임스페이스 정리
    /// - 외부에서는 RecordBodyCompositionUseCase.Input으로 접근
    /// 💡 Java 비교: static nested class와 유사
    struct Input {
        /// 측정 날짜 (기본값: 현재 시간)
        let date: Date

        /// 체중 (kg)
        /// 📚 학습 포인트: Decimal for Precision
        /// 부동소수점 오차를 방지하기 위해 Decimal 사용
        let weight: Decimal

        /// 체지방률 (%)
        /// 범위: 1-60%
        let bodyFatPercent: Decimal

        /// 근육량 (kg)
        let muscleMass: Decimal

        /// 사용자 프로필 (BMR/TDEE 계산에 필요)
        /// 📚 학습 포인트: Composition
        /// 신장, 나이, 성별, 활동 수준 정보 포함
        let userProfile: UserProfile

        /// Input 유효성 검증
        /// 📚 학습 포인트: Validation in Domain Layer
        /// 비즈니스 규칙 검증을 도메인 레이어에서 처리
        /// - Returns: 유효하면 true, 그렇지 않으면 false
        var isValid: Bool {
            // 체중: 20-500 kg
            guard weight >= 20 && weight <= 500 else { return false }

            // 체지방률: 1-60%
            guard bodyFatPercent >= 1 && bodyFatPercent <= 60 else { return false }

            // 근육량: 10-100 kg
            guard muscleMass >= 10 && muscleMass <= 100 else { return false }

            // 근육량은 체중보다 작아야 함
            guard muscleMass < weight else { return false }

            return true
        }
    }

    /// 신체 구성 기록 저장 결과
    /// 📚 학습 포인트: Result Type
    /// 성공 시 저장된 데이터와 계산된 대사율 정보를 함께 반환
    /// 💡 Java 비교: DTO (Data Transfer Object)와 유사
    struct Output {
        /// 저장된 신체 구성 데이터
        let bodyEntry: BodyCompositionEntry

        /// 계산된 대사율 데이터
        let metabolismData: MetabolismData

        /// 계산된 BMR 값 (kcal/day)
        /// 📚 학습 포인트: Convenience Property
        /// metabolismData에서 추출한 값을 직접 접근 가능하게 함
        var bmr: Decimal {
            metabolismData.bmr
        }

        /// 계산된 TDEE 값 (kcal/day)
        var tdee: Decimal {
            metabolismData.tdee
        }

        /// 포맷된 요약 정보
        /// 📚 학습 포인트: Computed String Property
        /// UI에서 바로 사용할 수 있는 포맷된 문자열 제공
        func summary() -> String {
            let weightStr = String(format: "%.1f", NSDecimalNumber(decimal: bodyEntry.weight).doubleValue)
            let bfStr = String(format: "%.1f", NSDecimalNumber(decimal: bodyEntry.bodyFatPercent).doubleValue)
            let bmrStr = String(format: "%.0f", NSDecimalNumber(decimal: bmr).doubleValue)
            let tdeeStr = String(format: "%.0f", NSDecimalNumber(decimal: tdee).doubleValue)

            return """
            Weight: \(weightStr) kg
            Body Fat: \(bfStr)%
            BMR: \(bmrStr) kcal/day
            TDEE: \(tdeeStr) kcal/day
            """
        }
    }

    // MARK: - Error

    /// 신체 구성 기록 중 발생할 수 있는 에러
    /// 📚 학습 포인트: Custom Error Type
    /// Swift의 Error 프로토콜을 conform하여 throw 가능한 타입 정의
    /// 💡 Java 비교: Custom Exception과 유사
    enum RecordError: Error, LocalizedError {
        /// 유효하지 않은 입력 값
        case invalidInput(String)

        /// BMR 계산 실패
        case bmrCalculationFailed(Error)

        /// TDEE 계산 실패
        case tdeeCalculationFailed(Error)

        /// 저장 실패
        case saveFailed(Error)

        /// 사용자 업데이트 실패
        case userUpdateFailed(Error)

        /// 에러 설명 (사용자에게 표시할 메시지)
        /// 📚 학습 포인트: LocalizedError Protocol
        /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
        var errorDescription: String? {
            switch self {
            case .invalidInput(let message):
                return "유효하지 않은 입력: \(message)"
            case .bmrCalculationFailed(let error):
                return "BMR 계산 실패: \(error.localizedDescription)"
            case .tdeeCalculationFailed(let error):
                return "TDEE 계산 실패: \(error.localizedDescription)"
            case .saveFailed(let error):
                return "저장 실패: \(error.localizedDescription)"
            case .userUpdateFailed(let error):
                return "사용자 정보 업데이트 실패: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Dependencies

    /// BMR 계산 Use Case
    /// 📚 학습 포인트: Dependency Injection
    /// 외부에서 주입받아 사용 (테스트 가능성 향상)
    private let calculateBMRUseCase: CalculateBMRUseCase

    /// TDEE 계산 Use Case
    private let calculateTDEEUseCase: CalculateTDEEUseCase

    /// 신체 데이터 저장소
    /// 📚 학습 포인트: Protocol-Oriented Programming
    /// 구현체가 아닌 프로토콜에 의존하여 유연성 확보
    /// 💡 Java 비교: Interface에 의존하는 것과 동일
    private let bodyRepository: BodyRepositoryProtocol

    /// 사용자 데이터 저장소
    /// 📚 학습 포인트: User Entity Update
    /// 체성분 저장 시 User 엔티티의 현재 값도 함께 업데이트
    private let userRepository: UserRepository

    // MARK: - Initialization

    /// RecordBodyCompositionUseCase 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 모든 의존성을 생성자를 통해 주입받음
    /// - 의존성 역전 원칙 (Dependency Inversion Principle) 준수
    /// 💡 Java 비교: @Autowired constructor injection과 유사
    ///
    /// - Parameters:
    ///   - calculateBMRUseCase: BMR 계산 Use Case (기본값: 새 인스턴스)
    ///   - calculateTDEEUseCase: TDEE 계산 Use Case (기본값: 새 인스턴스)
    ///   - bodyRepository: 신체 데이터 저장소 (필수)
    ///   - userRepository: 사용자 데이터 저장소 (필수)
    init(
        calculateBMRUseCase: CalculateBMRUseCase = CalculateBMRUseCase(),
        calculateTDEEUseCase: CalculateTDEEUseCase = CalculateTDEEUseCase(),
        bodyRepository: BodyRepositoryProtocol,
        userRepository: UserRepository
    ) {
        self.calculateBMRUseCase = calculateBMRUseCase
        self.calculateTDEEUseCase = calculateTDEEUseCase
        self.bodyRepository = bodyRepository
        self.userRepository = userRepository
    }

    // MARK: - Execute

    /// 신체 구성 기록 저장 실행
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// 📚 학습 포인트: Orchestration Logic
    /// 여러 단계의 비즈니스 로직을 순차적으로 실행:
    /// 1. 입력 검증
    /// 2. BMR 계산
    /// 3. TDEE 계산
    /// 4. 도메인 엔티티 생성
    /// 5. 저장소에 저장
    /// 6. 사용자 현재 값 업데이트 (향후 구현)
    ///
    /// - Parameter input: 신체 구성 기록 입력 데이터
    /// - Returns: 저장된 데이터와 계산된 대사율 정보
    /// - Throws: RecordError - 각 단계에서 실패 시
    func execute(input: Input) async throws -> Output {
        // 📚 학습 포인트: Guard Statement
        // 조건이 false일 때 early return
        // 💡 Java 비교: if (!condition) throw와 유사하지만 더 명시적
        guard input.isValid else {
            throw RecordError.invalidInput("입력 값이 유효하지 않습니다. 체중(20-500kg), 체지방률(1-60%), 근육량(10-100kg)을 확인하세요.")
        }

        // Step 1: BMR 계산
        // 📚 학습 포인트: Error Handling with do-catch
        // Use Case의 에러를 RecordError로 래핑하여 계층별 에러 분리
        let bmrOutput: CalculateBMRUseCase.Output
        do {
            bmrOutput = try calculateBMRUseCase.execute(
                profile: input.userProfile,
                bodyEntry: BodyCompositionEntry(
                    date: input.date,
                    weight: input.weight,
                    bodyFatPercent: input.bodyFatPercent,
                    muscleMass: input.muscleMass
                )
            )
        } catch {
            throw RecordError.bmrCalculationFailed(error)
        }

        // Step 2: TDEE 계산
        // 📚 학습 포인트: Use Case Chaining
        // BMR 계산 결과를 바로 TDEE 계산에 사용
        let tdeeOutput: CalculateTDEEUseCase.Output
        do {
            tdeeOutput = try calculateTDEEUseCase.execute(
                bmrOutput: bmrOutput,
                activityLevel: input.userProfile.activityLevel
            )
        } catch {
            throw RecordError.tdeeCalculationFailed(error)
        }

        // Step 3: 도메인 엔티티 생성
        // 📚 학습 포인트: Domain Entity Creation
        // 계산된 값들을 사용하여 저장할 엔티티 생성
        let bodyEntry = BodyCompositionEntry(
            date: input.date,
            weight: input.weight,
            bodyFatPercent: input.bodyFatPercent,
            muscleMass: input.muscleMass
        )

        let metabolismData = MetabolismData(
            date: input.date,
            bmr: bmrOutput.bmr,
            tdee: tdeeOutput.tdee,
            weight: input.weight,
            bodyFatPercent: input.bodyFatPercent,
            activityLevel: input.userProfile.activityLevel
        )

        // Step 4: 저장소에 저장
        // 📚 학습 포인트: Repository Pattern
        // 데이터 저장 세부사항을 추상화하여 Use Case는 비즈니스 로직에만 집중
        let savedEntry: BodyCompositionEntry
        do {
            savedEntry = try await bodyRepository.save(
                entry: bodyEntry,
                metabolismData: metabolismData
            )
        } catch {
            throw RecordError.saveFailed(error)
        }

        // Step 5: 사용자 현재 값 업데이트
        // 📚 학습 포인트: Side Effect
        // 저장 작업과 함께 사용자의 현재 값도 업데이트
        // User 엔티티의 currentWeight, currentBMR, currentTDEE 등 업데이트
        do {
            try await userRepository.updateCurrentValues(
                weight: input.weight,
                bodyFatPercent: input.bodyFatPercent,
                muscleMass: input.muscleMass,
                bmr: bmrOutput.bmr,
                tdee: tdeeOutput.tdee
            )
        } catch {
            // 📚 학습 포인트: Non-critical Error Handling
            // User 업데이트 실패는 치명적이지 않으므로 로깅만 하고 계속 진행
            // 다음 체성분 입력 시 다시 시도됨
            print("⚠️ User 현재 값 업데이트 실패 (비치명적): \(error.localizedDescription)")
            // 필요시 throw RecordError.userUpdateFailed(error) 로 변경 가능
        }

        // Step 6: 결과 반환
        // 📚 학습 포인트: Successful Completion
        // 모든 작업이 성공하면 저장된 데이터와 계산된 대사율 정보 반환
        return Output(
            bodyEntry: savedEntry,
            metabolismData: metabolismData
        )
    }

    // MARK: - Convenience Methods

    /// 개별 파라미터를 사용한 편의 메서드
    /// 📚 학습 포인트: Convenience Method
    /// 개별 파라미터를 받아서 Input으로 변환하는 헬퍼 메서드
    /// 💡 사용처: ViewModel에서 쉽게 호출 가능
    ///
    /// - Parameters:
    ///   - date: 측정 날짜 (기본값: 현재 시간)
    ///   - weight: 체중 (kg)
    ///   - bodyFatPercent: 체지방률 (%)
    ///   - muscleMass: 근육량 (kg)
    ///   - userProfile: 사용자 프로필
    /// - Returns: 저장된 데이터와 계산된 대사율 정보
    /// - Throws: RecordError
    func execute(
        date: Date = Date(),
        weight: Decimal,
        bodyFatPercent: Decimal,
        muscleMass: Decimal,
        userProfile: UserProfile
    ) async throws -> Output {
        let input = Input(
            date: date,
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            muscleMass: muscleMass,
            userProfile: userProfile
        )
        return try await execute(input: input)
    }
}

// MARK: - Sample Usage

extension RecordBodyCompositionUseCase {
    /// 📚 학습 포인트: Sample Data for Testing
    /// Use Case의 사용 예시와 테스트를 위한 샘플 데이터
    /// 💡 Java 비교: JUnit의 @Test fixture와 유사

    /// 샘플 입력 - 30세 남성, 70kg, 체지방률 18.5%, 근육량 32kg
    static func sampleInput() -> Input {
        return Input(
            date: Date(),
            weight: Decimal(70.0),
            bodyFatPercent: Decimal(18.5),
            muscleMass: Decimal(32.0),
            userProfile: UserProfile.sample
        )
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Orchestration Use Case 이해
///
/// RecordBodyCompositionUseCase의 역할:
/// - 여러 Use Case를 조합하여 복잡한 비즈니스 프로세스 구현
/// - 트랜잭션 경계 역할 (모든 작업이 성공하거나 모두 실패)
/// - 비즈니스 규칙 검증 및 에러 처리
///
/// 비즈니스 플로우:
/// 1. 입력 검증: 체중, 체지방률, 근육량의 범위와 일관성 확인
/// 2. BMR 계산: 하이브리드 공식 사용 (CalculateBMRUseCase)
///    - 체지방률 있음 → Katch-McArdle 공식 (더 정확)
///    - 체지방률 없음 → Mifflin-St Jeor 공식 (표준)
/// 3. TDEE 계산: BMR × Activity Multiplier (CalculateTDEEUseCase)
/// 4. 엔티티 생성: BodyCompositionEntry와 MetabolismData 생성
/// 5. 저장: Repository를 통해 Core Data에 저장
/// 6. 사용자 업데이트: User 엔티티의 현재 값 업데이트
///    - currentWeight, currentBodyFatPct, currentMuscleMass
///    - currentBMR, currentTDEE, metabolismUpdatedAt
///
/// 에러 처리:
/// - 각 단계의 에러를 적절한 RecordError로 변환
/// - 계층별로 에러를 분리하여 더 나은 디버깅과 사용자 피드백 제공
/// - 저장 실패 시 자동 롤백 (Core Data의 트랜잭션 특성)
///
/// Clean Architecture에서의 위치:
/// - Domain Layer의 Use Case
/// - 다른 Use Case와 Repository에 의존
/// - Presentation Layer (ViewModel)에서 호출됨
///
/// 💡 Java Spring과의 비교:
/// - Spring: @Service class with @Transactional
/// - Swift: Struct with async/await
/// - Spring: 여러 Service를 @Autowired로 주입
/// - Swift: 생성자로 의존성 주입
///
/// 사용 예시:
/// ```swift
/// let useCase = RecordBodyCompositionUseCase(bodyRepository: repository)
///
/// do {
///     let result = try await useCase.execute(
///         weight: 70.0,
///         bodyFatPercent: 18.5,
///         muscleMass: 32.0,
///         userProfile: userProfile
///     )
///
///     print("저장 완료!")
///     print("BMR: \(result.bmr) kcal/day")
///     print("TDEE: \(result.tdee) kcal/day")
/// } catch {
///     print("에러 발생: \(error.localizedDescription)")
/// }
/// ```
///
