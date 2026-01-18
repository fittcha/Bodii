//
//  SleepLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Local Data Source for Sleep Tracking
// Core Data 작업을 담당하는 데이터 소스 레이어
// 💡 Java 비교: DAO (Data Access Object)와 유사한 역할

import Foundation
import CoreData

// MARK: - SleepLocalDataSource

/// SleepRecord의 Core Data 작업을 담당하는 로컬 데이터 소스
/// 📚 학습 포인트: Clean Architecture - Data Source Layer
/// - Repository와 Core Data 사이의 추상화 레이어
/// - Core Data 특화된 작업 수행 (NSFetchRequest, NSManagedObjectContext 등)
/// - Mapper를 활용하여 Domain Entity와 Core Data Entity 변환
/// - 02:00 경계 로직 적용 (DateUtils.getLogicalDate)
/// - SleepRecord 저장 시 DailyLog 자동 업데이트
/// 💡 Java 비교: JPA를 사용하는 DAO 구현체와 유사
///
/// 성능 요구사항:
/// - 모든 쿼리는 0.5초 이내에 완료
/// - 대량 작업은 백그라운드 컨텍스트 사용
/// - 날짜 필드에 인덱스 활용
final class SleepLocalDataSource {

    // MARK: - Constants

    /// 최대 조회 레코드 수
    /// 📚 학습 포인트: Performance Safeguard Constant
    /// - 한 번에 너무 많은 데이터를 로드하지 않도록 제한
    /// - 실제 앱에서는 페이징 구현 권장
    private static let maxFetchLimit = 1000

    // MARK: - Properties

    /// Core Data 스택 관리자
    /// 📚 학습 포인트: Dependency Injection
    /// - PersistenceController를 외부에서 주입받아 사용
    /// - 테스트 시 인메모리 컨트롤러로 교체 가능
    private let persistenceController: PersistenceController

    /// SleepRecord 매퍼
    /// 📚 학습 포인트: Mapper Pattern
    /// - Core Data Entity ↔ Domain Entity 변환 담당
    private let sleepRecordMapper: SleepRecordMapper

    // MARK: - Initialization

