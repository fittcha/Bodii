//
//  MilestoneProgressBar.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Milestone Progress Visualization Component
// 목표 진행 상황을 마일스톤과 함께 시각화하는 재사용 가능한 컴포넌트
// 💡 Java 비교: Android의 Custom Progress Bar with Milestone Markers와 유사

import SwiftUI

// MARK: - Milestone Progress Bar

/// 마일스톤 진행 바 컴포넌트
///
/// 25%, 50%, 75%, 100% 마일스톤을 시각적으로 표시하는 프로그레스 바입니다.
///
/// **주요 기능:**
/// - 전체 진행률 프로그레스 바 (그라데이션)
/// - 마일스톤 마커 (25%, 50%, 75%, 100%)
/// - 달성한 마일스톤 강조 표시 (보라색)
/// - 미달성 마일스톤 회색 표시
/// - 체크마크 아이콘으로 달성 표시
/// - 마일스톤 레이블 표시
/// - 달성한 마일스톤 목록 표시
///
/// **애니메이션:**
/// - 진행률 변경 시 부드러운 애니메이션
/// - easeInOut 애니메이션
///
/// - Example:
/// ```swift
/// MilestoneProgressBar(
///     progress: 55.0,
///     achievedMilestones: [.quarter, .half]
/// )
/// ```
struct MilestoneProgressBar: View {

    // MARK: - Properties

    /// 전체 진행률 (0.0 ~ 150.0)
    /// 📚 학습 포인트: Progress Percentage
    /// 0% ~ 100%가 일반적이지만, 초과 달성을 위해 150%까지 허용
    let progress: Decimal

    /// 달성한 마일스톤 배열
    /// 📚 학습 포인트: Milestone Achievement Tracking
    /// 25%, 50%, 75%, 100% 마일스톤 중 달성한 것들
    let achievedMilestones: [Milestone]

    /// 마일스톤 목록 표시 여부 (기본값: true)
    /// 📚 학습 포인트: Optional Content Display
    /// 공간이 제한적인 경우 목록을 숨길 수 있음
    var showAchievementList: Bool = true

    // MARK: - Constants

    /// 프로그레스 바 높이
    private let barHeight: CGFloat = 16

    /// 마일스톤 마커 크기
    private let markerSize: CGFloat = 24

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 헤더
            header

            // 프로그레스 바 with 마일스톤 마커
            progressBarWithMarkers

