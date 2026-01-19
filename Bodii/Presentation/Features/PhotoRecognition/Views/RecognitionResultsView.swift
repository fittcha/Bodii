//
//  RecognitionResultsView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Recognition Results View
// AI 음식 인식 결과를 표시하고 사용자 확인/수정을 받는 화면
// 💡 인식된 음식 목록, 선택/삭제, 추가 검색 기능 제공

import SwiftUI

/// 음식 인식 결과 화면
///
/// Vision API로 인식한 음식 목록을 표시하고 사용자가 확인/수정할 수 있는 화면입니다.
///
/// **주요 기능:**
/// - 촬영한 이미지 썸네일 표시
/// - 인식된 음식 목록 (신뢰도 순)
/// - 체크박스로 포함/제외 선택
/// - 스와이프하여 음식 삭제
/// - 추가 음식 검색 버튼
/// - 빈 상태 처리 (음식 미인식)
/// - 에러 상태 처리 (재시도 버튼)
///
/// - Note: PhotoRecognitionViewModel을 사용하여 데이터를 관리합니다.
/// - Note: 각 음식은 FoodMatchCard 컴포넌트로 표시됩니다.
///
/// - Example:
/// ```swift
/// RecognitionResultsView(
///     viewModel: photoRecognitionViewModel,
///     capturedImage: image,
///     matches: foodMatches,
///     onContinue: { selectedMatches in
///         // 선택된 음식 처리
///     },
///     onAddMoreFoods: {
///         // 음식 추가 검색 열기
///     },
///     onRetry: {
///         // 재시도 처리
///     }
/// )
/// ```
struct RecognitionResultsView: View {

    // MARK: - Properties

    /// ViewModel
    @ObservedObject var viewModel: PhotoRecognitionViewModel

    /// 촬영한 이미지
    let capturedImage: UIImage?

    /// 인식된 음식 매칭 목록
    let matches: [FoodMatch]

    /// 계속하기 버튼 콜백 (선택된 음식들 전달)
    let onContinue: ([FoodMatch]) -> Void

    /// 음식 추가 검색 콜백
    let onAddMoreFoods: () -> Void

    /// 재시도 콜백
    let onRetry: () -> Void

    /// 취소 콜백
    let onCancel: () -> Void

    // MARK: - State

    /// 선택된 음식 ID 목록
    ///
    /// 📚 학습 포인트: Set-based Selection Tracking
    /// Set을 사용하여 선택 상태를 O(1)로 조회 가능
    @State private var selectedMatchIds: Set<UUID> = []

    /// 삭제할 음식 ID (스와이프 삭제용)
    @State private var matchesToDelete: Set<UUID> = []

    /// 편집 중인 음식 매칭 (편집 화면으로 이동)
    @State private var editingMatch: FoodMatch?

    /// 편집된 음식 항목들 (수량/단위 정보 포함)
    ///
    /// 📚 학습 포인트: Edited Items Dictionary
    /// 사용자가 편집한 수량/단위 정보를 UUID로 매핑하여 관리
    @State private var editedItems: [UUID: EditedFoodItem] = [:]

    /// 확인 화면으로 이동 여부
    @State private var showingConfirmView: Bool = false

    // MARK: - Lifecycle

