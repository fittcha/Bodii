//
//  SleepRecordMapperTests.swift
//  BodiiTests
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Mapper Unit Testing
// Mapper의 domain/entity 변환 로직을 단위 테스트
// 💡 Java 비교: ModelMapper 또는 MapStruct의 매핑 로직 테스트와 유사

import XCTest
import CoreData
@testable import Bodii

/// SleepRecordMapper의 단위 테스트
/// 📚 학습 포인트: Unit Test vs Integration Test
/// - Unit Test: 개별 컴포넌트를 독립적으로 테스트 (Mapper만 테스트)
/// - Integration Test: 여러 컴포넌트를 함께 테스트 (Repository + DataSource)
/// 💡 Java 비교: JUnit의 단위 테스트와 유사
final class SleepRecordMapperTests: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 Mapper
    /// 📚 학습 포인트: System Under Test (SUT)
    var sut: SleepRecordMapper!

    /// 테스트용 Persistence Controller (인메모리)
    /// 📚 학습 포인트: In-Memory Core Data Stack
    /// - Core Data entity 생성을 위해 context가 필요
    /// - 실제 디스크에 저장하지 않고 메모리에서만 동작
    var testPersistenceController: PersistenceController!

    /// 테스트용 Context
    var testContext: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    /// 각 테스트 실행 전 호출
    /// 📚 학습 포인트: Test Setup
    /// - 각 테스트마다 깨끗한 상태로 시작
    override func setUp() {
        super.setUp()

        // 매퍼 초기화
        sut = SleepRecordMapper()

        // 인메모리 Core Data 스택 생성
        testPersistenceController = PersistenceController(inMemory: true)
        testContext = testPersistenceController.container.viewContext
    }

    /// 각 테스트 실행 후 호출
    /// 📚 학습 포인트: Test Teardown
    /// - 메모리 정리
    override func tearDown() {
        sut = nil
        testContext = nil
        testPersistenceController = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// 테스트용 Domain SleepRecord 생성
    /// 📚 학습 포인트: Test Helper Method
    /// - 테스트 데이터 생성 로직을 재사용
    /// - 가독성 향상
    private func makeDomainSleepRecord(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        date: Date = Date(),
        duration: Int32 = 420,  // 7시간 (good)
        status: SleepStatus = .good,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Bodii.SleepRecord {
        return Bodii.SleepRecord(
            id: id,
            userId: userId,
            date: date,
            duration: duration,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// 테스트용 Core Data SleepRecord 엔티티 생성
    /// 📚 학습 포인트: NSManagedObject Creation Helper
    /// - Core Data 엔티티를 테스트용으로 생성
    private func makeEntitySleepRecord(
        id: UUID = UUID(),
        userId: UUID = UUID(),
        date: Date = Date(),
        duration: Int32 = 420,
        status: Int16 = 2,  // good
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> SleepRecord {
        let entity = SleepRecord(context: testContext)
        entity.id = id
        entity.userId = userId
        entity.date = date
        entity.duration = duration
        entity.status = status
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
        return entity
    }

    // MARK: - toDomain Tests (Core Data → Domain)

    /// toDomain - 정상 케이스 (good status)
    /// 📚 학습 포인트: Happy Path Testing
    /// - 모든 필드가 올바르게 변환되는지 확인
    func testToDomain_ValidEntityGoodStatus_ConvertsSuccessfully() throws {
        // Given: 유효한 Core Data SleepRecord 엔티티 (good status)
        let entityId = UUID()
        let entityUserId = UUID()
        let entityDate = Date()
        let entityDuration: Int32 = 420  // 7시간
        let entityStatus: Int16 = 2  // good
        let entityCreatedAt = Date()
        let entityUpdatedAt = Date()

        let entity = makeEntitySleepRecord(
            id: entityId,
            userId: entityUserId,
            date: entityDate,
            duration: entityDuration,
            status: entityStatus,
            createdAt: entityCreatedAt,
            updatedAt: entityUpdatedAt
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: 모든 필드가 올바르게 변환됨
        XCTAssertEqual(domainRecord.id, entityId, "ID가 일치해야 합니다")
        XCTAssertEqual(domainRecord.userId, entityUserId, "userId가 일치해야 합니다")
        XCTAssertEqual(domainRecord.date, entityDate, "date가 일치해야 합니다")
        XCTAssertEqual(domainRecord.duration, entityDuration, "duration이 일치해야 합니다")
        XCTAssertEqual(domainRecord.status, .good, "status가 good이어야 합니다")
        XCTAssertEqual(domainRecord.createdAt, entityCreatedAt, "createdAt이 일치해야 합니다")
        XCTAssertEqual(domainRecord.updatedAt, entityUpdatedAt, "updatedAt이 일치해야 합니다")
    }

    /// toDomain - bad status 변환
    /// 📚 학습 포인트: Enum Conversion Testing
    /// - Int16 → SleepStatus 변환이 올바른지 확인
    func testToDomain_BadStatus_ConvertsSuccessfully() throws {
        // Given: bad status 엔티티
        let entity = makeEntitySleepRecord(
            duration: 240,  // 4시간
            status: 0  // bad
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: bad status로 변환됨
        XCTAssertEqual(domainRecord.status, .bad, "status가 bad여야 합니다")
        XCTAssertEqual(domainRecord.status.rawValue, 0, "rawValue가 0이어야 합니다")
        XCTAssertEqual(domainRecord.duration, 240, "duration이 일치해야 합니다")
    }

    /// toDomain - soso status 변환
    func testToDomain_SosoStatus_ConvertsSuccessfully() throws {
        // Given: soso status 엔티티
        let entity = makeEntitySleepRecord(
            duration: 360,  // 6시간
            status: 1  // soso
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: soso status로 변환됨
        XCTAssertEqual(domainRecord.status, .soso, "status가 soso여야 합니다")
        XCTAssertEqual(domainRecord.status.rawValue, 1, "rawValue가 1이어야 합니다")
        XCTAssertEqual(domainRecord.duration, 360, "duration이 일치해야 합니다")
    }

    /// toDomain - excellent status 변환
    func testToDomain_ExcellentStatus_ConvertsSuccessfully() throws {
        // Given: excellent status 엔티티
        let entity = makeEntitySleepRecord(
            duration: 480,  // 8시간
            status: 3  // excellent
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: excellent status로 변환됨
        XCTAssertEqual(domainRecord.status, .excellent, "status가 excellent여야 합니다")
        XCTAssertEqual(domainRecord.status.rawValue, 3, "rawValue가 3이어야 합니다")
        XCTAssertEqual(domainRecord.duration, 480, "duration이 일치해야 합니다")
    }

    /// toDomain - oversleep status 변환
    func testToDomain_OversleepStatus_ConvertsSuccessfully() throws {
        // Given: oversleep status 엔티티
        let entity = makeEntitySleepRecord(
            duration: 600,  // 10시간
            status: 4  // oversleep
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: oversleep status로 변환됨
        XCTAssertEqual(domainRecord.status, .oversleep, "status가 oversleep이어야 합니다")
        XCTAssertEqual(domainRecord.status.rawValue, 4, "rawValue가 4여야 합니다")
        XCTAssertEqual(domainRecord.duration, 600, "duration이 일치해야 합니다")
    }

    /// toDomain - 모든 status 값 변환 테스트
    /// 📚 학습 포인트: Comprehensive Enum Testing
    /// - 모든 enum 케이스가 올바르게 변환되는지 확인
    func testToDomain_AllStatusValues_ConvertCorrectly() throws {
        // Given: 모든 status 값에 대한 테스트 케이스
        let testCases: [(status: Int16, expected: SleepStatus, description: String)] = [
            (0, .bad, "bad"),
            (1, .soso, "soso"),
            (2, .good, "good"),
            (3, .excellent, "excellent"),
            (4, .oversleep, "oversleep")
        ]

        // When/Then: 각 status 값이 올바르게 변환됨
        for testCase in testCases {
            let entity = makeEntitySleepRecord(status: testCase.status)
            let domainRecord = try sut.toDomain(entity)

            XCTAssertEqual(
                domainRecord.status,
                testCase.expected,
                "\(testCase.description) status가 올바르게 변환되어야 합니다"
            )
        }
    }

    /// toDomain - 0분 수면 시간 (밤샘)
    /// 📚 학습 포인트: Edge Case Testing
    /// - 최소값 경계 조건 테스트
    func testToDomain_ZeroDuration_ConvertsSuccessfully() throws {
        // Given: 0분 수면 시간 (밤샘)
        let entity = makeEntitySleepRecord(
            duration: 0,
            status: 0  // bad
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: 0분도 올바르게 변환됨
        XCTAssertEqual(domainRecord.duration, 0, "duration이 0이어야 합니다")
        XCTAssertEqual(domainRecord.status, .bad, "0분은 bad status여야 합니다")
    }

    /// toDomain - 매우 긴 수면 시간
    /// 📚 학습 포인트: Large Value Testing
    func testToDomain_LargeDuration_ConvertsSuccessfully() throws {
        // Given: 매우 긴 수면 시간 (12시간)
        let entity = makeEntitySleepRecord(
            duration: 720,  // 12시간
            status: 4  // oversleep
        )

        // When: Domain으로 변환
        let domainRecord = try sut.toDomain(entity)

        // Then: 큰 값도 올바르게 변환됨
        XCTAssertEqual(domainRecord.duration, 720, "duration이 720이어야 합니다")
        XCTAssertEqual(domainRecord.status, .oversleep, "oversleep status여야 합니다")
    }

    // MARK: - toDomain Error Tests

    /// toDomain - id 필드 누락
    /// 📚 학습 포인트: Error Case Testing
    /// - 필수 필드 누락 시 에러가 발생하는지 확인
    func testToDomain_MissingId_ThrowsError() throws {
        // Given: id가 nil인 엔티티
        let entity = makeEntitySleepRecord()
        entity.id = nil

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError else {
                XCTFail("MappingError 타입이어야 합니다")
                return
            }

            // 📚 학습 포인트: Error Pattern Matching
            if case .missingRequiredField(let field) = mappingError {
                XCTAssertEqual(field, "id", "id 필드 누락 에러여야 합니다")
            } else {
                XCTFail("missingRequiredField 에러여야 합니다")
            }
        }
    }

    /// toDomain - userId 필드 누락
    func testToDomain_MissingUserId_ThrowsError() throws {
        // Given: userId가 nil인 엔티티
        let entity = makeEntitySleepRecord()
        entity.userId = nil

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError,
                  case .missingRequiredField(let field) = mappingError else {
                XCTFail("missingRequiredField 에러여야 합니다")
                return
            }
            XCTAssertEqual(field, "userId", "userId 필드 누락 에러여야 합니다")
        }
    }

    /// toDomain - date 필드 누락
    func testToDomain_MissingDate_ThrowsError() throws {
        // Given: date가 nil인 엔티티
        let entity = makeEntitySleepRecord()
        entity.date = nil

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError,
                  case .missingRequiredField(let field) = mappingError else {
                XCTFail("missingRequiredField 에러여야 합니다")
                return
            }
            XCTAssertEqual(field, "date", "date 필드 누락 에러여야 합니다")
        }
    }

    /// toDomain - createdAt 필드 누락
    func testToDomain_MissingCreatedAt_ThrowsError() throws {
        // Given: createdAt이 nil인 엔티티
        let entity = makeEntitySleepRecord()
        entity.createdAt = nil

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError,
                  case .missingRequiredField(let field) = mappingError else {
                XCTFail("missingRequiredField 에러여야 합니다")
                return
            }
            XCTAssertEqual(field, "createdAt", "createdAt 필드 누락 에러여야 합니다")
        }
    }

    /// toDomain - updatedAt 필드 누락
    func testToDomain_MissingUpdatedAt_ThrowsError() throws {
        // Given: updatedAt이 nil인 엔티티
        let entity = makeEntitySleepRecord()
        entity.updatedAt = nil

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError,
                  case .missingRequiredField(let field) = mappingError else {
                XCTFail("missingRequiredField 에러여야 합니다")
                return
            }
            XCTAssertEqual(field, "updatedAt", "updatedAt 필드 누락 에러여야 합니다")
        }
    }

    /// toDomain - 잘못된 status 값
    /// 📚 학습 포인트: Invalid Enum Value Testing
    /// - 존재하지 않는 enum 값에 대한 에러 처리
    func testToDomain_InvalidStatus_ThrowsError() throws {
        // Given: 잘못된 status 값 (5는 존재하지 않음)
        let entity = makeEntitySleepRecord(status: 5)

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError else {
                XCTFail("MappingError 타입이어야 합니다")
                return
            }

            if case .invalidEnumValue(let field) = mappingError {
                XCTAssertTrue(field.contains("status"), "status 필드 에러여야 합니다")
                XCTAssertTrue(field.contains("5"), "status 값 5를 포함해야 합니다")
            } else {
                XCTFail("invalidEnumValue 에러여야 합니다")
            }
        }
    }

    /// toDomain - 음수 status 값
    func testToDomain_NegativeStatus_ThrowsError() throws {
        // Given: 음수 status 값
        let entity = makeEntitySleepRecord(status: -1)

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entity)) { error in
            guard let mappingError = error as? SleepRecordMapper.MappingError,
                  case .invalidEnumValue = mappingError else {
                XCTFail("invalidEnumValue 에러여야 합니다")
                return
            }
        }
    }

    // MARK: - toDomain Array Tests

    /// toDomain - 여러 엔티티 변환
    /// 📚 학습 포인트: Collection Transformation Testing
    /// - 배열 변환이 올바르게 작동하는지 확인
    func testToDomain_MultipleEntities_ConvertsAll() throws {
        // Given: 여러 Core Data 엔티티
        let entity1 = makeEntitySleepRecord(duration: 240, status: 0)  // bad
        let entity2 = makeEntitySleepRecord(duration: 360, status: 1)  // soso
        let entity3 = makeEntitySleepRecord(duration: 480, status: 3)  // excellent

        let entities = [entity1, entity2, entity3]

        // When: 배열을 Domain으로 변환
        let domainRecords = try sut.toDomain(entities)

        // Then: 모든 엔티티가 변환됨
        XCTAssertEqual(domainRecords.count, 3, "3개의 레코드가 변환되어야 합니다")
        XCTAssertEqual(domainRecords[0].status, .bad, "첫 번째는 bad여야 합니다")
        XCTAssertEqual(domainRecords[1].status, .soso, "두 번째는 soso여야 합니다")
        XCTAssertEqual(domainRecords[2].status, .excellent, "세 번째는 excellent여야 합니다")
    }

    /// toDomain - 빈 배열
    func testToDomain_EmptyArray_ReturnsEmptyArray() throws {
        // Given: 빈 배열
        let entities: [SleepRecord] = []

        // When: 배열을 Domain으로 변환
        let domainRecords = try sut.toDomain(entities)

        // Then: 빈 배열 반환
        XCTAssertTrue(domainRecords.isEmpty, "빈 배열을 반환해야 합니다")
    }

    /// toDomain - 배열 중 하나가 잘못된 경우
    /// 📚 학습 포인트: Fail-Fast Behavior
    /// - 하나라도 실패하면 전체 변환 실패
    func testToDomain_ArrayWithInvalidEntity_ThrowsError() throws {
        // Given: 하나는 유효하고 하나는 잘못된 엔티티
        let validEntity = makeEntitySleepRecord()
        let invalidEntity = makeEntitySleepRecord()
        invalidEntity.id = nil

        let entities = [validEntity, invalidEntity]

        // When/Then: 에러 발생
        XCTAssertThrowsError(try sut.toDomain(entities)) { error in
            XCTAssertTrue(error is SleepRecordMapper.MappingError,
                         "MappingError 타입이어야 합니다")
        }
    }

    // MARK: - toEntity Tests (Domain → Core Data)

    /// toEntity - 정상 케이스
    /// 📚 학습 포인트: Domain to Entity Conversion
    /// - Domain 모델을 Core Data 엔티티로 변환
    func testToEntity_ValidDomainRecord_ConvertsSuccessfully() {
        // Given: 유효한 Domain SleepRecord
        let domainId = UUID()
        let domainUserId = UUID()
        let domainDate = Date()
        let domainDuration: Int32 = 420
        let domainStatus: SleepStatus = .good
        let domainCreatedAt = Date()
        let domainUpdatedAt = Date()

        let domainRecord = makeDomainSleepRecord(
            id: domainId,
            userId: domainUserId,
            date: domainDate,
            duration: domainDuration,
            status: domainStatus,
            createdAt: domainCreatedAt,
            updatedAt: domainUpdatedAt
        )

        // When: Core Data 엔티티로 변환
        let entity = sut.toEntity(domainRecord, context: testContext)

        // Then: 모든 필드가 올바르게 변환됨
        XCTAssertEqual(entity.id, domainId, "ID가 일치해야 합니다")
        XCTAssertEqual(entity.userId, domainUserId, "userId가 일치해야 합니다")
        XCTAssertEqual(entity.date, domainDate, "date가 일치해야 합니다")
        XCTAssertEqual(entity.duration, domainDuration, "duration이 일치해야 합니다")
        XCTAssertEqual(entity.status, domainStatus.rawValue, "status rawValue가 일치해야 합니다")
        XCTAssertEqual(entity.createdAt, domainCreatedAt, "createdAt이 일치해야 합니다")
        XCTAssertEqual(entity.updatedAt, domainUpdatedAt, "updatedAt이 일치해야 합니다")
    }

    /// toEntity - 모든 status 값 변환
    /// 📚 학습 포인트: Enum to Int16 Conversion
    /// - SleepStatus → Int16 변환 테스트
    func testToEntity_AllStatusValues_ConvertCorrectly() {
        // Given: 모든 status 값에 대한 테스트 케이스
        let testCases: [(status: SleepStatus, expectedRawValue: Int16, description: String)] = [
            (.bad, 0, "bad"),
            (.soso, 1, "soso"),
            (.good, 2, "good"),
            (.excellent, 3, "excellent"),
            (.oversleep, 4, "oversleep")
        ]

        // When/Then: 각 status 값이 올바르게 변환됨
        for testCase in testCases {
            let domainRecord = makeDomainSleepRecord(status: testCase.status)
            let entity = sut.toEntity(domainRecord, context: testContext)

            XCTAssertEqual(
                entity.status,
                testCase.expectedRawValue,
                "\(testCase.description) status의 rawValue가 올바르게 변환되어야 합니다"
            )
        }
    }

    /// toEntity - 0분 수면 시간
    func testToEntity_ZeroDuration_ConvertsSuccessfully() {
        // Given: 0분 수면 시간
        let domainRecord = makeDomainSleepRecord(
            duration: 0,
            status: .bad
        )

        // When: Core Data 엔티티로 변환
        let entity = sut.toEntity(domainRecord, context: testContext)

        // Then: 0분도 올바르게 변환됨
        XCTAssertEqual(entity.duration, 0, "duration이 0이어야 합니다")
        XCTAssertEqual(entity.status, 0, "status가 bad(0)여야 합니다")
    }

    /// toEntity - 매우 긴 수면 시간
    func testToEntity_LargeDuration_ConvertsSuccessfully() {
        // Given: 매우 긴 수면 시간
        let domainRecord = makeDomainSleepRecord(
            duration: 720,
            status: .oversleep
        )

        // When: Core Data 엔티티로 변환
        let entity = sut.toEntity(domainRecord, context: testContext)

        // Then: 큰 값도 올바르게 변환됨
        XCTAssertEqual(entity.duration, 720, "duration이 720이어야 합니다")
        XCTAssertEqual(entity.status, 4, "status가 oversleep(4)여야 합니다")
    }

    // MARK: - Round-trip Conversion Tests

    /// Round-trip 변환 - Entity → Domain → Entity
    /// 📚 학습 포인트: Round-trip Testing
    /// - 양방향 변환 후에도 데이터가 보존되는지 확인
    func testRoundTrip_EntityToDomainToEntity_PreservesData() throws {
        // Given: 원본 Core Data 엔티티
        let originalEntity = makeEntitySleepRecord(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            duration: 480,
            status: 3,  // excellent
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Entity → Domain → Entity 변환
        let domainRecord = try sut.toDomain(originalEntity)
        let newEntity = sut.toEntity(domainRecord, context: testContext)

        // Then: 모든 데이터가 보존됨
        XCTAssertEqual(newEntity.id, originalEntity.id, "ID가 보존되어야 합니다")
        XCTAssertEqual(newEntity.userId, originalEntity.userId, "userId가 보존되어야 합니다")
        XCTAssertEqual(newEntity.date, originalEntity.date, "date가 보존되어야 합니다")
        XCTAssertEqual(newEntity.duration, originalEntity.duration, "duration이 보존되어야 합니다")
        XCTAssertEqual(newEntity.status, originalEntity.status, "status가 보존되어야 합니다")
        XCTAssertEqual(newEntity.createdAt, originalEntity.createdAt, "createdAt이 보존되어야 합니다")
        XCTAssertEqual(newEntity.updatedAt, originalEntity.updatedAt, "updatedAt이 보존되어야 합니다")
    }

    /// Round-trip 변환 - Domain → Entity → Domain
    func testRoundTrip_DomainToEntityToDomain_PreservesData() throws {
        // Given: 원본 Domain 레코드
        let originalDomain = makeDomainSleepRecord(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            duration: 360,
            status: .soso,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When: Domain → Entity → Domain 변환
        let entity = sut.toEntity(originalDomain, context: testContext)
        let newDomain = try sut.toDomain(entity)

        // Then: 모든 데이터가 보존됨
        XCTAssertEqual(newDomain.id, originalDomain.id, "ID가 보존되어야 합니다")
        XCTAssertEqual(newDomain.userId, originalDomain.userId, "userId가 보존되어야 합니다")
        XCTAssertEqual(newDomain.date, originalDomain.date, "date가 보존되어야 합니다")
        XCTAssertEqual(newDomain.duration, originalDomain.duration, "duration이 보존되어야 합니다")
        XCTAssertEqual(newDomain.status, originalDomain.status, "status가 보존되어야 합니다")
        XCTAssertEqual(newDomain.createdAt, originalDomain.createdAt, "createdAt이 보존되어야 합니다")
        XCTAssertEqual(newDomain.updatedAt, originalDomain.updatedAt, "updatedAt이 보존되어야 합니다")
    }

    // MARK: - updateEntity Tests

    /// updateEntity - 정상 케이스
    /// 📚 학습 포인트: Partial Update Testing
    /// - 기존 엔티티를 업데이트하는 로직 테스트
    func testUpdateEntity_ValidData_UpdatesSuccessfully() {
        // Given: 기존 엔티티와 새로운 Domain 레코드
        let entity = makeEntitySleepRecord(
            duration: 360,
            status: 1  // soso
        )

        let updatedDomain = makeDomainSleepRecord(
            id: entity.id!,
            userId: entity.userId!,
            duration: 480,  // 수정된 값
            status: .excellent,  // 수정된 값
            updatedAt: Date()
        )

        // When: 엔티티 업데이트
        sut.updateEntity(entity, from: updatedDomain)

        // Then: 필드가 업데이트됨
        XCTAssertEqual(entity.duration, 480, "duration이 업데이트되어야 합니다")
        XCTAssertEqual(entity.status, 3, "status가 excellent(3)로 업데이트되어야 합니다")
        XCTAssertEqual(entity.date, updatedDomain.date, "date가 업데이트되어야 합니다")
        XCTAssertEqual(entity.updatedAt, updatedDomain.updatedAt, "updatedAt이 업데이트되어야 합니다")
    }

    /// updateEntity - ID는 변경되지 않음
    /// 📚 학습 포인트: Immutable Field Testing
    /// - ID와 userId, createdAt은 변경되지 않아야 함
    func testUpdateEntity_ImmutableFields_NotUpdated() {
        // Given: 기존 엔티티
        let originalId = UUID()
        let originalUserId = UUID()
        let originalCreatedAt = Date()

        let entity = makeEntitySleepRecord(
            id: originalId,
            userId: originalUserId,
            createdAt: originalCreatedAt
        )

        // 다른 ID를 가진 Domain 레코드
        let updatedDomain = makeDomainSleepRecord(
            id: UUID(),  // 다른 ID
            userId: UUID(),  // 다른 userId
            createdAt: Date()  // 다른 createdAt
        )

        // When: 엔티티 업데이트
        sut.updateEntity(entity, from: updatedDomain)

        // Then: ID, userId, createdAt은 변경되지 않음
        XCTAssertEqual(entity.id, originalId, "ID는 변경되지 않아야 합니다")
        XCTAssertEqual(entity.userId, originalUserId, "userId는 변경되지 않아야 합니다")
        XCTAssertEqual(entity.createdAt, originalCreatedAt, "createdAt은 변경되지 않아야 합니다")
    }

    /// updateEntity - status 변경
    func testUpdateEntity_StatusChange_UpdatesSuccessfully() {
        // Given: bad status 엔티티
        let entity = makeEntitySleepRecord(
            duration: 240,
            status: 0  // bad
        )

        // excellent status로 변경
        let updatedDomain = makeDomainSleepRecord(
            id: entity.id!,
            userId: entity.userId!,
            duration: 480,
            status: .excellent
        )

        // When: 엔티티 업데이트
        sut.updateEntity(entity, from: updatedDomain)

        // Then: status가 변경됨
        XCTAssertEqual(entity.status, 3, "status가 excellent(3)로 변경되어야 합니다")
        XCTAssertEqual(entity.duration, 480, "duration도 변경되어야 합니다")
    }

    // MARK: - Convenience Method Tests

    /// createAndSave - 정상 케이스
    /// 📚 학습 포인트: Convenience Method Testing
    /// - 생성과 저장을 한 번에 처리하는 메서드 테스트
    func testCreateAndSave_ValidData_SavesSuccessfully() throws {
        // Given: 유효한 Domain 레코드
        let domainRecord = makeDomainSleepRecord()

        // When: 생성 및 저장
        let savedEntity = try sut.createAndSave(domainRecord, context: testContext)

        // Then: 저장 성공
        XCTAssertNotNil(savedEntity, "저장된 엔티티가 nil이 아니어야 합니다")
        XCTAssertEqual(savedEntity.id, domainRecord.id, "ID가 일치해야 합니다")
        XCTAssertEqual(savedEntity.duration, domainRecord.duration, "duration이 일치해야 합니다")

        // 📚 학습 포인트: Context State Verification
        // save()가 호출되었는지 확인
        XCTAssertFalse(testContext.hasChanges, "저장 후에는 변경사항이 없어야 합니다")
    }

    /// updateAndSave - 정상 케이스
    func testUpdateAndSave_ValidData_SavesSuccessfully() throws {
        // Given: 기존 엔티티
        let entity = makeEntitySleepRecord(duration: 360, status: 1)

        // When: 업데이트 및 저장
        let updatedDomain = makeDomainSleepRecord(
            id: entity.id!,
            userId: entity.userId!,
            duration: 480,
            status: .excellent
        )

        try sut.updateAndSave(entity, from: updatedDomain, context: testContext)

        // Then: 업데이트 성공
        XCTAssertEqual(entity.duration, 480, "duration이 업데이트되어야 합니다")
        XCTAssertEqual(entity.status, 3, "status가 업데이트되어야 합니다")
        XCTAssertFalse(testContext.hasChanges, "저장 후에는 변경사항이 없어야 합니다")
    }

    // MARK: - Date Handling Tests

    /// Date 정밀도 보존 테스트
    /// 📚 학습 포인트: Date Precision Testing
    /// - 날짜 정밀도가 유지되는지 확인
    func testRoundTrip_PreservesDatePrecision() throws {
        // Given: 특정 시간의 Domain 레코드
        let calendar = Calendar.current
        let specificDate = calendar.date(from: DateComponents(
            year: 2026, month: 1, day: 14,
            hour: 2, minute: 30, second: 0
        ))!

        let domainRecord = makeDomainSleepRecord(date: specificDate)

        // When: Domain → Entity → Domain 변환
        let entity = sut.toEntity(domainRecord, context: testContext)
        let convertedDomain = try sut.toDomain(entity)

        // Then: 날짜 정밀도가 유지됨 (초 단위까지)
        let originalComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: specificDate
        )
        let convertedComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: convertedDomain.date
        )

        XCTAssertEqual(originalComponents, convertedComponents,
                      "날짜 정밀도가 유지되어야 합니다")
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Mapper Unit Test 작성 가이드
///
/// Mapper Test의 목적:
/// - Domain ↔ Entity 변환 로직의 정확성 검증
/// - Enum 변환 로직 테스트 (Int16 ↔ SleepStatus)
/// - 필수 필드 누락 시 에러 처리 검증
/// - Round-trip 변환 시 데이터 보존 확인
///
/// 테스트 전략:
/// 1. toDomain (Core Data → Domain) 테스트
///    - 정상 케이스: 모든 status 값
///    - 에러 케이스: 필수 필드 누락, 잘못된 enum 값
///    - 경계 조건: 0분, 매우 긴 시간
///    - 배열 변환
///
/// 2. toEntity (Domain → Core Data) 테스트
///    - 정상 케이스: 모든 status 값
///    - Enum → rawValue 변환
///    - 경계 조건
///
/// 3. updateEntity 테스트
///    - 가변 필드 업데이트
///    - 불변 필드 보존 (id, userId, createdAt)
///
/// 4. Round-trip 테스트
///    - Entity → Domain → Entity
///    - Domain → Entity → Domain
///    - 데이터 보존 검증
///
/// 5. Convenience Method 테스트
///    - createAndSave
///    - updateAndSave
///
/// Helper Method 활용:
/// - makeDomainSleepRecord(): 테스트용 Domain 엔티티 생성
/// - makeEntitySleepRecord(): 테스트용 Core Data 엔티티 생성
/// - 기본값 제공으로 간결한 테스트 작성
///
/// 💡 실무 팁:
/// - Given-When-Then 패턴으로 가독성 향상
/// - Enum 변환은 모든 케이스를 테스트
/// - 에러 케이스는 구체적인 에러 타입과 메시지 검증
/// - Round-trip 테스트로 데이터 무결성 보장
/// - In-Memory Core Data 사용으로 빠른 테스트 실행
///
/// 💡 Java 비교:
/// - ModelMapper/MapStruct 테스트와 유사
/// - Entity ↔ DTO 변환 로직 검증
/// - @BeforeEach setUp()과 유사한 패턴
/// - assertThrows()와 유사한 XCTAssertThrowsError
///
