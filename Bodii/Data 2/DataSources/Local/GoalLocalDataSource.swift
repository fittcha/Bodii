//
//  GoalLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Local Data Source
// Core Data 작업을 담당하는 데이터 소스 레이어
// 💡 Java 비교: DAO (Data Access Object)와 유사한 역할

import Foundation
import CoreData

// MARK: - GoalLocalDataSource

/// Goal의 Core Data 작업을 담당하는 로컬 데이터 소스
/// 📚 학습 포인트: Clean Architecture - Data Source Layer
/// - Repository와 Core Data 사이의 추상화 레이어
/// - Core Data 특화된 작업 수행 (NSFetchRequest, NSManagedObjectContext 등)
/// - Domain Entity와 Core Data Entity 변환
/// 💡 Java 비교: JPA를 사용하는 DAO 구현체와 유사
///
/// 성능 요구사항:
/// - 모든 쿼리는 0.5초 이내에 완료
/// - 대량 작업은 백그라운드 컨텍스트 사용
/// - isActive 필드에 인덱스 활용
final class GoalLocalDataSource {

    // MARK: - Properties

    /// Core Data 스택 관리자
    /// 📚 학습 포인트: Dependency Injection
    /// - PersistenceController를 외부에서 주입받아 사용
    /// - 테스트 시 인메모리 컨트롤러로 교체 가능
    private let persistenceController: PersistenceController

    // MARK: - Initialization

    /// GoalLocalDataSource 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - 의존성을 생성자를 통해 주입받음
    /// - 기본값으로 shared instance 사용
    /// 💡 Java 비교: @Autowired 또는 생성자 주입과 유사
    ///
    /// - Parameter persistenceController: Core Data 스택 관리자
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Create

    /// 새로운 목표를 저장합니다.
    /// 📚 학습 포인트: Create Operation
    /// - 새로운 Goal 엔티티 생성 및 저장
    /// - 백그라운드 컨텍스트에서 처리
    /// - 성능: <0.2초 (단일 레코드 생성)
    ///
    /// - Parameter goal: 저장할 목표 도메인 엔티티
    /// - Returns: 저장된 목표 엔티티 (ID가 할당된 상태)
    /// - Throws: 저장 실패 시 에러
    func save(_ goal: Bodii.Goal) async throws -> Bodii.Goal {
        // 📚 학습 포인트: Background Context for Write Operations
        // UI 블로킹을 방지하기 위해 백그라운드 컨텍스트 사용
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            // 📚 학습 포인트: Create Core Data Entity
            // NSManagedObject를 context와 함께 생성
            let goalEntity = NSEntityDescription.insertNewObject(forEntityName: "Goal", into: context)

            // 📚 학습 포인트: Value Assignment
            // Domain entity의 값을 Core Data entity로 복사
            goalEntity.setValue(goal.id, forKey: "id")
            goalEntity.setValue(goal.goalType.rawValue, forKey: "goalType")
            goalEntity.setValue(goal.targetWeight as NSDecimalNumber?, forKey: "targetWeight")
            goalEntity.setValue(goal.targetBodyFatPct as NSDecimalNumber?, forKey: "targetBodyFatPct")
            goalEntity.setValue(goal.targetMuscleMass as NSDecimalNumber?, forKey: "targetMuscleMass")
            goalEntity.setValue(goal.weeklyWeightRate as NSDecimalNumber?, forKey: "weeklyWeightRate")
            goalEntity.setValue(goal.weeklyFatPctRate as NSDecimalNumber?, forKey: "weeklyFatPctRate")
            goalEntity.setValue(goal.weeklyMuscleRate as NSDecimalNumber?, forKey: "weeklyMuscleRate")
            goalEntity.setValue(goal.startWeight as NSDecimalNumber?, forKey: "startWeight")
            goalEntity.setValue(goal.startBodyFatPct as NSDecimalNumber?, forKey: "startBodyFatPct")
            goalEntity.setValue(goal.startMuscleMass as NSDecimalNumber?, forKey: "startMuscleMass")
            goalEntity.setValue(goal.startBMR as NSDecimalNumber?, forKey: "startBMR")
            goalEntity.setValue(goal.startTDEE as NSDecimalNumber?, forKey: "startTDEE")
            goalEntity.setValue(goal.dailyCalorieTarget ?? 0, forKey: "dailyCalorieTarget")
            goalEntity.setValue(goal.isActive, forKey: "isActive")
            goalEntity.setValue(goal.createdAt, forKey: "createdAt")
            goalEntity.setValue(goal.updatedAt, forKey: "updatedAt")

            // 📚 학습 포인트: User Relationship
            // User 엔티티를 조회하여 관계 설정
            let userRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "User")
            userRequest.predicate = NSPredicate(format: "id == %@", goal.userId as CVarArg)
            userRequest.fetchLimit = 1

