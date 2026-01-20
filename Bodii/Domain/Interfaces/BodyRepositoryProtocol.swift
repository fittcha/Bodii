//
//  BodyRepositoryProtocol.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Repository Pattern
// 데이터 접근 로직을 추상화하는 Repository 패턴
// 💡 Java 비교: Spring Data Repository 인터페이스와 유사

import Foundation

// MARK: - BodyRepositoryProtocol

/// 신체 구성 데이터 저장소 인터페이스
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
protocol BodyRepositoryProtocol {

    // MARK: - Create

    /// 새로운 신체 구성 기록을 저장합니다.
    /// 📚 학습 포인트: Async/Await
    /// - Swift 5.5+의 동시성 모델
    /// - 비동기 작업을 동기 코드처럼 작성 가능
    /// - Completion handler보다 가독성이 좋고 에러 처리가 쉬움
    /// 💡 Java 비교: CompletableFuture 또는 Kotlin Coroutines와 유사
    ///
    /// - Parameters:
    ///   - entry: 저장할 신체 구성 데이터
    ///   - metabolismData: 함께 저장할 대사율 데이터 (BMR/TDEE)
    /// - Returns: 저장된 신체 구성 데이터 (ID가 할당됨)
    /// - Throws: RepositoryError - 저장 실패 시
    ///
    /// 비즈니스 규칙:
    /// - 각 BodyCompositionEntry는 대응하는 MetabolismData와 함께 저장됨
    /// - 히스토리컬 트래킹을 위해 대사율 스냅샷 보존
    func save(entry: BodyCompositionEntry, metabolismData: MetabolismData) async throws -> BodyCompositionEntry

    // MARK: - Read (Single)

    /// ID로 특정 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Optional Return Type
    /// - 데이터가 없을 수 있으므로 Optional 반환
    /// - nil은 정상적인 상황 (데이터 없음), 에러는 예외 상황 (DB 접근 실패 등)
    ///
    /// - Parameter id: 조회할 기록의 고유 식별자
    /// - Returns: 신체 구성 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (단일 레코드 조회)
    func fetch(by id: UUID) async throws -> BodyCompositionEntry?

    /// 특정 날짜의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Date Comparison
    /// - 같은 날짜의 기록이 여러 개 있을 수 있음
    /// - 가장 최근 기록을 반환
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 신체 구성 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.2초 (날짜 인덱스 활용)
    func fetch(for date: Date) async throws -> BodyCompositionEntry?

    /// 가장 최근의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Most Recent Query
    /// - 대시보드나 현재 상태 표시에 사용
    /// - 날짜 기준 내림차순 정렬 후 첫 번째 결과
    ///
    /// - Returns: 가장 최근 신체 구성 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (날짜 인덱스 활용, LIMIT 1)
    func fetchLatest() async throws -> BodyCompositionEntry?

    // MARK: - Read (Multiple)

    /// 모든 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Collection Return
    /// - 날짜 내림차순 정렬 (최신순)
    /// - 대량 데이터의 경우 성능 이슈 가능 → 페이징 고려
    ///
    /// - Returns: 모든 신체 구성 데이터 배열 (비어있을 수 있음)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.5초 (최대 1000개 레코드 기준)
    /// 💡 주의: 데이터가 많아지면 fetchAll 대신 date range 쿼리 사용 권장
    func fetchAll() async throws -> [BodyCompositionEntry]

    /// 지정된 기간의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Date Range Query
    /// - 트렌드 차트를 위한 핵심 쿼리
    /// - 시작/종료 날짜를 모두 포함하는 범위
    /// - 날짜 인덱스를 활용한 최적화 필수
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (inclusive)
    ///   - endDate: 조회 종료 날짜 (inclusive)
    /// - Returns: 기간 내 신체 구성 데이터 배열 (날짜 오름차순)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.3초 (날짜 범위 쿼리, 최대 90일 기준)
    /// 사용 예: 7일/30일/90일 트렌드 차트
    func fetch(from startDate: Date, to endDate: Date) async throws -> [BodyCompositionEntry]

