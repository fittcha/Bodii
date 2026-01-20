//
//  ActivityLevelCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 활동 수준 선택 카드
/// 활동 수준 정보와 선택 상태를 표시
struct ActivityLevelCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 아이콘
                Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 40)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                // 텍스트
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.koreanDisplayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(level.koreanDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // 활동 계수
                Text("×\(String(format: "%.2f", level.multiplier))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch level {
        case .sedentary:
            return "figure.seated.seatbelt"
        case .lightlyActive:
            return "figure.walk"
        case .moderatelyActive:
            return "figure.run"
        case .veryActive:
            return "figure.highintensity.intervaltraining"
        case .extraActive:
            return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Preview

#Preview("Selected") {
    VStack(spacing: 12) {
        ActivityLevelCard(
            level: .sedentary,
            isSelected: false
        ) {
            print("Sedentary")
        }

        ActivityLevelCard(
            level: .moderatelyActive,
            isSelected: true
        ) {
            print("Moderately Active")
        }

        ActivityLevelCard(
            level: .veryActive,
            isSelected: false
        ) {
            print("Very Active")
        }
    }
    .padding()
}

#Preview("All Levels") {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(ActivityLevel.allCases, id: \.self) { level in
                ActivityLevelCard(
                    level: level,
                    isSelected: level == .moderatelyActive
                ) {
                    print("\(level)")
                }
            }
        }
        .padding()
    }
}
