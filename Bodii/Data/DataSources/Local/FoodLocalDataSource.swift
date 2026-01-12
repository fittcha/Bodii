//
//  FoodLocalDataSource.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Local Data Source Implementation
// Core Data를 사용하여 로컬 캐시를 관리하는 데이터 소스
// 💡 Java 비교: JPA Repository의 구현체와 유사

import Foundation
import CoreData

/// 식품 로컬 데이터 소스 구현체
///
/// 📚 학습 포인트: Local Data Source Pattern
/// Core Data를 사용하여 식품 정보를 로컬에 캐싱하고 관리합니다.
/// API 검색 결과를 캐싱하여 오프라인 접근과 빠른 재검색을 지원합니다.
/// 💡 Java 비교: JPA를 사용한 로컬 DB 접근 레이어와 유사
///
/// **아키텍처:**
/// ```
/// FoodSearchRepositoryImpl
///        ↓
/// FoodLocalDataSource (Implementation) ← Data Layer
///        ↓
/// Core Data (FoodEntity) ← Infrastructure Layer
/// ```
///
/// **캐싱 전략:**
/// - LRU (Least Recently Used): lastAccessedAt 기준
/// - 인기도 추적: searchCount로 인기 식품 파악
/// - 자동 만료: 30일 이상 된 캐시 자동 정리
/// - 중복 방지: apiCode로 중복 저장 방지
///
/// **주요 기능:**
/// - 식품 검색 (이름 기반 부분 매칭)
/// - 최근 검색 식품 조회 (LRU)
/// - 식품 저장 (중복 체크 포함)
/// - 접근 시간 업데이트 (LRU 캐시 유지)
/// - 오래된 캐시 정리 (저장 공간 최적화)
///
/// **사용 예시:**
/// ```swift
/// let dataSource = FoodLocalDataSourceImpl()
///
/// // 캐시에 저장
/// try await dataSource.saveFoods(foods)
///
/// // 캐시에서 검색
/// let results = try await dataSource.searchFoods(query: "김치", limit: 20)
///
/// // 최근 검색 식품
/// let recent = try await dataSource.getRecentFoods(limit: 10)
/// ```
final class FoodLocalDataSourceImpl: FoodLocalDataSource {

    // MARK: - Properties

    /// Core Data 컨텍스트
    ///
    /// 📚 학습 포인트: NSManagedObjectContext
    /// Core Data 작업의 핵심 - 엔티티 생성, 조회, 수정, 삭제 관리
    /// 💡 Java 비교: JPA의 EntityManager와 유사한 역할
    private let context: NSManagedObjectContext

    /// 기본 캐시 크기 제한
    ///
    /// 📚 학습 포인트: 캐시 사이즈 제한
    /// 무한정 증가를 방지하여 저장 공간과 성능 최적화
    /// 💡 500개 = 약 50KB (엔티티당 100B 가정)
    private let defaultMaxCacheSize = 500

    // MARK: - Initialization

    /// FoodLocalDataSourceImpl 초기화
    ///
    /// 📚 학습 포인트: Dependency Injection
    /// PersistenceController를 주입받아 테스트 시 mock으로 교체 가능
    /// 💡 Java 비교: @Autowired EntityManager injection
    ///
    /// - Parameter persistenceController: Core Data 컨트롤러 (기본값: shared)
    init(persistenceController: PersistenceController = .shared) {
        self.context = persistenceController.viewContext
    }

    // MARK: - FoodLocalDataSource Protocol Implementation

