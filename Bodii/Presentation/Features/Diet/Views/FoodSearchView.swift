//
//  FoodSearchView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Food Search View
// 음식 검색 화면 - 검색, 최근 음식, 자주 사용하는 음식 표시
// 💡 검색어 입력 시 디바운스 처리하여 실시간 검색 제공

import SwiftUI

// MARK: - Food Search View

/// 음식 검색 화면
///
/// 음식을 검색하고 최근/자주 사용하는 음식을 표시하여 빠른 추가를 지원합니다.
///
/// - Note: FoodSearchViewModel을 사용하여 데이터를 관리합니다.
/// - Note: 검색어가 비어있을 때는 최근/자주 사용하는 음식을 표시합니다.
///
/// - Example:
/// ```swift
/// FoodSearchView(
///     viewModel: foodSearchViewModel,
///     userId: userId,
///     mealType: .breakfast,
///     onSelectFood: { food in
///         // 음식 선택 처리
///     }
/// )
/// ```
struct FoodSearchView: View {

    // MARK: - Properties

    /// ViewModel
    @ObservedObject var viewModel: FoodSearchViewModel

    /// 사용자 ID
    let userId: UUID

    /// 끼니 타입
    let mealType: MealType

    /// 음식 선택 콜백
    let onSelectFood: (Food) -> Void

    /// 수동 입력 콜백
    let onManualEntry: () -> Void

    /// 사진 인식 콜백 (옵션)
    let onPhotoRecognition: (() -> Void)?

    // MARK: - State

    /// 검색 필드에 포커스 여부
    @FocusState private var isSearchFocused: Bool

    // MARK: - Body

    var body: some View {
        ZStack {
            // 📚 학습 포인트: Background Color
            // iOS 디자인 가이드에 따른 시스템 배경색 사용
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                // 검색 바
                searchBar
                    .padding()
                    .background(Color(.systemBackground))

                // 메인 컨텐츠
                if viewModel.isAnyLoading {
                    // 로딩 상태 (개선된 애니메이션)
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

                        Text(viewModel.isSearching ? "검색 중..." : "불러오는 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(viewModel.isSearching ? "검색 중" : "불러오는 중")
                    .transition(.opacity)
                    Spacer()
                } else if viewModel.isEmpty {
                    // 빈 상태
                    emptyStateView
                } else {
                    // 검색 결과 또는 최근/자주 사용하는 음식 목록
                    ScrollView {
                        VStack(spacing: 16) {
                            if viewModel.isInSearchMode {
                                // 검색 결과 표시
                                searchResultsSection
                            } else {
                                // 최근 음식과 자주 사용하는 음식 표시
                                if viewModel.hasRecentFoods {
                                    recentFoodsSection
                                }

                                if viewModel.hasFrequentFoods {
                                    frequentFoodsSection
                                }
                            }
                        }
                        .padding(.vertical)
                    }
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
            // 📚 학습 포인트: Optional Toolbar Item
            // 사진 인식 기능이 활성화된 경우에만 카메라 버튼 표시
            if let onPhotoRecognition = onPhotoRecognition {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onPhotoRecognition) {
                        Image(systemName: "camera.fill")
                            .accessibilityLabel("사진으로 음식 추가")
                            .accessibilityHint("카메라로 음식을 촬영하여 자동으로 인식합니다")
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
        .onAppear {
            viewModel.onAppear(userId: userId, mealType: mealType)
        }
    }

    // MARK: - Subviews

    /// 검색 바
    ///
    /// 검색어 입력과 초기화 기능을 제공합니다.
    private var searchBar: some View {
        HStack(spacing: 12) {
            // 검색 아이콘
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            // 검색 텍스트 필드
            TextField("음식 이름을 입력하세요", text: $viewModel.searchQuery)
                .focused($isSearchFocused)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accessibilityLabel("음식 검색")
                .accessibilityHint("음식 이름을 입력하여 검색하세요")

            // 검색어 초기화 버튼
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
    }

    /// 검색 결과 섹션
    ///
    /// 검색어와 일치하는 음식 목록을 표시합니다.
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            Text("검색 결과")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            // 검색 결과 목록
            VStack(spacing: 0) {
                ForEach(viewModel.searchResults) { food in
                    Button(action: {
                        onSelectFood(food)
                    }) {
                        FoodSearchResultRow(food: food)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if food.id != viewModel.searchResults.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 최근 음식 섹션
    ///
    /// 최근에 사용한 음식 목록을 표시합니다.
    private var recentFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("최근 음식")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal)

            // 최근 음식 목록
            VStack(spacing: 0) {
                ForEach(viewModel.recentFoods) { food in
                    Button(action: {
                        onSelectFood(food)
                    }) {
                        FoodSearchResultRow(food: food)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if food.id != viewModel.recentFoods.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 자주 사용하는 음식 섹션
    ///
    /// 자주 사용한 음식 목록을 표시합니다.
    private var frequentFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.secondary)
                Text("자주 먹는 음식")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal)

            // 자주 사용하는 음식 목록
            VStack(spacing: 0) {
                ForEach(viewModel.frequentFoods) { food in
                    Button(action: {
                        onSelectFood(food)
                    }) {
                        FoodSearchResultRow(food: food)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if food.id != viewModel.frequentFoods.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    /// 빈 상태 뷰
    ///
    /// 검색 결과나 음식이 없을 때 표시되는 안내 메시지입니다.
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.isInSearchMode ? "magnifyingglass" : "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(viewModel.isInSearchMode ? "검색 결과가 없습니다" : "최근 음식이 없습니다")
                .font(.headline)
                .foregroundColor(.primary)

            Text(viewModel.isInSearchMode ? "다른 검색어를 입력하거나\n수동으로 음식을 추가해보세요" : "음식을 추가하면\n여기에 표시됩니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isInSearchMode
            ? "검색 결과가 없습니다. 다른 검색어를 입력하거나 수동으로 음식을 추가해보세요"
            : "최근 음식이 없습니다. 음식을 추가하면 여기에 표시됩니다")
    }

    /// 수동 입력 버튼
    ///
    /// 음식 수동 입력 화면으로 이동하는 버튼입니다.
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

// 📚 학습 포인트: Core Data/UseCase 의존성 Preview 제한
// Mock 클래스가 프로토콜을 준수하지 않거나 final class 상속 불가
// TODO: Phase 7에서 Preview용 Mock 구현 완성

#Preview("Placeholder") {
    Text("FoodSearchView Preview")
        .font(.headline)
        .padding()
}
