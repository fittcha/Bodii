//
//  FoodSearchViewModel.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import Foundation
import Combine

/// 음식 검색 화면의 ViewModel
///
/// 음식 검색, 최근 사용 음식, 자주 사용하는 음식, 커스텀 음식 표시를 담당합니다.
/// 검색 버튼 탭 또는 키보드 Return 시에만 API 검색을 수행합니다.
@MainActor
final class FoodSearchViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 검색어
    @Published var searchQuery: String = ""

    /// 검색 결과 목록
    @Published var searchResults: [Food] = []

    /// 최근 사용한 음식 목록
    @Published var recentFoods: [Food] = []

    /// 자주 사용하는 음식 목록
    @Published var frequentFoods: [Food] = []

    /// 커스텀 음식 목록
    @Published var customFoods: [Food] = []

    /// 선택된 탭
    @Published var selectedTab: FoodSearchTab = .recent

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 검색 중 여부
    @Published var isSearching: Bool = false

    /// API 경고 메시지 (외부 API 실패 시)
    @Published var apiWarning: String?

    // MARK: - Private Properties

    /// 음식 검색 서비스
    private let foodSearchService: FoodSearchServiceProtocol

    /// 최근 음식 서비스
    private let recentFoodsService: RecentFoodsServiceProtocol

    /// 음식 레포지토리 (커스텀 음식 조회용)
    private let foodRepository: FoodRepositoryProtocol?

    /// 하이브리드 검색 서비스 (API 경고 관찰용)
    private weak var hybridService: HybridFoodSearchService?

    /// Combine Cancellables
    private var cancellables = Set<AnyCancellable>()

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    /// 현재 끼니 타입
    private var currentMealType: MealType?

    // MARK: - Initialization

    init(
        foodSearchService: FoodSearchServiceProtocol,
        recentFoodsService: RecentFoodsServiceProtocol,
        hybridService: HybridFoodSearchService? = nil,
        foodRepository: FoodRepositoryProtocol? = nil
    ) {
        self.foodSearchService = foodSearchService
        self.recentFoodsService = recentFoodsService
        self.hybridService = hybridService
        self.foodRepository = foodRepository

        observeAPIWarning()
    }

    // MARK: - Public Methods

    /// 화면 진입 시 호출됩니다.
    func onAppear(userId: UUID, mealType: MealType) {
        self.currentUserId = userId
        self.currentMealType = mealType

        // 이전 검색 상태 초기화
        clearSearch()

        loadInitialData()
    }

    /// 검색 버튼 탭 또는 키보드 Return 시 호출됩니다.
    func searchButtonTapped() {
        performSearch(query: searchQuery)
    }

    /// 검색어를 초기화합니다.
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
    }

    /// 데이터를 새로고침합니다.
    func refresh() {
        loadInitialData()
    }

    /// 커스텀 음식을 삭제합니다.
    func deleteCustomFood(_ food: Food) async {
        guard let repository = foodRepository,
              let foodId = food.id else { return }
        do {
            try await repository.delete(foodId)
            // 로컬 목록에서도 제거
            customFoods.removeAll { $0.id == foodId }
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    /// HybridFoodSearchService의 apiWarning을 관찰합니다.
    private func observeAPIWarning() {
        hybridService?.$apiWarning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] warning in
                self?.apiWarning = warning
            }
            .store(in: &cancellables)
    }

    /// 초기 데이터를 로드합니다.
    private func loadInitialData() {
        guard let userId = currentUserId else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                async let recent = recentFoodsService.getRecentFoods(userId: userId)
                async let frequent = recentFoodsService.getFrequentFoods(userId: userId)

                recentFoods = try await recent
                frequentFoods = try await frequent

                // 커스텀 음식도 로드
                if let repository = foodRepository {
                    customFoods = (try? await repository.getUserDefinedFoods(userId: userId)) ?? []
                }

                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }

    /// 검색을 수행합니다.
    private func performSearch(query: String) {
        guard let userId = currentUserId else { return }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        Task {
            do {
                let results = try await foodSearchService.searchFoods(
                    query: trimmedQuery,
                    userId: userId
                )

                searchResults = results
                isSearching = false
            } catch {
                handleError(error)
            }
        }
    }

    /// 에러를 처리합니다.
    private func handleError(_ error: Error) {
        isLoading = false
        isSearching = false

        if let repositoryError = error as? RepositoryError {
            errorMessage = repositoryError.localizedDescription
        } else {
            errorMessage = "오류가 발생했습니다: \(error.localizedDescription)"
        }
    }
}

// MARK: - Computed Properties

extension FoodSearchViewModel {

    /// 검색 중이거나 초기 로딩 중인지 여부
    var isAnyLoading: Bool {
        isLoading || isSearching
    }

    /// 검색 결과가 있는지 여부
    var hasSearchResults: Bool {
        !searchResults.isEmpty
    }

    /// 검색 상태인지 여부 (검색이 실행되었거나 진행 중)
    var isInSearchMode: Bool {
        isSearching || !searchResults.isEmpty
    }

    /// 현재 탭에 표시할 음식 목록
    var currentTabFoods: [Food] {
        switch selectedTab {
        case .recent: return recentFoods
        case .frequent: return frequentFoods
        case .custom: return customFoods
        }
    }

    /// 현재 탭에 음식이 있는지 여부
    var hasCurrentTabFoods: Bool {
        !currentTabFoods.isEmpty
    }

    /// 표시할 컨텐츠가 없는지 여부
    var isEmpty: Bool {
        if isInSearchMode {
            return !hasSearchResults && !isSearching
        } else {
            return !hasCurrentTabFoods && !isLoading
        }
    }

    /// 현재 탭의 빈 상태 메시지
    var emptyTabMessage: String {
        switch selectedTab {
        case .recent: return "최근 먹은 음식이 없습니다"
        case .frequent: return "자주 먹는 음식이 없습니다"
        case .custom: return "저장된 커스텀 음식이 없습니다"
        }
    }

    /// 현재 탭의 빈 상태 안내 메시지
    var emptyTabHint: String {
        switch selectedTab {
        case .recent: return "음식을 추가하면\n여기에 표시됩니다"
        case .frequent: return "음식을 자주 추가하면\n여기에 표시됩니다"
        case .custom: return "음식 직접 입력으로\n커스텀 음식을 만들어보세요"
        }
    }
}