    /// 캐시에서 식품 검색
    ///
    /// 📚 학습 포인트: Name-Based Search
    /// Core Data의 NSPredicate를 사용하여 이름 기반 부분 매칭 검색
    /// CONTAINS[cd]: 대소문자/발음 구별 없이 검색
    /// 💡 Java 비교: JPA의 LIKE 쿼리와 유사 (%keyword%)
    ///
    /// - Parameters:
    ///   - query: 검색어 (식품명)
    ///   - limit: 최대 결과 개수
    ///
    /// - Returns: 검색된 식품 배열 (searchCount 기준 정렬)
    ///
    /// - Throws: `FoodLocalDataSourceError.fetchFailed`: 조회 실패
    func searchFoods(query: String, limit: Int) async throws -> [Food] {
        // 📚 학습 포인트: Async/Await with Core Data
        // Core Data는 동기 API이므로 Task를 사용하여 비동기로 래핑
        // 💡 Java 비교: CompletableFuture로 동기 작업을 비동기화하는 것과 유사
        return try await context.perform {
            do {
                // 📚 학습 포인트: Fetch Request with Predicate
                // FoodEntity+CoreData의 확장 메서드 사용
                let request = Food.fetchByName(query, limit: limit)
                let foodEntities = try self.context.fetch(request)

                #if DEBUG
                print("✅ [FoodLocalDataSource] Found \(foodEntities.count) foods for query '\(query)'")
                #endif

                // 📚 학습 포인트: Entity to Domain Conversion
                // Core Data 엔티티를 Domain 엔티티로 변환
                // 💡 Java 비교: JPA Entity → DTO 변환과 유사
                return try foodEntities.map { try $0.toDomainEntity() }

            } catch let error as FoodEntityError {
                // Core Data 엔티티 에러를 로컬 데이터 소스 에러로 변환
                throw FoodLocalDataSourceError.conversionFailed(error.localizedDescription)
            } catch {
                // 기타 에러 (fetch 실패 등)
                throw FoodLocalDataSourceError.fetchFailed(error)
            }
        }
    }

    /// 최근 검색한 식품 조회
    ///
    /// 📚 학습 포인트: LRU (Least Recently Used) Cache
    /// lastAccessedAt 기준으로 정렬하여 최근 접근한 식품 우선 반환
    /// 💡 Java 비교: LinkedHashMap의 access-order mode와 유사
    ///
    /// - Parameter limit: 최대 결과 개수 (기본값: 20)
    ///
    /// - Returns: 최근 검색한 식품 배열 (lastAccessedAt 내림차순)
    ///
    /// - Throws: `FoodLocalDataSourceError.fetchFailed`: 조회 실패
    func getRecentFoods(limit: Int) async throws -> [Food] {
        return try await context.perform {
            do {
                // 📚 학습 포인트: Pre-defined Fetch Request
                // FoodEntity+CoreData의 fetchRecentFoods() 메서드 사용
                let request = Food.fetchRecentFoods(limit: limit)
                let foodEntities = try self.context.fetch(request)

                #if DEBUG
                print("✅ [FoodLocalDataSource] Retrieved \(foodEntities.count) recent foods")
                #endif

                return try foodEntities.map { try $0.toDomainEntity() }

            } catch let error as FoodEntityError {
                throw FoodLocalDataSourceError.conversionFailed(error.localizedDescription)
            } catch {
                throw FoodLocalDataSourceError.fetchFailed(error)
            }
        }
    }

    /// 식품 저장 (중복 체크 포함)
    ///
    /// 📚 학습 포인트: Upsert Pattern (Update or Insert)
    /// apiCode로 기존 데이터 확인 후 업데이트 또는 삽입
    /// 💡 Java 비교: JPA의 merge() 또는 @Entity의 @Id 기반 upsert
    ///
    /// - Parameter foods: 저장할 식품 배열
    ///
    /// - Throws: `FoodLocalDataSourceError.saveFailed`: 저장 실패
    func saveFoods(_ foods: [Food]) async throws {
        guard !foods.isEmpty else {
            #if DEBUG
            print("ℹ️ [FoodLocalDataSource] No foods to save")
            #endif
            return
        }

        try await context.perform {
            do {
                // 📚 학습 포인트: Batch Insert with Deduplication
                // FoodEntity+CoreData의 saveUnique() 메서드 사용
                // apiCode 기준으로 중복 체크 후 upsert
                let savedCount = try Food.saveUnique(from: foods, context: self.context)

                // 📚 학습 포인트: Context Save
                // Core Data는 변경사항을 메모리에 저장 → save() 호출 시 디스크에 기록
                // 💡 Java 비교: EntityManager.flush()와 유사
                if self.context.hasChanges {
                    try self.context.save()
                }

                #if DEBUG
                print("✅ [FoodLocalDataSource] Saved \(savedCount) new foods (total: \(foods.count))")
                #endif

            } catch {
                throw FoodLocalDataSourceError.saveFailed(error)
            }
        }
    }

