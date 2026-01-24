//
//  BodyRepositoryTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Integration Testing
// 데이터 레이어의 통합 테스트 - Repository와 Data Source를 함께 테스트
// 💡 Java 비교: @DataJpaTest와 유사한 통합 테스트

import XCTest
import CoreData
@testable import Bodii

/// BodyRepository와 BodyLocalDataSource의 통합 테스트
/// 📚 학습 포인트: Integration Test vs Unit Test
/// - Unit Test: 개별 컴포넌트를 Mock과 함께 테스트
/// - Integration Test: 여러 컴포넌트가 함께 작동하는지 테스트
/// 💡 Java 비교: JUnit + @DataJpaTest와 유사
final class BodyRepositoryTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Repository
    /// 📚 학습 포인트: System Under Test (SUT)
    var sut: BodyRepository!

    /// 테스트용 Data Source
    var dataSource: BodyLocalDataSource!

    /// 테스트용 Persistence Controller (인메모리)
    /// 📚 학습 포인트: In-Memory Core Data Stack
    /// - 실제 디스크에 저장하지 않고 메모리에서만 동작
    /// - 테스트 간 격리 보장 (독립성)
    /// - 빠른 실행 속도
    var testPersistenceController: PersistenceController!

    // MARK: - Setup & Teardown

    /// 각 테스트 실행 전 호출
    /// 📚 학습 포인트: Test Setup
    /// - 각 테스트마다 깨끗한 상태로 시작
    /// - 테스트 간 의존성 제거
    override func setUp() {
        super.setUp()

        // 📚 학습 포인트: In-Memory Store for Testing
        // 인메모리 Core Data 스택 생성
        testPersistenceController = PersistenceController(inMemory: true)

        // 데이터 소스와 리포지토리 초기화
        dataSource = BodyLocalDataSource(persistenceController: testPersistenceController)
        sut = BodyRepository(localDataSource: dataSource)
    }

    /// 각 테스트 실행 후 호출
    /// 📚 학습 포인트: Test Teardown
    /// - 메모리 정리
    /// - 다음 테스트를 위한 준비
    override func tearDown() {
        sut = nil
        dataSource = nil
        testPersistenceController = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// 테스트용 BodyCompositionEntry 생성
    /// 📚 학습 포인트: Test Helper Method
    /// - 테스트 데이터 생성 로직을 재사용
    /// - 가독성 향상
    private func makeTestEntry(
        date: Date = Date(),
        weight: Decimal = 70.0,
        bodyFatPercent: Decimal = 18.0,
        muscleMass: Decimal = 32.0
    ) -> BodyCompositionEntry {
        return BodyCompositionEntry(
            date: date,
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            muscleMass: muscleMass
        )
    }

    /// 테스트용 MetabolismData 생성
    private func makeTestMetabolismData(
        date: Date = Date(),
        bmr: Decimal = 1650.0,
        tdee: Decimal = 2280.0,
        weight: Decimal = 70.0,
        bodyFatPercent: Decimal = 18.0,
        activityLevel: ActivityLevel = .moderatelyActive
    ) -> MetabolismData {
        return MetabolismData(
            date: date,
            bmr: bmr,
            tdee: tdee,
            weight: weight,
            bodyFatPercent: bodyFatPercent,
            activityLevel: activityLevel
        )
    }

    // MARK: - Create Tests

    /// 저장 - 정상 케이스
    /// 📚 학습 포인트: Async Test
    /// - async/await를 사용하는 메서드 테스트
    /// - XCTest의 async throws 지원
    func testSave_ValidData_SavesSuccessfully() async throws {
        // Given: 유효한 신체 구성 데이터와 대사율 데이터
        let entry = makeTestEntry()
        let metabolismData = makeTestMetabolismData()

        // When: 저장 실행
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolismData)

        // Then: 저장 성공
        XCTAssertNotNil(savedEntry, "저장된 엔트리가 nil이 아니어야 합니다")
        XCTAssertEqual(savedEntry.weight, entry.weight, "체중이 일치해야 합니다")
        XCTAssertEqual(savedEntry.bodyFatPercent, entry.bodyFatPercent, "체지방률이 일치해야 합니다")
        XCTAssertEqual(savedEntry.muscleMass, entry.muscleMass, "근육량이 일치해야 합니다")
    }

    /// 저장 후 조회 - 데이터 영속성 확인
    /// 📚 학습 포인트: Data Persistence Verification
    /// - 저장된 데이터가 실제로 조회되는지 확인
    func testSave_ThenFetch_DataPersists() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry()
        let metabolismData = makeTestMetabolismData()
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolismData)

        // When: ID로 조회
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)

        // Then: 조회 성공 및 데이터 일치
        XCTAssertNotNil(fetchedEntry, "저장된 데이터를 조회할 수 있어야 합니다")
        XCTAssertEqual(fetchedEntry?.id, savedEntry.id, "ID가 일치해야 합니다")
        XCTAssertEqual(fetchedEntry?.weight, entry.weight, "체중이 일치해야 합니다")
    }

    /// MetabolismSnapshot 자동 생성 확인
    /// 📚 학습 포인트: Relationship Testing
    /// - 1:1 관계가 올바르게 생성되는지 확인
    func testSave_CreatesMetabolismSnapshot() async throws {
        // Given: 신체 구성 데이터와 대사율 데이터
        let entry = makeTestEntry()
        let metabolismData = makeTestMetabolismData(
            bmr: 1650.0,
            tdee: 2280.0,
            activityLevel: .moderatelyActive
        )

        // When: 저장
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolismData)

        // Then: MetabolismSnapshot 조회 가능
        let fetchedMetabolism = try await sut.fetchMetabolismData(for: savedEntry.id)
        XCTAssertNotNil(fetchedMetabolism, "대사율 데이터가 저장되어야 합니다")
        XCTAssertEqual(fetchedMetabolism?.bmr, 1650.0, accuracy: 0.01, "BMR이 일치해야 합니다")
        XCTAssertEqual(fetchedMetabolism?.tdee, 2280.0, accuracy: 0.01, "TDEE가 일치해야 합니다")
        XCTAssertEqual(fetchedMetabolism?.activityLevel, .moderatelyActive, "활동 수준이 일치해야 합니다")
    }

    // MARK: - Read Tests (Single)

    /// ID로 조회 - 존재하는 데이터
    func testFetchById_ExistingData_ReturnsEntry() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry()
        let metabolismData = makeTestMetabolismData()
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolismData)

        // When: ID로 조회
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)

        // Then: 데이터 반환
        XCTAssertNotNil(fetchedEntry)
        XCTAssertEqual(fetchedEntry?.id, savedEntry.id)
    }

    /// ID로 조회 - 존재하지 않는 데이터
    func testFetchById_NonExistingData_ReturnsNil() async throws {
        // Given: 저장되지 않은 ID
        let nonExistingId = UUID()

        // When: 조회
        let fetchedEntry = try await sut.fetch(by: nonExistingId)

        // Then: nil 반환
        XCTAssertNil(fetchedEntry, "존재하지 않는 ID는 nil을 반환해야 합니다")
    }

    /// 날짜로 조회 - 해당 날짜 데이터 존재
    func testFetchByDate_ExistingData_ReturnsEntry() async throws {
        // Given: 특정 날짜의 데이터 저장
        let calendar = Calendar.current
        let testDate = calendar.startOfDay(for: Date())
        let entry = makeTestEntry(date: testDate)
        let metabolismData = makeTestMetabolismData(date: testDate)

        _ = try await sut.save(entry: entry, metabolismData: metabolismData)

        // When: 날짜로 조회
        let fetchedEntry = try await sut.fetch(for: testDate)

        // Then: 데이터 반환
        XCTAssertNotNil(fetchedEntry, "해당 날짜의 데이터를 찾을 수 있어야 합니다")

        // 📚 학습 포인트: Date Comparison
        // 같은 날짜인지 확인 (시간 부분 제외)
        let fetchedDateComponents = calendar.dateComponents([.year, .month, .day], from: fetchedEntry!.date)
        let testDateComponents = calendar.dateComponents([.year, .month, .day], from: testDate)
        XCTAssertEqual(fetchedDateComponents, testDateComponents, "날짜가 일치해야 합니다")
    }

    /// 최신 데이터 조회
    func testFetchLatest_MultipleEntries_ReturnsLatest() async throws {
        // Given: 여러 날짜의 데이터 저장
        let calendar = Calendar.current
        let today = Date()

        // 3일 전 데이터
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let entry1 = makeTestEntry(date: threeDaysAgo, weight: 71.0)
        let metabolism1 = makeTestMetabolismData(date: threeDaysAgo)
        _ = try await sut.save(entry: entry1, metabolismData: metabolism1)

        // 1일 전 데이터
        let oneDayAgo = calendar.date(byAdding: .day, value: -1, to: today)!
        let entry2 = makeTestEntry(date: oneDayAgo, weight: 70.0)
        let metabolism2 = makeTestMetabolismData(date: oneDayAgo)
        _ = try await sut.save(entry: entry2, metabolismData: metabolism2)

        // 오늘 데이터 (가장 최신)
        let entry3 = makeTestEntry(date: today, weight: 69.0)
        let metabolism3 = makeTestMetabolismData(date: today)
        _ = try await sut.save(entry: entry3, metabolismData: metabolism3)

        // When: 최신 데이터 조회
        let latestEntry = try await sut.fetchLatest()

        // Then: 가장 최신 데이터 반환
        XCTAssertNotNil(latestEntry, "최신 데이터를 조회할 수 있어야 합니다")
        XCTAssertEqual(latestEntry?.weight, 69.0, "가장 최신 데이터가 반환되어야 합니다")
    }

    /// 최신 데이터 조회 - 데이터 없음
    func testFetchLatest_NoData_ReturnsNil() async throws {
        // Given: 저장된 데이터 없음

        // When: 최신 데이터 조회
        let latestEntry = try await sut.fetchLatest()

        // Then: nil 반환
        XCTAssertNil(latestEntry, "데이터가 없으면 nil을 반환해야 합니다")
    }

    // MARK: - Read Tests (Multiple)

    /// 모든 데이터 조회
    func testFetchAll_MultipleEntries_ReturnsAll() async throws {
        // Given: 여러 데이터 저장
        let entry1 = makeTestEntry(weight: 70.0)
        let metabolism1 = makeTestMetabolismData()
        let entry2 = makeTestEntry(weight: 71.0)
        let metabolism2 = makeTestMetabolismData()
        let entry3 = makeTestEntry(weight: 72.0)
        let metabolism3 = makeTestMetabolismData()

        _ = try await sut.save(entry: entry1, metabolismData: metabolism1)
        _ = try await sut.save(entry: entry2, metabolismData: metabolism2)
        _ = try await sut.save(entry: entry3, metabolismData: metabolism3)

        // When: 모든 데이터 조회
        let allEntries = try await sut.fetchAll()

        // Then: 3개의 데이터 반환
        XCTAssertEqual(allEntries.count, 3, "3개의 데이터를 반환해야 합니다")
    }

    /// 모든 데이터 조회 - 데이터 없음
    func testFetchAll_NoData_ReturnsEmptyArray() async throws {
        // Given: 저장된 데이터 없음

        // When: 모든 데이터 조회
        let allEntries = try await sut.fetchAll()

        // Then: 빈 배열 반환
        XCTAssertTrue(allEntries.isEmpty, "데이터가 없으면 빈 배열을 반환해야 합니다")
    }

    /// 날짜 범위 조회
    /// 📚 학습 포인트: Date Range Query Testing
    /// - 트렌드 차트의 핵심 기능
    func testFetchDateRange_ReturnsEntriesInRange() async throws {
        // Given: 7일간의 데이터 저장
        let calendar = Calendar.current
        let today = Date()

        for daysAgo in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let entry = makeTestEntry(date: date, weight: Decimal(70 + daysAgo))
            let metabolism = makeTestMetabolismData(date: date)
            _ = try await sut.save(entry: entry, metabolismData: metabolism)
        }

        // When: 최근 3일간의 데이터 조회
        let startDate = calendar.date(byAdding: .day, value: -2, to: today)!
        let endDate = today
        let entries = try await sut.fetch(from: startDate, to: endDate)

        // Then: 3개의 데이터 반환 (0일 전, 1일 전, 2일 전)
        XCTAssertEqual(entries.count, 3, "3일간의 데이터를 반환해야 합니다")

        // 📚 학습 포인트: 날짜 오름차순 정렬 확인
        // Swift Charts에서 사용하기 위해 오름차순 정렬 필요
        for i in 0..<(entries.count - 1) {
            XCTAssertLessThanOrEqual(entries[i].date, entries[i + 1].date,
                                    "날짜가 오름차순으로 정렬되어야 합니다")
        }
    }

    /// 최근 N일 조회
    func testFetchRecent_ReturnsDaysOfData() async throws {
        // Given: 30일간의 데이터 저장
        let calendar = Calendar.current
        let today = Date()

        for daysAgo in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let entry = makeTestEntry(date: date)
            let metabolism = makeTestMetabolismData(date: date)
            _ = try await sut.save(entry: entry, metabolismData: metabolism)
        }

        // When: 최근 7일 조회
        let recentEntries = try await sut.fetchRecent(days: 7)

        // Then: 7일 이내의 데이터만 반환
        XCTAssertLessThanOrEqual(recentEntries.count, 8, "최대 7-8일의 데이터를 반환해야 합니다")

        // 모든 데이터가 7일 이내인지 확인
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        for entry in recentEntries {
            XCTAssertGreaterThanOrEqual(entry.date, sevenDaysAgo,
                                       "모든 데이터가 7일 이내여야 합니다")
        }
    }

    // MARK: - Update Tests

    /// 업데이트 - 정상 케이스
    func testUpdate_ExistingEntry_UpdatesSuccessfully() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry(weight: 70.0)
        let metabolism = makeTestMetabolismData()
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)

        // When: 체중 수정
        let updatedEntry = BodyCompositionEntry(
            id: savedEntry.id,
            date: savedEntry.date,
            weight: 69.5,  // 수정된 값
            bodyFatPercent: savedEntry.bodyFatPercent,
            muscleMass: savedEntry.muscleMass
        )
        let updatedMetabolism = makeTestMetabolismData(weight: 69.5)

        let result = try await sut.update(entry: updatedEntry, metabolismData: updatedMetabolism)

        // Then: 업데이트 성공
        XCTAssertEqual(result.weight, 69.5, "체중이 업데이트되어야 합니다")

        // 조회하여 확인
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)
        XCTAssertEqual(fetchedEntry?.weight, 69.5, "조회한 데이터도 업데이트되어야 합니다")
    }

    /// 업데이트 - 존재하지 않는 데이터
    func testUpdate_NonExistingEntry_ThrowsError() async throws {
        // Given: 존재하지 않는 ID
        let nonExistingEntry = makeTestEntry()
        let metabolism = makeTestMetabolismData()

        // When/Then: 에러 발생
        do {
            _ = try await sut.update(entry: nonExistingEntry, metabolismData: metabolism)
            XCTFail("존재하지 않는 데이터 업데이트 시 에러가 발생해야 합니다")
        } catch let error as RepositoryError {
            // 📚 학습 포인트: Error Type Checking
            // 특정 에러 타입이 발생하는지 확인
            if case .notFound = error {
                // 예상된 에러
            } else if case .updateFailed = error {
                // updateFailed도 허용 (구현에 따라)
            } else {
                XCTFail("notFound 또는 updateFailed 에러가 발생해야 합니다")
            }
        } catch {
            XCTFail("RepositoryError 타입의 에러가 발생해야 합니다")
        }
    }

    /// MetabolismData도 함께 업데이트
    func testUpdate_UpdatesMetabolismDataToo() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry()
        let metabolism = makeTestMetabolismData(bmr: 1650.0, tdee: 2280.0)
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)

        // When: 대사율 데이터 수정
        let updatedEntry = savedEntry
        let updatedMetabolism = makeTestMetabolismData(
            date: metabolism.date,
            bmr: 1700.0,  // 수정된 BMR
            tdee: 2340.0,  // 수정된 TDEE
            weight: entry.weight,
            bodyFatPercent: entry.bodyFatPercent
        )

        _ = try await sut.update(entry: updatedEntry, metabolismData: updatedMetabolism)

        // Then: 대사율 데이터도 업데이트
        let fetchedMetabolism = try await sut.fetchMetabolismData(for: savedEntry.id)
        XCTAssertEqual(fetchedMetabolism?.bmr, 1700.0, accuracy: 0.01, "BMR이 업데이트되어야 합니다")
        XCTAssertEqual(fetchedMetabolism?.tdee, 2340.0, accuracy: 0.01, "TDEE가 업데이트되어야 합니다")
    }

    // MARK: - Delete Tests

    /// 삭제 - 정상 케이스
    func testDelete_ExistingEntry_DeletesSuccessfully() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry()
        let metabolism = makeTestMetabolismData()
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)

        // When: 삭제
        try await sut.delete(by: savedEntry.id)

        // Then: 조회 시 nil 반환
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)
        XCTAssertNil(fetchedEntry, "삭제된 데이터는 조회되지 않아야 합니다")
    }

    /// 삭제 - 존재하지 않는 데이터
    func testDelete_NonExistingEntry_ThrowsError() async throws {
        // Given: 존재하지 않는 ID
        let nonExistingId = UUID()

        // When/Then: 에러 발생
        do {
            try await sut.delete(by: nonExistingId)
            XCTFail("존재하지 않는 데이터 삭제 시 에러가 발생해야 합니다")
        } catch let error as RepositoryError {
            if case .notFound = error {
                // 예상된 에러
            } else if case .deleteFailed = error {
                // deleteFailed도 허용 (구현에 따라)
            } else {
                XCTFail("notFound 또는 deleteFailed 에러가 발생해야 합니다")
            }
        } catch {
            XCTFail("RepositoryError 타입의 에러가 발생해야 합니다")
        }
    }

    /// 삭제 시 MetabolismSnapshot도 함께 삭제 (Cascade Delete)
    /// 📚 학습 포인트: Cascade Delete Testing
    /// - 관계된 엔티티도 함께 삭제되는지 확인
    func testDelete_AlsoDeletesMetabolismSnapshot() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry()
        let metabolism = makeTestMetabolismData()
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)

        // MetabolismData 존재 확인
        let metabolismBeforeDelete = try await sut.fetchMetabolismData(for: savedEntry.id)
        XCTAssertNotNil(metabolismBeforeDelete, "삭제 전에는 대사율 데이터가 존재해야 합니다")

        // When: BodyRecord 삭제
        try await sut.delete(by: savedEntry.id)

        // Then: MetabolismSnapshot도 삭제됨
        let metabolismAfterDelete = try await sut.fetchMetabolismData(for: savedEntry.id)
        XCTAssertNil(metabolismAfterDelete, "삭제 후에는 대사율 데이터도 함께 삭제되어야 합니다")
    }

    /// 전체 삭제
    func testDeleteAll_RemovesAllEntries() async throws {
        // Given: 여러 데이터 저장
        for i in 0..<5 {
            let entry = makeTestEntry(weight: Decimal(70 + i))
            let metabolism = makeTestMetabolismData()
            _ = try await sut.save(entry: entry, metabolismData: metabolism)
        }

        // 저장 확인
        let allEntriesBeforeDelete = try await sut.fetchAll()
        XCTAssertEqual(allEntriesBeforeDelete.count, 5, "5개의 데이터가 저장되어야 합니다")

        // When: 전체 삭제
        try await sut.deleteAll()

        // Then: 모든 데이터 삭제
        let allEntriesAfterDelete = try await sut.fetchAll()
        XCTAssertTrue(allEntriesAfterDelete.isEmpty, "모든 데이터가 삭제되어야 합니다")
    }

    // MARK: - Statistics Tests

    /// 통계 조회
    /// 📚 학습 포인트: Aggregate Query Testing
    func testFetchStatistics_ReturnsCorrectAggregates() async throws {
        // Given: 여러 데이터 저장 (체중: 68, 70, 72kg)
        let calendar = Calendar.current
        let today = Date()

        let date1 = calendar.date(byAdding: .day, value: -2, to: today)!
        let entry1 = makeTestEntry(date: date1, weight: 68.0, bodyFatPercent: 17.0)
        let metabolism1 = makeTestMetabolismData(date: date1)
        _ = try await sut.save(entry: entry1, metabolismData: metabolism1)

        let date2 = calendar.date(byAdding: .day, value: -1, to: today)!
        let entry2 = makeTestEntry(date: date2, weight: 70.0, bodyFatPercent: 18.0)
        let metabolism2 = makeTestMetabolismData(date: date2)
        _ = try await sut.save(entry: entry2, metabolismData: metabolism2)

        let date3 = today
        let entry3 = makeTestEntry(date: date3, weight: 72.0, bodyFatPercent: 19.0)
        let metabolism3 = makeTestMetabolismData(date: date3)
        _ = try await sut.save(entry: entry3, metabolismData: metabolism3)

        // When: 통계 조회
        let startDate = calendar.date(byAdding: .day, value: -2, to: today)!
        let endDate = today
        let statistics = try await sut.fetchStatistics(from: startDate, to: endDate)

        // Then: 통계 값 확인
        XCTAssertEqual(statistics.recordCount, 3, "레코드 개수가 3이어야 합니다")

        // 평균 체중: (68 + 70 + 72) / 3 = 70
        XCTAssertEqual(statistics.averageWeight, 70.0, accuracy: 0.01, "평균 체중이 70kg이어야 합니다")

        // 평균 체지방률: (17 + 18 + 19) / 3 = 18
        XCTAssertEqual(statistics.averageBodyFatPercent, 18.0, accuracy: 0.01, "평균 체지방률이 18%여야 합니다")

        // 최소/최대 체중
        XCTAssertEqual(statistics.minWeight, 68.0, "최소 체중이 68kg이어야 합니다")
        XCTAssertEqual(statistics.maxWeight, 72.0, "최대 체중이 72kg이어야 합니다")

        // 최소/최대 체지방률
        XCTAssertEqual(statistics.minBodyFatPercent, 17.0, "최소 체지방률이 17%여야 합니다")
        XCTAssertEqual(statistics.maxBodyFatPercent, 19.0, "최대 체지방률이 19%여야 합니다")
    }

    // MARK: - Data Integrity Tests

    /// 데이터 무결성 - Decimal 정밀도 보존
    /// 📚 학습 포인트: Decimal Precision Testing
    /// - Decimal 타입의 정밀도가 유지되는지 확인
    func testDataIntegrity_PreservesDecimalPrecision() async throws {
        // Given: 소수점 2자리 데이터
        let entry = makeTestEntry(
            weight: Decimal(string: "70.25")!,
            bodyFatPercent: Decimal(string: "18.75")!,
            muscleMass: Decimal(string: "32.50")!
        )
        let metabolism = makeTestMetabolismData()

        // When: 저장 후 조회
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)

        // Then: 정밀도 유지
        XCTAssertEqual(fetchedEntry?.weight, Decimal(string: "70.25")!, "체중 정밀도가 유지되어야 합니다")
        XCTAssertEqual(fetchedEntry?.bodyFatPercent, Decimal(string: "18.75")!, "체지방률 정밀도가 유지되어야 합니다")
        XCTAssertEqual(fetchedEntry?.muscleMass, Decimal(string: "32.50")!, "근육량 정밀도가 유지되어야 합니다")
    }

    /// 데이터 무결성 - 날짜 정확도
    /// 📚 학습 포인트: Date Precision Testing
    func testDataIntegrity_PreservesDateAccuracy() async throws {
        // Given: 특정 시간의 데이터
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(
            year: 2026, month: 1, day: 13,
            hour: 14, minute: 30, second: 0
        ))!

        let entry = makeTestEntry(date: testDate)
        let metabolism = makeTestMetabolismData(date: testDate)

        // When: 저장 후 조회
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)

        // Then: 날짜 정확도 유지 (초 단위까지)
        XCTAssertNotNil(fetchedEntry)

        let savedComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fetchedEntry!.date)
        let testComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: testDate)
        XCTAssertEqual(savedComponents, testComponents, "날짜 정확도가 유지되어야 합니다")
    }

    /// 데이터 무결성 - 관계 일관성
    /// 📚 학습 포인트: Relationship Integrity
    func testDataIntegrity_MaintainsRelationshipConsistency() async throws {
        // Given: 저장된 데이터
        let entry = makeTestEntry(weight: 70.0, bodyFatPercent: 18.0)
        let metabolism = makeTestMetabolismData(
            bmr: 1650.0,
            weight: 70.0,
            bodyFatPercent: 18.0
        )
        let savedEntry = try await sut.save(entry: entry, metabolismData: metabolism)

        // When: BodyEntry와 MetabolismData 조회
        let fetchedEntry = try await sut.fetch(by: savedEntry.id)
        let fetchedMetabolism = try await sut.fetchMetabolismData(for: savedEntry.id)

        // Then: 데이터 일관성 확인
        XCTAssertNotNil(fetchedEntry)
        XCTAssertNotNil(fetchedMetabolism)

        // 체중과 체지방률이 일치해야 함
        XCTAssertEqual(fetchedEntry?.weight, fetchedMetabolism?.weight, "체중이 일치해야 합니다")
        XCTAssertEqual(fetchedEntry?.bodyFatPercent, fetchedMetabolism?.bodyFatPercent, "체지방률이 일치해야 합니다")
    }

    /// 데이터 무결성 - 동시성 테스트
    /// 📚 학습 포인트: Concurrent Access Testing
    func testDataIntegrity_HandlesMultipleConcurrentSaves() async throws {
        // Given: 여러 저장 작업을 동시에 실행

        // When: 5개의 저장 작업을 동시에 실행
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    let entry = self.makeTestEntry(weight: Decimal(70 + i))
                    let metabolism = self.makeTestMetabolismData()
                    _ = try? await self.sut.save(entry: entry, metabolismData: metabolism)
                }
            }
        }

        // Then: 모든 데이터가 정상적으로 저장됨
        let allEntries = try await sut.fetchAll()
        XCTAssertEqual(allEntries.count, 5, "5개의 데이터가 모두 저장되어야 합니다")
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Integration Test 작성 가이드
///
/// Integration Test의 목적:
/// - 여러 컴포넌트가 함께 작동하는지 확인
/// - 실제 데이터베이스 작업이 올바르게 수행되는지 검증
/// - Repository와 Data Source의 통합 동작 테스트
///
/// 테스트 전략:
/// 1. CRUD 작업 테스트
///    - Create: 저장 기능과 데이터 영속성
///    - Read: 단일/다중 조회, 날짜 범위 쿼리
///    - Update: 수정 기능과 업데이트 검증
///    - Delete: 삭제 기능과 cascade delete
///
/// 2. 관계 테스트
///    - BodyRecord ↔ MetabolismSnapshot 1:1 관계
///    - Cascade delete 동작 확인
///    - 관계 데이터 일관성 검증
///
/// 3. 쿼리 테스트
///    - 날짜 범위 쿼리 (트렌드 차트용)
///    - 최신 데이터 조회
///    - 통계 쿼리 (평균, 최소, 최대)
///
/// 4. 데이터 무결성 테스트
///    - Decimal 정밀도 보존
///    - 날짜 정확도 유지
///    - 관계 일관성 확인
///    - 동시성 처리
///
/// In-Memory Core Data 사용:
/// - 실제 디스크에 저장하지 않음
/// - 테스트 간 격리 보장
/// - 빠른 실행 속도
/// - setUp/tearDown으로 깨끗한 상태 유지
///
/// 💡 실무 팁:
/// - 각 테스트는 독립적으로 실행 가능해야 함
/// - Given-When-Then 패턴으로 가독성 향상
/// - 테스트 실패 시 명확한 에러 메시지 제공
/// - Edge case와 Error case 모두 테스트
/// - 성능 테스트는 별도로 분리 (BodyQueryPerformanceTests)
///
/// 💡 Java 비교:
/// - JUnit + @DataJpaTest: Spring Boot의 데이터 레이어 테스트
/// - @Transactional: 각 테스트 후 롤백 (Swift는 In-Memory 사용)
/// - TestEntityManager: Swift의 PersistenceController와 유사
