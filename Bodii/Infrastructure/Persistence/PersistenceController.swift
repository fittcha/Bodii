//
//  PersistenceController.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-11.
//

// 📚 학습 포인트: Core Data Stack 관리
// Core Data의 핵심 컴포넌트인 NSPersistentContainer를 관리하는 컨트롤러
// 💡 Java 비교: JPA의 EntityManager/EntityManagerFactory와 유사한 역할

import CoreData

// MARK: - PersistenceController

/// Core Data 스택을 관리하는 컨트롤러
/// - 앱 전체에서 공유되는 싱글턴 인스턴스 제공
/// - SwiftUI Preview용 인메모리 인스턴스 제공
/// - 자동 경량 마이그레이션 지원
final class PersistenceController {

    // MARK: - Shared Instance

    // 📚 학습 포인트: Singleton Pattern in Swift
    // static let으로 선언하면 lazy하게 초기화되고 thread-safe
    // 💡 Java 비교: synchronized singleton과 달리 언어 레벨에서 thread-safe 보장
    static let shared = PersistenceController()

    // MARK: - Preview Instance

    // 📚 학습 포인트: SwiftUI Preview용 인스턴스
    // 실제 디스크에 저장하지 않고 메모리에서만 동작
    // Preview에서 실제 데이터를 사용하면 테스트가 느려지고 side effect 발생
    @MainActor
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // 📚 학습 포인트: Preview용 샘플 데이터 생성
        // SwiftUI Preview와 개발 중 테스트를 위한 샘플 데이터 생성
        // 실제 디스크에 저장되지 않고 메모리에만 존재
        let viewContext = controller.container.viewContext

        // 📚 학습 포인트: Sample Data Creation
        // 다양한 날짜의 신체 구성 데이터를 생성하여 트렌드 확인 가능
        // BodyRecord와 MetabolismSnapshot을 1:1 관계로 생성

        // 샘플 데이터 배열 생성 (30일치 데이터)
        let calendar = Calendar.current
        let today = Date()

        // 📚 학습 포인트: 현실적인 데이터 범위
        // 체중: 68-72kg 범위에서 변동
        // 체지방률: 17-20% 범위에서 변동 (감소 트렌드)
        // 근육량: 30-33kg 범위에서 증가
        let sampleDataSpecs: [(daysAgo: Int, weight: Double, bodyFatPercent: Double, muscleMass: Double, activityLevel: ActivityLevel)] = [
            // 📚 학습 포인트: 시계열 데이터 패턴
            // 최근 30일 동안 체중 감량 및 근육 증가 추세 시뮬레이션
            // 체중과 체지방률은 감소, 근육량은 증가하는 건강한 변화 패턴

            // 4주 전 (Week 1)
            (28, 72.0, 20.0, 30.0, .lightlyActive),
            (27, 71.8, 19.9, 30.2, .lightlyActive),
            (26, 71.6, 19.8, 30.4, .moderatelyActive),
            (25, 71.5, 19.7, 30.5, .moderatelyActive),

            // 3주 전 (Week 2)
            (21, 71.3, 19.5, 30.7, .moderatelyActive),
            (20, 71.1, 19.4, 30.9, .moderatelyActive),
            (19, 71.0, 19.3, 31.0, .moderatelyActive),
            (18, 70.8, 19.2, 31.2, .moderatelyActive),

            // 2주 전 (Week 3)
            (14, 70.6, 19.0, 31.4, .moderatelyActive),
            (13, 70.4, 18.9, 31.6, .moderatelyActive),
            (12, 70.3, 18.8, 31.8, .moderatelyActive),
            (11, 70.1, 18.7, 32.0, .veryActive),

            // 1주 전 (Week 4)
            (7, 69.9, 18.5, 32.2, .veryActive),
            (6, 69.7, 18.4, 32.4, .veryActive),
            (5, 69.5, 18.3, 32.6, .veryActive),
            (4, 69.3, 18.2, 32.8, .veryActive),

            // 최근 (This Week)
            (3, 69.0, 18.0, 33.0, .veryActive),
            (2, 68.8, 17.9, 33.2, .veryActive),
            (1, 68.5, 17.8, 33.4, .veryActive),
            (0, 68.3, 17.7, 33.5, .veryActive),
        ]

