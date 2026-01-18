//
//  MilestoneCelebrationView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Celebration Modal with Dynamic Content
// 마일스톤별로 다른 축하 메시지와 애니메이션을 보여주는 모달
// 💡 Java 비교: Android의 Custom Dialog with Animation과 유사

import SwiftUI

// MARK: - Milestone Celebration View

/// 마일스톤 달성 축하 뷰
///
/// 마일스톤 달성 시 표시되는 축하 모달입니다.
///
/// **주요 기능:**
/// - 색종이 애니메이션 효과
/// - 마일스톤별 맞춤 메시지와 아이콘
/// - 진동(haptic) 피드백
/// - 애니메이션 등장 효과
/// - 닫기 버튼
///
/// **마일스톤별 차별화:**
/// - 25% (1/4): 파란색, 별 아이콘, 낮은 색종이 강도
/// - 50% (절반): 주황색, 불 아이콘, 중간 색종이 강도
/// - 75% (3/4): 보라색, 로켓 아이콘, 높은 색종이 강도
/// - 100% (완료): 초록색, 트로피 아이콘, 매우 높은 색종이 강도
///
/// - Example:
/// ```swift
/// MilestoneCelebrationView(
///     milestones: [.half, .threeQuarters],
///     onDismiss: {
///         // 축하 모달 닫기
///     }
/// )
/// ```
struct MilestoneCelebrationView: View {

    // MARK: - Properties

    /// 달성한 마일스톤 목록
    /// 📚 학습 포인트: Multiple Milestones Support
    /// 여러 마일스톤을 동시에 달성할 수 있음 (ex: 40% → 60% 점프 시 50% 마일스톤)
    let milestones: [Milestone]

    /// 닫기 버튼 콜백
    let onDismiss: () -> Void

    // MARK: - State

    /// 색종이 애니메이션 활성화 여부
    @State private var showConfetti = false

    /// 카드 스케일 애니메이션
    @State private var cardScale: CGFloat = 0.8

    /// 카드 투명도 애니메이션
    @State private var cardOpacity: Double = 0.0

    // MARK: - Computed Properties

    /// 가장 높은 마일스톤 (축하 강도 결정용)
    /// 📚 학습 포인트: Highest Achievement Display
    /// 여러 마일스톤 중 가장 높은 것을 기준으로 축하 레벨 결정
    private var primaryMilestone: Milestone {
        milestones.max(by: { $0.percentage < $1.percentage }) ?? .quarter
    }

    /// 마일스톤별 색상
    private var milestoneColor: Color {
        switch primaryMilestone {
        case .quarter: return .blue
        case .half: return .orange
        case .threeQuarters: return .purple
        case .complete: return .green
        }
    }

    /// 마일스톤별 아이콘
    private var milestoneIcon: String {
        switch primaryMilestone {
        case .quarter: return "star.fill"
        case .half: return "flame.fill"
        case .threeQuarters: return "rocket.fill"
        case .complete: return "trophy.fill"
        }
    }

    /// 축하 메시지 제목
    private var congratulationTitle: String {
        switch primaryMilestone {
        case .quarter: return "좋은 시작이에요! 🎯"
        case .half: return "절반을 넘었어요! 🔥"
        case .threeQuarters: return "거의 다 왔어요! 🚀"
        case .complete: return "목표 달성! 🏆"
        }
    }

    /// 축하 메시지 본문
    private var congratulationMessage: String {
        switch primaryMilestone {
        case .quarter:
            return "첫 번째 마일스톤을 달성했습니다.\n이 조자로 계속 해봐요!"
        case .half:
            return "벌써 절반이나 왔네요!\n목표가 손에 잡힙니다."
        case .threeQuarters:
            return "3/4 지점을 통과했습니다.\n마지막 스퍼트!"
        case .complete:
            return "축하합니다! 목표를 달성했어요.\n정말 대단해요!"
        }
    }

    /// 격려 메시지
    private var encouragementMessage: String {
        switch primaryMilestone {
        case .quarter:
            return "시작이 반이라고 하죠. 멋진 출발입니다!"
        case .half:
            return "계속 이런 페이스로 가면 곧 목표를 달성할 거예요!"
        case .threeQuarters:
            return "여기까지 온 당신, 정말 대단해요!"
        case .complete:
            return "새로운 목표에 도전해보는 건 어떨까요?"
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 배경 딤 처리
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // 색종이 효과
            ConfettiEffect(
                intensity: primaryMilestone.confettiIntensity,
                isActive: $showConfetti
            )
            .allowsHitTesting(false)

            // 축하 카드
            celebrationCard
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
        }
        .onAppear {
            startCelebration()
        }
    }

