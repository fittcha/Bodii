//
//  ExerciseTypeGridView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import SwiftUI

/// 운동 종류 선택 그리드 컴포넌트
///
/// 8가지 운동 종류를 그리드 형태로 표시하고 선택할 수 있는 재사용 가능한 컴포넌트입니다.
///
/// **주요 기능**:
/// - 4×2 그리드 레이아웃으로 8개 운동 종류 표시
/// - 각 운동 종류별 SF Symbol 아이콘
/// - 선택 상태 시각적 강조 (색상, 폰트 굵기)
/// - 접근성 고려한 충분한 터치 영역 (50×50pt 원형 아이콘)
///
/// - Example:
/// ```swift
/// ExerciseTypeGridView(selectedType: $exerciseType)
/// ```
struct ExerciseTypeGridView: View {

    // MARK: - Properties

    /// 선택된 운동 종류 (양방향 바인딩)
    @Binding var selectedType: ExerciseType

    // MARK: - Body

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(ExerciseType.allCases) { exerciseType in
                exerciseTypeButton(for: exerciseType)
            }
        }
    }

    // MARK: - Subviews

    /// 운동 종류 버튼
    private func exerciseTypeButton(for type: ExerciseType) -> some View {
        let isSelected = selectedType == type

        return Button(action: {
            selectedType = type
        }) {
            VStack(spacing: 8) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(isSelected ? exerciseTypeColor(for: type) : Color(.systemGray5))
                        .frame(width: 50, height: 50)

                    Image(systemName: exerciseTypeIcon(for: type))
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .primary)
                }

                // 라벨
                Text(type.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? exerciseTypeColor(for: type) : .primary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    /// 운동 종류별 아이콘
    ///
    /// SF Symbols를 사용한 운동 종류별 아이콘 매핑
    ///
    /// - Parameter type: 운동 종류
    /// - Returns: SF Symbol 이름
    private func exerciseTypeIcon(for type: ExerciseType) -> String {
        switch type {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .weight:
            return "dumbbell.fill"
        case .crossfit:
            return "figure.cross.training"
        case .yoga:
            return "figure.yoga"
        case .other:
            return "figure.mixed.cardio"
        }
    }

    /// 운동 종류별 색상
    ///
    /// 각 운동 종류를 시각적으로 구분하기 위한 색상 매핑
    ///
    /// - Parameter type: 운동 종류
    /// - Returns: SwiftUI Color
    private func exerciseTypeColor(for type: ExerciseType) -> Color {
        switch type {
        case .walking:
            return .green
        case .running:
            return .blue
        case .cycling:
            return .orange
        case .swimming:
            return .cyan
        case .weight:
            return .red
        case .crossfit:
            return .purple
        case .yoga:
            return .pink
        case .other:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // 걷기 선택된 상태
        ExerciseTypeGridView(selectedType: .constant(.walking))
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

        // 러닝 선택된 상태
        ExerciseTypeGridView(selectedType: .constant(.running))
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

        // 웨이트 선택된 상태
        ExerciseTypeGridView(selectedType: .constant(.weight))
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