        // 📚 학습 포인트: Mapper Pattern Usage
        // Mapper를 사용하여 Domain Entity를 Core Data Entity로 변환
        let bodyMapper = BodyRecordMapper()
        let metabolismMapper = MetabolismSnapshotMapper()

        // 📚 학습 포인트: 샘플 UserProfile
        // BMR/TDEE 계산에 필요한 사용자 정보
        let sampleUserProfile = UserProfile(
            height: Decimal(175.5),
            birthDate: calendar.date(from: DateComponents(year: 1990, month: 6, day: 15))!,
            gender: .male,
            activityLevel: .moderatelyActive
        )

        // 각 날짜에 대해 BodyRecord와 MetabolismSnapshot 생성
        for spec in sampleDataSpecs {
            guard let date = calendar.date(byAdding: .day, value: -spec.daysAgo, to: today) else {
                continue
            }

            // 📚 학습 포인트: Domain Entity 생성
            // 먼저 Domain Entity를 생성하고 비즈니스 로직 적용
            let bodyEntry = BodyCompositionEntry(
                date: date,
                weight: Decimal(spec.weight),
                bodyFatPercent: Decimal(spec.bodyFatPercent),
                muscleMass: Decimal(spec.muscleMass)
            )

            // 📚 학습 포인트: BMR/TDEE 계산
            // Mifflin-St Jeor 공식으로 BMR 계산
            // 남성: (10 × weight) + (6.25 × height) - (5 × age) + 5
            let age = Decimal(sampleUserProfile.age)
            let bmr = (10 * bodyEntry.weight) +
                      (Decimal(6.25) * sampleUserProfile.height) -
                      (5 * age) + 5

            // TDEE = BMR × Activity Level Multiplier
            let tdee = bmr * Decimal(spec.activityLevel.multiplier)

            let metabolismData = MetabolismData(
                date: date,
                bmr: bmr,
                tdee: tdee,
                weight: bodyEntry.weight,
                bodyFatPercent: bodyEntry.bodyFatPercent,
                activityLevel: spec.activityLevel
            )

            // 📚 학습 포인트: Core Data Entity 생성
            // Mapper를 통해 Domain Entity를 Core Data Entity로 변환
            let bodyRecord = bodyMapper.toEntity(bodyEntry, context: viewContext)
            let metabolismSnapshot = metabolismMapper.toEntity(metabolismData, context: viewContext)

            // 📚 학습 포인트: Relationship 설정
            // BodyRecord와 MetabolismSnapshot을 1:1 관계로 연결
            // Core Data의 relationship은 양방향으로 자동 설정됨
            bodyRecord.metabolismSnapshot = metabolismSnapshot
            metabolismSnapshot.bodyRecord = bodyRecord
        }