            if let user = try context.fetch(userRequest).first {
                goalEntity.setValue(user, forKey: "user")
            }

            // 📚 학습 포인트: Context Save
            // 변경사항을 영구 저장소에 기록
            do {
                try context.save()
            } catch {
                // 📚 학습 포인트: Error Wrapping
                // Core Data 에러를 더 구체적인 도메인 에러로 변환
                throw NSError(
                    domain: "GoalLocalDataSource",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "목표 저장 실패: \(error.localizedDescription)"]
                )
            }

            // 📚 학습 포인트: Return Saved Entity
            // 저장된 Core Data entity를 다시 Domain entity로 변환
            return try self.toDomain(goalEntity)
        }
    }

    // MARK: - Read (Single)

    /// ID로 특정 목표를 조회합니다.
    /// 📚 학습 포인트: Fetch by ID
    /// - UUID 기반 조회
    /// - 성능: <0.1초 (Primary Key 조회)
    ///
    /// - Parameter id: 조회할 목표의 고유 식별자
    /// - Returns: 목표 엔티티 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetch(by id: UUID) async throws -> Bodii.Goal? {
        let context = persistenceController.viewContext

        return try await context.perform {
            // 📚 학습 포인트: NSFetchRequest
            // Core Data의 쿼리 객체
            // 💡 Java 비교: JPA의 CriteriaQuery와 유사
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            // 📚 학습 포인트: Optional Mapping
            // 결과가 있으면 변환, 없으면 nil 반환
            guard let goalEntity = results.first else { return nil }
            return try self.toDomain(goalEntity)
        }
    }

    /// 활성 목표를 조회합니다.
    /// 📚 학습 포인트: Filtered Query
    /// - isActive = true인 목표 조회
    /// - 사용자는 하나의 활성 목표만 가질 수 있음
    /// - 성능: <0.1초 (isActive 인덱스 활용)
    ///
    /// - Returns: 활성 목표 엔티티 (없으면 nil)
    /// - Throws: 조회 실패 시 에러
    func fetchActiveGoal() async throws -> Bodii.Goal? {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.predicate = NSPredicate(format: "isActive == YES")
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let goalEntity = results.first else { return nil }
            return try self.toDomain(goalEntity)
        }
    }

    // MARK: - Read (Multiple)

    /// 모든 목표를 조회합니다.
    /// 📚 학습 포인트: Fetch All
    /// - 생성일 내림차순 정렬 (최신순)
    /// - 성능: <0.5초
    ///
    /// - Returns: 모든 목표 엔티티 배열
    /// - Throws: 조회 실패 시 에러
    func fetchAll() async throws -> [Bodii.Goal] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            // 📚 학습 포인트: Performance Safeguard
            // 너무 많은 데이터를 한 번에 로드하지 않도록 제한
            request.fetchLimit = 100

            let results = try context.fetch(request)

            // 📚 학습 포인트: Collection Transformation
            // map을 사용하여 배열 전체를 변환
            return try results.map { try self.toDomain($0) }
        }
    }

    /// 비활성 목표 기록을 조회합니다.
    /// 📚 학습 포인트: Goal History
    /// - isActive = false인 목표 조회
    /// - 생성일 내림차순 정렬
    /// - 성능: <0.3초
    ///
    /// - Returns: 비활성 목표 엔티티 배열
    /// - Throws: 조회 실패 시 에러
    func fetchHistory() async throws -> [Bodii.Goal] {
        let context = persistenceController.viewContext

        return try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.predicate = NSPredicate(format: "isActive == NO")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.fetchLimit = 50

            let results = try context.fetch(request)

            return try results.map { try self.toDomain($0) }
        }
    }

    // MARK: - Update

    /// 기존 목표를 수정합니다.
    /// 📚 학습 포인트: Update Operation
    /// - ID로 기존 레코드를 찾아서 업데이트
    /// - 성능: <0.2초 (단일 레코드 업데이트)
    ///
    /// - Parameter goal: 수정할 목표 도메인 엔티티 (ID 포함)
    /// - Returns: 수정된 목표 엔티티
    /// - Throws: 수정 실패 시 에러
    func update(_ goal: Bodii.Goal) async throws -> Bodii.Goal {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            // 📚 학습 포인트: Fetch Before Update
            // 업데이트할 엔티티를 먼저 조회
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.predicate = NSPredicate(format: "id == %@", goal.id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let goalEntity = results.first else {
                throw NSError(
                    domain: "GoalLocalDataSource",
                    code: 1004,
                    userInfo: [NSLocalizedDescriptionKey: "수정할 목표를 찾을 수 없습니다 (ID: \(goal.id))"]
                )
            }

            // 📚 학습 포인트: Update Entity
            // 값 업데이트 (ID와 createdAt은 유지)
            goalEntity.setValue(goal.goalType.rawValue, forKey: "goalType")
            goalEntity.setValue(goal.targetWeight as NSDecimalNumber?, forKey: "targetWeight")
            goalEntity.setValue(goal.targetBodyFatPct as NSDecimalNumber?, forKey: "targetBodyFatPct")
            goalEntity.setValue(goal.targetMuscleMass as NSDecimalNumber?, forKey: "targetMuscleMass")
            goalEntity.setValue(goal.weeklyWeightRate as NSDecimalNumber?, forKey: "weeklyWeightRate")
            goalEntity.setValue(goal.weeklyFatPctRate as NSDecimalNumber?, forKey: "weeklyFatPctRate")
            goalEntity.setValue(goal.weeklyMuscleRate as NSDecimalNumber?, forKey: "weeklyMuscleRate")
            goalEntity.setValue(goal.startWeight as NSDecimalNumber?, forKey: "startWeight")
            goalEntity.setValue(goal.startBodyFatPct as NSDecimalNumber?, forKey: "startBodyFatPct")
            goalEntity.setValue(goal.startMuscleMass as NSDecimalNumber?, forKey: "startMuscleMass")
            goalEntity.setValue(goal.startBMR as NSDecimalNumber?, forKey: "startBMR")
            goalEntity.setValue(goal.startTDEE as NSDecimalNumber?, forKey: "startTDEE")
            goalEntity.setValue(goal.dailyCalorieTarget ?? 0, forKey: "dailyCalorieTarget")
            goalEntity.setValue(goal.isActive, forKey: "isActive")
            goalEntity.setValue(Date(), forKey: "updatedAt")

            try context.save()

            return try self.toDomain(goalEntity)
        }
    }

    /// 모든 활성 목표를 비활성화합니다.
    /// 📚 학습 포인트: Bulk Update
    /// - 새 목표 설정 시 기존 활성 목표를 비활성화하는 용도
    /// - 성능: <0.3초
    ///
    /// - Throws: 업데이트 실패 시 에러
    func deactivateAllGoals() async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.predicate = NSPredicate(format: "isActive == YES")

            let results = try context.fetch(request)

            // 📚 학습 포인트: Batch Update
            // 각 엔티티의 isActive를 false로 설정
            for goalEntity in results {
                goalEntity.setValue(false, forKey: "isActive")
                goalEntity.setValue(Date(), forKey: "updatedAt")
            }

            try context.save()
        }
    }

    // MARK: - Delete

    /// 특정 목표를 삭제합니다.
    /// 📚 학습 포인트: Delete Operation
    /// - ID로 목표 삭제
    /// - 성능: <0.2초 (단일 레코드 삭제)
    ///
    /// - Parameter id: 삭제할 목표의 고유 식별자
    /// - Throws: 삭제 실패 시 에러
    func delete(by id: UUID) async throws {
        let context = persistenceController.newBackgroundContext()

        try await context.perform {
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Goal")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            let results = try context.fetch(request)

            guard let goalEntity = results.first else {
                throw NSError(
                    domain: "GoalLocalDataSource",
                    code: 1005,
                    userInfo: [NSLocalizedDescriptionKey: "삭제할 목표를 찾을 수 없습니다 (ID: \(id))"]
                )
            }

            // 📚 학습 포인트: Context Delete
            // Core Data에서 엔티티 삭제
            context.delete(goalEntity)

            try context.save()
        }
    }

    /// 모든 목표를 삭제합니다.
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
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Goal")
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

    // MARK: - Mapper

    /// Core Data NSManagedObject를 Goal Domain Entity로 변환
    /// 📚 학습 포인트: Inline Mapper
    /// - 간단한 매핑 로직은 DataSource 내부에 포함
    /// - 복잡한 경우 별도 GoalMapper 클래스로 분리 가능
    ///
    /// - Parameter entity: Core Data Goal NSManagedObject
    /// - Returns: Domain Goal 엔티티
    /// - Throws: 필수 필드 누락 시 에러
    private func toDomain(_ entity: NSManagedObject) throws -> Bodii.Goal {
        guard let id = entity.value(forKey: "id") as? UUID else {
            throw NSError(
                domain: "GoalLocalDataSource",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "필수 필드 누락: id"]
            )
        }

        // 📚 학습 포인트: User Relationship Handling
        // User 관계에서 userId 추출
        guard let user = entity.value(forKey: "user") as? NSManagedObject,
              let userId = user.value(forKey: "id") as? UUID else {
            throw NSError(
                domain: "GoalLocalDataSource",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "필수 필드 누락: user.id"]
            )
        }

        guard let createdAt = entity.value(forKey: "createdAt") as? Date else {
            throw NSError(
                domain: "GoalLocalDataSource",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "필수 필드 누락: createdAt"]
            )
        }

        guard let updatedAt = entity.value(forKey: "updatedAt") as? Date else {
            throw NSError(
                domain: "GoalLocalDataSource",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "필수 필드 누락: updatedAt"]
            )
        }

        let goalTypeValue = entity.value(forKey: "goalType") as? Int16 ?? 0
        let goalType = GoalType(rawValue: goalTypeValue) ?? .lose

        let dailyCalorieTargetValue = entity.value(forKey: "dailyCalorieTarget") as? Int32 ?? 0
        let dailyCalorieTarget = dailyCalorieTargetValue == 0 ? nil : dailyCalorieTargetValue

        return Bodii.Goal(
            id: id,
            userId: userId,
            goalType: goalType,
            targetWeight: entity.value(forKey: "targetWeight") as? Decimal,
            targetBodyFatPct: entity.value(forKey: "targetBodyFatPct") as? Decimal,
            targetMuscleMass: entity.value(forKey: "targetMuscleMass") as? Decimal,
            weeklyWeightRate: entity.value(forKey: "weeklyWeightRate") as? Decimal,
            weeklyFatPctRate: entity.value(forKey: "weeklyFatPctRate") as? Decimal,
            weeklyMuscleRate: entity.value(forKey: "weeklyMuscleRate") as? Decimal,
            startWeight: entity.value(forKey: "startWeight") as? Decimal,
            startBodyFatPct: entity.value(forKey: "startBodyFatPct") as? Decimal,
            startMuscleMass: entity.value(forKey: "startMuscleMass") as? Decimal,
            startBMR: entity.value(forKey: "startBMR") as? Decimal,
            startTDEE: entity.value(forKey: "startTDEE") as? Decimal,
            dailyCalorieTarget: dailyCalorieTarget,
            isActive: entity.value(forKey: "isActive") as? Bool ?? true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: Goal Local Data Source Pattern 이해
///
/// GoalLocalDataSource의 역할:
/// - Repository와 Core Data 사이의 추상화 레이어
/// - Core Data 특화된 작업 수행 (NSFetchRequest, NSManagedObjectContext 등)
/// - Domain Entity와 Core Data Entity 변환
/// - 성능 최적화 (백그라운드 컨텍스트, 인덱스 활용 등)
///
/// 주요 특징:
/// 1. 활성 목표 관리
///    - fetchActiveGoal: 현재 활성 목표 조회
///    - deactivateAllGoals: 새 목표 설정 시 기존 목표 비활성화
///    - 하나의 활성 목표만 유지
///
/// 2. 목표 히스토리
///    - fetchHistory: 비활성화된 과거 목표 조회
///    - 목표 변경 이력 추적
///
/// 3. 백그라운드 처리
///    - Write 작업은 백그라운드 컨텍스트 사용
///    - Read 작업은 viewContext 사용 (UI 업데이트 위해)
///
/// 4. User 관계 처리
///    - Core Data는 user 관계로 저장
///    - Domain은 userId로 참조
///    - 저장 시: userId로 User 조회하여 관계 설정
///    - 로드 시: user 관계에서 userId 추출
///
/// 성능 고려사항:
/// - 모든 쿼리는 0.5초 이내 완료 목표
/// - isActive 필드에 인덱스 설정 권장
/// - 대량 데이터는 백그라운드 컨텍스트 사용
///
/// 사용 예시:
/// ```swift
/// let dataSource = GoalLocalDataSource()
///
/// // 새 목표 저장
/// let goal = Bodii.Goal(
///     id: UUID(),
///     userId: userId,
///     goalType: .lose,
///     targetWeight: 65.0,
///     isActive: true,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
/// let saved = try await dataSource.save(goal)
///
/// // 활성 목표 조회
/// let activeGoal = try await dataSource.fetchActiveGoal()
///
/// // 목표 히스토리 조회
/// let history = try await dataSource.fetchHistory()
/// ```
///
/// 💡 실무 팁:
/// - Data Source는 Repository에서만 사용 (직접 사용 지양)
/// - 에러는 구체적으로 정의하여 Repository에서 처리
/// - 성능 측정 및 모니터링 중요
/// - Core Data 인덱스 설정 잊지 말기
///
