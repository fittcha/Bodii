//
//  MetabolismResultCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 대사량 결과 표시 카드
/// BMR/TDEE 계산 결과를 표시
struct MetabolismResultCard: View {
    let title: String
    let value: Int
    let unit: String
    let description: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(unit)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Preview

#Preview("BMR Card") {
    MetabolismResultCard(
        title: "기초대사량 (BMR)",
        value: 1669,
        unit: "kcal",
        description: "아무것도 안 해도 소비되는 칼로리"
    )
    .padding()
}

#Preview("TDEE Card") {
    MetabolismResultCard(
        title: "일일 소비 칼로리 (TDEE)",
        value: 2587,
        unit: "kcal",
        description: "하루 동안 소비되는 총 칼로리"
    )
    .padding()
}

#Preview("Both Cards") {
    VStack(spacing: 16) {
        MetabolismResultCard(
            title: "기초대사량 (BMR)",
            value: 1669,
            unit: "kcal",
            description: "아무것도 안 해도 소비되는 칼로리"
        )

        MetabolismResultCard(
            title: "일일 소비 칼로리 (TDEE)",
            value: 2587,
            unit: "kcal",
            description: "하루 동안 소비되는 총 칼로리"
        )
    }
    .padding()
}