    /// SleepLocalDataSource 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 의존성을 생성자를 통해 주입받음
    /// - 기본값으로 shared instance 사용
    /// 💡 Java 비교: @Autowired 또는 생성자 주입과 유사
    ///
    /// - Parameter persistenceController: Core Data 스택 관리자
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.sleepRecordMapper = SleepRecordMapper()
    }

    // MARK: - Create

    /// 새로운 수면 기록을 저장합니다.
    /// 📚 학습 포인트: Transactional Operation with Side Effects
    /// - SleepRecord 생성
    /// - 02:00 경계 로직 적용 (DateUtils.getLogicalDate)
    /// - DailyLog 자동 업데이트 (sleepDuration, sleepStatus)
    /// - 하나의 트랜잭션에서 모두 처리 (원자성 보장)
    /// 💡 Java 비교: @Transactional 메서드와 유사
    ///
    /// - Parameter sleepRecord: 저장할 수면 기록 데이터
    /// - Returns: 저장된 수면 기록 데이터
    /// - Throws: 저장 실패 시 에러
    func save(sleepRecord: Bodii.SleepRecord) async throws -> Bodii.SleepRecord {
        // 📚 학습 포인트: Background Context for Write Operations
        // UI 블로킹을 방지하기 위해 백그라운드 컨텍스트 사용
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            // 📚 학습 포인트: 02:00 Boundary Logic
            // DateUtils.getLogicalDate를 사용하여 논리적 날짜 계산
            // 00:00-01:59 입력 시 전날로 처리
            let logicalDate = DateUtils.getLogicalDate(for: sleepRecord.date)

            // 📚 학습 포인트: Mapper 사용
            // Domain entity를 Core Data entity로 변환
            var adjustedSleepRecord = sleepRecord
            adjustedSleepRecord.date = logicalDate

            let sleepRecordEntity = self.sleepRecordMapper.toEntity(adjustedSleepRecord, context: context)

            // 📚 학습 포인트: User Relationship
            // 현재는 단일 사용자 가정, 향후 다중 사용자 지원 시 수정 필요
            // TODO: User 가져와서 연결

            // 📚 학습 포인트: DailyLog Update
            // SleepRecord 저장 시 해당 날짜의 DailyLog를 자동으로 업데이트
            try self.updateDailyLog(
                for: logicalDate,
                duration: sleepRecord.duration,
                status: sleepRecord.status,
                context: context
            )

            // 📚 학습 포인트: Context Save
            // 변경사항을 영구 저장소에 기록
            do {
                try context.save()
            } catch {
                // 📚 학습 포인트: Error Wrapping
                // Core Data 에러를 더 구체적인 도메인 에러로 변환
                throw NSError(
                    domain: "SleepLocalDataSource",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "저장 실패: \(error.localizedDescription)"]
                )
            }

            // 📚 학습 포인트: Return Saved Entity
            // 저장된 Core Data entity를 다시 Domain entity로 변환
            // ID가 할당되고 관계가 설정된 최신 상태를 반환
            return try self.sleepRecordMapper.toDomain(sleepRecordEntity)
        }
    }

    // MARK: - Read (Single)

    /// ID로 특정 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Fetch by ID
    /// - UUID 기반 조회
    /// - 성능: <0.1초 (Primary Key 조회)
    ///
    /// - Parameter id: 조회할 기록의 고유 식별자
    /// - Returns: 수면 기록 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetch(by id: UUID) async throws -> Bodii.SleepRecord? {
        let context = persistenceController.viewContext

        return try await context.perform {
            // 📚 학습 포인트: NSFetchRequest
            // Core Data의 쿼리 객체
            // 💡 Java 비교: JPA의 CriteriaQuery와 유사
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            // 📚 학습 포인트: Optional Mapping
            // 결과가 있으면 변환, 없으면 nil 반환
            guard let sleepRecordEntity = results.first else { return nil }
            return try self.sleepRecordMapper.toDomain(sleepRecordEntity)
        }
    }

    /// 특정 날짜의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Date Query with 02:00 Boundary
    /// - 02:00 경계 로직 적용된 날짜로 조회
    /// - 같은 날에 여러 기록이 있을 수 있으므로 가장 최근 것 반환
    /// - 성능: <0.2초 (날짜 인덱스 활용)
    ///
    /// - Parameter date: 조회할 날짜
    /// - Returns: 해당 날짜의 수면 기록 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetch(for date: Date) async throws -> Bodii.SleepRecord? {
        let context = persistenceController.viewContext

        return try await context.perform {
            // 📚 학습 포인트: 02:00 Boundary Logic
            // 논리적 날짜로 변환하여 조회
            let logicalDate = DateUtils.getLogicalDate(for: date)

            // 📚 학습 포인트: Date Range for Single Day
            // 날짜의 시작과 끝을 계산하여 범위 쿼리
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: logicalDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return nil
            }

            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            // 📚 학습 포인트: NSPredicate with Date Range
            // date >= startOfDay AND date < endOfDay
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )

            // 📚 학습 포인트: Sort Descriptor
            // 같은 날에 여러 기록이 있을 경우 가장 최근 것을 가져오기 위해 정렬
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let sleepRecordEntity = results.first else { return nil }
            return try self.sleepRecordMapper.toDomain(sleepRecordEntity)
        }
    }

    /// 가장 최근의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Latest Record Query
    /// - 날짜 기준 내림차순 정렬 후 첫 번째 결과
    /// - 성능: <0.1초 (날짜 인덱스 + LIMIT 1)
    ///
    /// - Returns: 가장 최근 수면 기록 데이터 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetchLatest() async throws -> Bodii.SleepRecord? {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let sleepRecordEntity = results.first else { return nil }
            return try self.sleepRecordMapper.toDomain(sleepRecordEntity)
        }
    }

    // MARK: - Read (Multiple)

    /// 모든 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Fetch All
    /// - 날짜 내림차순 정렬 (최신순)
    /// - 성능: <0.5초 (최대 1000개 레코드 기준)
    /// 💡 주의: 데이터가 많아지면 fetchAll 대신 date range 쿼리 사용 권장
    ///
    /// - Returns: 모든 수면 기록 데이터 배열
    /// - Throws: 조회 실패 시 에러
    func fetchAll() async throws -> [Bodii.SleepRecord] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            // 📚 학습 포인트: Performance Safeguard
            // 너무 많은 데이터를 한 번에 로드하지 않도록 제한
            // 실제 앱에서는 페이징 구현 권장
            request.fetchLimit = Self.maxFetchLimit

            let results = try context.fetch(request)

            // 📚 학습 포인트: Collection Transformation
            // map을 사용하여 배열 전체를 변환
            return try self.sleepRecordMapper.toDomain(results)
        }
    }

    /// 지정된 기간의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Date Range Query
    /// - 트렌드 차트를 위한 핵심 쿼리
    /// - 날짜 인덱스를 활용한 최적화
    /// - 성능: <0.3초 (날짜 범위 쿼리, 최대 90일 기준)
    ///
    /// - Parameters:
    ///   - startDate: 조회 시작 날짜 (inclusive)
    ///   - endDate: 조회 종료 날짜 (inclusive)
    /// - Returns: 기간 내 수면 기록 데이터 배열 (날짜 오름차순)
    /// - Throws: 조회 실패 시 에러
    func fetch(from startDate: Date, to endDate: Date) async throws -> [Bodii.SleepRecord] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()

            // 📚 학습 포인트: Date Range Predicate
            // startDate <= date <= endDate
            // 종료 날짜의 23:59:59까지 포함하기 위해 +1일 하여 '<' 비교
            let calendar = Calendar.current
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: endDate) else {
                throw NSError(
                    domain: "SleepLocalDataSource",
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

            return try self.sleepRecordMapper.toDomain(results)
        }
    }

    /// 최근 N일간의 수면 기록을 조회합니다.
    /// 📚 학습 포인트: Convenience Method
    /// - fetch(from:to:)의 편의 메서드
    /// - 자주 사용되는 패턴을 간단히 표현
    ///
    /// - Parameter days: 조회할 일수 (예: 7, 30, 90)
    /// - Returns: 최근 N일간의 수면 기록 데이터 배열 (날짜 오름차순)
    /// - Throws: 조회 실패 시 에러
    func fetchRecent(days: Int) async throws -> [Bodii.SleepRecord] {
        // 📚 학습 포인트: Date Calculation
        // 현재 시간에서 N일 전 계산
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            throw NSError(
                domain: "SleepLocalDataSource",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "날짜 계산 실패"]
            )
        }

        return try await fetch(from: startDate, to: endDate)
    }

    // MARK: - Update

    /// 기존 수면 기록을 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - 02:00 경계 로직 적용
    /// - DailyLog도 함께 업데이트
    /// - 성능: <0.2초 (단일 레코드 업데이트)
    ///
    /// - Parameter sleepRecord: 수정할 수면 기록 데이터 (ID 포함)
    /// - Returns: 수정된 수면 기록 데이터
    /// - Throws: 수정 실패 시 에러
    func update(sleepRecord: Bodii.SleepRecord) async throws -> Bodii.SleepRecord {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            // 📚 학습 포인트: Fetch Before Update
            // 업데이트할 엔티티를 먼저 조회
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", sleepRecord.id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let sleepRecordEntity = results.first else {
                throw NSError(
                    domain: "SleepLocalDataSource",
                    code: 1004,
                    userInfo: [NSLocalizedDescriptionKey: "수정할 기록을 찾을 수 없습니다 (ID: \(sleepRecord.id))"]
                )
            }

            // 📚 학습 포인트: Store Old Date for DailyLog Update
            // 날짜가 변경될 수 있으므로 이전 날짜의 DailyLog도 업데이트 필요
            let oldDate = sleepRecordEntity.date ?? Date()

            // 📚 학습 포인트: 02:00 Boundary Logic
            // DateUtils.getLogicalDate를 사용하여 논리적 날짜 계산
            let logicalDate = DateUtils.getLogicalDate(for: sleepRecord.date)

            var adjustedSleepRecord = sleepRecord
            adjustedSleepRecord.date = logicalDate

            // 📚 학습 포인트: Update Entity
            // Mapper의 updateEntity 메서드 사용
            self.sleepRecordMapper.updateEntity(sleepRecordEntity, from: adjustedSleepRecord)

            // 📚 학습 포인트: Update DailyLog for Both Dates
            // 날짜가 변경되었다면 이전 날짜의 DailyLog에서 수면 데이터 제거
            if !Calendar.current.isDate(oldDate, inSameDayAs: logicalDate) {
                try self.updateDailyLog(
                    for: oldDate,
                    duration: nil,
                    status: nil,
                    context: context
                )
            }

            // 새로운 날짜의 DailyLog 업데이트
            try self.updateDailyLog(
                for: logicalDate,
                duration: sleepRecord.duration,
                status: sleepRecord.status,
                context: context
            )

            try context.save()

            return try self.sleepRecordMapper.toDomain(sleepRecordEntity)
        }
    }

    // MARK: - Delete

    /// 특정 수면 기록을 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 레코드 삭제
    /// - DailyLog의 수면 데이터도 함께 제거
    /// - 성능: <0.2초 (단일 레코드 삭제)
    ///
    /// - Parameter id: 삭제할 기록의 고유 식별자
    /// - Throws: 삭제 실패 시 에러
    func delete(by id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<SleepRecord> = SleepRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let sleepRecordEntity = results.first else {
                throw NSError(
                    domain: "SleepLocalDataSource",
                    code: 1005,
                    userInfo: [NSLocalizedDescriptionKey: "삭제할 기록을 찾을 수 없습니다 (ID: \(id))"]
                )
            }

            // 📚 학습 포인트: Store Date for DailyLog Update
            // 삭제 전에 날짜를 저장하여 DailyLog 업데이트
            let date = sleepRecordEntity.date ?? Date()

            // 📚 학습 포인트: Context Delete
            // Core Data에서 엔티티 삭제
            context.delete(sleepRecordEntity)

            // 📚 학습 포인트: Update DailyLog
            // 해당 날짜의 DailyLog에서 수면 데이터 제거
            try self.updateDailyLog(
                for: date,
                duration: nil,
                status: nil,
                context: context
            )

            try context.save()
        }
    }

    /// 모든 수면 기록을 삭제합니다.
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
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SleepRecord.fetchRequest()
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

            // 📚 학습 포인트: Clear All DailyLog Sleep Data
            // 모든 DailyLog의 수면 데이터를 nil로 설정
            // 💡 주의: 프로덕션에서는 사용 시 주의 필요
            let dailyLogRequest: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
            let dailyLogs = try context.fetch(dailyLogRequest)

            for dailyLog in dailyLogs {
                dailyLog.sleepDuration = nil
                dailyLog.sleepStatus = nil
            }

            try context.save()
        }
    }

    // MARK: - DailyLog Update Helper

    /// DailyLog의 수면 데이터를 업데이트합니다.
    /// 📚 학습 포인트: Side Effect Management
    /// - SleepRecord 변경 시 DailyLog 자동 업데이트
    /// - DailyLog가 없으면 생성 (lazy creation)
    /// - 트랜잭션 내에서 호출되어야 함
    ///
    /// - Parameters:
    ///   - date: 업데이트할 날짜
    ///   - duration: 수면 시간 (분 단위, nil이면 제거)
    ///   - status: 수면 상태 (nil이면 제거)
    ///   - context: Core Data 컨텍스트
    /// - Throws: 업데이트 실패 시 에러
    private func updateDailyLog(
        for date: Date,
        duration: Int32?,
        status: SleepStatus?,
        context: NSManagedObjectContext
    ) throws {
        // 📚 학습 포인트: Fetch or Create Pattern
        // DailyLog를 조회하고 없으면 생성
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw NSError(
                domain: "SleepLocalDataSource",
                code: 1006,
                userInfo: [NSLocalizedDescriptionKey: "날짜 계산 실패"]
            )
        }

        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1

        let results = try context.fetch(request)

        let dailyLog: DailyLog
        if let existingLog = results.first {
            dailyLog = existingLog
        } else {
            // 📚 학습 포인트: Lazy Creation
            // DailyLog가 없으면 새로 생성
            dailyLog = DailyLog(context: context)
            dailyLog.id = UUID()
            dailyLog.date = startOfDay
            dailyLog.createdAt = Date()

            // 📚 학습 포인트: Default Values
            // 초기 값 설정 (다른 필드는 기본값 0)
            dailyLog.bmr = 0
            dailyLog.tdee = 0
            dailyLog.netCalories = 0
            dailyLog.totalCaloriesIn = 0
            dailyLog.totalCaloriesOut = 0
            dailyLog.totalCarbs = 0
            dailyLog.totalProtein = 0
            dailyLog.totalFat = 0
            dailyLog.exerciseMinutes = 0
            dailyLog.exerciseCount = 0

            // TODO: User 가져와서 연결
        }

        // 📚 학습 포인트: Update Sleep Data
        // nil이면 제거, 값이 있으면 업데이트
        if let duration = duration {
            dailyLog.sleepDuration = duration
        } else {
            dailyLog.sleepDuration = nil
        }

        if let status = status {
            dailyLog.sleepStatus = status.rawValue
        } else {
            dailyLog.sleepStatus = nil
        }

        dailyLog.updatedAt = Date()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepLocalDataSource의 특징
