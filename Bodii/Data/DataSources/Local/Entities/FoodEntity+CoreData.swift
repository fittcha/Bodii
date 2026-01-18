//
//  FoodEntity+CoreData.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Core Data Entity Extensions
// NSManagedObject 자동 생성 클래스에 편의 메서드를 추가하는 확장
// 💡 Java 비교: JPA Entity에 @Transient 메서드를 추가하는 것과 유사

import Foundation
import CoreData

// MARK: - Food Entity Extension

/// Food Core Data 엔티티 확장
///
/// Core Data의 자동 생성된 Food 엔티티에 편의 메서드를 추가합니다.
///
/// 📚 학습 포인트: 왜 확장을 사용하나?
/// - Core Data는 자동으로 NSManagedObject 서브클래스를 생성 (codeGenerationType="class")
/// - 자동 생성 클래스를 직접 수정하면 모델 변경 시 손실됨
/// - 확장(extension)을 사용하면 안전하게 기능 추가 가능
///
/// - Note: Food 엔티티는 음식의 영양 정보를 저장하며, API 검색 결과를 캐싱합니다.
/// - Note: 캐싱 전략: LRU (Least Recently Used) 기반으로 lastAccessedAt 사용
extension Food {

    // MARK: - Cache Management

    /// 최근에 검색/사용된 음식인지 확인
    ///
    /// 📚 학습 포인트: Computed Property
    /// - 저장된 값이 아니라 계산된 값을 반환
    /// - 💡 Java 비교: getter 메서드와 유사하지만 프로퍼티처럼 접근
    ///
    /// - Returns: 최근 7일 이내에 접근된 음식이면 true
    var isRecentlyAccessed: Bool {
        guard let lastAccessed = lastAccessedAt else { return false }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return lastAccessed > sevenDaysAgo
    }

    /// 인기 음식인지 확인 (검색 횟수 기준)
    ///
    /// - Parameter threshold: 인기 기준 검색 횟수 (기본값: 5)
    /// - Returns: 검색 횟수가 threshold 이상이면 true
    func isPopular(threshold: Int32 = 5) -> Bool {
        return searchCount >= threshold
    }

    /// 마지막 접근 시간 업데이트
    ///
    /// 📚 학습 포인트: NSManagedObject의 프로퍼티 변경
    /// - Core Data는 변경 사항을 자동으로 추적
    /// - save()를 호출해야 디스크에 저장됨
    ///
    /// - Note: 이 메서드는 메모리의 값만 변경합니다.
    ///         실제 저장은 NSManagedObjectContext.save()를 호출해야 합니다.
    func updateAccessTime() {
        lastAccessedAt = Date()
        searchCount += 1
    }

    /// 캐시 만료 여부 확인
    ///
    /// API 데이터는 일정 기간 후 만료되어 재검색이 필요합니다.
    ///
    /// - Parameter days: 만료 기준 일수 (기본값: 30일)
    /// - Returns: 만료되었으면 true
    func isCacheExpired(days: Int = 30) -> Bool {
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return createdAt < expirationDate
    }

    // MARK: - Fetch Requests

