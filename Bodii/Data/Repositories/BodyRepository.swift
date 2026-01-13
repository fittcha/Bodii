//
//  BodyRepository.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Repository Implementation
// Repository 패턴의 구현체 - 데이터 소스를 추상화하여 도메인 레이어에 제공
// 💡 Java 비교: Spring Data JPA의 Repository 구현체와 유사

import Foundation

// MARK: - BodyRepository

/// BodyRepositoryProtocol의 구현체
/// 로컬 데이터 소스(Core Data)를 사용하여 신체 구성 데이터를 관리합니다.
/// 📚 학습 포인트: Clean Architecture - Data Layer
/// - Protocol로 정의된 인터페이스를 구현
/// - Local Data Source를 사용하여 실제 데이터 작업 수행
/// - Mapper를 통해 Domain Entity와 Data Entity 변환
/// - 에러를 Domain 레이어의 에러로 변환
/// 💡 Java 비교: @Repository 어노테이션이 붙은 구현 클래스와 유사
final class BodyRepository: BodyRepositoryProtocol {

    // MARK: - Properties

    /// 로컬 데이터 소스 (Core Data 작업 담당)
    /// 📚 학습 포인트: Dependency Injection
    /// - 외부에서 주입받아 사용
    /// - 테스트 시 Mock 객체로 교체 가능
    /// 💡 Java 비교: @Autowired private BodyLocalDataSource 와 유사
    private let localDataSource: BodyLocalDataSource

    // MARK: - Initialization

    /// BodyRepository 초기화
    /// 📚 학습 포인트: Constructor Injection
    /// - 의존성을 생성자를 통해 주입받음
    /// - 기본값으로 실제 구현체 사용
    /// - 테스트 시 Mock 주입 가능
    /// 💡 Java 비교: @Autowired 생성자 주입과 유사
    ///
    /// - Parameter localDataSource: 로컬 데이터 소스 (기본값: 새 인스턴스)
    init(localDataSource: BodyLocalDataSource = BodyLocalDataSource()) {
        self.localDataSource = localDataSource
    }

    // MARK: - Create

    /// 새로운 신체 구성 기록을 저장합니다.
    /// 📚 학습 포인트: Error Handling
    /// - Data Source의 에러를 Repository 에러로 변환
    /// - 도메인 레이어가 infrastructure 에러를 알 필요 없음
    /// 💡 Java 비교: @Transactional 메서드와 유사한 동작
    ///
    /// - Parameters:
    ///   - entry: 저장할 신체 구성 데이터
    ///   - metabolismData: 함께 저장할 대사율 데이터
    /// - Returns: 저장된 신체 구성 데이터 (ID가 할당됨)
    /// - Throws: RepositoryError - 저장 실패 시
    func save(entry: BodyCompositionEntry, metabolismData: MetabolismData) async throws -> BodyCompositionEntry {
        do {
            // 📚 학습 포인트: Async/Await Chain
            // Local Data Source의 비동기 메서드를 호출하고 결과 반환
            return try await localDataSource.save(entry: entry, metabolismData: metabolismData)
        } catch {
            // 📚 학습 포인트: Error Transformation
            // Infrastructure 에러를 Domain 에러로 변환
            throw RepositoryError.saveFailed(error.localizedDescription)
        }
    }

    // MARK: - Read (Single)