    /// 접근 시간 업데이트
    ///
    /// 📚 학습 포인트: Activity Tracking for LRU
    /// 사용자가 식품을 선택할 때마다 호출하여 최근 접근 시간 갱신
    /// LRU 캐시 정책에 활용
    /// 💡 Java 비교: Cache.get()에서 자동으로 access time 업데이트하는 것과 유사
    ///
    /// - Parameter foodId: 식품 고유 ID
    ///
    /// - Throws: `FoodLocalDataSourceError.updateFailed`: 업데이트 실패
    func updateAccessTime(foodId: UUID) async throws {
        try await context.perform {
            do {
                // 📚 학습 포인트: Fetch by Primary Key
                // UUID로 특정 엔티티 조회
                let request: NSFetchRequest<Food> = Food.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", foodId as CVarArg)
                request.fetchLimit = 1

                guard let foodEntity = try self.context.fetch(request).first else {
                    #if DEBUG
                    print("ℹ️ [FoodLocalDataSource] Food not found: \(foodId)")
                    #endif
                    // 식품이 없어도 에러는 아님 (캐시에 없을 수 있음)
                    return
                }

                // 📚 학습 포인트: Entity Update
                // FoodEntity+CoreData의 updateAccessTime() 메서드 사용
                // lastAccessedAt = 현재 시간, searchCount += 1
                foodEntity.updateAccessTime()

                if self.context.hasChanges {
                    try self.context.save()
                }

                #if DEBUG
                print("✅ [FoodLocalDataSource] Updated access time for: \(foodEntity.name ?? "unknown")")
                #endif

            } catch {
                throw FoodLocalDataSourceError.updateFailed(error)
            }
        }
    }

    /// 오래된 캐시 정리
    ///
    /// 📚 학습 포인트: Cache Eviction Policy
    /// LRU 정책으로 캐시 크기 제한 - 최근 접근하지 않은 항목 삭제
    /// 💡 Java 비교: LinkedHashMap.removeEldestEntry()와 유사
    ///
    /// **정리 전략:**
    /// 1. 만료된 캐시 삭제 (30일 이상 된 API 데이터)
    /// 2. 최대 크기 초과 시 LRU로 추가 삭제
    ///
    /// - Parameter maxCount: 캐시 최대 크기 (기본값: 500)
    ///
    /// - Throws: `FoodLocalDataSourceError.deleteFailed`: 삭제 실패
    func cleanupOldFoods(maxCount: Int) async throws {
        let targetMaxCount = maxCount > 0 ? maxCount : defaultMaxCacheSize

        try await context.perform {
            do {
                // 📚 학습 포인트: 1단계 - 만료된 캐시 삭제
                // 30일 이상 된 API 데이터 자동 삭제
                let expiredRequest = Food.fetchExpiredCache(days: 30)
                let expiredFoods = try self.context.fetch(expiredRequest)

                var deletedCount = 0
                for food in expiredFoods {
                    self.context.delete(food)
                    deletedCount += 1
                }

                #if DEBUG
                if deletedCount > 0 {
                    print("🗑️ [FoodLocalDataSource] Deleted \(deletedCount) expired foods")
                }
                #endif

                // 📚 학습 포인트: 2단계 - LRU 기반 추가 정리
                // 최대 크기 초과 시 오래된 항목부터 삭제
                let countRequest: NSFetchRequest<Food> = Food.fetchRequest()
                let totalCount = try self.context.count(for: countRequest)

                if totalCount > targetMaxCount {
                    // 가장 오래된 항목부터 삭제 (lastAccessedAt 오름차순)
                    let excessCount = totalCount - targetMaxCount
                    let oldestRequest: NSFetchRequest<Food> = Food.fetchRequest()
                    oldestRequest.sortDescriptors = [NSSortDescriptor(key: "lastAccessedAt", ascending: true)]
                    oldestRequest.fetchLimit = excessCount

                    let oldestFoods = try self.context.fetch(oldestRequest)
                    for food in oldestFoods {
                        self.context.delete(food)
                        deletedCount += 1
                    }

                    #if DEBUG
                    print("🗑️ [FoodLocalDataSource] Deleted \(excessCount) oldest foods (LRU)")
                    #endif
                }

                // 변경사항 저장
                if self.context.hasChanges {
                    try self.context.save()
                }

                #if DEBUG
                let finalCount = try self.context.count(for: countRequest)
                print("✅ [FoodLocalDataSource] Cache cleanup completed (deleted: \(deletedCount), remaining: \(finalCount))")
                #endif

            } catch {
                throw FoodLocalDataSourceError.deleteFailed(error)
            }
        }
    }
}