    /// 최근 N일간의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Convenience Method
    /// - fetch(from:to:)의 편의 메서드
    /// - 자주 사용되는 패턴을 간단히 표현
    ///
    /// - Parameter days: 조회할 일수 (예: 7, 30, 90)
    /// - Returns: 최근 N일간의 신체 구성 데이터 배열 (날짜 오름차순)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.3초 (내부적으로 fetch(from:to:) 호출)
    func fetchRecent(days: Int) async throws -> [BodyCompositionEntry]

    // MARK: - Update

    /// 기존 신체 구성 기록을 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - MetabolismData도 함께 업데이트
    ///
    /// - Parameters:
    ///   - entry: 수정할 신체 구성 데이터 (ID 포함)
    ///   - metabolismData: 함께 수정할 대사율 데이터
    /// - Returns: 수정된 신체 구성 데이터
    /// - Throws: RepositoryError - 수정 실패 시 (존재하지 않는 ID 등)
    ///
    /// 성능: <0.2초 (단일 레코드 업데이트)
    func update(entry: BodyCompositionEntry, metabolismData: MetabolismData) async throws -> BodyCompositionEntry

    // MARK: - Delete

    /// 특정 신체 구성 기록을 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 레코드 삭제
    /// - Cascade delete: 연관된 MetabolismData도 함께 삭제
    ///
    /// - Parameter id: 삭제할 기록의 고유 식별자
    /// - Throws: RepositoryError - 삭제 실패 시
    ///
    /// 성능: <0.2초 (단일 레코드 삭제 + cascade)
    func delete(by id: UUID) async throws

    /// 모든 신체 구성 기록을 삭제합니다.
    /// 📚 학습 포인트: Bulk Delete
    /// - 테스트나 데이터 초기화에 사용
    /// - 💡 주의: 실제 앱에서는 신중하게 사용해야 함
    ///
    /// - Throws: RepositoryError - 삭제 실패 시
    ///
    /// 성능: <0.5초 (전체 레코드 삭제)
    func deleteAll() async throws

    // MARK: - Metabolism Data

    /// 특정 신체 구성 기록과 연결된 대사율 데이터를 조회합니다.
    /// 📚 학습 포인트: Related Entity Query
    /// - 1:1 관계의 연관 엔티티 조회
    /// - 히스토리컬 BMR/TDEE 트래킹에 사용
    ///
    /// - Parameter bodyEntryId: 신체 구성 기록 ID
    /// - Returns: 연결된 대사율 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.1초 (관계 인덱스 활용)
    func fetchMetabolismData(for bodyEntryId: UUID) async throws -> MetabolismData?

    // MARK: - Statistics

    /// 지정된 기간의 통계 데이터를 조회합니다.
    /// 📚 학습 포인트: Aggregate Query
    /// - 평균, 최소, 최대 등의 통계 계산
    /// - 차트 요약 정보에 사용
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜
    ///   - endDate: 조회 종료 날짜
    /// - Returns: 기간 내 통계 데이터
    /// - Throws: RepositoryError - 조회 실패 시
    ///
    /// 성능: <0.3초 (집계 쿼리)
    func fetchStatistics(from startDate: Date, to endDate: Date) async throws -> BodyCompositionStatistics
}

// MARK: - Supporting Types

/// 신체 구성 통계 데이터
/// 📚 학습 포인트: Value Object
/// - 여러 값을 그룹화한 불변 객체
/// - 차트 요약 정보에 사용
struct BodyCompositionStatistics: Codable, Equatable {
    /// 평균 체중 (kg)
    let averageWeight: Decimal

    /// 최소 체중 (kg)
    let minWeight: Decimal

    /// 최대 체중 (kg)
    let maxWeight: Decimal

    /// 평균 체지방률 (%)
    let averageBodyFatPercent: Decimal

    /// 최소 체지방률 (%)
    let minBodyFatPercent: Decimal