///
/// Local Data Source의 역할:
/// - Repository와 Core Data 사이의 추상화 레이어
/// - Core Data 특화된 작업 수행 (NSFetchRequest, NSManagedObjectContext 등)
/// - Mapper를 활용하여 Domain Entity와 Core Data Entity 변환
/// - 성능 최적화 (백그라운드 컨텍스트, 인덱스 활용 등)
///
/// 주요 특징:
/// 1. 02:00 경계 로직 적용
///    - DateUtils.getLogicalDate를 사용
///    - 00:00-01:59는 전날로 처리
///    - 입력 시와 조회 시 모두 적용
///
/// 2. DailyLog 자동 업데이트
///    - SleepRecord 저장/수정/삭제 시 DailyLog 동기화
///    - sleepDuration과 sleepStatus 필드 업데이트
///    - DailyLog가 없으면 자동 생성 (lazy creation)
///
/// 3. 백그라운드 처리
///    - Write 작업은 백그라운드 컨텍스트 사용
///    - Read 작업은 viewContext 사용 (UI 업데이트 위해)
///
/// 4. 날짜 범위 쿼리 최적화
///    - 트렌드 차트를 위한 효율적인 쿼리
///    - 날짜 인덱스 활용 (Core Data 모델에서 설정 필요)
///
/// BodyLocalDataSource와의 차이점:
/// - BodyLocalDataSource는 BodyRecord와 MetabolismSnapshot을 함께 관리
/// - SleepLocalDataSource는 SleepRecord와 DailyLog를 함께 관리
/// - SleepLocalDataSource는 02:00 경계 로직이 추가로 적용됨
///
/// 성능 고려사항:
/// - 모든 쿼리는 0.5초 이내 완료 목표
/// - 날짜 필드에 인덱스 설정 필수 (Core Data 모델에서)
/// - 대량 데이터는 백그라운드 컨텍스트 사용
/// - Batch 작업 활용 (NSBatchDeleteRequest 등)
///
/// 사용 예시:
/// ```swift
/// let dataSource = SleepLocalDataSource()
///
/// // 저장
/// let sleepRecord = Bodii.SleepRecord(
///     id: UUID(),
///     userId: user.id,
///     date: Date(),
///     duration: 420,
///     status: .good,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// let saved = try await dataSource.save(sleepRecord: sleepRecord)
///
/// // 조회
/// let latest = try await dataSource.fetchLatest()
/// let recent = try await dataSource.fetchRecent(days: 7)
/// let forDate = try await dataSource.fetch(for: Date())
///
/// // 업데이트
/// var updated = saved
/// updated.duration = 450
/// updated.status = .excellent
/// try await dataSource.update(sleepRecord: updated)
///
/// // 삭제
/// try await dataSource.delete(by: saved.id)
/// ```
///
/// 💡 실무 팁:
/// - Data Source는 Repository에서만 사용 (직접 사용 지양)
/// - 에러는 구체적으로 정의하여 Repository에서 처리
/// - 성능 측정 및 모니터링 중요
/// - Core Data 인덱스 설정 잊지 말기
/// - DailyLog 업데이트는 트랜잭션 내에서 처리하여 원자성 보장
///
