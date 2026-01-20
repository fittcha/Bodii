//
//  GenderButton.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 성별 선택 버튼
/// 아이콘과 텍스트를 표시하고 선택 상태를 시각적으로 구분
struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(isSelected ? .blue : .gray)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Male Selected") {
    HStack(spacing: 16) {
        GenderButton(
            title: "남성",
            icon: "figure.stand",
            isSelected: true
        ) {
            print("Male selected")
        }

        GenderButton(
            title: "여성",
            icon: "figure.stand.dress",
            isSelected: false
        ) {
            print("Female selected")
        }
    }
    .padding()
}

#Preview("Female Selected") {
    HStack(spacing: 16) {
        GenderButton(
            title: "남성",
            icon: "figure.stand",
            isSelected: false
        ) {
            print("Male selected")
        }

        GenderButton(
            title: "여성",
            icon: "figure.stand.dress",
            isSelected: true
        ) {
            print("Female selected")
        }
    }
    .padding()
}
