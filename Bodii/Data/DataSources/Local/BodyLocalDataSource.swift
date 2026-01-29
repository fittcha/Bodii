//
//  BodyLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Local Data Source
// Core Data 작업을 담당하는 데이터 소스 레이어
// 💡 Java 비교: DAO (Data Access Object)와 유사한 역할

import Foundation
import CoreData

// MARK: - BodyLocalDataSource

/// BodyRecord와 MetabolismSnapshot의 Core Data 작업을 담당하는 로컬 데이터 소스
/// 📚 학습 포인트: Clean Architecture - Data Source Layer
/// - Repository와 Core Data 사이의 추상화 레이어
/// - Core Data 특화된 작업 수행 (NSFetchRequest, NSManagedObjectContext 등)
/// - Mapper를 활용하여 Domain Entity와 Core Data Entity 변환
/// 💡 Java 비교: JPA를 사용하는 DAO 구현체와 유사
///
/// 성능 요구사항:
/// - 모든 쿼리는 0.5초 이내에 완료
/// - 대량 작업은 백그라운드 컨텍스트 사용
/// - 날짜 필드에 인덱스 활용
final class BodyLocalDataSource {

    // MARK: - Properties

    /// Core Data 스택 관리자
    /// 📚 학습 포인트: Dependency Injection
    /// - PersistenceController를 외부에서 주입받아 사용
    /// - 테스트 시 인메모리 컨트롤러로 교체 가능
    private let persistenceController: PersistenceController

    /// BodyRecord 매퍼
    /// 📚 학습 포인트: Mapper Pattern
    /// - Core Data Entity ↔ Domain Entity 변환 담당
    private let bodyRecordMapper: BodyRecordMapper

    /// MetabolismSnapshot 매퍼
    private let metabolismSnapshotMapper: MetabolismSnapshotMapper

    // MARK: - Initialization

