//
//  HybridFoodSearchService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-30.
//

import Foundation
import CoreData
import Combine

/// 로컬 + API 통합 음식 검색 서비스
///
/// 로컬 DB를 먼저 검색하여 즉시 결과를 제공하고,
/// 동시에 외부 API(KFDA/USDA)를 검색하여 추가 결과를 병합합니다.
/// API에서 가져온 음식을 사용자가 선택하면 로컬 DB에 캐시합니다.
final class HybridFoodSearchService: FoodSearchServiceProtocol, ObservableObject {

    // MARK: - Properties

    private let localService: LocalFoodSearchService
    private let apiService: UnifiedFoodSearchService
    private let foodRepository: FoodRepositoryProtocol
    private let context: NSManagedObjectContext

    /// API 검색 실패 시 경고 메시지 (UI에서 표시용)
    @Published var apiWarning: String?

    // MARK: - Initialization

    init(
        localService: LocalFoodSearchService,
        apiService: UnifiedFoodSearchService,
        foodRepository: FoodRepositoryProtocol,
        context: NSManagedObjectContext
    ) {
        self.localService = localService
        self.apiService = apiService
        self.foodRepository = foodRepository
        self.context = context
    }

    // MARK: - FoodSearchServiceProtocol

    func searchFoods(query: String, userId: UUID) async throws -> [Food] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // 1. 로컬 검색 + API 검색을 병렬 실행
        async let localResults = localService.searchFoods(query: trimmed, userId: userId)
        async let apiResults = fetchAPIResults(query: trimmed)

        let local = (try? await localResults) ?? []
        let api = await apiResults

        // 2. 로컬 결과가 충분하고 API 결과가 없으면 로컬만 반환
        if api.isEmpty && !local.isEmpty {
            return local
        }
        if api.isEmpty && local.isEmpty {
            return []
        }