        // 📚 학습 포인트: Sample User Data
        // Goal 엔티티는 User와의 관계를 가지므로 먼저 User 생성
        let sampleUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: viewContext)
        let sampleUserId = sampleUserProfile.id
        sampleUser.setValue(sampleUserId, forKey: "id")
        sampleUser.setValue(Date(), forKey: "createdAt")
        sampleUser.setValue(Date(), forKey: "updatedAt")

        // 📚 학습 포인트: Sample Goal Data
        // 다양한 목표 시나리오를 커버하는 샘플 데이터 생성
        // - 활성 목표 1개 (체중 감량)
        // - 비활성 목표 2개 (과거 목표 이력)

        // 활성 목표: 체중 감량 (현재 진행 중)
        // 현재 체중 68.3kg에서 목표 체중 65kg로 감량 중
        let activeGoal = NSEntityDescription.insertNewObject(forEntityName: "Goal", into: viewContext)
        activeGoal.setValue(UUID(), forKey: "id")
        activeGoal.setValue(sampleUser, forKey: "user")
        activeGoal.setValue(Int16(0), forKey: "goalType") // lose
        activeGoal.setValue(Decimal(65.0) as NSDecimalNumber, forKey: "targetWeight")
        activeGoal.setValue(Decimal(15.0) as NSDecimalNumber, forKey: "targetBodyFatPct")
        activeGoal.setValue(Decimal(35.0) as NSDecimalNumber, forKey: "targetMuscleMass")
        activeGoal.setValue(Decimal(-0.5) as NSDecimalNumber, forKey: "weeklyWeightRate")
        activeGoal.setValue(Decimal(-0.5) as NSDecimalNumber, forKey: "weeklyFatPctRate")
        activeGoal.setValue(Decimal(0.2) as NSDecimalNumber, forKey: "weeklyMuscleRate")
        activeGoal.setValue(Decimal(72.0) as NSDecimalNumber, forKey: "startWeight")
        activeGoal.setValue(Decimal(20.0) as NSDecimalNumber, forKey: "startBodyFatPct")
        activeGoal.setValue(Decimal(30.0) as NSDecimalNumber, forKey: "startMuscleMass")
        activeGoal.setValue(Decimal(1650) as NSDecimalNumber, forKey: "startBMR")
        activeGoal.setValue(Decimal(2310) as NSDecimalNumber, forKey: "startTDEE")
        activeGoal.setValue(Int32(1800), forKey: "dailyCalorieTarget")
        activeGoal.setValue(true, forKey: "isActive")
        activeGoal.setValue(calendar.date(byAdding: .day, value: -28, to: today)!, forKey: "createdAt")
        activeGoal.setValue(Date(), forKey: "updatedAt")

        // 비활성 목표 1: 체중 유지 (과거 목표)
        // 70kg 유지 목표 (3개월 전)
        let maintenanceGoal = NSEntityDescription.insertNewObject(forEntityName: "Goal", into: viewContext)
        maintenanceGoal.setValue(UUID(), forKey: "id")
        maintenanceGoal.setValue(sampleUser, forKey: "user")
        maintenanceGoal.setValue(Int16(1), forKey: "goalType") // maintain
        maintenanceGoal.setValue(Decimal(70.0) as NSDecimalNumber, forKey: "targetWeight")
        maintenanceGoal.setValue(Decimal(18.0) as NSDecimalNumber, forKey: "targetBodyFatPct")
        maintenanceGoal.setValue(nil, forKey: "targetMuscleMass")
        maintenanceGoal.setValue(Decimal(0.0) as NSDecimalNumber, forKey: "weeklyWeightRate")
        maintenanceGoal.setValue(Decimal(0.0) as NSDecimalNumber, forKey: "weeklyFatPctRate")
        maintenanceGoal.setValue(nil, forKey: "weeklyMuscleRate")
        maintenanceGoal.setValue(Decimal(70.5) as NSDecimalNumber, forKey: "startWeight")
        maintenanceGoal.setValue(Decimal(18.5) as NSDecimalNumber, forKey: "startBodyFatPct")
        maintenanceGoal.setValue(nil, forKey: "startMuscleMass")
        maintenanceGoal.setValue(Decimal(1620) as NSDecimalNumber, forKey: "startBMR")
        maintenanceGoal.setValue(Decimal(2268) as NSDecimalNumber, forKey: "startTDEE")
        maintenanceGoal.setValue(Int32(2200), forKey: "dailyCalorieTarget")
        maintenanceGoal.setValue(false, forKey: "isActive")
        maintenanceGoal.setValue(calendar.date(byAdding: .day, value: -90, to: today)!, forKey: "createdAt")
        maintenanceGoal.setValue(calendar.date(byAdding: .day, value: -30, to: today)!, forKey: "updatedAt")

        // 비활성 목표 2: 근육 증량 (과거 목표)
        // 체중 증가 및 근육량 증가 목표 (6개월 전)
        let gainGoal = NSEntityDescription.insertNewObject(forEntityName: "Goal", into: viewContext)
        gainGoal.setValue(UUID(), forKey: "id")
        gainGoal.setValue(sampleUser, forKey: "user")
        gainGoal.setValue(Int16(2), forKey: "goalType") // gain
        gainGoal.setValue(Decimal(75.0) as NSDecimalNumber, forKey: "targetWeight")
        gainGoal.setValue(Decimal(18.0) as NSDecimalNumber, forKey: "targetBodyFatPct")
        gainGoal.setValue(Decimal(38.0) as NSDecimalNumber, forKey: "targetMuscleMass")
        gainGoal.setValue(Decimal(0.3) as NSDecimalNumber, forKey: "weeklyWeightRate")
        gainGoal.setValue(Decimal(0.0) as NSDecimalNumber, forKey: "weeklyFatPctRate")
        gainGoal.setValue(Decimal(0.3) as NSDecimalNumber, forKey: "weeklyMuscleRate")
        gainGoal.setValue(Decimal(68.0) as NSDecimalNumber, forKey: "startWeight")
        gainGoal.setValue(Decimal(16.0) as NSDecimalNumber, forKey: "startBodyFatPct")
        gainGoal.setValue(Decimal(28.0) as NSDecimalNumber, forKey: "startMuscleMass")
        gainGoal.setValue(Decimal(1580) as NSDecimalNumber, forKey: "startBMR")
        gainGoal.setValue(Decimal(2212) as NSDecimalNumber, forKey: "startTDEE")
        gainGoal.setValue(Int32(2600), forKey: "dailyCalorieTarget")
        gainGoal.setValue(false, forKey: "isActive")
        gainGoal.setValue(calendar.date(byAdding: .day, value: -180, to: today)!, forKey: "createdAt")
        gainGoal.setValue(calendar.date(byAdding: .day, value: -95, to: today)!, forKey: "updatedAt")

        do {
            try viewContext.save()
        } catch {
            // 📚 학습 포인트: fatalError 사용
            // Preview/개발 환경에서만 사용 - 프로덕션에서는 적절한 에러 처리 필요
            let nsError = error as NSError
            fatalError("Failed to save preview context: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    // MARK: - Properties

    // 📚 학습 포인트: NSPersistentContainer
    // Core Data 스택의 핵심 - 모델, 컨텍스트, 저장소를 모두 관리
    // iOS 10+에서 도입되어 Core Data 설정을 크게 간소화
    let container: NSPersistentContainer

    // 📚 학습 포인트: NSManagedObjectContext
    // viewContext는 main queue에서 동작하며 UI 업데이트에 사용
    // 💡 Java 비교: JPA의 EntityManager와 유사 - 엔티티의 생명주기 관리
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    // 📚 학습 포인트: Convenience Init with Default Parameters
    // inMemory: true로 하면 SQLite 파일 대신 메모리에 저장
    // 테스트나 Preview에서 유용
    init(inMemory: Bool = false) {
        // 📚 학습 포인트: Bundle에서 Core Data 모델 로드
        // NSPersistentContainer는 자동으로 .xcdatamodeld 파일을 찾음
        // 파일명이 "Bodii"이면 Bodii.xcdatamodeld를 찾음
        container = NSPersistentContainer(name: "Bodii")

        // 📚 학습 포인트: Lightweight Migration 설정
        // 스키마 변경 시 자동으로 마이그레이션 수행
        // ⚠️ 주의: 복잡한 변경은 수동 마이그레이션 필요
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        // 📚 학습 포인트: 인메모리 저장소 설정
        // 테스트/Preview용 - 앱 종료 시 데이터 소멸
        if inMemory {
            description?.url = URL(fileURLWithPath: "/dev/null")
        }

        // 📚 학습 포인트: 비동기 저장소 로드
        // loadPersistentStores는 비동기로 동작하지만 completion handler에서 에러 처리
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                // 📚 학습 포인트: Core Data 로드 실패 처리
                // ⚠️ 주의: 프로덕션에서는 fatalError 대신 적절한 복구 로직 필요
                // 예: 손상된 저장소 삭제 후 재생성, 사용자에게 알림 등
                fatalError("Failed to load Core Data store: \(error), \(error.userInfo)")
            }

            // 📚 학습 포인트: Merge Policy 설정
            // 여러 컨텍스트에서 동시에 변경 시 충돌 해결 정책
            // mergeByPropertyObjectTrump: 메모리의 값이 저장소 값을 덮어씀
            self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            // 📚 학습 포인트: 자동 병합 설정
            // 백그라운드 컨텍스트의 변경사항을 viewContext에 자동 반영
            self?.container.viewContext.automaticallyMergesChangesFromParent = true

            // 초기 음식 데이터 시딩 (Food 테이블이 비어있을 때만)
            self?.seedFoodDataIfNeeded()

            #if DEBUG
            // 📚 학습 포인트: Core Data 모델 검증
            // 앱 시작 시 모든 엔티티가 정상적으로 로드되었는지 확인
            self?.verifyModelLoaded()
            #endif
        }
    }

    // MARK: - Public Methods

    // 📚 학습 포인트: Context 저장
    // Core Data는 변경사항을 메모리에 저장하다가 save() 호출 시 디스크에 기록
    // ⚠️ 주의: save() 호출을 잊으면 앱 종료 시 데이터 손실
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            // 📚 학습 포인트: 에러 처리
            // 프로덕션에서는 사용자에게 알리거나 로깅 필요
            let nsError = error as NSError
            assertionFailure("Failed to save context: \(nsError), \(nsError.userInfo)")
        }
    }

    // MARK: - Food Data Seeding

    /// Food 테이블이 비어있으면 샘플 음식 데이터를 시딩합니다.
    private func seedFoodDataIfNeeded() {
        let context = container.viewContext
        let request: NSFetchRequest<Food> = Food.fetchRequest()
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            if count == 0 {
                SampleFoods.createAllFoods(in: context)
                try context.save()
                #if DEBUG
                print("✅ [Core Data] 샘플 음식 데이터 시딩 완료 (\(SampleFoods.allFoodData.count)개)")
                #endif
            }
        } catch {
            #if DEBUG
            print("❌ [Core Data] 음식 데이터 시딩 실패: \(error.localizedDescription)")
            #endif
        }
    }

    // 📚 학습 포인트: Background Context 생성
    // 대용량 데이터 처리 시 메인 스레드 블로킹 방지
    // 💡 Java 비교: 별도 스레드에서 EntityManager 사용하는 것과 유사
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // 📚 학습 포인트: Background Context에서 작업 수행
    // 클로저 내에서 백그라운드 작업 수행 후 자동으로 저장
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(context)
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension PersistenceController {
    // 📚 학습 포인트: 테스트용 헬퍼
    // 인메모리 컨트롤러를 빠르게 생성하여 단위 테스트에 활용
    static func makeForTesting() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    // 📚 학습 포인트: 저장소 위치 디버깅
    // Core Data 파일이 어디에 저장되는지 확인용
    func printStoreLocation() {
        guard let url = container.persistentStoreDescriptions.first?.url else {
            print("No store URL found")
            return
        }
        print("Core Data store location: \(url)")
    }

    // 📚 학습 포인트: Core Data 모델 검증
    // 앱 시작 시 모든 엔티티가 정상적으로 로드되었는지 확인
    // 💡 이 메서드는 DEBUG 빌드에서만 실행됨
    func verifyModelLoaded() {
        // 📚 학습 포인트: NSManagedObjectModel
        // Core Data 모델의 메타데이터에 접근하여 엔티티 목록 확인
        guard let model = container.managedObjectModel as NSManagedObjectModel? else {
            print("⚠️ [Core Data] Failed to access managed object model")
            return
        }

        // 앱에서 필요한 9개 엔티티 목록
        let expectedEntities: Set<String> = [
            "User",
            "BodyRecord",
            "MetabolismSnapshot",
            "Food",
            "FoodRecord",
            "ExerciseRecord",
            "SleepRecord",
            "DailyLog",
            "Goal"
        ]

        // 모델에서 로드된 엔티티 이름 추출
        let loadedEntities = Set(model.entities.compactMap { $0.name })

        // 검증: 모든 필수 엔티티가 로드되었는지 확인
        let missingEntities = expectedEntities.subtracting(loadedEntities)
        let extraEntities = loadedEntities.subtracting(expectedEntities)

        if missingEntities.isEmpty {
            print("✅ [Core Data] Model loaded successfully with all 9 entities:")
            for entity in expectedEntities.sorted() {
                print("   - \(entity)")
            }
        } else {
            print("❌ [Core Data] Missing entities: \(missingEntities.sorted().joined(separator: ", "))")
        }

        if !extraEntities.isEmpty {
            print("ℹ️ [Core Data] Additional entities found: \(extraEntities.sorted().joined(separator: ", "))")
        }

        // 각 엔티티의 속성 수 출력 (모델 구조 확인용)
        print("📊 [Core Data] Entity details:")
        for entityName in expectedEntities.sorted() {
            if let entity = model.entitiesByName[entityName] {
                let attributeCount = entity.attributesByName.count
                let relationshipCount = entity.relationshipsByName.count
                print("   - \(entityName): \(attributeCount) attributes, \(relationshipCount) relationships")
            }
        }
    }
}
#endif
