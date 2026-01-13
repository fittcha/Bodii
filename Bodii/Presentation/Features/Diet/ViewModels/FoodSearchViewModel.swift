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
/// 음식 검색, 최근 사용 음식, 자주 사용하는 음식 표시를 담당합니다.
/// 검색어 입력 시 300ms 디바운스를 적용하여 API 호출을 최적화합니다.
///
/// - Note: ObservableObject를 준수하여 SwiftUI View와 바인딩됩니다.
/// - Note: 검색어가 비어있을 때는 최근/자주 사용하는 음식을 표시합니다.
///
/// - Example:
/// ```swift
/// let viewModel = FoodSearchViewModel(
///     foodSearchService: foodSearchService,
///     recentFoodsService: recentFoodsService
/// )
/// viewModel.onAppear(userId: userId, mealType: .breakfast)
/// viewModel.searchQuery = "닭가슴살"
/// ```
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

    /// 로딩 상태
    @Published var isLoading: Bool = false

    /// 에러 메시지
    @Published var errorMessage: String?

    /// 검색 중 여부
    @Published var isSearching: Bool = false

    // MARK: - Private Properties

    /// 음식 검색 서비스
    private let foodSearchService: FoodSearchServiceProtocol

    /// 최근 음식 서비스
    private let recentFoodsService: RecentFoodsServiceProtocol

    /// Combine Cancellables
    private var cancellables = Set<AnyCancellable>()

    /// 현재 사용자 ID
    private var currentUserId: UUID?

    /// 현재 끼니 타입
    private var currentMealType: MealType?

    // MARK: - Initialization

    /// FoodSearchViewModel을 초기화합니다.
    ///
    /// - Parameters:
    ///   - foodSearchService: 음식 검색 서비스
    ///   - recentFoodsService: 최근 음식 서비스
    init(
        foodSearchService: FoodSearchServiceProtocol,
        recentFoodsService: RecentFoodsServiceProtocol
    ) {
        self.foodSearchService = foodSearchService
        self.recentFoodsService = recentFoodsService

        setupSearchDebounce()
    }

    // MARK: - Public Methods

    /// 화면 진입 시 호출됩니다.
    ///
    /// 최근 사용 음식과 자주 사용하는 음식을 불러옵니다.
    ///
    /// - Parameters:
    ///   - userId: 사용자 ID
    ///   - mealType: 끼니 타입
    func onAppear(userId: UUID, mealType: MealType) {
        self.currentUserId = userId
        self.currentMealType = mealType

        loadInitialData()
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

    // MARK: - Private Methods

    /// 검색어 디바운스를 설정합니다.
    ///
    /// 검색어가 변경되면 300ms 대기 후 검색을 수행합니다.
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    /// 초기 데이터를 로드합니다.
    ///
    /// 최근 사용 음식과 자주 사용하는 음식을 병렬로 조회합니다.
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

                isLoading = false
            } catch {
                handleError(error)
            }
        }
    }

    /// 검색을 수행합니다.
    ///
    /// - Parameter query: 검색어
    private func performSearch(query: String) {
        guard let userId = currentUserId else { return }

        // 빈 검색어인 경우 검색 결과를 초기화
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
    ///
    /// - Parameter error: 발생한 에러
    private func handleError(_ error: Error) {
        isLoading = false
        isSearching = false

        // 에러 메시지 설정
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

    /// 최근 음식이 있는지 여부
    var hasRecentFoods: Bool {
        !recentFoods.isEmpty
    }

    /// 자주 사용하는 음식이 있는지 여부
    var hasFrequentFoods: Bool {
        !frequentFoods.isEmpty
    }

    /// 검색 상태인지 여부
    var isInSearchMode: Bool {
        !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 표시할 컨텐츠가 없는지 여부
    var isEmpty: Bool {
        if isInSearchMode {
            return !hasSearchResults && !isSearching
        } else {
            return !hasRecentFoods && !hasFrequentFoods && !isLoading
        }
    }
}