        // 3. 결과 병합 (로컬 우선, API 추가, 중복 제거, 관련도순 정렬)
        // API에서 넉넉하게 가져왔으므로 관련도 상위 50개만 반환
        let merged = mergeResults(local: local, api: api, query: trimmed)
        return Array(merged.prefix(50))
    }

    func getRecentFoods(userId: UUID) async throws -> [Food] {
        return try await localService.getRecentFoods(userId: userId)
    }

    func getFrequentFoods(userId: UUID) async throws -> [Food] {
        return try await localService.getFrequentFoods(userId: userId)
    }

    // MARK: - API Result Caching

    /// API에서 가져온 음식을 로컬 DB에 캐시합니다.
    /// 사용자가 음식을 선택했을 때 호출합니다.
    func cacheFood(_ food: Food) async {
        do {
            // 이미 로컬 DB에 같은 apiCode로 존재하는지 확인
            if let apiCode = food.apiCode, !apiCode.isEmpty {
                let existing = try await findByApiCode(apiCode)
                if existing != nil {
                    return // 이미 캐시됨
                }
            }

            _ = try await foodRepository.save(food)

            #if DEBUG
            print("✅ Food cached to local DB: \(food.name ?? "unknown")")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to cache food: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Private Methods

    /// API 검색 (에러 시 빈 배열 반환, 경고 메시지 설정)
    ///
    /// KFDA API는 결과를 관련도순이 아닌 내부 정렬로 반환하므로,
    /// 충분히 많은 결과를 가져온 뒤 로컬에서 관련도 정렬을 적용합니다.
    /// 짧은 검색어(1-2글자)는 원재료가 결과 뒤쪽에 위치하므로 더 많이 가져옵니다.
    private func fetchAPIResults(query: String) async -> [Food] {
        do {
            // 짧은 검색어는 원재료를 찾기 위해 더 많은 결과 필요
            let fetchLimit = query.count <= 2 ? 1000 : 100
            var results = try await apiService.searchFoods(query: query, limit: fetchLimit)

            // 결과가 부족하면 동의어로 재검색
            if results.count < 5 {
                let syns = synonyms(for: query)
                for syn in syns where syn != query {
                    let extra = (try? await apiService.searchFoods(query: syn, limit: 50)) ?? []
                    results.append(contentsOf: extra)
                }
            }

            // 결과가 여전히 부족하고 3글자 이상 복합어면 분리 검색
            if results.count < 5 && query.count >= 3 {
                let subwords = extractSearchSubwords(from: query)
                for subword in subwords {
                    let extra = (try? await apiService.searchFoods(query: subword, limit: 50)) ?? []
                    results.append(contentsOf: extra)
                }
            }

            await MainActor.run { apiWarning = nil }
            return results
        } catch {
            #if DEBUG
            print("⚠️ API search failed, using local results only: \(error.localizedDescription)")
            #endif
            await MainActor.run {
                apiWarning = "외부 검색 서버 연결 실패. 저장된 음식만 표시됩니다."
            }
            return []
        }
    }

    /// 복합 검색어를 API 검색용 부분 단어로 분리합니다.
    /// 예: "팥도너츠" → ["팥", "도너츠"], "치킨샐러드" → ["치킨", "샐러드"]
    private func extractSearchSubwords(from query: String) -> [String] {
        var subwords: [String] = []
        let chars = Array(query)

        for splitAt in 1..<chars.count {
            let front = String(chars[0..<splitAt])
            let back = String(chars[splitAt..<chars.count])
            // 앞뒤 모두 2글자 이상인 경우만 유의미한 분리
            if front.count >= 2 && back.count >= 2 {
                subwords.append(front)
                subwords.append(back)
            }
        }

        return Array(Set(subwords))
    }

    /// 로컬 + API 결과를 병합, 중복 제거, 관련도순 정렬합니다.
    private func mergeResults(local: [Food], api: [Food], query: String? = nil) -> [Food] {
        var seen = Set<String>()
        var merged: [Food] = []

        // 로컬 결과 먼저 추가
        for food in local {
            let key = deduplicationKey(for: food)
            if !seen.contains(key) {
                seen.insert(key)
                merged.append(food)
            }
        }

        // API 결과 추가 (중복 제외)
        for food in api {
            let key = deduplicationKey(for: food)
            if !seen.contains(key) {
                seen.insert(key)
                merged.append(food)
            }
        }

        // 검색어가 있으면 관련도순 정렬
        if let query = query, !query.isEmpty {
            return sortByRelevance(merged, query: query)
        }

        return merged
    }

    /// 검색 결과를 검색어 관련도순으로 정렬합니다.
    ///
    /// KFDA 식품명 형식: "카테고리_제품명" (예: "요구르트(액상)_플레인요거트")
    ///
    /// 정렬 우선순위:
    /// 1. 정확히 일치하는 이름 (100)
    /// 2. 이름이 검색어로 시작 (80)
    /// 3. 복합명에서 카테고리가 검색어와 관련 (70) — 예: "요구르트(액상)_플레인요거트"
    /// 4. 단순 이름에 검색어 포함, 짧은 이름 (60) — 원물 가능성
    /// 5. 단순 이름에 검색어 포함, 긴 이름 (40)
    /// 6. 복합명에서 카테고리 무관, 제품명에 검색어 포함 (20) — 예: "케이크_블루베리요거트"
    /// 7. 나머지 (0)
    private func sortByRelevance(_ foods: [Food], query: String) -> [Food] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()

        return foods.sorted { a, b in
            let nameA = (a.name ?? "").lowercased()
            let nameB = (b.name ?? "").lowercased()

            let scoreA = relevanceScore(name: nameA, query: q)
            let scoreB = relevanceScore(name: nameB, query: q)

            if scoreA != scoreB {
                return scoreA > scoreB
            }
            // 같은 점수면 이름이 짧은 것을 우선 (원물일 가능성 높음)
            return nameA.count < nameB.count
        }
    }

    /// 음식 이름과 검색어의 관련도 점수
    ///
    /// KFDA 복합 식품명 ("카테고리_제품명")을 분석하여,
    /// 원재료(짧고 단순한 이름)를 가공식품보다 우선합니다.
    ///
    /// 점수 체계:
    /// - 100: 정확 일치 ("꿀" == "꿀")
    /// - 90: 접두사 일치 ("꿀물" starts with "꿀")
    /// - 85: 단순명 + 매우 짧은 이름 (≤ query+5자, 원재료 가능성 높음)
    /// - 70: 단순명 + 짧은 이름 (≤ query+15자)
    /// - 65: 복합명 카테고리 매칭 + 짧은 제품명 (≤15자)
    /// - 60: 복합명 카테고리 매칭 + 긴 제품명
    /// - 45: 복합명 제품명이 검색어로 시작
    /// - 40: 단순명 + 긴 이름
    /// - 20: 복합명 제품명에 검색어 포함
    /// - 15: 슬래시 포함 복합명
    private func relevanceScore(name: String, query: String) -> Int {
        // 검색어의 동의어 목록 (검색어 자체 포함)
        let queries = synonyms(for: query)

        // 정확히 일치
        if queries.contains(name) {
            return 100
        }

        // 이름이 검색어로 시작 (예: "꿀물", "요거트 드링크")
        if queries.contains(where: { name.hasPrefix($0) }) {
            return 90
        }

        // 복합 식품명 분석 (KFDA 형식: "카테고리_제품명")
        if let underscoreIndex = name.firstIndex(of: "_") {
            let category = String(name[name.startIndex..<underscoreIndex])
            let productName = String(name[name.index(after: underscoreIndex)...])

            // 카테고리가 검색어(동의어 포함)를 포함 → 해당 식품 종류
            if queries.contains(where: { category.contains($0) }) {
                if productName.count <= 15 {
                    return 65
                }
                return 60
            }

            // 제품명이 검색어로 시작 (예: "아이스크림_요거트 젤라또")
            if queries.contains(where: { productName.hasPrefix($0) }) {
                return 45
            }

            // 제품명에 검색어 포함하지만 카테고리 무관 (예: "케이크_블루베리요거트")
            if queries.contains(where: { productName.contains($0) }) {
                return 20
            }

            // 카테고리에도 제품명에도 검색어 없음
            return 0
        }

        // "/" 구분자 처리 (예: "비스킷/쿠키/크래커_...")
        let hasSlash = name.contains("/")

        if queries.contains(where: { name.contains($0) }) {
            if !hasSlash && name.count <= query.count + 5 {
                // 단순 이름 + 매우 짧음 → 원재료 가능성 높음 (예: "생꿀", "참꿀")
                return 85
            }
            if !hasSlash && name.count <= query.count + 15 {
                // 단순 이름 + 짧은 이름 (예: "아카시아꿀")
                return 70
            }
            if !hasSlash {
                // 이름에 포함되지만 긴 이름
                return 40
            }
            // 슬래시 포함 복합명
            return 15
        }

        return 0
    }

    /// 검색어의 한국어 동의어 목록을 반환합니다.
    /// KFDA 데이터에서 같은 식품이 다른 표기로 등록된 경우를 처리합니다.
    /// 복합어인 경우 각 부분의 동의어도 포함합니다.
    private func synonyms(for query: String) -> [String] {
        // 한국어 식품명 동의어 매핑
        let synonymMap: [[String]] = [
            ["요거트", "요구르트", "yogurt"],
            ["도넛", "도너츠", "도나쓰", "doughnut"],
            ["치킨", "chicken", "닭고기", "닭"],
            ["우유", "밀크", "milk"],
            ["빵", "bread", "브레드"],
            ["주스", "juice", "쥬스"],
            ["샐러드", "salad", "샐라드"],
            ["커피", "coffee", "카페"],
            ["초콜릿", "초코", "chocolate", "쵸콜렛"],
        ]

        var result = [query]

        // 정확히 일치하는 동의어 그룹 찾기
        for group in synonymMap {
            if group.contains(where: { $0 == query }) {
                result = group
                return result
            }
        }

        // 복합어에서 동의어 부분 매칭
        // 예: "팥도너츠" → query에 "도너츠"가 포함 → "도넛", "도나쓰" 등도 매칭 가능
        for group in synonymMap {
            for synonym in group {
                if query.contains(synonym) {
                    for altSynonym in group where altSynonym != synonym {
                        let replaced = query.replacingOccurrences(of: synonym, with: altSynonym)
                        if !result.contains(replaced) {
                            result.append(replaced)
                        }
                    }
                }
            }
        }

        return result
    }

    /// 중복 제거용 키 생성 (apiCode 우선, 없으면 name)
    private func deduplicationKey(for food: Food) -> String {
        if let apiCode = food.apiCode, !apiCode.isEmpty {
            return "api:\(apiCode)"
        }
        return "name:\(food.name ?? UUID().uuidString)"
    }

    /// apiCode로 로컬 DB에서 음식 검색
    private func findByApiCode(_ apiCode: String) async throws -> Food? {
        return try await context.perform { [weak self] in
            guard let self = self else { return nil }

            let request: NSFetchRequest<Food> = Food.fetchRequest()
            request.predicate = NSPredicate(format: "apiCode == %@", apiCode)
            request.fetchLimit = 1

            return try self.context.fetch(request).first
        }
    }
}