    var body: some View {
        ZStack {
            // 배경색
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // 메인 컨텐츠
            if viewModel.isOffline {
                // 오프라인 상태
                offlineStateView
            } else if viewModel.hasError {
                // 에러 상태
                errorStateView
            } else if filteredMatches.isEmpty && !viewModel.isLoading {
                // 빈 상태 (음식 미인식)
                emptyStateView
            } else {
                // 결과 표시
                resultsContentView
            }
        }
        .navigationTitle("인식 결과")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("취소") {
                    onCancel()
                }
            }
        }
        .navigationDestination(item: $editingMatch) { match in
            // 음식 편집 화면
            FoodMatchEditorView(
                match: match,
                onSave: { updatedMatch, quantity, unit, mealType in
                    // 편집된 항목 저장
                    editedItems[updatedMatch.id] = EditedFoodItem(
                        match: updatedMatch,
                        quantity: quantity,
                        unit: unit
                    )
                    // 편집 화면 닫기
                    editingMatch = nil
                },
                onDelete: {
                    // 항목 삭제
                    deleteMatch(match)
                    editingMatch = nil
                },
                onSearchAlternative: { currentMatch in
                    // 다른 음식 검색
                    // TODO: 음식 검색 화면 열기
                    #if DEBUG
                    print("ℹ️ Search alternative for: \(currentMatch.food.name)")
                    #endif
                },
                onCancel: {
                    // 취소 - 편집 화면 닫기
                    editingMatch = nil
                }
            )
        }
        .navigationDestination(isPresented: $showingConfirmView) {
            // 최종 확인 화면
            RecognitionConfirmView(
                viewModel: viewModel,
                selectedItems: getEditedItemsForSave(),
                onSave: {
                    // 저장 완료 후 처리 (RecognitionConfirmView에서 실제 저장 수행)
                    showingConfirmView = false
                    // DietTabView에서 데이터 새로고침하도록 더미 호출
                    // (실제 저장은 RecognitionConfirmView에서 이미 완료됨)
                    onContinue([])
                },
                onCancel: {
                    // 확인 화면 닫기
                    showingConfirmView = false
                }
            )
        }
        .onAppear {
            // 초기 상태: 모든 음식 선택
            selectedMatchIds = Set(matches.map { $0.id })
        }
    }

    // MARK: - Subviews

    /// 결과 표시 뷰
    private var resultsContentView: some View {
        VStack(spacing: 0) {
            // 할당량 경고 배너
            if viewModel.showQuotaWarning && !viewModel.isQuotaExceeded {
                QuotaWarningView(
                    showWarning: viewModel.showQuotaWarning,
                    remainingQuota: viewModel.remainingQuota,
                    daysUntilReset: viewModel.daysUntilReset,
                    isQuotaExceeded: viewModel.isQuotaExceeded,
                    onManualEntryTapped: {
                        onAddMoreFoods()
                    }
                )
            }

            // 스크롤 가능한 컨텐츠
            ScrollView {
                VStack(spacing: 16) {
                    // 이미지 썸네일
                    if let image = capturedImage {
                        imageThumbnailSection(image)
                    }

                    // 인식 결과 요약
                    resultsSummarySection

                    // 음식 목록
                    foodMatchesSection
                }
                .padding(.vertical)
            }

            // 하단 액션 버튼
            bottomActionButtons
                .padding()
                .background(Color(.systemBackground))
        }
    }

    /// 이미지 썸네일 섹션
    ///
    /// 촬영한 이미지를 작은 썸네일로 표시합니다.
    ///
    /// - Parameter image: 표시할 이미지
    private func imageThumbnailSection(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("촬영한 사진")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
        }
    }

    /// 인식 결과 요약 섹션
    ///
    /// 인식된 음식 개수와 선택된 음식 개수를 표시합니다.
    private var resultsSummarySection: some View {
        HStack(spacing: 12) {
            // 인식 완료 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("음식 인식 완료")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(filteredMatches.count)개 음식 인식됨 · \(selectedCount)개 선택됨")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .padding(.horizontal)
    }

    /// 음식 매칭 목록 섹션
    ///
    /// 인식된 음식들을 카드 형태로 표시합니다.
    private var foodMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack {
                Text("인식된 음식")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // 전체 선택/해제 버튼
                Button(action: toggleAllSelection) {
                    Text(isAllSelected ? "전체 해제" : "전체 선택")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // 음식 카드 목록
            ForEach(filteredMatches) { match in
                FoodMatchCard(
                    match: match,
                    isSelected: selectedMatchIds.contains(match.id),
                    onToggleSelection: { isSelected in
                        toggleSelection(for: match, isSelected: isSelected)
                    },
                    onTap: {
                        // 음식 편집 화면으로 이동
                        editingMatch = match
                    }
                )
                .padding(.horizontal)
                .transition(.opacity)
                // 스와이프하여 삭제
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteMatch(match)
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                }
            }

            // 음식 추가 버튼
            addMoreFoodsButton
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }

    /// 음식 추가 버튼
    private var addMoreFoodsButton: some View {
        Button(action: onAddMoreFoods) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)

                Text("다른 음식 추가")
                    .font(.headline)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1.5)
            )
        }
    }

    /// 하단 액션 버튼들
    private var bottomActionButtons: some View {
        VStack(spacing: 12) {
            // 선택 요약
            if selectedCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)

                    Text("\(selectedCount)개 음식 선택됨")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 4)
            }

            // 계속하기 버튼
            Button(action: handleContinue) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)

                    Text("선택한 음식 추가")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedCount > 0 ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(selectedCount == 0)
        }
    }

    /// 빈 상태 뷰
    ///
    /// 음식이 인식되지 않았을 때 표시되는 안내 메시지입니다.
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 안내 아이콘
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            // 안내 텍스트
            VStack(spacing: 8) {
                Text("음식을 인식하지 못했습니다")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("다른 각도에서 다시 촬영하거나\n수동으로 음식을 추가해보세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // 액션 버튼들
            VStack(spacing: 12) {
                // 재시도 버튼
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)

                        Text("다시 촬영")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                // 수동 추가 버튼
                Button(action: onAddMoreFoods) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.title3)

                        Text("수동으로 음식 추가")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }

    /// 오프라인 상태 뷰
    ///
    /// 네트워크 연결이 없을 때 표시되는 뷰입니다.
    private var offlineStateView: some View {
        PhotoRecognitionOfflineView(
            onRetry: {
                Task {
                    try? await viewModel.retry()
                }
            },
            onManualEntry: {
                onAddMoreFoods()
            }
        )
    }

    /// 에러 상태 뷰
    ///
    /// 인식 실패 시 표시되는 에러 메시지와 재시도 버튼입니다.
    private var errorStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 에러 아이콘
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            // 에러 메시지
            VStack(spacing: 8) {
                Text("인식 중 오류가 발생했습니다")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            Spacer()

            // 재시도 버튼
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        try? await viewModel.retry()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)

                        Text("다시 시도")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Button(action: onCancel) {
                    Text("취소")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    /// 선택 토글
    ///
    /// 특정 음식의 선택 상태를 변경합니다.
    ///
    /// - Parameters:
    ///   - match: 음식 매칭
    ///   - isSelected: 선택 여부
    private func toggleSelection(for match: FoodMatch, isSelected: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isSelected {
                selectedMatchIds.insert(match.id)
            } else {
                selectedMatchIds.remove(match.id)
            }
        }
    }

    /// 전체 선택/해제 토글
    private func toggleAllSelection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isAllSelected {
                selectedMatchIds.removeAll()
            } else {
                selectedMatchIds = Set(filteredMatches.map { $0.id })
            }
        }
    }

    /// 음식 매칭 삭제
    ///
    /// 📚 학습 포인트: Swipe to Delete
    /// 스와이프 제스처로 목록에서 항목 제거
    ///
    /// - Parameter match: 삭제할 음식 매칭
    private func deleteMatch(_ match: FoodMatch) {
        withAnimation(.easeInOut(duration: 0.3)) {
            matchesToDelete.insert(match.id)
            selectedMatchIds.remove(match.id)
        }
    }

    /// 계속하기 버튼 처리
    ///
    /// 📚 학습 포인트: Navigate to Confirmation
    /// 선택된 음식들을 확인 화면으로 이동합니다.
    private func handleContinue() {
        let selectedMatches = filteredMatches.filter { selectedMatchIds.contains($0.id) }

        guard !selectedMatches.isEmpty else {
            return
        }

        // 확인 화면으로 이동
        showingConfirmView = true
    }

    /// 저장할 편집된 음식 항목 목록 생성
    ///
    /// 📚 학습 포인트: Edited Items Assembly
    /// 선택된 음식에 대해 사용자가 편집한 수량 정보를 포함한 EditedFoodItem 생성
    /// 편집하지 않은 음식은 기본값(1.0 serving)으로 생성
    ///
    /// - Returns: 저장할 EditedFoodItem 배열
    private func getEditedItemsForSave() -> [EditedFoodItem] {
        let selectedMatches = filteredMatches.filter { selectedMatchIds.contains($0.id) }

        return selectedMatches.map { match in
            // 편집된 항목이 있으면 사용, 없으면 기본값으로 생성
            if let editedItem = editedItems[match.id] {
                return editedItem
            } else {
                return EditedFoodItem(
                    match: match,
                    quantity: 1.0,
                    unit: .serving
                )
            }
        }
    }

    // MARK: - Computed Properties

    /// 삭제되지 않은 음식 매칭 목록
    ///
    /// 📚 학습 포인트: Filtered List
    /// 삭제 표시된 항목을 제외한 목록 반환
    private var filteredMatches: [FoodMatch] {
        matches.filter { !matchesToDelete.contains($0.id) }
    }

    /// 선택된 음식 개수
    private var selectedCount: Int {
        selectedMatchIds.count
    }

    /// 전체 선택 여부
    private var isAllSelected: Bool {
        !filteredMatches.isEmpty && selectedMatchIds.count == filteredMatches.count
    }
}

// MARK: - Preview

// 📚 학습 포인트: Core Data 및 ViewModel 타입 제약
// Food는 Core Data 엔티티, MockPhotoRecognitionViewModel은 PhotoRecognitionViewModel으로 변환 불가
// TODO: Phase 7에서 Preview용 helper 및 protocol 리팩토링 후 수정

#Preview("Placeholder") {
    Text("RecognitionResultsView Preview")
        .font(.headline)
        .padding()
}
