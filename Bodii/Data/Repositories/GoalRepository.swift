//
//  GoalRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Repository Implementation
// Repository 패턴의 구현체 - 데이터 소스를 추상화하여 도메인 레이어에 제공
// 💡 Java 비교: Spring Data JPA의 Repository 구현체와 유사

import Foundation

// MARK: - GoalRepository

/// GoalRepositoryProtocol의 구현체
/// 로컬 데이터 소스(Core Data)를 사용하여 목표 데이터를 관리합니다.
/// 📚 학습 포인트: Clean Architecture - Data Layer
/// - Protocol로 정의된 인터페이스를 구현
/// - Local Data Source를 사용하여 실제 데이터 작업 수행
/// - 에러를 Domain 레이어의 에러로 변환
/// 💡 Java 비교: @Repository 어노테이션이 붙은 구현 클래스와 유사
final class GoalRepository: GoalRepositoryProtocol {

    // MARK: - Properties

    /// 로컬 데이터 소스 (Core Data 작업 담당)
    /// 📚 학습 포인트: Dependency Injection
    /// - 외부에서 주입받아 사용
    /// - 테스트 시 Mock 객체로 교체 가능
    /// 💡 Java 비교: @Autowired private GoalLocalDataSource 와 유사
    private let localDataSource: GoalLocalDataSource

    // MARK: - Initialization

    /// GoalRepository 초기화
    /// 📚 학습 포인트: Constructor Injection
    /// - 의존성을 생성자를 통해 주입받음
    /// - 기본값으로 실제 구현체 사용
    /// - 테스트 시 Mock 주입 가능
    /// 💡 Java 비교: @Autowired 생성자 주입과 유사
    ///
    /// - Parameter localDataSource: 로컬 데이터 소스 (기본값: 새 인스턴스)
    init(localDataSource: GoalLocalDataSource = GoalLocalDataSource()) {
        self.localDataSource = localDataSource
    }

    // MARK: - Create

    /// 새로운 목표를 생성합니다.
    /// 📚 학습 포인트: Factory Method in Repository
    /// - Core Data 엔티티 생성을 LocalDataSource에 위임
    /// - UseCase는 직접 NSManagedObject를 생성하지 않음
    func createGoal(
        userId: UUID,
        goalType: GoalType,
        targetWeight: Decimal?,
        targetBodyFatPct: Decimal?,
        targetMuscleMass: Decimal?,
        weeklyWeightRate: Decimal?,
        weeklyFatPctRate: Decimal?,
        weeklyMuscleRate: Decimal?,
        startWeight: Decimal?,
        startBodyFatPct: Decimal?,
        startMuscleMass: Decimal?,
        startBMR: Decimal?,
        startTDEE: Decimal?,
        dailyCalorieTarget: Int32?
    ) async throws -> Goal {
        do {
            return try await localDataSource.create(
                userId: userId,
                goalType: goalType,
                targetWeight: targetWeight,
                targetBodyFatPct: targetBodyFatPct,
                targetMuscleMass: targetMuscleMass,
                weeklyWeightRate: weeklyWeightRate,
                weeklyFatPctRate: weeklyFatPctRate,
                weeklyMuscleRate: weeklyMuscleRate,
                dailyCalorieTarget: dailyCalorieTarget,
                startWeight: startWeight,
                startBodyFatPct: startBodyFatPct,
                startMuscleMass: startMuscleMass,
                startBMR: startBMR,
                startTDEE: startTDEE
            )
        } catch {
            throw RepositoryError.saveFailed(error.localizedDescription)
        }
    }

