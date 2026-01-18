//
//  GoalRepositoryProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Repository Pattern
// 데이터 접근 로직을 추상화하는 Repository 패턴
// 💡 Java 비교: Spring Data Repository 인터페이스와 유사

import Foundation

// MARK: - GoalRepositoryProtocol

/// 목표 데이터 저장소 인터페이스
/// 📚 학습 포인트: Protocol-Oriented Programming
/// - Swift의 핵심 패러다임 중 하나
/// - 구현 세부사항을 숨기고 인터페이스만 정의
/// - 테스트 가능성 향상 (Mock 구현 가능)
/// - Dependency Inversion Principle (의존성 역전 원칙) 구현
/// 💡 Java 비교: Interface와 유사하지만 더 강력한 기능 제공
///
/// 성능 요구사항:
/// - 모든 쿼리는 0.5초 이내에 완료되어야 함
/// - 대량 데이터 조회 시 페이징 또는 최적화된 인덱싱 필요
protocol GoalRepositoryProtocol {

    // MARK: - Create

    /// 새로운 목표를 저장합니다.
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// - Completion handler보다 가독성이 좋고 에러 처리가 쉬움
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// - Parameter goal: 저장할 목표 데이터
    /// - Returns: 저장된 목표 데이터 (ID가 할당됨)
    /// - Throws: RepositoryError - 저장 실패 시
    ///
    /// 비즈니스 규칙:
    /// - 새 목표 저장 시 기존 활성 목표는 자동으로 비활성화되지 않음
    /// - 활성 목표 관리는 Use Case에서 처리
    func save(_ goal: Goal) async throws -> Goal

    // MARK: - Read (Single)

    /// ID로 특정 목표를 조회합니다.
    /// 📚 학습 포인트: Optional Return Type
    /// - 데이터가 없을 수 있으므로 Optional 반환
    /// - nil은 정상적인 상황 (데이터 없음), 에러는 예외 상황 (DB 접근 실패 등)
    ///
    /// - Parameter id: 조회할 목표의 고유 식별자
    /// - Returns: 목표 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (단일 레코드 조회)
    func fetch(by id: UUID) async throws -> Goal?

    /// 현재 활성 목표를 조회합니다.
    /// 📚 학습 포인트: Business Logic in Query
    /// - isActive = true인 목표 조회
    /// - 사용자는 하나의 활성 목표만 가질 수 있음
    ///
    /// - Returns: 활성 목표 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (isActive 인덱스 활용)
    func fetchActiveGoal() async throws -> Goal?

    // MARK: - Read (Multiple)

    /// 모든 목표를 조회합니다.
    /// 📚 학습 포인트: Collection Return
    /// - 생성일 내림차순 정렬 (최신순)
    /// - 대량 데이터의 경우 성능 이슈 가능 → 페이징 고려
    ///
    /// - Returns: 모든 목표 데이터 배열 (비어있을 수 있음)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.5초 (최대 100개 레코드 기준)
    /// 💡 주의: 데이터가 많아지면 fetchAll 대신 특정 조건 쿼리 사용 권장
    func fetchAll() async throws -> [Goal]

    /// 비활성 목표 기록을 조회합니다.
    /// 📚 학습 포인트: Goal History
    /// - isActive = false인 목표 조회
    /// - 목표 변경 이력 추적에 사용
    ///
    /// - Returns: 비활성 목표 데이터 배열 (생성일 내림차순)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.3초 (isActive 인덱스 활용)
    func fetchHistory() async throws -> [Goal]

    // MARK: - Update

    /// 기존 목표를 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - 목표 값, 주간 변화율, 활성 상태 등을 수정 가능
    ///
    /// - Parameter goal: 수정할 목표 데이터 (ID 포함)
    /// - Returns: 수정된 목표 데이터
    /// - Throws: RepositoryError - 수정 실패 시 (존재하지 않는 ID 등)
    ///
    /// 성능: <0.2초 (단일 레코드 업데이트)
    func update(_ goal: Goal) async throws -> Goal