    // MARK: - View Components

    /// 축하 카드
    @ViewBuilder
    private var celebrationCard: some View {
        VStack(spacing: 0) {
            // 헤더 (색상 배경)
            headerSection
                .background(milestoneColor.gradient)

            // 본문
            contentSection
                .background(Color(.systemBackground))

            // 버튼
            buttonSection
                .background(Color(.systemBackground))
        }
        .frame(width: 320)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    /// 헤더 섹션 (아이콘 + 타이틀)
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 마일스톤 아이콘
            Image(systemName: milestoneIcon)
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            // 제목
            Text(congratulationTitle)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.bottom, 30)
    }

    /// 본문 섹션 (달성한 마일스톤 + 메시지)
    @ViewBuilder
    private var contentSection: some View {
        VStack(spacing: 20) {
            // 달성한 마일스톤 목록
            milestonesListSection

            // 축하 메시지
            VStack(spacing: 8) {
                Text(congratulationMessage)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(encouragementMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }

    /// 달성한 마일스톤 목록
    @ViewBuilder
    private var milestonesListSection: some View {
        if milestones.count == 1 {
            // 단일 마일스톤
            milestoneBadge(milestones[0])
        } else {
            // 여러 마일스톤
            VStack(spacing: 8) {
                Text("새로운 마일스톤 달성")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(milestones, id: \.self) { milestone in
                        milestoneBadge(milestone)
                    }
                }
            }
        }
    }

    /// 마일스톤 배지
    @ViewBuilder
    private func milestoneBadge(_ milestone: Milestone) -> some View {
        Text(milestone.displayName)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(milestoneColor.gradient)
            )
    }

    /// 버튼 섹션
    @ViewBuilder
    private var buttonSection: some View {
        Button {
            dismiss()
        } label: {
            Text("확인")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(milestoneColor.gradient)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    /// 축하 시작 (애니메이션 + 햅틱)
    /// 📚 학습 포인트: Coordinated Animations and Haptics
    /// 여러 애니메이션과 햅틱 피드백을 조율하여 몰입감 향상
    private func startCelebration() {
        // 햅틱 피드백
        triggerHapticFeedback()

        // 카드 등장 애니메이션
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }

        // 색종이 시작 (약간 지연)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showConfetti = true
        }
    }

    /// 닫기
    private func dismiss() {
        // 카드 사라지는 애니메이션
        withAnimation(.easeOut(duration: 0.2)) {
            cardScale = 0.9
            cardOpacity = 0.0
        }

        // 색종이 중지
        showConfetti = false

        // 콜백 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    /// 햅틱 피드백
    /// 📚 학습 포인트: Haptic Feedback by Milestone
    /// 마일스톤 중요도에 따라 다른 강도의 햅틱 제공
    private func triggerHapticFeedback() {
        #if os(iOS)
        switch primaryMilestone {
        case .quarter:
            // 가벼운 피드백
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

        case .half:
            // 중간 피드백
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.notificationOccurred(.success)
            }

        case .threeQuarters:
            // 강한 피드백
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred()
            }

        case .complete:
            // 매우 강한 피드백 (트리플)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.notificationOccurred(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                generator.notificationOccurred(.success)
            }
        }
        #endif
    }
}

// MARK: - Convenience Initializers

extension MilestoneCelebrationView {
    /// 단일 마일스톤 축하 뷰 생성
    ///
    /// - Parameters:
    ///   - milestone: 달성한 마일스톤
    ///   - onDismiss: 닫기 콜백
    init(milestone: Milestone, onDismiss: @escaping () -> Void) {
        self.init(milestones: [milestone], onDismiss: onDismiss)
    }
}

// MARK: - Preview

#Preview("25% 달성") {
    MilestoneCelebrationView(
        milestone: .quarter,
        onDismiss: {}
    )
}

#Preview("50% 달성") {
    MilestoneCelebrationView(
        milestone: .half,
        onDismiss: {}
    )
}

#Preview("75% 달성") {
    MilestoneCelebrationView(
        milestone: .threeQuarters,
        onDismiss: {}
    )
}

#Preview("100% 목표 달성") {
    MilestoneCelebrationView(
        milestone: .complete,
        onDismiss: {}
    )
}

#Preview("여러 마일스톤 동시 달성") {
    MilestoneCelebrationView(
        milestones: [.half, .threeQuarters],
        onDismiss: {}
    )
}

#Preview("다크 모드 - 목표 달성") {
    MilestoneCelebrationView(
        milestone: .complete,
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
