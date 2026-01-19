//
//  SleepRepositoryProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Repository Pattern for Sleep Tracking
// 수면 데이터 접근 로직을 추상화하는 Repository 패턴
// 💡 Java 비교: Spring Data Repository 인터페이스와 유사

import Foundation

// MARK: - SleepRepositoryProtocol

/// 수면 데이터 저장소 인터페이스
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
protocol SleepRepositoryProtocol {

    // MARK: - Create

    /// 새로운 수면 기록을 생성합니다.
    /// 📚 학습 포인트: Factory Method in Repository
    /// - Core Data 엔티티는 context 없이 생성 불가
    /// - Repository가 Core Data context를 통해 엔티티 생성
    /// - UseCase는 데이터만 전달하고 생성은 Repository에서 처리
    /// 💡 Java 비교: DAO.create() 패턴과 유사
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - date: 수면 날짜 (02:00 경계 적용)
    ///   - duration: 수면 시간 (분)
    ///   - status: 수면 상태
    /// - Returns: 생성된 수면 기록
    /// - Throws: RepositoryError - 생성 실패 시
    func create(
        userId: UUID,
        date: Date,
        duration: Int32,
        status: SleepStatus
    ) async throws -> SleepRecord

    /// 기존 수면 기록을 저장합니다.
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// - Completion handler보다 가독성이 좋고 에러 처리가 쉬움
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// - Parameter sleepRecord: 저장할 수면 데이터
    /// - Returns: 저장된 수면 데이터 (ID가 할당됨)
    /// - Throws: RepositoryError - 저장 실패 시
    ///
    /// 비즈니스 규칙:
    /// - 02:00 경계 로직 적용 (00:00-01:59는 전날로 처리)
    /// - DailyLog의 sleepDuration과 sleepStatus가 자동으로 업데이트됨
    /// - SleepStatus는 duration 값에 따라 자동으로 결정됨
    func save(sleepRecord: SleepRecord) async throws -> SleepRecord

    // MARK: - Read (Single)

    /// ID로 특정 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Optional Return Type
    /// - 데이터가 없을 수 있으므로 Optional 반환
    /// - nil은 정상적인 상황 (데이터 없음), 에러는 예외 상황 (DB 접근 실패 등)
    ///
    /// - Parameter id: 조회할 기록의 고유 식별자
    /// - Returns: 수면 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (단일 레코드 조회)
    func fetch(by id: UUID) async throws -> SleepRecord?

    /// 특정 날짜의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Date Query with 02:00 Boundary
    /// - 02:00 경계 로직이 적용된 날짜로 조회
    /// - 같은 날짜의 기록이 여러 개 있을 수 있음
    /// - 가장 최근 기록을 반환
    ///
    /// - Parameter date: 조회할 날짜 (02:00 경계 적용)
    /// - Returns: 해당 날짜의 수면 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.2초 (날짜 인덱스 활용)
    func fetch(for date: Date) async throws -> SleepRecord?

    /// 가장 최근의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Most Recent Query
    /// - 대시보드나 현재 상태 표시에 사용
    /// - 날짜 기준 내림차순 정렬 후 첫 번째 결과
    ///
    /// - Returns: 가장 최근 수면 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (날짜 인덱스 활용, LIMIT 1)
    func fetchLatest() async throws -> SleepRecord?

    // MARK: - Read (Multiple)

    /// 모든 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Collection Return
    /// - 날짜 내림차순 정렬 (최신순)
    /// - 대량 데이터의 경우 성능 이슈 가능 → 페이징 고려
    ///
    /// - Returns: 모든 수면 데이터 배열 (비어있을 수 있음)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.5초 (최대 1000개 레코드 기준)
    /// 💡 주의: 데이터가 많아지면 fetchAll 대신 date range 쿼리 사용 권장
    func fetchAll() async throws -> [SleepRecord]

    /// 지정된 기간의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Date Range Query
    /// - 트렌드 차트를 위한 핵심 쿼리
    /// - 시작/종료 날짜를 모두 포함하는 범위
    /// - 날짜 인덱스를 활용한 최적화 필수
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (inclusive)
    ///   - endDate: 조회 종료 날짜 (inclusive)
    /// - Returns: 기간 내 수면 데이터 배열 (날짜 오름차순)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.3초 (날짜 범위 쿼리, 최대 90일 기준)
    /// 사용 예: 7일/30일/90일 트렌드 차트
    func fetch(from startDate: Date, to endDate: Date) async throws -> [SleepRecord]

