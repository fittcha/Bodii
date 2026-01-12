//
//  BodyQueryPerformanceTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Performance Testing
// 성능 요구사항을 검증하는 테스트 - 모든 쿼리는 0.5초 이내 완료
// 💡 Java 비교: JMH (Java Microbenchmark Harness)와 유사한 성능 벤치마킹

import XCTest
import CoreData
@testable import Bodii

/// BodyRepository 및 FetchBodyTrendsUseCase 성능 테스트
/// 📚 학습 포인트: Performance Testing Strategy
/// - 성능 요구사항: 모든 쿼리는 0.5초 이내 완료
/// - 대량 데이터 시나리오 테스트 (1000+ 레코드)
/// - 실제 사용 패턴 시뮬레이션
/// 💡 Java 비교: Spring Boot의 성능 테스트와 유사
///
/// 테스트 시나리오:
/// 1. 대량 데이터 조회 (<0.5초)
/// 2. 날짜 범위 쿼리 (<0.5초)
/// 3. 트렌드 데이터 변환 (<0.5초)
/// 4. 통계 계산 (<0.5초)
final class BodyQueryPerformanceTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Repository
    var repository: BodyRepository!

    /// 테스트 대상 Use Case
    var fetchTrendsUseCase: FetchBodyTrendsUseCase!

    /// 데이터 소스
    var dataSource: BodyLocalDataSource!

    /// 인메모리 Core Data 스택
    var testPersistenceController: PersistenceController!

    /// 성능 요구사항: 최대 허용 시간 (초)
    /// 📚 학습 포인트: Performance SLA (Service Level Agreement)
    /// - 0.5초 이내에 모든 쿼리 완료
    /// - 사용자 경험을 위한 응답 시간 목표
    let maxAllowedTime: TimeInterval = 0.5

    // MARK: - Setup & Teardown

    /// 각 테스트 실행 전 호출
    /// 📚 학습 포인트: Performance Test Setup
    /// - 대량 데이터 미리 생성
    /// - 실제 프로덕션 환경과 유사한 데이터셋 준비
    override func setUp() {
        super.setUp()

        // 인메모리 Core Data 스택 생성
        testPersistenceController = PersistenceController(inMemory: true)

        // 데이터 소스와 리포지토리 초기화
        dataSource = BodyLocalDataSource(persistenceController: testPersistenceController)
        repository = BodyRepository(localDataSource: dataSource)

        // Use Case 초기화
        fetchTrendsUseCase = FetchBodyTrendsUseCase(repository: repository)
    }

    /// 각 테스트 실행 후 호출
    override func tearDown() {
        fetchTrendsUseCase = nil
        repository = nil
        dataSource = nil
        testPersistenceController = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// 대량 테스트 데이터 생성
    /// 📚 학습 포인트: Test Data Generation
    /// - 실제와 유사한 패턴의 데이터 생성
    /// - 체중, 체지방률, 근육량의 점진적 변화 시뮬레이션
    ///
    /// - Parameter count: 생성할 레코드 수
    private func generateTestData(count: Int) async throws {
        let calendar = Calendar.current
        let today = Date()

        // 📚 학습 포인트: Realistic Data Generation
        // 실제 사용자의 데이터 변화 패턴을 시뮬레이션
        // - 체중: 70kg 기준 ±5kg 범위에서 점진적 변화
        // - 체지방률: 18% 기준 ±3% 범위에서 점진적 변화
        // - 근육량: 32kg 기준 ±2kg 범위에서 점진적 변화
        for i in 0..<count {
            let daysAgo = count - i - 1
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

            // 점진적 변화 시뮬레이션
            let weightChange = sin(Double(i) / 10.0) * 2.0  // ±2kg 변동
            let bodyFatChange = sin(Double(i) / 15.0) * 1.5  // ±1.5% 변동
            let muscleChange = cos(Double(i) / 12.0) * 1.0   // ±1kg 변동

            let entry = BodyCompositionEntry(
                date: date,
                weight: Decimal(70.0 + weightChange),
                bodyFatPercent: Decimal(18.0 + bodyFatChange),
                muscleMass: Decimal(32.0 + muscleChange)
            )

            let metabolism = MetabolismData(
                date: date,
                bmr: Decimal(1650.0),
                tdee: Decimal(2280.0),
                weight: entry.weight,
                bodyFatPercent: entry.bodyFatPercent,
                activityLevel: .moderatelyActive
            )

            _ = try await repository.save(entry: entry, metabolismData: metabolism)
        }
    }

    /// 성능 측정 헬퍼 메서드
    /// 📚 학습 포인트: Performance Measurement
    /// - 작업 실행 시간을 정밀하게 측정
    /// - 결과를 성능 요구사항과 비교
    ///
    /// - Parameter operation: 측정할 비동기 작업
    /// - Returns: 실행 시간 (초)
    private func measureTime(_ operation: () async throws -> Void) async rethrows -> TimeInterval {
        let startTime = Date()
        try await operation()
        let endTime = Date()
        return endTime.timeIntervalSince(startTime)
    }

    // MARK: - Large Dataset Query Tests

    /// 1000개 레코드 조회 성능 테스트
    /// 📚 학습 포인트: Large Dataset Performance
    /// - 요구사항: 1000+ 레코드 조회 <0.5초
    /// - 실제 사용: 3년간 매일 기록 시 약 1095개 레코드
    func testFetchAll_1000Records_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        // When: 전체 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetchAll()
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - fetchAll(1000): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "1000개 레코드 조회는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// 2000개 레코드 조회 성능 테스트
    /// 📚 학습 포인트: Stress Testing
    /// - 예상보다 많은 데이터에서도 성능 유지 확인
    /// - 실제 사용: 5년 이상 사용 시나리오
    func testFetchAll_2000Records_CompletesUnder500ms() async throws {
        // Given: 2000개의 레코드
        try await generateTestData(count: 2000)

        // When: 전체 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetchAll()
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - fetchAll(2000): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "2000개 레코드 조회는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    // MARK: - Date Range Query Tests

    /// 날짜 범위 쿼리 성능 테스트 - 7일
    /// 📚 학습 포인트: Indexed Query Performance
    /// - 요구사항: 날짜 범위 쿼리 <0.5초
    /// - 날짜 필드 인덱스 활용으로 빠른 조회
    /// - 실제 사용: 주간 트렌드 차트
    func testFetchDateRange_7Days_From1000Records_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!

        // When: 최근 7일 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetch(from: startDate, to: today)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - 7일 범위 쿼리(1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "7일 범위 쿼리는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// 날짜 범위 쿼리 성능 테스트 - 30일
    /// 📚 학습 포인트: Medium Range Query
    /// - 실제 사용: 월간 트렌드 차트
    func testFetchDateRange_30Days_From1000Records_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: today)!

        // When: 최근 30일 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetch(from: startDate, to: today)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - 30일 범위 쿼리(1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "30일 범위 쿼리는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// 날짜 범위 쿼리 성능 테스트 - 90일
    /// 📚 학습 포인트: Large Range Query
    /// - 실제 사용: 분기별 트렌드 차트
    /// - 가장 많은 데이터를 반환하는 쿼리
    func testFetchDateRange_90Days_From1000Records_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -90, to: today)!

        // When: 최근 90일 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetch(from: startDate, to: today)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - 90일 범위 쿼리(1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "90일 범위 쿼리는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// fetchRecent 메서드 성능 테스트
    /// 📚 학습 포인트: Convenience Method Performance
    func testFetchRecent_7Days_From1000Records_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        // When: 최근 7일 조회 (편의 메서드)
        let executionTime = await measureTime {
            _ = try await self.repository.fetchRecent(days: 7)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - fetchRecent(7일, 1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "fetchRecent(7일)는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    // MARK: - Trend Data Fetch Tests

    /// FetchBodyTrendsUseCase 성능 테스트 - 7일
    /// 📚 학습 포인트: Use Case Performance
    /// - 요구사항: 트렌드 데이터 준비 <0.5초
    /// - Repository 조회 + 데이터 변환 포함
    /// - 차트 렌더링에 바로 사용 가능한 형태로 변환
    func testFetchBodyTrends_Week_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let input = FetchBodyTrendsUseCase.Input(
            period: .week,
            includeMetabolismData: true
        )

        // When: 트렌드 데이터 조회 및 변환
        let executionTime = await measureTime {
            _ = try await self.fetchTrendsUseCase.execute(input: input)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - FetchBodyTrends(주간): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "주간 트렌드 조회는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// FetchBodyTrendsUseCase 성능 테스트 - 30일
    func testFetchBodyTrends_Month_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let input = FetchBodyTrendsUseCase.Input(
            period: .month,
            includeMetabolismData: true
        )

        // When: 트렌드 데이터 조회 및 변환
        let executionTime = await measureTime {
            _ = try await self.fetchTrendsUseCase.execute(input: input)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - FetchBodyTrends(월간): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "월간 트렌드 조회는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// FetchBodyTrendsUseCase 성능 테스트 - 90일
    /// 📚 학습 포인트: Worst Case Performance
    /// - 가장 많은 데이터를 처리하는 시나리오
    /// - 90일 × 1일 1회 = 약 90개 데이터 포인트 반환
    func testFetchBodyTrends_Quarter_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let input = FetchBodyTrendsUseCase.Input(
            period: .quarter,
            includeMetabolismData: true
        )

        // When: 트렌드 데이터 조회 및 변환
        let executionTime = await measureTime {
            _ = try await self.fetchTrendsUseCase.execute(input: input)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - FetchBodyTrends(분기): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "분기별 트렌드 조회는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// FetchBodyTrendsUseCase 성능 테스트 - Metabolism 데이터 제외
    /// 📚 학습 포인트: Performance Optimization
    /// - includeMetabolismData: false로 성능 최적화
    /// - 필요한 데이터만 로드하여 성능 향상
    func testFetchBodyTrends_WithoutMetabolism_IsFaster() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        // When: Metabolism 데이터 포함
        let inputWithMetabolism = FetchBodyTrendsUseCase.Input(
            period: .month,
            includeMetabolismData: true
        )
        let timeWithMetabolism = await measureTime {
            _ = try await self.fetchTrendsUseCase.execute(input: inputWithMetabolism)
        }

        // When: Metabolism 데이터 제외
        let inputWithoutMetabolism = FetchBodyTrendsUseCase.Input(
            period: .month,
            includeMetabolismData: false
        )
        let timeWithoutMetabolism = await measureTime {
            _ = try await self.fetchTrendsUseCase.execute(input: inputWithoutMetabolism)
        }

        // Then: 데이터 제외 시 더 빠르거나 비슷해야 함
        print("📊 성능 비교 - Metabolism 포함: \(String(format: "%.3f", timeWithMetabolism))초, 제외: \(String(format: "%.3f", timeWithoutMetabolism))초")
        XCTAssertLessThanOrEqual(
            timeWithoutMetabolism,
            timeWithMetabolism * 1.2,  // 최대 20% 더 느려도 허용 (측정 오차 고려)
            "Metabolism 데이터 제외 시 더 빠르거나 비슷해야 합니다"
        )

        // 둘 다 요구사항 충족
        XCTAssertLessThan(timeWithMetabolism, maxAllowedTime)
        XCTAssertLessThan(timeWithoutMetabolism, maxAllowedTime)
    }

    // MARK: - Statistics Query Tests

    /// 통계 계산 성능 테스트
    /// 📚 학습 포인트: Aggregate Query Performance
    /// - 요구사항: 통계 쿼리 <0.5초
    /// - NSExpression을 활용한 서버 사이드 집계
    /// - 평균, 최소, 최대 값 계산
    func testFetchStatistics_1000Records_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -90, to: today)!

        // When: 통계 계산
        let executionTime = await measureTime {
            _ = try await self.repository.fetchStatistics(from: startDate, to: today)
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - 통계 계산(90일, 1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "통계 계산은 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    // MARK: - Latest Record Query Tests

    /// 최신 레코드 조회 성능 테스트
    /// 📚 학습 포인트: Single Record Query Optimization
    /// - fetchLimit = 1로 최적화
    /// - 날짜 내림차순 정렬 + 인덱스 활용
    func testFetchLatest_1000Records_CompletesUnder100ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        // When: 최신 레코드 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetchLatest()
        }

        // Then: 0.1초 이내 완료 (단일 레코드이므로 더 빠른 목표)
        print("📊 성능 측정 - fetchLatest(1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            0.1,  // 단일 레코드 조회는 더 빠른 목표
            "최신 레코드 조회는 0.1초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    /// ID로 조회 성능 테스트
    /// 📚 학습 포인트: Primary Key Query Performance
    /// - UUID primary key 조회는 매우 빠름
    /// - 인덱스를 활용한 O(log n) 성능
    func testFetchById_1000Records_CompletesUnder100ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        // 중간에 있는 레코드 ID 가져오기
        let allEntries = try await repository.fetchAll()
        guard let targetId = allEntries[allEntries.count / 2].id else {
            XCTFail("테스트 데이터에 ID가 없습니다")
            return
        }

        // When: ID로 조회
        let executionTime = await measureTime {
            _ = try await self.repository.fetch(by: targetId)
        }

        // Then: 0.1초 이내 완료
        print("📊 성능 측정 - fetchById(1000개 중): \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            0.1,
            "ID 조회는 0.1초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    // MARK: - Chart Data Preparation Tests

    /// 차트 데이터 준비 전체 플로우 성능 테스트
    /// 📚 학습 포인트: End-to-End Performance
    /// - 실제 UI 렌더링 시나리오 시뮬레이션
    /// - Repository 조회 + Use Case 변환 + 통계 계산
    func testChartDataPreparation_CompletesUnder500ms() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: today)!

        // When: 차트에 필요한 모든 데이터 준비
        let executionTime = await measureTime {
            // 1. 트렌드 데이터 조회
            let input = FetchBodyTrendsUseCase.Input(
                period: .month,
                includeMetabolismData: true
            )
            let trendsOutput = try await self.fetchTrendsUseCase.execute(input: input)

            // 2. 통계 데이터 조회
            _ = try await self.repository.fetchStatistics(from: startDate, to: today)

            // 3. 최신 레코드 조회
            _ = try await self.repository.fetchLatest()

            // 📚 학습 포인트: Data Validation
            // 차트에 표시할 데이터가 올바르게 준비되었는지 확인
            XCTAssertFalse(trendsOutput.dataPoints.isEmpty, "데이터 포인트가 존재해야 합니다")
        }

        // Then: 0.5초 이내 완료
        print("📊 성능 측정 - 차트 데이터 전체 준비: \(String(format: "%.3f", executionTime))초")
        XCTAssertLessThan(
            executionTime,
            maxAllowedTime,
            "차트 데이터 준비는 \(maxAllowedTime)초 이내에 완료되어야 합니다. 실제: \(String(format: "%.3f", executionTime))초"
        )
    }

    // MARK: - XCTest Performance Measurement

    /// XCTest의 measure 블록을 사용한 성능 측정
    /// 📚 학습 포인트: XCTest Performance Metrics
    /// - 여러 번 실행하여 평균, 표준편차 측정
    /// - Xcode에서 baseline 설정 가능
    /// - CI/CD 파이프라인에서 성능 회귀 감지
    func testPerformance_FetchTrends_Month() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let input = FetchBodyTrendsUseCase.Input(
            period: .month,
            includeMetabolismData: true
        )

        // When & Then: 성능 측정 (10회 반복)
        measure {
            let expectation = self.expectation(description: "Fetch trends")

            Task {
                _ = try await self.fetchTrendsUseCase.execute(input: input)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }

    /// XCTest measure를 사용한 날짜 범위 쿼리 성능 측정
    func testPerformance_FetchDateRange_90Days() async throws {
        // Given: 1000개의 레코드
        try await generateTestData(count: 1000)

        let calendar = Calendar.current
        let today = Date()
        let startDate = calendar.date(byAdding: .day, value: -90, to: today)!

        // When & Then: 성능 측정 (10회 반복)
        measure {
            let expectation = self.expectation(description: "Fetch date range")

            Task {
                _ = try await self.repository.fetch(from: startDate, to: today)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Performance Test 작성 가이드
///
/// 성능 테스트의 목적:
/// - 성능 요구사항 검증 (모든 쿼리 <0.5초)
/// - 대량 데이터에서의 성능 확인
/// - 성능 회귀 방지
///
/// 테스트 전략:
/// 1. Large Dataset Tests
///    - 1000+ 레코드로 실제 프로덕션 환경 시뮬레이션
///    - 3년 이상 사용 시나리오
///
/// 2. Date Range Query Tests
///    - 7/30/90일 범위 쿼리 성능
///    - 인덱스 활용 확인
///    - 트렌드 차트 렌더링 시나리오
///
/// 3. Use Case Performance Tests
///    - Repository 조회 + 데이터 변환 전체 플로우
///    - 차트에 바로 사용 가능한 형태로 변환
///
/// 4. Statistics Query Tests
///    - NSExpression을 활용한 서버 사이드 집계
///    - 평균, 최소, 최대 계산
///
/// 5. End-to-End Tests
///    - 실제 UI 렌더링 시나리오
///    - 여러 쿼리를 조합한 전체 플로우
///
/// 성능 최적화 포인트:
/// - 날짜 필드 인덱스 활용
/// - fetchLimit으로 결과 제한
/// - 백그라운드 컨텍스트로 쓰기 작업
/// - ViewContext로 읽기 작업
/// - includeMetabolismData 플래그로 선택적 로딩
///
/// 성능 측정 방법:
/// 1. 커스텀 measureTime() 헬퍼
///    - 단일 실행 시간 정밀 측정
///    - 성능 요구사항과 직접 비교
///
/// 2. XCTest measure 블록
///    - 여러 번 실행하여 평균/표준편차 계산
///    - Xcode baseline 설정
///    - CI/CD 성능 회귀 감지
///
/// 💡 실무 팁:
/// - 인메모리 Core Data로 테스트 속도 향상
/// - 실제 데이터 패턴 시뮬레이션 (점진적 변화)
/// - 성능 목표를 명확히 설정 (0.5초)
/// - 테스트 실패 시 실제 시간 출력
/// - CI에서 정기적으로 실행하여 회귀 방지
///
/// 💡 Java 비교:
/// - JMH: Java Microbenchmark Harness
/// - Spring Boot Test의 @Sql로 대량 데이터 생성
/// - JUnit의 @Timeout으로 성능 요구사항 검증
///
/// 성능 요구사항 달성 전략:
/// 1. 데이터베이스 최적화
///    - 날짜 필드 인덱스 (Core Data 모델에 설정)
///    - fetchLimit 활용
///    - NSPredicate 최적화
///
/// 2. 컨텍스트 관리
///    - ViewContext: 읽기 (UI 스레드)
///    - BackgroundContext: 쓰기 (백그라운드)
///
/// 3. 쿼리 최적화
///    - 필요한 데이터만 조회
///    - 서버 사이드 집계 (NSExpression)
///    - 정렬과 제한을 쿼리에 포함
///
/// 4. 데이터 변환 최적화
///    - 메모리 효율적인 매핑
///    - 불필요한 복사 최소화
