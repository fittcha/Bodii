//
//  DailyDietScoreCard.swift
//  Bodii
//
//  Created on 2026-01-29.
//

import SwiftUI

/// 일일 식단 AI 점수/총평 카드
///
/// 식단 탭 상단에 항상 표시되는 컴팩트 카드입니다.
/// 식단 추가/수정 시마다 자동으로 갱신됩니다.
struct DailyDietScoreCard: View {

    // MARK: - Properties

    /// AI 식단 코멘트
    let comment: DietComment?

    /// 로딩 상태
    let isLoading: Bool

    /// 에러 메시지
    let errorMessage: String?

    /// 카드 탭 시 상세 보기 콜백
    let onTapDetail: (() -> Void)?

    /// 재시도 콜백
    let onRetry: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                loadingCard
            } else if let error = errorMessage {
                errorCard(error)
            } else if let comment = comment {
                commentCard(comment)
            }
        }
    }

    // MARK: - Comment Card

    private func commentCard(_ comment: DietComment) -> some View {
        Button(action: { onTapDetail?() }) {
            HStack(spacing: 14) {
                // 점수 원형 배지
                scoreBadge(comment.dietScore, score: comment.score)

                // 요약 텍스트 + 마이크로 인디케이터
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("오늘의 식단 총평")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // 점수 등급 라벨
                        Text(comment.dietScore.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(comment.dietScore.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(comment.dietScore.color.opacity(0.12))
                            .cornerRadius(3)
                    }

                    Text(comment.summary)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // 잘한 점 / 개선점 마이크로 인디케이터
                    HStack(spacing: 10) {
                        if !comment.goodPoints.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.green)
                                Text("\(comment.goodPoints.count)개 잘함")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if !comment.improvements.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                                Text("\(comment.improvements.count)개 개선")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Score Badge

    private func scoreBadge(_ dietScore: DietScore, score: Int) -> some View {
        ZStack {
            Circle()
                .fill(dietScore.color.opacity(0.15))
                .frame(width: 48, height: 48)

            Circle()
                .strokeBorder(dietScore.color, lineWidth: 2.5)
                .frame(width: 48, height: 48)

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(dietScore.color)

                Text("/ 10")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(dietScore.color.opacity(0.7))
            }
        }
    }

    // MARK: - Loading Card

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.purple)

            Text("AI가 오늘의 식단을 분석하고 있어요...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - Error Card

    private func errorCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.subheadline)
                .foregroundStyle(.orange)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    Text("재시도")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

#Preview("Score - Great") {
    DailyDietScoreCard(
        comment: DietComment(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            mealType: nil,
            goodPoints: ["단백질 충분", "채소 균형"],
            improvements: ["수분 섭취 늘리기"],
            summary: "전반적으로 매우 균형잡힌 식단입니다. 영양소 비율이 목표에 잘 맞고 있어요!",
            score: 9,
            generatedAt: Date()
        ),
        isLoading: false,
        errorMessage: nil,
        onTapDetail: {},
        onRetry: nil
    )
    .padding()
}

#Preview("Score - Needs Work") {
    DailyDietScoreCard(
        comment: DietComment(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            mealType: nil,
            goodPoints: ["아침 식사"],
            improvements: ["단백질 부족", "채소 부족"],
            summary: "영양 균형이 부족합니다. 단백질과 채소 섭취를 늘려주세요.",
            score: 3,
            generatedAt: Date()
        ),
        isLoading: false,
        errorMessage: nil,
        onTapDetail: {},
        onRetry: nil
    )
    .padding()
}

#Preview("Loading") {
    DailyDietScoreCard(
        comment: nil,
        isLoading: true,
        errorMessage: nil,
        onTapDetail: nil,
        onRetry: nil
    )
    .padding()
}

#Preview("Error") {
    DailyDietScoreCard(
        comment: nil,
        isLoading: false,
        errorMessage: "네트워크 연결을 확인해주세요.",
        onTapDetail: nil,
        onRetry: {}
    )
    .padding()
}