    /// 최대 체지방률 (%)
    let maxBodyFatPercent: Decimal

    /// 평균 근육량 (kg)
    let averageMuscleMass: Decimal

    /// 최소 근육량 (kg)
    let minMuscleMass: Decimal

    /// 최대 근육량 (kg)
    let maxMuscleMass: Decimal

    /// 측정 횟수
    let recordCount: Int

    /// 체중 변화량 (kg) - 기간 내 첫 기록과 마지막 기록의 차이
    /// 📚 학습 포인트: Computed Property
    /// 양수: 체중 증가, 음수: 체중 감소
    var weightChange: Decimal {
        maxWeight - minWeight
    }
}

// MARK: - Error

/// Repository 작업 중 발생할 수 있는 에러
/// 📚 학습 포인트: Domain Error
/// - 도메인 레이어의 에러 정의
/// - Infrastructure 에러를 도메인 에러로 변환
/// 💡 Java 비교: Custom Exception과 유사
enum RepositoryError: Error, LocalizedError {
    /// 저장 실패
    case saveFailed(String)

    /// 조회 실패
    case fetchFailed(String)

    /// 업데이트 실패
    case updateFailed(String)

    /// 삭제 실패
    case deleteFailed(String)

    /// 데이터를 찾을 수 없음
    case notFound(UUID)

    /// 유효하지 않은 입력
    case invalidInput(String)

    /// 유효하지 않은 데이터
    case invalidData(String)

    /// 성능 타임아웃 (0.5초 초과)
    case timeout

    /// Core Data Context가 해제됨
    case contextDeallocated

    /// 알 수 없는 에러
    case unknown(Error)

    /// 에러 설명 (사용자에게 표시할 메시지)
    /// 📚 학습 포인트: LocalizedError Protocol
    /// errorDescription을 구현하여 사용자 친화적인 에러 메시지 제공
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "저장 실패: \(message)"
        case .fetchFailed(let message):
            return "조회 실패: \(message)"
        case .updateFailed(let message):
            return "수정 실패: \(message)"
        case .deleteFailed(let message):
            return "삭제 실패: \(message)"
        case .notFound(let id):
            return "데이터를 찾을 수 없습니다 (ID: \(id))"
        case .invalidInput(let message):
            return "유효하지 않은 입력: \(message)"
        case .invalidData(let message):
            return "유효하지 않은 데이터: \(message)"
        case .timeout:
            return "작업 시간이 초과되었습니다 (성능 요구사항: 0.5초 이내)"
        case .contextDeallocated:
            return "Core Data Context가 해제되었습니다"
        case .unknown(let error):
            return "알 수 없는 에러: \(error.localizedDescription)"
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Repository Pattern 이해
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
/// 성능 고려사항:
/// - 모든 쿼리는 0.5초 이내 완료 목표
/// - 날짜 필드에 인덱스 필수
/// - 대량 데이터는 페이징 또는 제한 필요
/// - 백그라운드 컨텍스트 활용 (Core Data의 경우)
///
/// 사용 예시:
/// ```swift
/// let repository: BodyRepositoryProtocol = BodyRepository()
///
/// // 새 기록 저장
/// let entry = BodyCompositionEntry(weight: 70, bodyFatPercent: 18, muscleMass: 32)
/// let metabolism = MetabolismData(bmr: 1650, tdee: 2280, ...)
/// let saved = try await repository.save(entry: entry, metabolismData: metabolism)
///
/// // 최근 7일 데이터 조회
/// let recentEntries = try await repository.fetchRecent(days: 7)
///
/// // 기간별 통계
/// let stats = try await repository.fetchStatistics(from: startDate, to: endDate)
/// ```
///
/// 💡 Java Spring Data Repository와의 비교:
/// - Spring: @Repository 어노테이션, JpaRepository 상속
/// - Swift: Protocol로 인터페이스 정의, 명시적 구현
/// - Spring: 메서드 이름 규칙으로 자동 쿼리 생성
/// - Swift: 모든 메서드를 명시적으로 구현
///
