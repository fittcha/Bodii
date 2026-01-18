//
//  DietCommentCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: AI Diet Comment Display Component
// AI 식단 코멘트를 표시하는 재사용 가능한 카드 컴포넌트
// 💡 Java 비교: Compose의 @Composable Card와 유사한 역할

import SwiftUI

// MARK: - DietCommentCard

/// AI 식단 코멘트 카드
///
/// Gemini API를 통해 생성된 AI 식단 피드백을 카드 형태로 표시하는 재사용 가능한 뷰입니다.
///
/// **표시 내용:**
/// - 식단 점수 배지 (우수/좋음/개선 필요)
/// - 좋은 점 목록
/// - 개선점 목록
/// - 전체 요약
///
/// **특징:**
/// - 점수에 따른 색상 구분 (초록/노랑/빨강)
/// - 로딩 상태 지원 (스피너)
/// - 에러 상태 지원 (재시도 버튼)
/// - 닫기 버튼 포함
/// - 한국어 현지화
///
/// - Example:
/// ```swift
/// DietCommentCard(
///     comment: dietComment,
///     isLoading: false,
///     errorMessage: nil,
///     onDismiss: { /* 닫기 액션 */ },
///     onRetry: { /* 재시도 액션 */ }
/// )
/// ```
struct DietCommentCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Optional Props Pattern
    // View의 입력 데이터는 옵셔널로 선언하여 다양한 상태 지원
    // 💡 Java 비교: @Nullable 파라미터와 유사

    /// AI 식단 코멘트 (nil이면 에러 상태 또는 로딩 상태)
    let comment: DietComment?

    /// 로딩 상태
    let isLoading: Bool

    /// 에러 메시지 (nil이면 에러 없음)
    let errorMessage: String?

    /// 닫기 버튼 콜백
    let onDismiss: (() -> Void)?

    /// 재시도 버튼 콜백
    let onRetry: (() -> Void)?

    // MARK: - Computed Properties

    /// 에러 상태인지 여부
    private var hasError: Bool {
        errorMessage != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 헤더 (닫기 버튼)
            headerSection

            // 컨텐츠 영역
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        // 로딩 상태
                        loadingView
                    } else if hasError {
                        // 에러 상태
                        errorView
                    } else if let comment = comment {
                        // 코멘트 표시
                        commentContent(comment)
                    } else {
                        // 빈 상태
                        emptyStateView
                    }
                }
                .padding(20)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Subviews

    /// 헤더 섹션 (닫기 버튼)
    private var headerSection: some View {
        HStack {
            // 제목
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.purple)

                Text("AI 식단 코멘트")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // 닫기 버튼
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }

    /// 코멘트 컨텐츠
    /// - Parameter comment: 표시할 식단 코멘트
    /// - Returns: 코멘트 내용 뷰
    private func commentContent(_ comment: DietComment) -> some View {
        VStack(spacing: 20) {
            // 점수 배지
            scoreBadge(comment.dietScore)

            // 요약
            summarySection(comment.summary)

            // 좋은 점
            if !comment.goodPoints.isEmpty {
                sectionCard(
                    title: "잘하고 있어요! 👍",
                    items: comment.goodPoints,
                    accentColor: .green
                )
            }

            // 개선점
            if !comment.improvements.isEmpty {
                sectionCard(
                    title: "개선하면 좋아요 💡",
                    items: comment.improvements,
                    accentColor: .orange
                )
            }
        }
    }

    /// 점수 배지
    /// - Parameter score: 식단 점수 등급
    /// - Returns: 점수 배지 뷰
    private func scoreBadge(_ score: DietScore) -> some View {
        HStack(spacing: 12) {
            // 점수 원형 배지
            ZStack {
                Circle()
                    .fill(score.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Circle()
                    .strokeBorder(score.color, lineWidth: 3)
                    .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Text(score.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(score.color)
                }
            }

            // 점수 설명
            VStack(alignment: .leading, spacing: 4) {
                Text("식단 평가")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(score.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(score.color)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(score.color.opacity(0.05))
        )
    }

    /// 요약 섹션
    /// - Parameter summary: 요약 텍스트
    /// - Returns: 요약 섹션 뷰
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.quote")
                    .font(.caption)
                    .foregroundStyle(.purple)

                Text("종합 평가")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Text(summary)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    /// 섹션 카드 (좋은 점 / 개선점)
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - items: 항목 목록
    ///   - accentColor: 강조 색상
    /// - Returns: 섹션 카드 뷰
    private func sectionCard(
        title: String,
        items: [String],
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 제목
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // 항목 목록
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        // 불릿 포인트
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        // 항목 텍스트
                        Text(item)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)

                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        VStack(spacing: 16) {
            // 스피너
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)

            // 로딩 메시지
            Text("AI가 식단을 분석하고 있어요...")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // 로딩 설명
            Text("영양 균형과 목표를 고려하여\n개인화된 피드백을 생성 중입니다")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    /// 에러 뷰
    /// 📚 학습 포인트: Error State UI with Retry
    private var errorView: some View {
        VStack(spacing: 20) {
            // 에러 아이콘
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            // 에러 제목
            Text("코멘트를 불러올 수 없어요")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // 에러 메시지
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // 재시도 버튼
            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)

                        Text("다시 시도")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // 빈 상태 아이콘
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.gray)

            // 빈 상태 메시지
            Text("코멘트가 없습니다")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Text("식사를 기록하면\nAI 피드백을 받을 수 있어요")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Convenience Initializers

extension DietCommentCard {
    /// 📚 학습 포인트: Convenience Initializer for Success State
    /// - 코멘트가 정상적으로 로드된 상태의 편의 생성자
    ///
    /// - Parameters:
    ///   - comment: 식단 코멘트
    ///   - onDismiss: 닫기 버튼 콜백
    init(
        comment: DietComment,
        onDismiss: (() -> Void)? = nil
    ) {
        self.comment = comment
        self.isLoading = false
        self.errorMessage = nil
        self.onDismiss = onDismiss
        self.onRetry = nil
    }

    /// 📚 학습 포인트: Convenience Initializer for Loading State
    /// - 로딩 중 상태의 편의 생성자
    ///
    /// - Parameter onDismiss: 닫기 버튼 콜백
    static func loading(onDismiss: (() -> Void)? = nil) -> DietCommentCard {
        DietCommentCard(
            comment: nil,
            isLoading: true,
            errorMessage: nil,
            onDismiss: onDismiss,
            onRetry: nil
        )
    }

    /// 📚 학습 포인트: Convenience Initializer for Error State
    /// - 에러 상태의 편의 생성자
    ///
    /// - Parameters:
    ///   - message: 에러 메시지
    ///   - onDismiss: 닫기 버튼 콜백
    ///   - onRetry: 재시도 버튼 콜백
    static func error(
        message: String,
        onDismiss: (() -> Void)? = nil,
        onRetry: (() -> Void)? = nil
    ) -> DietCommentCard {
        DietCommentCard(
            comment: nil,
            isLoading: false,
            errorMessage: message,
            onDismiss: onDismiss,
            onRetry: onRetry
        )
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (성공/로딩/에러)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Success - Great Score") {
    DietCommentCard(
        comment: DietComment(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            mealType: .lunch,
            goodPoints: [
                "단백질 섭취가 충분합니다",
                "채소 섭취가 균형있어요",
                "탄수화물 양이 적절합니다"
            ],
            improvements: [
                "과일 섭취를 조금 더 늘려보세요",
                "수분 섭취를 충분히 해주세요"
            ],
            summary: "전반적으로 매우 균형잡힌 식단입니다. 영양소 비율이 목표에 잘 맞고 있어요!",
            score: 9,
            generatedAt: Date()
        ),
        onDismiss: { print("Dismiss tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Success - Good Score") {
    DietCommentCard(
        comment: DietComment(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            mealType: .dinner,
            goodPoints: [
                "칼로리가 목표 범위 안에 있어요",
                "단백질 섭취가 양호합니다"
            ],
            improvements: [
                "탄수화물 섭취가 다소 높습니다",
                "나트륨 섭취를 줄여보세요",
                "채소 섭취를 늘려주세요"
            ],
            summary: "좋은 식단이지만 나트륨과 탄수화물 조절이 필요해요.",
            score: 6,
            generatedAt: Date()
        ),
        onDismiss: { print("Dismiss tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Success - Needs Work") {
    DietCommentCard(
        comment: DietComment(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            mealType: .breakfast,
            goodPoints: [
                "아침 식사를 거르지 않았어요"
            ],
            improvements: [
                "칼로리가 목표보다 너무 적습니다",
                "단백질 섭취가 부족해요",
                "채소 섭취가 부족합니다",
                "균형잡힌 식사를 하세요"
            ],
            summary: "영양 균형이 많이 부족합니다. 다음 끼니에서 더 신경 써주세요.",
            score: 3,
            generatedAt: Date()
        ),
        onDismiss: { print("Dismiss tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Loading State") {
    DietCommentCard.loading(
        onDismiss: { print("Dismiss tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Error State") {
    DietCommentCard.error(
        message: "네트워크 연결을 확인해주세요",
        onDismiss: { print("Dismiss tapped") },
        onRetry: { print("Retry tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Rate Limit Error") {
    DietCommentCard.error(
        message: "API 요청 한도를 초과했습니다.\n5분 후에 다시 시도해주세요.",
        onDismiss: { print("Dismiss tapped") },
        onRetry: { print("Retry tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    DietCommentCard(
        comment: nil,
        isLoading: false,
        errorMessage: nil,
        onDismiss: { print("Dismiss tapped") },
        onRetry: nil
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode - Success") {
    DietCommentCard(
        comment: DietComment(
            id: UUID(),
            userId: UUID(),
            date: Date(),
            mealType: .lunch,
            goodPoints: [
                "단백질 섭취가 충분합니다",
                "채소 섭취가 균형있어요"
            ],
            improvements: [
                "과일 섭취를 늘려보세요"
            ],
            summary: "전반적으로 균형잡힌 식단입니다!",
            score: 8,
            generatedAt: Date()
        ),
        onDismiss: { print("Dismiss tapped") }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

// MARK: - Documentation

/// 📚 학습 포인트: DietCommentCard 사용법
///
/// **ViewModel과 함께 사용 (권장):**
/// ```swift
/// struct DietCommentPopupView: View {
///     @ObservedObject var viewModel: DietCommentViewModel
///
///     var body: some View {
///         DietCommentCard(
///             comment: viewModel.comment,
///             isLoading: viewModel.isLoading,
///             errorMessage: viewModel.errorMessage,
///             onDismiss: { viewModel.dismissComment() },
///             onRetry: { viewModel.generateComment() }
///         )
///     }
/// }
/// ```
///
/// **편의 생성자로 사용:**
/// ```swift
/// // 성공 상태
/// DietCommentCard(
///     comment: dietComment,
///     onDismiss: { /* 닫기 */ }
/// )
///
/// // 로딩 상태
/// DietCommentCard.loading(
///     onDismiss: { /* 닫기 */ }
/// )
///
/// // 에러 상태
/// DietCommentCard.error(
///     message: "네트워크 연결을 확인해주세요",
///     onDismiss: { /* 닫기 */ },
///     onRetry: { /* 재시도 */ }
/// )
/// ```
///
/// **주요 기능:**
/// - 점수에 따른 색상 구분 (초록/노랑/빨강)
/// - 좋은 점과 개선점을 명확히 구분하여 표시
/// - 로딩 상태와 에러 상태 지원
/// - 재시도 기능으로 사용자 경험 향상
/// - 닫기 버튼으로 편리한 UI 제어
/// - 라이트/다크 모드 자동 대응
/// - 스크롤 가능한 컨텐츠 영역
///
/// **디자인 패턴:**
/// - Props-based design (Stateless component)
/// - Computed properties for derived state
/// - View composition for reusable sections
/// - Convenience initializers for common states
/// - Preview-driven development
///
/// **💡 Android 비교:**
/// - Android: CardView + Compose Column
/// - SwiftUI: VStack with background and shadow
/// - Android: ViewModel LiveData
/// - SwiftUI: ViewModel @Published
/// - Android: Loading/Error/Success states
/// - SwiftUI: Optional comment + isLoading + errorMessage
///
