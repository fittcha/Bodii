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
        // 실제 앱에서는 이 블록에서 샘플 데이터를 생성할 수 있음
        // 현재는 빈 상태로 유지 (엔티티 구현 후 추가 예정)
        let viewContext = controller.container.viewContext

        // TODO: 샘플 데이터 생성 코드 추가
        // 예: User, DailyLog 등의 샘플 데이터

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
}
#endif