// MARK: - FoodLocalDataSource Error

/// 로컬 데이터 소스 에러
///
/// 📚 학습 포인트: Custom Error Types
/// 각 작업별로 구체적인 에러 타입 정의
/// 💡 Java 비교: Custom Exception 클래스와 유사
enum FoodLocalDataSourceError: Error {
    case fetchFailed(Error)
    case saveFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case conversionFailed(String)

    /// 사용자에게 표시할 에러 메시지
    var localizedDescription: String {
        switch self {
        case .fetchFailed(let error):
            return "캐시 조회에 실패했습니다: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "캐시 저장에 실패했습니다: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "캐시 업데이트에 실패했습니다: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "캐시 삭제에 실패했습니다: \(error.localizedDescription)"
        case .conversionFailed(let message):
            return "데이터 변환에 실패했습니다: \(message)"
        }
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock FoodLocalDataSource
///
/// 📚 학습 포인트: Mock Data Source for Testing
/// 테스트에서 실제 Core Data 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock와 유사
final class MockFoodLocalDataSource: FoodLocalDataSource {

    /// Mock 저장소
    private var mockStorage: [UUID: Food] = [:]

    /// 에러 시뮬레이션
    var shouldThrowError: Error?

    /// 호출 추적
    var searchCallCount = 0
    var getRecentCallCount = 0
    var saveCallCount = 0
    var updateAccessTimeCallCount = 0
    var cleanupCallCount = 0

    func searchFoods(query: String, limit: Int) async throws -> [Food] {
        searchCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        // 이름에 검색어가 포함된 식품 필터링
        let results = mockStorage.values.filter { food in
            food.name.localizedCaseInsensitiveContains(query)
        }

        return Array(results.prefix(limit))
    }

    func getRecentFoods(limit: Int) async throws -> [Food] {
        getRecentCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        // Mock: 저장된 모든 식품 반환
        return Array(mockStorage.values.prefix(limit))
    }

    func saveFoods(_ foods: [Food]) async throws {
        saveCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        // Mock 저장소에 추가
        for food in foods {
            mockStorage[food.id] = food
        }
    }

    func updateAccessTime(foodId: UUID) async throws {
        updateAccessTimeCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        // Mock: 아무 작업도 하지 않음
    }

    func cleanupOldFoods(maxCount: Int) async throws {
        cleanupCallCount += 1

        if let error = shouldThrowError {
            throw error
        }

        // Mock: 초과분 삭제
        if mockStorage.count > maxCount {
            let excessCount = mockStorage.count - maxCount
            let keysToRemove = Array(mockStorage.keys.prefix(excessCount))
            for key in keysToRemove {
                mockStorage.removeValue(forKey: key)
            }
        }
    }

    /// 테스트 헬퍼: Mock 저장소 초기화
    func reset() {
        mockStorage.removeAll()
        shouldThrowError = nil
        searchCallCount = 0
        getRecentCallCount = 0
        saveCallCount = 0
        updateAccessTimeCallCount = 0
        cleanupCallCount = 0
    }

    /// 테스트 헬퍼: Mock 저장소에 식품 추가
    func addMockFood(_ food: Food) {
        mockStorage[food.id] = food
    }
}
#endif