    /// 새로운 목표를 저장합니다.
    /// 📚 학습 포인트: Error Handling
    /// - Data Source의 에러를 Repository 에러로 변환
    /// - 도메인 레이어가 infrastructure 에러를 알 필요 없음
    /// 💡 Java 비교: @Transactional 메서드와 유사한 동작
    ///
    /// - Parameter goal: 저장할 목표 데이터
    /// - Returns: 저장된 목표 데이터 (ID가 할당됨)
    /// - Throws: RepositoryError - 저장 실패 시
    func save(_ goal: Goal) async throws -> Goal {
        do {
            // 📚 학습 포인트: Async/Await Chain
            // Local Data Source의 비동기 메서드를 호출하고 결과 반환
            return try await localDataSource.save(goal)
        } catch {
            // 📚 학습 포인트: Error Transformation
            // Infrastructure 에러를 Domain 에러로 변환
            throw RepositoryError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Read (Single)

    /// ID로 특정 목표를 조회합니다.
    /// 📚 학습 포인트: Optional Result
    /// - 데이터가 없으면 nil 반환 (에러가 아님)
    /// - 에러는 예외 상황 (DB 접근 실패 등)
    ///
    /// - Parameter id: 조회할 목표의 고유 식별자
    /// - Returns: 목표 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetch(by id: UUID) async throws -> Goal? {
        do {
            return try await localDataSource.fetch(by: id)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    /// 현재 활성 목표를 조회합니다.
    /// 📚 학습 포인트: Business Logic Delegation
    /// - isActive 필터링 로직은 Data Source에 위임
    /// - Repository는 단순히 중계 역할
    ///
    /// - Returns: 활성 목표 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchActiveGoal() async throws -> Goal? {
        do {
            return try await localDataSource.fetchActiveGoal()
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Read (Multiple)

    /// 모든 목표를 조회합니다.
    /// 📚 학습 포인트: Collection Return
    /// - 빈 배열도 정상적인 결과 (nil이 아님)
    /// - 데이터가 많을 경우 성능 이슈 가능성
    ///
    /// - Returns: 모든 목표 데이터 배열 (비어있을 수 있음)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchAll() async throws -> [Goal] {
        do {
            return try await localDataSource.fetchAll()
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    /// 비활성 목표 기록을 조회합니다.
    /// 📚 학습 포인트: Goal History Query
    /// - isActive = false인 목표들을 조회
    /// - 목표 변경 이력 추적에 사용
    ///
    /// - Returns: 비활성 목표 데이터 배열 (생성일 내림차순)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchHistory() async throws -> [Goal] {
        do {
            return try await localDataSource.fetchHistory()
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Update

    /// 기존 목표를 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - 목표 값, 주간 변화율, 활성 상태 등을 수정 가능
    ///
    /// - Parameter goal: 수정할 목표 데이터 (ID 포함)
    /// - Returns: 수정된 목표 데이터
    /// - Throws: RepositoryError - 수정 실패 시
    func update(_ goal: Goal) async throws -> Goal {
        do {
            return try await localDataSource.update(goal)
        } catch {
            // 📚 학습 포인트: Specific Error Handling
            // 에러 메시지에서 "찾을 수 없습니다" 문자열이 있으면 notFound 에러로 변환
            if error.localizedDescription.contains("찾을 수 없습니다") {
                throw RepositoryError.notFoundWithId(goal.id)
            }
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }

    /// 모든 활성 목표를 비활성화합니다.
    /// 📚 학습 포인트: Bulk Update
    /// - 새 목표 설정 시 기존 활성 목표를 비활성화하는 용도
    /// - Use Case에서 save 전에 호출
    ///
    /// - Throws: RepositoryError - 업데이트 실패 시
    func deactivateAllGoals() async throws {
        do {
            try await localDataSource.deactivateAllGoals()
        } catch {
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }

    /// 특정 사용자의 모든 활성 목표를 비활성화합니다.
    /// 📚 학습 포인트: Bulk Update with User Filter
    /// - 새 목표 설정 시 기존 활성 목표를 비활성화하는 용도
    /// - Use Case에서 save 전에 호출
    ///
    /// - Parameter userId: 사용자 ID
    /// - Throws: RepositoryError - 업데이트 실패 시
    func deactivateAllGoals(for userId: UUID) async throws {
        do {
            // TODO: userId 필터 적용 필요 시 LocalDataSource에 메서드 추가
            // 현재는 전체 비활성화로 대체 (단일 사용자 가정)
            try await localDataSource.deactivateAllGoals()
        } catch {
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete

    /// 특정 목표를 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 목표 삭제
    /// - 히스토리 보존을 위해 실제 삭제보다는 비활성화 권장
    ///
    /// - Parameter id: 삭제할 목표의 고유 식별자
    /// - Throws: RepositoryError - 삭제 실패 시
    func delete(by id: UUID) async throws {
        do {
            try await localDataSource.delete(by: id)
        } catch {
            // 📚 학습 포인트: Specific Error Handling
            // 에러 메시지에서 "찾을 수 없습니다" 문자열이 있으면 notFound 에러로 변환
            if error.localizedDescription.contains("찾을 수 없습니다") {
                throw RepositoryError.notFoundWithId(id)
            }
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }

    /// 모든 목표를 삭제합니다.
    /// 📚 학습 포인트: Bulk Delete
    /// - 테스트나 데이터 초기화에 사용
    /// - 💡 주의: 실제 앱에서는 신중하게 사용해야 함
    ///
    /// - Throws: RepositoryError - 삭제 실패 시
    func deleteAll() async throws {
        do {
            try await localDataSource.deleteAll()
        } catch {
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Goal Repository Pattern Implementation 이해
///
/// Repository의 역할:
/// - Protocol로 정의된 인터페이스를 구현
/// - Data Source를 사용하여 실제 데이터 작업 수행
/// - Domain Layer가 Data Layer의 구현 세부사항을 알지 못하도록 격리
/// - 에러를 Domain 레이어의 에러로 변환
///
/// 왜 Repository Layer가 필요한가?
/// 1. 추상화 (Abstraction)
///    - Domain Layer는 데이터가 어디에 저장되는지 알 필요 없음
///    - Core Data, Realm, Network API 등으로 쉽게 교체 가능
///
/// 2. 테스트 용이성 (Testability)
///    - Mock Repository로 쉽게 테스트 가능
///    - Use Case나 ViewModel을 테스트할 때 실제 DB 불필요
///
/// 3. 에러 변환 (Error Transformation)
///    - Infrastructure 에러를 Domain 에러로 변환
///    - 상위 레이어가 Core Data 에러를 직접 처리할 필요 없음
///
/// 4. 일관성 (Consistency)
///    - 데이터 접근 로직을 한 곳에 집중
///    - 여러 Data Source를 조합할 수 있음 (예: Cache + Network)
///
/// Clean Architecture에서의 위치:
/// ```
/// Presentation Layer (ViewModels)
///        ↓
/// Domain Layer (Use Cases) ← GoalRepositoryProtocol (Interface)
///        ↓
/// Data Layer (Repository) ← GoalRepository (Implementation)
///        ↓
/// Data Layer (Data Source) ← GoalLocalDataSource
///        ↓
/// Infrastructure (Core Data)
/// ```
///
/// 이 Repository의 특징:
/// 1. 단순한 중계자 (Simple Delegator)
///    - 복잡한 로직은 Data Source나 Use Case에 위임
///    - 주로 에러 변환과 메서드 호출 중계 역할
///
/// 2. 에러 처리 (Error Handling)
///    - Data Source의 에러를 RepositoryError로 변환
///    - 특정 에러 (notFound)는 별도로 처리
///
/// 3. Async/Await 지원
///    - 모든 메서드가 비동기 처리
///    - Main thread 블로킹 없이 데이터 작업 수행
///
/// 4. 활성 목표 관리
///    - fetchActiveGoal: 현재 활성 목표 조회
///    - deactivateAllGoals: 새 목표 설정 시 기존 목표 비활성화
///
/// 향후 확장 가능성:
/// - Remote Data Source 추가 (서버 동기화)
/// - Cache Layer 추가 (메모리 캐싱)
/// - Offline-first 전략 구현
/// - Conflict Resolution (충돌 해결)
///
/// 사용 예시:
/// ```swift
/// // DI Container에서 주입
/// let repository: GoalRepositoryProtocol = GoalRepository()
///
/// // Use Case에서 사용 (새 목표 설정)
/// try await repository.deactivateAllGoals()
/// let goal = Goal(userId: userId, goalType: .lose, targetWeight: 65.0, isActive: true, ...)
/// let saved = try await repository.save(goal)
///
/// // ViewModel에서 사용 (활성 목표 조회)
/// let activeGoal = try await repository.fetchActiveGoal()
/// ```
///
/// 💡 실무 팁:
/// - Repository는 비즈니스 로직을 포함하지 않음 (Use Case에서 처리)
/// - 여러 Data Source를 조합할 때 Repository에서 처리
/// - 에러는 구체적으로 변환하여 상위 레이어에서 적절히 처리 가능하도록
/// - 성능 최적화는 Data Source 레벨에서 수행
/// - Repository는 항상 Protocol을 통해 사용 (직접 참조 지양)
///
/// 💡 Java Spring과의 비교:
/// - Spring: @Repository, JpaRepository 인터페이스 상속
/// - Swift: Protocol 정의 후 직접 구현
/// - Spring: 자동 트랜잭션 관리 (@Transactional)
/// - Swift: 수동 트랜잭션 관리 (Context.save())
///