            // 달성한 마일스톤 목록 (옵션)
            if showAchievementList && !achievedMilestones.isEmpty {
                achievementListView
            }
        }
        .padding()
        .background(cardBackground)
    }

    // MARK: - View Components

    /// 헤더
    ///
    /// 마일스톤 제목과 아이콘을 표시합니다.
    @ViewBuilder
    private var header: some View {
        HStack {
            Image(systemName: "rosette")
                .font(.title3)
                .foregroundStyle(.purple)

            Text("마일스톤")
                .font(.headline)

            Spacer()
        }
    }

    /// 프로그레스 바 with 마일스톤 마커
    ///
    /// GeometryReader를 사용하여 마일스톤 위치를 정확히 배치합니다.
    @ViewBuilder
    private var progressBarWithMarkers: some View {
        VStack(spacing: 12) {
            // 📚 학습 포인트: GeometryReader for Precise Layout
            // 부모 뷰의 크기를 기반으로 마일스톤 위치 계산
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경 바
                    backgroundBar

                    // 진행률 바
                    progressBar(width: geometry.size.width)

                    // 마일스톤 마커들
                    milestoneMarkers
                }
            }
            .frame(height: markerSize)

            // 마일스톤 레이블
            milestoneLabels
        }
    }

    /// 배경 바
    @ViewBuilder
    private var backgroundBar: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(height: barHeight)
    }

    /// 진행률 바
    ///
    /// - Parameter width: 부모 뷰의 전체 너비
    @ViewBuilder
    private func progressBar(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                width: width * CGFloat(min(Double(truncating: progress as NSNumber) / 100.0, 1.0)),
                height: barHeight
            )
            .animation(.easeInOut, value: progress)
    }

    /// 마일스톤 마커들
    ///
    /// 25%, 50%, 75%, 100% 위치에 마커를 표시합니다.
    @ViewBuilder
    private var milestoneMarkers: some View {
        // 📚 학습 포인트: Milestone Marker Layout with Spacers
        // Spacer()를 사용하여 마커들을 균등 배치
        HStack(spacing: 0) {
            ForEach([Milestone.quarter, .half, .threeQuarters, .complete], id: \.self) { milestone in
                Spacer()

                VStack(spacing: 0) {
                    // 마커 원
                    milestoneMarker(for: milestone)
                }
                .offset(y: -4) // 바 위로 약간 올림

                if milestone != .complete {
                    Spacer()
                }
            }
        }
    }

    /// 개별 마일스톤 마커
    ///
    /// - Parameter milestone: 마일스톤 (25%, 50%, 75%, 100%)
    @ViewBuilder
    private func milestoneMarker(for milestone: Milestone) -> some View {
        let isAchieved = achievedMilestones.contains(milestone)

        Circle()
            .fill(isAchieved ? Color.purple : Color.gray.opacity(0.5))
            .frame(width: markerSize, height: markerSize)
            .overlay(
                // 달성한 경우 체크마크 표시
                Image(systemName: isAchieved ? "checkmark" : "")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            )
    }

    /// 마일스톤 레이블
    ///
    /// 각 마일스톤 아래에 레이블을 표시합니다.
    @ViewBuilder
    private var milestoneLabels: some View {
        HStack(spacing: 0) {
            ForEach([Milestone.quarter, .half, .threeQuarters, .complete], id: \.self) { milestone in
                Spacer()

                Text(milestone.displayName)
                    .font(.caption2)
                    .foregroundStyle(achievedMilestones.contains(milestone) ? .purple : .secondary)
                    .fontWeight(achievedMilestones.contains(milestone) ? .semibold : .regular)

                if milestone != .complete {
                    Spacer()
                }
            }
        }
    }

    /// 달성한 마일스톤 목록
    ///
    /// 별 아이콘과 함께 달성한 마일스톤을 나열합니다.
    @ViewBuilder
    private var achievementListView: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.caption)

            Text("달성한 마일스톤: ")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(achievedMilestones.map { $0.displayName }.joined(separator: ", "))
                .font(.caption)
                .fontWeight(.semibold)

            Spacer()
        }
    }

    /// 카드 배경
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview("진행 중 - 55%") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 55.0,
            achievedMilestones: [.quarter, .half]
        )

        Text("55% 진행 - 절반 달성")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("초반 - 30%") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 30.0,
            achievedMilestones: [.quarter]
        )

        Text("30% 진행 - 첫 번째 마일스톤 달성")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("거의 완료 - 90%") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 90.0,
            achievedMilestones: [.quarter, .half, .threeQuarters]
        )

        Text("90% 진행 - 3/4 달성")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("목표 달성 - 100%") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 100.0,
            achievedMilestones: [.quarter, .half, .threeQuarters, .complete]
        )

        Text("100% 진행 - 목표 달성!")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("초과 달성 - 110%") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 110.0,
            achievedMilestones: [.quarter, .half, .threeQuarters, .complete]
        )

        Text("110% 진행 - 초과 달성!")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("목록 숨김") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 55.0,
            achievedMilestones: [.quarter, .half],
            showAchievementList: false
        )

        Text("달성 목록 숨김 모드")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("다크 모드") {
    VStack(spacing: 20) {
        MilestoneProgressBar(
            progress: 75.0,
            achievedMilestones: [.quarter, .half, .threeQuarters]
        )

        Text("다크 모드에서의 마일스톤 바")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