    /// 모든 활성 목표를 비활성화합니다.
    /// 📚 학습 포인트: Bulk Update
    /// - 새 목표 설정 시 기존 활성 목표를 비활성화하는 용도
    /// - Use Case에서 save 전에 호출
    ///
    /// - Throws: RepositoryError - 업데이트 실패 시
    ///
    /// 성능: <0.3초 (배치 업데이트)
    func deactivateAllGoals() async throws

    // MARK: - Delete

    /// 특정 목표를 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 목표 삭제
    /// - 히스토리 보존을 위해 실제 삭제보다는 비활성화 권장
    ///
    /// - Parameter id: 삭제할 목표의 고유 식별자
    /// - Throws: RepositoryError - 삭제 실패 시
    ///
    /// 성능: <0.2초 (단일 레코드 삭제)
    func delete(by id: UUID) async throws

    /// 모든 목표를 삭제합니다.
    /// 📚 학습 포인트: Bulk Delete
    /// - 테스트나 데이터 초기화에 사용
    /// - 💡 주의: 실제 앱에서는 신중하게 사용해야 함
    ///
    /// - Throws: RepositoryError - 삭제 실패 시
    ///
    /// 성능: <0.5초 (전체 레코드 삭제)
    func deleteAll() async throws
}

// MARK: - Documentation

/// 📚 학습 포인트: Goal Repository Pattern 이해
///
/// Repository Pattern이란?
/// - 데이터 접근 로직을 추상화하는 디자인 패턴
/// - Domain Layer는 데이터가 어디에 저장되는지 알 필요가 없음
/// - Core Data, Realm, Network API 등 다양한 구현체로 교체 가능
///
/// 장점:
/// 1. 테스트 용이성: Mock Repository로 쉽게 테스트 가능
/// 2. 관심사 분리: 비즈니스 로직과 데이터 접근 로직 분리
/// 3. 유연성: 데이터 소스 변경 시 Repository 구현만 교체
/// 4. 의존성 역전: 고수준 모듈이 저수준 모듈에 의존하지 않음
///
/// Clean Architecture에서의 위치:
/// - Protocol: Domain Layer (Interfaces)
/// - Implementation: Data Layer (Repositories)
/// - Usage: Domain Layer (Use Cases) 및 Presentation Layer (ViewModels)
///
/// Goal Repository의 특징:
/// 1. 활성 목표 관리
///    - fetchActiveGoal: 현재 활성 목표 조회
///    - deactivateAllGoals: 새 목표 설정 시 기존 목표 비활성화
///
/// 2. 목표 히스토리
///    - fetchHistory: 비활성화된 과거 목표 조회
///    - 목표 변경 이력 추적
///
/// 3. 단순한 인터페이스
///    - 신체 구성 데이터와 달리 목표는 단독 엔티티
///    - 복잡한 관계나 통계 계산 없음
///
/// 성능 고려사항:
/// - 모든 쿼리는 0.5초 이내 완료 목표
/// - isActive 필드에 인덱스 필수
/// - 대량 데이터는 페이징 또는 제한 필요
/// - 백그라운드 컨텍스트 활용 (Core Data의 경우)
///
/// 사용 예시:
/// ```swift
/// let repository: GoalRepositoryProtocol = GoalRepository()
///
/// // 새 목표 저장 (활성 목표를 먼저 비활성화)
/// try await repository.deactivateAllGoals()
/// let goal = Goal(userId: userId, goalType: .lose, targetWeight: 65.0, isActive: true, ...)
/// let saved = try await repository.save(goal)
///
/// // 활성 목표 조회
/// let activeGoal = try await repository.fetchActiveGoal()
///
/// // 목표 히스토리 조회
/// let history = try await repository.fetchHistory()
/// ```
///
/// 💡 Java Spring Data Repository와의 비교:
/// - Spring: @Repository 어노테이션, JpaRepository 상속
/// - Swift: Protocol로 인터페이스 정의, 명시적 구현
/// - Spring: 메서드 이름 규칙으로 자동 쿼리 생성
/// - Swift: 모든 메서드를 명시적으로 구현
///