    /// 최근 N일간의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Convenience Method
    /// - fetch(from:to:)의 편의 메서드
    /// - 자주 사용되는 패턴을 간단히 표현
    ///
    /// - Parameter days: 조회할 일수 (예: 7, 30, 90)
    /// - Returns: 최근 N일간의 수면 데이터 배열 (날짜 오름차순)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.3초 (내부적으로 fetch(from:to:) 호출)
    func fetchRecent(days: Int) async throws -> [SleepRecord]

    // MARK: - Update

    /// 기존 수면 기록을 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - 02:00 경계 로직 적용
    /// - DailyLog도 함께 업데이트
    ///
    /// - Parameter sleepRecord: 수정할 수면 데이터 (ID 포함)
    /// - Returns: 수정된 수면 데이터
    /// - Throws: RepositoryError - 수정 실패 시 (존재하지 않는 ID 등)
    ///
    /// 성능: <0.2초 (단일 레코드 업데이트)
    /// 비즈니스 규칙:
    /// - 날짜가 변경되면 이전 날짜의 DailyLog에서 수면 데이터 제거
    /// - 새로운 날짜의 DailyLog 업데이트
    func update(sleepRecord: SleepRecord) async throws -> SleepRecord

    // MARK: - Delete

    /// 특정 수면 기록을 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 레코드 삭제
    /// - 해당 날짜의 DailyLog에서 수면 데이터도 함께 제거
    ///
    /// - Parameter id: 삭제할 기록의 고유 식별자
    /// - Throws: RepositoryError - 삭제 실패 시
    ///
    /// 성능: <0.2초 (단일 레코드 삭제)
    func delete(by id: UUID) async throws

    /// 모든 수면 기록을 삭제합니다.
    /// 📚 학습 포인트: Bulk Delete
    /// - 테스트나 데이터 초기화에 사용
    /// - 💡 주의: 실제 앱에서는 신중하게 사용해야 함
    ///
    /// - Throws: RepositoryError - 삭제 실패 시
    ///
    /// 성능: <0.5초 (전체 레코드 삭제)
    /// 비즈니스 규칙:
    /// - 모든 DailyLog의 수면 데이터가 함께 제거됨
    func deleteAll() async throws
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepRepositoryProtocol 이해
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
/// 수면 추적 특화 기능:
/// 1. 02:00 경계 로직
///    - 00:00-01:59 입력 시 전날로 처리
///    - DateUtils.getLogicalDate 활용
///    - 입력 시와 조회 시 모두 적용
///
/// 2. DailyLog 자동 업데이트
///    - SleepRecord 저장/수정/삭제 시 DailyLog 동기화
///    - sleepDuration과 sleepStatus 필드 업데이트
///    - 다른 건강 지표와의 상관관계 분석 가능
///
/// 3. SleepStatus 자동 계산
///    - duration 값에 따라 status 자동 결정
///    - Bad: < 5.5h, Soso: 5.5-6.5h, Good: 6.5-7.5h
///    - Excellent: 7.5-9h, Oversleep: > 9h
///
/// 성능 고려사항:
/// - 모든 쿼리는 0.5초 이내 완료 목표
/// - 날짜 필드에 인덱스 필수
/// - 대량 데이터는 페이징 또는 제한 필요
/// - 백그라운드 컨텍스트 활용 (Core Data의 경우)
///
/// 사용 예시:
/// ```swift
/// let repository: SleepRepositoryProtocol = SleepRepository()
///
/// // 새 기록 저장
/// let sleepRecord = SleepRecord(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     duration: 420,  // 7시간 = 420분
///     status: .good,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// let saved = try await repository.save(sleepRecord: sleepRecord)
///
/// // 최근 7일 데이터 조회
/// let recentRecords = try await repository.fetchRecent(days: 7)
///
/// // 특정 날짜 조회
/// let todaysSleep = try await repository.fetch(for: Date())
///
/// // 업데이트
/// var updated = saved
/// updated.duration = 480  // 8시간으로 변경
/// updated.status = .excellent
/// try await repository.update(sleepRecord: updated)
///
/// // 삭제
/// try await repository.delete(by: saved.id)
/// ```
///
/// 💡 Java Spring Data Repository와의 비교:
/// - Spring: @Repository 어노테이션, JpaRepository 상속
/// - Swift: Protocol로 인터페이스 정의, 명시적 구현
/// - Spring: 메서드 이름 규칙으로 자동 쿼리 생성
/// - Swift: 모든 메서드를 명시적으로 구현
///
/// BodyRepositoryProtocol과의 차이점:
/// - BodyRepository는 BodyCompositionEntry와 MetabolismData를 함께 관리
/// - SleepRepository는 SleepRecord와 DailyLog를 함께 관리
/// - SleepRepository는 02:00 경계 로직이 추가로 적용됨
/// - SleepRepository는 단일 엔티티만 다루므로 더 단순함
///