    /// BodyLocalDataSource 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 의존성을 생성자를 통해 주입받음
    /// - 기본값으로 shared instance 사용
    /// 💡 Java 비교: @Autowired 또는 생성자 주입과 유사
    ///
    /// - Parameter persistenceController: Core Data 스택 관리자
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.bodyRecordMapper = BodyRecordMapper()
        self.metabolismSnapshotMapper = MetabolismSnapshotMapper()
    }

    // MARK: - Create

    /// 새로운 신체 구성 기록과 대사율 스냅샷을 저장합니다.
    /// 📚 학습 포인트: Transactional Operation
    /// - BodyRecord와 MetabolismSnapshot을 함께 생성
    /// - 두 엔티티 간의 관계 설정
    /// - 하나의 트랜잭션에서 모두 처리 (원자성 보장)
    /// 💡 Java 비교: @Transactional 메서드와 유사
    ///
    /// - Parameters:
    ///   - entry: 저장할 신체 구성 데이터
    ///   - metabolismData: 함께 저장할 대사율 데이터
    /// - Returns: 저장된 신체 구성 데이터
    /// - Throws: 저장 실패 시 에러
    func save(entry: BodyCompositionEntry, metabolismData: MetabolismData) async throws -> BodyCompositionEntry {
        // 📚 학습 포인트: Background Context for Write Operations
        // UI 블로킹을 방지하기 위해 백그라운드 컨텍스트 사용
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            // 📚 학습 포인트: Upsert - 같은 날짜의 기존 레코드 확인
            // 하루에 하나의 체성분 데이터만 저장되도록 함
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: entry.date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                throw NSError(
                    domain: "BodyLocalDataSource",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "날짜 계산 실패"]
                )
            }

            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            request.fetchLimit = 1

            let existingRecords = try context.fetch(request)

            let bodyRecord: BodyRecord
            let metabolismSnapshot: MetabolismSnapshot

            if let existingRecord = existingRecords.first {
                // 기존 레코드 업데이트
                bodyRecord = existingRecord
                self.bodyRecordMapper.updateEntity(bodyRecord, from: entry)

                // MetabolismSnapshot 업데이트 또는 생성
                if let existingSnapshot = existingRecord.metabolismSnapshot {
                    metabolismSnapshot = existingSnapshot
                    self.metabolismSnapshotMapper.updateEntity(metabolismSnapshot, from: metabolismData)
                } else {
                    metabolismSnapshot = self.metabolismSnapshotMapper.toEntity(metabolismData, context: context)
                    bodyRecord.metabolismSnapshot = metabolismSnapshot
                    metabolismSnapshot.bodyRecord = bodyRecord
                }
            } else {
                // 새 레코드 생성
                // 📚 학습 포인트: Mapper 사용
                // Domain entity를 Core Data entity로 변환
                bodyRecord = self.bodyRecordMapper.toEntity(entry, context: context)
                metabolismSnapshot = self.metabolismSnapshotMapper.toEntity(metabolismData, context: context)

                // 📚 학습 포인트: Core Data Relationship
                // 두 엔티티 간의 관계 설정
                // BodyRecord ↔ MetabolismSnapshot (1:1)
                bodyRecord.metabolismSnapshot = metabolismSnapshot
                metabolismSnapshot.bodyRecord = bodyRecord
            }

            // 📚 학습 포인트: User Relationship
            // 현재는 단일 사용자 가정, 향후 다중 사용자 지원 시 수정 필요
            // TODO: User 가져와서 연결

            // 📚 학습 포인트: Context Save
            // 변경사항을 영구 저장소에 기록
            do {
                try context.save()
            } catch {
                // 📚 학습 포인트: Error Wrapping
                // Core Data 에러를 더 구체적인 도메인 에러로 변환
                throw NSError(
                    domain: "BodyLocalDataSource",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "저장 실패: \(error.localizedDescription)"]
                )
            }

            // 📚 학습 포인트: Return Saved Entity
            // 저장된 Core Data entity를 다시 Domain entity로 변환
            // ID가 할당되고 관계가 설정된 최신 상태를 반환
            return try self.bodyRecordMapper.toDomain(bodyRecord)
        }
    }

    // MARK: - Read (Single)

    /// ID로 특정 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Fetch by ID
    /// - UUID 기반 조회
    /// - 성능: <0.1초 (Primary Key 조회)
    ///
    /// - Parameter id: 조회할 기록의 고유 식별자
    /// - Returns: 신체 구성 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetch(by id: UUID) async throws -> BodyCompositionEntry? {
        let context = persistenceController.viewContext

        return try await context.perform {
            // 📚 학습 포인트: NSFetchRequest
            // Core Data의 쿼리 객체
            // 💡 Java 비교: JPA의 CriteriaQuery와 유사
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            // 📚 학습 포인트: Optional Mapping
            // 결과가 있으면 변환, 없으면 nil 반환
            guard let bodyRecord = results.first else { return nil }
            return try self.bodyRecordMapper.toDomain(bodyRecord)
        }
    }

    /// 특정 날짜의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Date Range Query
    /// - 날짜의 시작(00:00:00)부터 끝(23:59:59)까지 조회
    /// - 같은 날에 여러 기록이 있을 수 있으므로 가장 최근 것 반환
    /// - 성능: <0.2초 (날짜 인덱스 활용)
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 신체 구성 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetch(for date: Date) async throws -> BodyCompositionEntry? {
        let context = persistenceController.viewContext

        return try await context.perform {
            // 📚 학습 포인트: Date Range for Single Day
            // 날짜의 시작과 끝을 계산하여 범위 쿼리
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return nil
            }

            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            // 📚 학습 포인트: NSPredicate with Date Range
            // date >= startOfDay AND date < endOfDay
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )

            // 📚 학습 포인트: Sort Descriptor
            // 같은 날에 여러 기록이 있을 경우 가장 최근 것을 가져오기 위해 정렬
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let bodyRecord = results.first else { return nil }
            return try self.bodyRecordMapper.toDomain(bodyRecord)
        }
    }

    /// 가장 최근의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Latest Record Query
    /// - 날짜 기준 내림차순 정렬 후 첫 번째 결과
    /// - 성능: <0.1초 (날짜 인덱스 + LIMIT 1)
    ///
    /// - Returns: 가장 최근 신체 구성 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetchLatest() async throws -> BodyCompositionEntry? {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let bodyRecord = results.first else { return nil }
            return try self.bodyRecordMapper.toDomain(bodyRecord)
        }
    }

    // MARK: - Read (Multiple)

    /// 모든 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Fetch All
    /// - 날짜 내림차순 정렬 (최신순)
    /// - 성능: <0.5초 (최대 1000개 레코드 기준)
    /// 💡 주의: 데이터가 많아지면 fetchAll 대신 date range 쿼리 사용 권장
    ///
    /// - Returns: 모든 신체 구성 데이터 배열
    /// - Throws: 조회 실패 시 에러
    func fetchAll() async throws -> [BodyCompositionEntry] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            // 📚 학습 포인트: Performance Safeguard
            // 너무 많은 데이터를 한 번에 로드하지 않도록 제한
            // 실제 앱에서는 페이징 구현 권장
            request.fetchLimit = 1000

            let results = try context.fetch(request)

            // 📚 학습 포인트: Collection Transformation
            // map을 사용하여 배열 전체를 변환
            return try self.bodyRecordMapper.toDomain(results)
        }
    }

    /// 지정된 기간의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Date Range Query
    /// - 트렌드 차트를 위한 핵심 쿼리
    /// - 날짜 인덱스를 활용한 최적화
    /// - 성능: <0.3초 (날짜 범위 쿼리, 최대 90일 기준)
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (inclusive)
    ///   - endDate: 조회 종료 날짜 (inclusive)
    /// - Returns: 기간 내 신체 구성 데이터 배열 (날짜 오름차순)
    /// - Throws: 조회 실패 시 에러
    func fetch(from startDate: Date, to endDate: Date) async throws -> [BodyCompositionEntry] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()

            // 📚 학습 포인트: Date Range Predicate
            // startDate <= date <= endDate
            // 종료 날짜의 23:59:59까지 포함하기 위해 +1일 하여 '<' 비교
            let calendar = Calendar.current
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: endDate) else {
                throw NSError(
                    domain: "BodyLocalDataSource",
                    code: 1002,
                    userInfo: [NSLocalizedDescriptionKey: "날짜 계산 실패"]
                )
            }

            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startDate as NSDate,
                endOfDay as NSDate
            )

            // 📚 학습 포인트: Sort for Chart Display
            // 차트는 시간순으로 표시하므로 오름차순 정렬
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

            let results = try context.fetch(request)

            return try self.bodyRecordMapper.toDomain(results)
        }
    }

    /// 최근 N일간의 신체 구성 기록을 조회합니다.
    /// 📚 학습 포인트: Convenience Method
    /// - fetch(from:to:)의 편의 메서드
    /// - 자주 사용되는 패턴을 간단히 표현
    ///
    /// - Parameter days: 조회할 일수 (예: 7, 30, 90)
    /// - Returns: 최근 N일간의 신체 구성 데이터 배열 (날짜 오름차순)
    /// - Throws: 조회 실패 시 에러
    func fetchRecent(days: Int) async throws -> [BodyCompositionEntry] {
        // 📚 학습 포인트: Date Calculation
        // 현재 시간에서 N일 전 계산
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            throw NSError(
                domain: "BodyLocalDataSource",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "날짜 계산 실패"]
            )
        }

        return try await fetch(from: startDate, to: endDate)
    }

    // MARK: - Update

    /// 기존 신체 구성 기록을 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - MetabolismData도 함께 업데이트
    /// - 성능: <0.2초 (단일 레코드 업데이트)
    ///
    /// - Parameters:
    ///   - entry: 수정할 신체 구성 데이터 (ID 포함)
    ///   - metabolismData: 함께 수정할 대사율 데이터
    /// - Returns: 수정된 신체 구성 데이터
    /// - Throws: 수정 실패 시 에러
    func update(entry: BodyCompositionEntry, metabolismData: MetabolismData) async throws -> BodyCompositionEntry {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            // 📚 학습 포인트: Fetch Before Update
            // 업데이트할 엔티티를 먼저 조회
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let bodyRecord = results.first else {
                throw NSError(
                    domain: "BodyLocalDataSource",
                    code: 1004,
                    userInfo: [NSLocalizedDescriptionKey: "수정할 기록을 찾을 수 없습니다 (ID: \(entry.id))"]
                )
            }

            // 📚 학습 포인트: Update Entity
            // Mapper의 updateEntity 메서드 사용
            self.bodyRecordMapper.updateEntity(bodyRecord, from: entry)

            // 📚 학습 포인트: Update Related Entity
            // MetabolismSnapshot도 함께 업데이트
            if let snapshot = bodyRecord.metabolismSnapshot {
                self.metabolismSnapshotMapper.updateEntity(snapshot, from: metabolismData)
            } else {
                // 📚 학습 포인트: Create if Not Exists
                // 관계가 없으면 새로 생성
                let snapshot = self.metabolismSnapshotMapper.toEntity(metabolismData, context: context)
                bodyRecord.metabolismSnapshot = snapshot
                snapshot.bodyRecord = bodyRecord
            }

            try context.save()

            return try self.bodyRecordMapper.toDomain(bodyRecord)
        }
    }

    // MARK: - Delete

    /// 특정 신체 구성 기록을 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 레코드 삭제
    /// - Cascade delete: 연관된 MetabolismData도 함께 삭제 (Core Data 모델에서 설정됨)
    /// - 성능: <0.2초 (단일 레코드 삭제)
    ///
    /// - Parameter id: 삭제할 기록의 고유 식별자
    /// - Throws: 삭제 실패 시 에러
    func delete(by id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let bodyRecord = results.first else {
                throw NSError(
                    domain: "BodyLocalDataSource",
                    code: 1005,
                    userInfo: [NSLocalizedDescriptionKey: "삭제할 기록을 찾을 수 없습니다 (ID: \(id))"]
                )
            }

            // 📚 학습 포인트: Context Delete
            // Core Data에서 엔티티 삭제
            // Cascade rule에 의해 연관된 MetabolismSnapshot도 자동 삭제됨
            context.delete(bodyRecord)

            try context.save()
        }
    }

    /// 모든 신체 구성 기록을 삭제합니다.
    /// 📚 학습 포인트: Bulk Delete
    /// - 배치 삭제 작업
    /// - 테스트나 데이터 초기화에 사용
    /// - 성능: <0.5초
    /// 💡 주의: 실제 앱에서는 신중하게 사용해야 함
    ///
    /// - Throws: 삭제 실패 시 에러
    func deleteAll() async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            // 📚 학습 포인트: Batch Delete Request
            // iOS 9+에서 지원하는 효율적인 배치 삭제
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = BodyRecord.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            // 📚 학습 포인트: Result Type
            // 삭제된 객체의 ID를 반환받도록 설정
            batchDeleteRequest.resultType = .resultTypeObjectIDs

            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult

            // 📚 학습 포인트: Merge Changes
            // 배치 삭제는 context를 거치지 않으므로 변경사항을 수동으로 merge
            if let objectIDArray = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [self.persistenceController.viewContext]
                )
            }
        }
    }

    // MARK: - Metabolism Data

    /// 특정 신체 구성 기록과 연결된 대사율 데이터를 조회합니다.
    /// 📚 학습 포인트: Related Entity Query
    /// - 1:1 관계의 연관 엔티티 조회
    /// - 성능: <0.1초 (관계 인덱스 활용)
    ///
    /// - Parameter bodyEntryId: 신체 구성 기록 ID
    /// - Returns: 연결된 대사율 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetchMetabolismData(for bodyEntryId: UUID) async throws -> MetabolismData? {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<BodyRecord> = BodyRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", bodyEntryId as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let bodyRecord = results.first else { return nil }

            // 📚 학습 포인트: Relationship Navigation
            // Core Data의 관계를 통해 연관된 엔티티 접근
            guard let snapshot = bodyRecord.metabolismSnapshot else { return nil }

            return try self.metabolismSnapshotMapper.toDomain(snapshot)
        }
    }

    // MARK: - Statistics

    /// 지정된 기간의 통계 데이터를 조회합니다.
    /// 📚 학습 포인트: Aggregate Query
    /// - Core Data의 집계 함수 사용
    /// - 평균, 최소, 최대 등의 통계 계산
    /// - 성능: <0.3초
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜
    ///   - endDate: 조회 종료 날짜
    /// - Returns: 기간 내 통계 데이터
    /// - Throws: 조회 실패 시 에러
    func fetchStatistics(from startDate: Date, to endDate: Date) async throws -> BodyCompositionStatistics {
        let context = persistenceController.viewContext

        return try await context.perform {
            let calendar = Calendar.current
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: endDate) else {
                throw NSError(
                    domain: "BodyLocalDataSource",
                    code: 1006,
                    userInfo: [NSLocalizedDescriptionKey: "날짜 계산 실패"]
                )
            }

            // 📚 학습 포인트: Expression Description
            // Core Data의 집계 함수를 사용하여 통계 계산
            // 💡 Java 비교: JPA의 CriteriaBuilder.avg(), min(), max()와 유사

            // Weight statistics
            let avgWeightExpression = NSExpressionDescription()
            avgWeightExpression.name = "avgWeight"
            avgWeightExpression.expression = NSExpression(forFunction: "average:", arguments: [NSExpression(forKeyPath: "weight")])
            avgWeightExpression.expressionResultType = .decimalAttributeType

            let minWeightExpression = NSExpressionDescription()
            minWeightExpression.name = "minWeight"
            minWeightExpression.expression = NSExpression(forFunction: "min:", arguments: [NSExpression(forKeyPath: "weight")])
            minWeightExpression.expressionResultType = .decimalAttributeType

            let maxWeightExpression = NSExpressionDescription()
            maxWeightExpression.name = "maxWeight"
            maxWeightExpression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "weight")])
            maxWeightExpression.expressionResultType = .decimalAttributeType

            // Body fat percentage statistics
            let avgBodyFatExpression = NSExpressionDescription()
            avgBodyFatExpression.name = "avgBodyFat"
            avgBodyFatExpression.expression = NSExpression(forFunction: "average:", arguments: [NSExpression(forKeyPath: "bodyFatPercent")])
            avgBodyFatExpression.expressionResultType = .decimalAttributeType

            let minBodyFatExpression = NSExpressionDescription()
            minBodyFatExpression.name = "minBodyFat"
            minBodyFatExpression.expression = NSExpression(forFunction: "min:", arguments: [NSExpression(forKeyPath: "bodyFatPercent")])
            minBodyFatExpression.expressionResultType = .decimalAttributeType

            let maxBodyFatExpression = NSExpressionDescription()
            maxBodyFatExpression.name = "maxBodyFat"
            maxBodyFatExpression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "bodyFatPercent")])
            maxBodyFatExpression.expressionResultType = .decimalAttributeType

            // Muscle mass statistics
            let avgMuscleExpression = NSExpressionDescription()
            avgMuscleExpression.name = "avgMuscle"
            avgMuscleExpression.expression = NSExpression(forFunction: "average:", arguments: [NSExpression(forKeyPath: "muscleMass")])
            avgMuscleExpression.expressionResultType = .decimalAttributeType

            let minMuscleExpression = NSExpressionDescription()
            minMuscleExpression.name = "minMuscle"
            minMuscleExpression.expression = NSExpression(forFunction: "min:", arguments: [NSExpression(forKeyPath: "muscleMass")])
            minMuscleExpression.expressionResultType = .decimalAttributeType

            let maxMuscleExpression = NSExpressionDescription()
            maxMuscleExpression.name = "maxMuscle"
            maxMuscleExpression.expression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "muscleMass")])
            maxMuscleExpression.expressionResultType = .decimalAttributeType

            // Count
            let countExpression = NSExpressionDescription()
            countExpression.name = "count"
            countExpression.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "id")])
            countExpression.expressionResultType = .integer64AttributeType

            let request: NSFetchRequest<NSFetchRequestResult> = BodyRecord.fetchRequest()
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startDate as NSDate,
                endOfDay as NSDate
            )
            request.resultType = .dictionaryResultType
            request.propertiesToFetch = [
                avgWeightExpression, minWeightExpression, maxWeightExpression,
                avgBodyFatExpression, minBodyFatExpression, maxBodyFatExpression,
                avgMuscleExpression, minMuscleExpression, maxMuscleExpression,
                countExpression
            ]

            let results = try context.fetch(request)

            // 📚 학습 포인트: Parse Aggregate Results
            // 집계 결과를 Dictionary에서 추출
            guard let result = results.first as? [String: Any] else {
                // 📚 학습 포인트: Empty Statistics
                // 데이터가 없을 경우 0으로 초기화된 통계 반환
                return BodyCompositionStatistics(
                    averageWeight: 0,
                    minWeight: 0,
                    maxWeight: 0,
                    averageBodyFatPercent: 0,
                    minBodyFatPercent: 0,
                    maxBodyFatPercent: 0,
                    averageMuscleMass: 0,
                    minMuscleMass: 0,
                    maxMuscleMass: 0,
                    recordCount: 0
                )
            }

            return BodyCompositionStatistics(
                averageWeight: (result["avgWeight"] as? NSDecimalNumber)?.decimalValue ?? 0,
                minWeight: (result["minWeight"] as? NSDecimalNumber)?.decimalValue ?? 0,
                maxWeight: (result["maxWeight"] as? NSDecimalNumber)?.decimalValue ?? 0,
                averageBodyFatPercent: (result["avgBodyFat"] as? NSDecimalNumber)?.decimalValue ?? 0,
                minBodyFatPercent: (result["minBodyFat"] as? NSDecimalNumber)?.decimalValue ?? 0,
                maxBodyFatPercent: (result["maxBodyFat"] as? NSDecimalNumber)?.decimalValue ?? 0,
                averageMuscleMass: (result["avgMuscle"] as? NSDecimalNumber)?.decimalValue ?? 0,
                minMuscleMass: (result["minMuscle"] as? NSDecimalNumber)?.decimalValue ?? 0,
                maxMuscleMass: (result["maxMuscle"] as? NSDecimalNumber)?.decimalValue ?? 0,
                recordCount: (result["count"] as? Int) ?? 0
            )
        }
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Local Data Source Pattern 이해
///
/// Local Data Source의 역할:
/// - Repository와 Core Data 사이의 추상화 레이어
/// - Core Data 특화된 작업 수행 (NSFetchRequest, NSManagedObjectContext 등)
/// - Mapper를 활용하여 Domain Entity와 Core Data Entity 변환
/// - 성능 최적화 (백그라운드 컨텍스트, 인덱스 활용 등)
///
/// 주요 특징:
/// 1. 관계 자동 생성
///    - BodyRecord 저장 시 MetabolismSnapshot 자동 생성 및 연결
///    - 1:1 관계 유지
///
/// 2. 백그라운드 처리
///    - Write 작업은 백그라운드 컨텍스트 사용
///    - Read 작업은 viewContext 사용 (UI 업데이트 위해)
///
/// 3. 날짜 범위 쿼리 최적화
///    - 트렌드 차트를 위한 효율적인 쿼리
///    - 날짜 인덱스 활용 (Core Data 모델에서 설정 필요)
///
/// 4. 집계 쿼리
///    - Core Data의 NSExpression을 활용한 통계 계산
///    - 데이터베이스 레벨에서 집계하여 성능 향상
///
/// 성능 고려사항:
/// - 모든 쿼리는 0.5초 이내 완료 목표
/// - 날짜 필드에 인덱스 설정 필수 (Core Data 모델에서)
/// - 대량 데이터는 백그라운드 컨텍스트 사용
/// - Batch 작업 활용 (NSBatchDeleteRequest 등)
///
/// 사용 예시:
/// ```swift
/// let dataSource = BodyLocalDataSource()
///
/// // 저장
/// let entry = BodyCompositionEntry(weight: 70, bodyFatPercent: 18, muscleMass: 32)
/// let metabolism = MetabolismData(bmr: 1650, tdee: 2280, ...)
/// let saved = try await dataSource.save(entry: entry, metabolismData: metabolism)
///
/// // 조회
/// let latest = try await dataSource.fetchLatest()
/// let recent = try await dataSource.fetchRecent(days: 7)
///
/// // 통계
/// let stats = try await dataSource.fetchStatistics(from: startDate, to: endDate)
/// ```
///
/// 💡 실무 팁:
/// - Data Source는 Repository에서만 사용 (직접 사용 지양)
/// - 에러는 구체적으로 정의하여 Repository에서 처리
/// - 성능 측정 및 모니터링 중요
/// - Core Data 인덱스 설정 잊지 말기
///
