//
//  QuickAddSection.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Quick Add Section Component
// 최근/자주 먹는 음식을 가로 스크롤로 표시하는 빠른 추가 섹션
// 💡 FoodSearchView에서 사용되어 빠른 음식 추가를 지원

import SwiftUI

/// 빠른 추가 섹션 뷰
///
/// 최근 또는 자주 먹는 음식을 가로 스크롤로 표시하여 빠른 추가를 지원합니다.
///
/// - Note: 짧게 탭하면 기본 수량(1.0)으로 추가됩니다.
/// - Note: 길게 누르면 수량 선택 화면이 표시됩니다.
///
/// - Example:
/// ```swift
/// QuickAddSection(
///     title: "최근 음식",
///     icon: "clock",
///     foods: recentFoods,
///     onQuickAdd: { food in
///         // 기본 수량으로 음식 추가
///     },
///     onSelectWithQuantity: { food in
///         // 수량 선택 화면 표시
///     }
/// )
/// ```
struct QuickAddSection: View {

    // MARK: - Properties

    /// 섹션 제목
    let title: String

    /// 섹션 아이콘 (SF Symbol 이름)
    let icon: String

    /// 음식 목록
    let foods: [Food]

    /// 빠른 추가 액션 (기본 수량)
    let onQuickAdd: (Food) -> Void

    /// 수량 선택 후 추가 액션
    let onSelectWithQuantity: (Food) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader

            // 📚 학습 포인트: Horizontal ScrollView
            // 가로 스크롤을 사용하여 많은 아이템을 효율적으로 표시
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(foods) { food in
                        QuickAddFoodChip(
                            food: food,
                            onQuickAdd: onQuickAdd,
                            onSelectWithQuantity: onSelectWithQuantity
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Subviews

    /// 섹션 헤더
    ///
    /// 아이콘과 제목을 표시합니다.
    private var sectionHeader: some View {
        HStack(spacing: 8) {
            // 아이콘
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.secondary)

            // 제목
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // 힌트 텍스트
            Text("길게 눌러서 수량 선택")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// Food는 Core Data 엔티티이므로 직접 초기화 불가
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("QuickAddSection Preview")
        .font(.headline)
        .padding()
}
