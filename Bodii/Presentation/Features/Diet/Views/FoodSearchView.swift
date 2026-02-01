//
//  FoodSearchView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import SwiftUI

// MARK: - Food Search View

/// 음식 검색 화면
///
/// 검색 바 + 3탭(최근/자주/커스텀) 구조.
/// 검색 모드에서는 탭이 숨겨지고 검색 결과만 표시됩니다.
struct FoodSearchView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: FoodSearchViewModel

    let userId: UUID
    let mealType: MealType
    let onSelectFood: (Food) -> Void
    let onManualEntry: () -> Void
    let onPhotoRecognition: (() -> Void)?

    // MARK: - State

    @FocusState private var isSearchFocused: Bool
    @State private var showDeleteConfirmation = false
    @State private var foodToDelete: Food?
    @State private var foodToEdit: Food?
    @State private var showingEditSheet = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                // 검색 바
                searchBar
                    .padding()
                    .background(Color(.systemBackground))

                // API 경고 배너
                if let warning = viewModel.apiWarning {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                }

                // 메인 컨텐츠
                if viewModel.isInSearchMode {
                    // 검색 모드: 검색 결과 표시
                    searchContent
                } else {
                    // 기본 모드: 3탭 표시
                    tabContent
                }

                // 수동 입력 버튼
                manualEntryButton
                    .padding()
                    .background(Color(.systemBackground))
            }
        }
        .navigationTitle("음식 검색")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onPhotoRecognition = onPhotoRecognition {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onPhotoRecognition) {
                        Image(systemName: "camera.fill")
                            .accessibilityLabel("사진으로 음식 추가")
                    }
                }
            }
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("커스텀 음식 삭제", isPresented: $showDeleteConfirmation) {
            Button("삭제", role: .destructive) {
                if let food = foodToDelete {
                    Task {
                        await viewModel.deleteCustomFood(food)
                    }
                    foodToDelete = nil
                }
            }
            Button("취소", role: .cancel) {
                foodToDelete = nil
            }
        } message: {
            if let food = foodToDelete {
                Text("\(food.name ?? "이 음식")을(를) 삭제하시겠습니까?\n관련된 식단 기록도 함께 삭제됩니다.")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let food = foodToEdit {
                NavigationStack {
                    CustomFoodEditView(
                        viewModel: CustomFoodEditViewModel(
                            food: food,
                            context: food.managedObjectContext ?? PersistenceController.shared.container.viewContext
                        ),
                        onSave: {
                            showingEditSheet = false
                            foodToEdit = nil
                            viewModel.refresh()
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("취소") {
                                showingEditSheet = false
                                foodToEdit = nil
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear(userId: userId, mealType: mealType)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                TextField("음식 이름을 입력하세요", text: $viewModel.searchQuery)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .submitLabel(.search)
                    .onSubmit {
                        viewModel.searchButtonTapped()
                        isSearchFocused = false
                    }
                    .accessibilityLabel("음식 검색")

                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.clearSearch()
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("검색어 지우기")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // 검색 버튼
            if !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: {
                    viewModel.searchButtonTapped()
                    isSearchFocused = false
                }) {
                    Text("검색")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .accessibilityLabel("검색 실행")
            }
        }
    }

    // MARK: - Search Content

    @ViewBuilder
    private var searchContent: some View {
        if viewModel.isSearching {
            Spacer()
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                Text("검색 중...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        } else if viewModel.hasSearchResults {
            ScrollView {
                searchResultsSection
                    .padding(.vertical)
            }
        } else {
            // 검색 결과 없음
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("검색 결과가 없습니다")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("다른 검색어를 입력하거나\n수동으로 음식을 추가해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        VStack(spacing: 0) {
            // Segmented Picker (3탭)
            Picker("", selection: $viewModel.selectedTab) {
                ForEach(FoodSearchTab.allCases, id: \.self) { tab in
                    Text(tab.displayName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)

            // 탭별 컨텐츠
            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("불러오는 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if viewModel.hasCurrentTabFoods {
                ScrollView {
                    tabFoodsList
                        .padding(.vertical, 4)
                }
            } else {
                // 현재 탭 빈 상태
                VStack(spacing: 16) {
                    Image(systemName: tabEmptyIcon)
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text(viewModel.emptyTabMessage)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(viewModel.emptyTabHint)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }

    /// 현재 탭의 빈 상태 아이콘
    private var tabEmptyIcon: String {
        switch viewModel.selectedTab {
        case .recent: return "clock"
        case .frequent: return "star"
        case .custom: return "square.and.pencil"
        }
    }

    // MARK: - Food Lists

    /// 검색 결과 섹션
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("검색 결과")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            foodListView(foods: viewModel.searchResults)
        }
    }

    /// 탭별 음식 목록
    private var tabFoodsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.selectedTab == .custom {
                customFoodListView(foods: viewModel.currentTabFoods)
            } else {
                foodListView(foods: viewModel.currentTabFoods)
            }
        }
    }

    /// 일반 음식 목록 뷰 (최근/자주)
    private func foodListView(foods: [Food]) -> some View {
        VStack(spacing: 0) {
            ForEach(foods) { food in
                Button(action: { onSelectFood(food) }) {
                    FoodSearchResultRow(food: food)
                }
                .buttonStyle(PlainButtonStyle())

                if food.id != foods.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    /// 커스텀 음식 목록 뷰 (수정/삭제 버튼 포함)
    private func customFoodListView(foods: [Food]) -> some View {
        VStack(spacing: 0) {
            ForEach(foods) { food in
                HStack {
                    // 탭: 식단에 추가
                    Button(action: { onSelectFood(food) }) {
                        FoodSearchResultRow(food: food)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 수정 버튼
                    Button {
                        foodToEdit = food
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 삭제 버튼
                    Button(role: .destructive) {
                        foodToDelete = food
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(.trailing, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                if food.id != foods.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Manual Entry Button

    private var manualEntryButton: some View {
        Button(action: onManualEntry) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("음식 직접 입력")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .accessibilityLabel("음식 직접 입력")
        .accessibilityHint("검색 결과에 없는 음식을 직접 입력할 수 있습니다")
    }
}

// MARK: - Preview

#Preview("Placeholder") {
    Text("FoodSearchView Preview")
        .font(.headline)
        .padding()
}