    /// API 코드로 음식 조회
    ///
    /// 중복 저장 방지를 위해 API 코드로 기존 음식을 검색합니다.
    ///
    /// - Parameter apiCode: API 식품 코드
    /// - Returns: NSFetchRequest<Food>
    static func fetchRequestByApiCode(_ apiCode: String) -> NSFetchRequest<Food> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "apiCode == %@", apiCode)
        request.fetchLimit = 1
        return request
    }

    /// 최근 검색한 음식 조회 (LRU)
    ///
    /// 📚 학습 포인트: LRU (Least Recently Used) Cache
    /// - lastAccessedAt으로 정렬하여 최근 접근 음식 우선 반환
    /// - limit으로 캐시 크기 제한
    ///
    /// - Parameter limit: 조회할 음식 개수 (기본값: 20)
    /// - Returns: NSFetchRequest<Food>
    static func fetchRecentFoods(limit: Int = 20) -> NSFetchRequest<Food> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "lastAccessedAt != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "lastAccessedAt", ascending: false)]
        request.fetchLimit = limit
        return request
    }

    /// 인기 음식 조회 (검색 횟수 기준)
    ///
    /// - Parameter limit: 조회할 음식 개수 (기본값: 20)
    /// - Returns: NSFetchRequest<Food>
    static func fetchPopularFoods(limit: Int = 20) -> NSFetchRequest<Food> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "searchCount > 0")
        request.sortDescriptors = [NSSortDescriptor(key: "searchCount", ascending: false)]
        request.fetchLimit = limit
        return request
    }

    /// 이름으로 음식 검색
    ///
    /// 📚 학습 포인트: NSPredicate String Matching
    /// - CONTAINS[cd]: 대소문자/발음 구별 없이 포함 검색
    /// - [cd] 플래그: c=case insensitive, d=diacritic insensitive
    ///
    /// - Parameters:
    ///   - query: 검색어
    ///   - limit: 조회할 음식 개수 (기본값: 50)
    /// - Returns: NSFetchRequest<Food>
    static func fetchByName(_ query: String, limit: Int = 50) -> NSFetchRequest<Food> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        request.sortDescriptors = [
            NSSortDescriptor(key: "searchCount", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        request.fetchLimit = limit
        return request
    }

    /// 만료된 캐시 조회
    ///
    /// 오래된 API 데이터를 정리하기 위한 조회입니다.
    ///
    /// - Parameter days: 만료 기준 일수 (기본값: 30일)
    /// - Returns: NSFetchRequest<Food>
    static func fetchExpiredCache(days: Int = 30) -> NSFetchRequest<Food> {
        let request = fetchRequest()
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        // 📚 학습 포인트: Compound Predicate
        // 여러 조건을 AND/OR로 결합
        // API 출처이면서(governmentAPI 또는 usda) 만료된 것만 조회
        let apiSourcePredicate = NSPredicate(
            format: "source == %d OR source == %d",
            FoodSource.governmentAPI.rawValue,
            FoodSource.usda.rawValue
        )
        let expiredPredicate = NSPredicate(format: "createdAt < %@", expirationDate as NSDate)

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            apiSourcePredicate,
            expiredPredicate
        ])

        return request
    }
}

// MARK: - Food Entity Error

/// Food Core Data 엔티티 관련 에러
///
/// 📚 학습 포인트: Custom Error Types
/// - Swift의 Error 프로토콜을 구현
/// - 💡 Java 비교: Custom Exception 클래스와 유사
enum FoodEntityError: Error {
    case missingRequiredField(String)
    case invalidEnumValue(String, Int16)
    case conversionFailed(String)

    /// 사용자에게 표시할 에러 메시지
    var localizedDescription: String {
        switch self {
        case .missingRequiredField(let field):
            return "필수 필드가 누락되었습니다: \(field)"
        case .invalidEnumValue(let field, let value):
            return "잘못된 열거형 값입니다: \(field) = \(value)"
        case .conversionFailed(let message):
            return "변환에 실패했습니다: \(message)"
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension Food {
    /// 디버깅용 설명 문자열
    var debugDescription: String {
        """
        Food(
            id: \(id?.uuidString ?? "nil"),
            name: \(name ?? "nil"),
            calories: \(calories),
            source: \(FoodSource(rawValue: source)?.displayName ?? "unknown"),
            apiCode: \(apiCode ?? "nil"),
            searchCount: \(searchCount),
            lastAccessedAt: \(lastAccessedAt?.description ?? "nil")
        )
        """
    }

    /// 테스트용 샘플 데이터 생성
    ///
    /// - Parameter context: NSManagedObjectContext
    /// - Returns: 샘플 Food entity
    static func createSample(context: NSManagedObjectContext) -> Food {
        let food = Food(context: context)
        food.id = UUID()
        food.name = "현미밥"
        food.calories = 330
        food.carbohydrates = 73.4
        food.protein = 6.8
        food.fat = 2.5
        food.sodium = 5.0
        food.fiber = 3.0
        food.sugar = 0.5
        food.servingSize = 210.0
        food.servingUnit = "1공기"
        food.source = FoodSource.governmentAPI.rawValue
        food.apiCode = "D000001"
        food.createdAt = Date()
        food.lastAccessedAt = Date()
        food.searchCount = 0
        return food
    }
}
#endif