    /// ID로 특정 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Optional Result
    /// - 데이터가 없으면 nil 반환 (에러가 아님)
    /// - 에러는 예외 상황 (DB 접근 실패 등)
    ///
    /// - Parameter id: 조회할 기록의 고유 식별자
    /// - Returns: 신체 구성 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetch(by id: UUID) async throws -> BodyCompositionEntry? {
        do {
            return try await localDataSource.fetch(by: id)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    /// 특정 날짜의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Business Logic Delegation
    /// - 날짜 범위 계산 등의 로직은 Data Source에 위임
    /// - Repository는 단순히 중계 역할
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 신체 구성 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetch(for date: Date) async throws -> BodyCompositionEntry? {
        do {
            return try await localDataSource.fetch(for: date)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    /// 가장 최근의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Common Query Pattern
    /// - 대시보드나 현재 상태 표시에 자주 사용
    /// - 데이터 소스의 최적화된 쿼리 활용
    ///
    /// - Returns: 가장 최근 신체 구성 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchLatest() async throws -> BodyCompositionEntry? {
        do {
            return try await localDataSource.fetchLatest()
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Read (Multiple)

    /// 모든 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Collection Return
    /// - 빈 배열도 정상적인 결과 (nil이 아님)
    /// - 데이터가 많을 경우 성능 이슈 가능성
    ///
    /// - Returns: 모든 신체 구성 데이터 배열 (비어있을 수 있음)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchAll() async throws -> [BodyCompositionEntry] {
        do {
            return try await localDataSource.fetchAll()
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    /// 지정된 기간의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Date Range Query
    /// - 트렌드 차트를 위한 핵심 쿼리
    /// - 시작/종료 날짜를 모두 포함하는 범위
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (inclusive)
    ///   - endDate: 조회 종료 날짜 (inclusive)
    /// - Returns: 기간 내 신체 구성 데이터 배열 (날짜 오름차순)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetch(from startDate: Date, to endDate: Date) async throws -> [BodyCompositionEntry] {
        do {
            return try await localDataSource.fetch(from: startDate, to: endDate)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

    /// 최근 N일간의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Convenience Method
    /// - fetch(from:to:)의 편의 메서드
    /// - 자주 사용되는 패턴을 간단히 표현
    ///
    /// - Parameter days: 조회할 일수 (예: 7, 30, 90)
    /// - Returns: 최근 N일간의 신체 구성 데이터 배열 (날짜 오름차순)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchRecent(days: Int) async throws -> [BodyCompositionEntry] {
        do {
            return try await localDataSource.fetchRecent(days: days)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

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
    /// - Throws: RepositoryError - 수정 실패 시
    func update(entry: BodyCompositionEntry, metabolismData: MetabolismData) async throws -> BodyCompositionEntry {
        do {
            return try await localDataSource.update(entry: entry, metabolismData: metabolismData)
        } catch {
            // 📚 학습 포인트: Specific Error Handling
            // 에러 메시지에서 "찾을 수 없습니다" 문자열이 있으면 notFound 에러로 변환
            if error.localizedDescription.contains("찾을 수 없습니다") {
                throw RepositoryError.notFound(entry.id)
            }
            throw RepositoryError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete

    /// 특정 신체 구성 기록을 삭제합니다.
    /// 📚 학습 포인트: Cascade Delete
    /// - 연관된 MetabolismData도 함께 삭제
    /// - Core Data 모델에서 cascade rule 설정됨
    ///
    /// - Parameter id: 삭제할 기록의 고유 식별자
    /// - Throws: RepositoryError - 삭제 실패 시
    func delete(by id: UUID) async throws {
        do {
            try await localDataSource.delete(by: id)
        } catch {
            // 📚 학습 포인트: Specific Error Handling
            // 에러 메시지에서 "찾을 수 없습니다" 문자열이 있으면 notFound 에러로 변환
            if error.localizedDescription.contains("찾을 수 없습니다") {
                throw RepositoryError.notFound(id)
            }
            throw RepositoryError.deleteFailed(error.localizedDescription)
        }
    }

    /// 모든 신체 구성 기록을 삭제합니다.
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

    // MARK: - Metabolism Data

    /// 특정 신체 구성 기록과 연결된 대사율 데이터를 조회합니다.
    /// 📚 학습 포인트: Related Entity Query
    /// - 1:1 관계의 연관 엔티티 조회
    /// - 히스토리컬 BMR/TDEE 트래킹에 사용
    ///
    /// - Parameter bodyEntryId: 신체 구성 기록 ID
    /// - Returns: 연결된 대사율 데이터 (없으면 nil)
    /// - Throws: RepositoryError - 조회 실패 시
    func fetchMetabolismData(for bodyEntryId: UUID) async throws -> MetabolismData? {
        do {
            return try await localDataSource.fetchMetabolismData(for: bodyEntryId)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }

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
    func fetchStatistics(from startDate: Date, to endDate: Date) async throws -> BodyCompositionStatistics {
        do {
            return try await localDataSource.fetchStatistics(from: startDate, to: endDate)
        } catch {
            throw RepositoryError.fetchFailed(error.localizedDescription)
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Repository Pattern Implementation 이해
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
/// Domain Layer (Use Cases) ← BodyRepositoryProtocol (Interface)
///        ↓
/// Data Layer (Repository) ← BodyRepository (Implementation)
///        ↓
/// Data Layer (Data Source) ← BodyLocalDataSource
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
/// 향후 확장 가능성:
/// - Remote Data Source 추가 (서버 동기화)
/// - Cache Layer 추가 (메모리 캐싱)
/// - Offline-first 전략 구현
/// - Conflict Resolution (충돌 해결)
///
/// 사용 예시:
/// ```swift
/// // DI Container에서 주입
/// let repository: BodyRepositoryProtocol = BodyRepository()
///
/// // Use Case에서 사용
/// let entry = BodyCompositionEntry(weight: 70, bodyFatPercent: 18, muscleMass: 32)
/// let metabolism = MetabolismData(bmr: 1650, tdee: 2280, ...)
/// let saved = try await repository.save(entry: entry, metabolismData: metabolism)
///
/// // ViewModel에서 사용
/// let recent = try await repository.fetchRecent(days: 7)
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
