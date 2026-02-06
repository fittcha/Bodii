//
//  KFDAFoodImporter.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-02-04.
//

import CoreData
import Foundation

/// 번들 JSON에서 KFDA 음식 데이터를 Core Data로 임포트하는 서비스
///
/// 앱 첫 실행 시 `kfda_foods.json`을 파싱하여 Core Data에 대량 삽입합니다.
/// 백그라운드 컨텍스트에서 배치 처리하여 메인 스레드를 차단하지 않습니다.
final class KFDAFoodImporter {

    // MARK: - Types

    /// JSON 파일의 루트 구조
    private struct KFDAFoodBundle: Codable {
        let version: Int
        let totalCount: Int
        let foods: [KFDABundledFood]
    }

    /// 번들된 음식 데이터 구조 (다운로드 스크립트 출력과 일치)
    struct KFDABundledFood: Codable {
        let foodCd: String
        let name: String
        let calories: Double?
        let protein: Double?
        let fat: Double?
        let carbohydrates: Double?
        let sodium: Double?
        let fiber: Double?
        let sugar: Double?
        let servingSize: Double?
        let servingUnit: String?
        let groupName: String?
        let makerName: String?
    }

    // MARK: - Constants

    private static let seedVersionKey = "kfdaFoodSeedVersion"
    private static let currentSeedVersion = 1
    private static let batchSize = 500

    // MARK: - Properties

    private let persistenceController: PersistenceController

    // MARK: - Initialization

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }

    // MARK: - Public Methods

    /// 번들 JSON에서 KFDA 음식 데이터를 임포트합니다 (최초 1회).
    ///
    /// - Returns: 임포트된 음식 수 (이미 임포트된 경우 0)
    @discardableResult
    func importIfNeeded() async -> Int {
        let savedVersion = UserDefaults.standard.integer(forKey: Self.seedVersionKey)
        guard savedVersion < Self.currentSeedVersion else {
            #if DEBUG
            print("[KFDAFoodImporter] 이미 임포트 완료 (version \(savedVersion))")
            #endif
            return 0
        }

        guard let jsonURL = Bundle.main.url(forResource: "kfda_foods", withExtension: "json") else {
            #if DEBUG
            print("[KFDAFoodImporter] kfda_foods.json 번들 파일 없음")
            #endif
            return 0
        }

        do {
            let data = try Data(contentsOf: jsonURL)
            let bundle = try JSONDecoder().decode(KFDAFoodBundle.self, from: data)

            #if DEBUG
            print("[KFDAFoodImporter] JSON 파싱 완료: \(bundle.foods.count)개 음식")
            #endif

            let importedCount = try await importFoods(bundle.foods)

            UserDefaults.standard.set(Self.currentSeedVersion, forKey: Self.seedVersionKey)

            #if DEBUG
            print("[KFDAFoodImporter] 임포트 완료: \(importedCount)개")
            #endif

            return importedCount
        } catch {
            #if DEBUG
            print("[KFDAFoodImporter] 임포트 실패: \(error.localizedDescription)")
            #endif
            return 0
        }
    }

    // MARK: - Private Methods

    /// 음식 데이터를 배치로 Core Data에 삽입합니다.
    private func importFoods(_ foods: [KFDABundledFood]) async throws -> Int {
        let context = persistenceController.newBackgroundContext()

        return try await context.perform {
            var importedCount = 0

            // 기존 apiCode 조회 (중복 방지)
            let existingCodes = try self.fetchExistingApiCodes(context: context)

            for (index, food) in foods.enumerated() {
                // 중복 건너뛰기
                if existingCodes.contains(food.foodCd) {
                    continue
                }

                // Core Data Food 엔티티 생성
                let entity = Food(context: context)
                entity.id = UUID()
                entity.apiCode = food.foodCd
                entity.name = food.name
                entity.calories = Int32(food.calories ?? 0)
                entity.carbohydrates = NSDecimalNumber(value: food.carbohydrates ?? 0)
                entity.protein = NSDecimalNumber(value: food.protein ?? 0)
                entity.fat = NSDecimalNumber(value: food.fat ?? 0)
                entity.sodium = food.sodium.map { NSDecimalNumber(value: $0) }
                entity.fiber = food.fiber.map { NSDecimalNumber(value: $0) }
                entity.sugar = food.sugar.map { NSDecimalNumber(value: $0) }
                entity.servingSize = NSDecimalNumber(value: food.servingSize ?? 100)
                entity.servingUnit = food.servingUnit
                entity.source = Int16(FoodSource.governmentAPI.rawValue)
                entity.createdAt = Date()
                entity.searchCount = 0

                importedCount += 1

                // 배치 저장 (메모리 관리)
                if (index + 1) % Self.batchSize == 0 {
                    try context.save()
                    context.reset()

                    #if DEBUG
                    if (index + 1) % 5000 == 0 {
                        print("[KFDAFoodImporter] 진행 중... \(index + 1)/\(foods.count)")
                    }
                    #endif
                }
            }

            // 남은 데이터 저장
            if context.hasChanges {
                try context.save()
            }

            return importedCount
        }
    }

    /// 이미 존재하는 apiCode 집합을 조회합니다.
    private func fetchExistingApiCodes(context: NSManagedObjectContext) throws -> Set<String> {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Food")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["apiCode"]
        fetchRequest.predicate = NSPredicate(format: "apiCode != nil")

        let results = try context.fetch(fetchRequest) as? [[String: Any]] ?? []
        let codes = results.compactMap { $0["apiCode"] as? String }
        return Set(codes)
    }
}
