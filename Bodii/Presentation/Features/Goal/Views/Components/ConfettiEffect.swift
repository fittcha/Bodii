//
//  ConfettiEffect.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-18.
//

// 📚 학습 포인트: Particle Animation Effect in SwiftUI
// SwiftUI의 Canvas와 TimelineView를 사용한 입자 애니메이션 시스템
// 💡 Java 비교: Android의 Custom View with Canvas Animation과 유사

import SwiftUI

// MARK: - Confetti Effect

/// 축하 색종이 효과 컴포넌트
///
/// 마일스톤 달성 시 화면에 떨어지는 색종이 애니메이션을 표시합니다.
///
/// **주요 기능:**
/// - 입자 기반 애니메이션 시스템
/// - 랜덤한 색상, 크기, 속도
/// - 중력 효과와 회전
/// - 자동 생명주기 관리
/// - 성능 최적화된 Canvas 렌더링
///
/// **애니메이션 파라미터:**
/// - 입자 개수: 마일스톤에 따라 변화 (25% → 30개, 100% → 100개)
/// - 낙하 속도: 100-300 pt/s
/// - 회전 속도: -180 ~ 180도/s
/// - 생명주기: 3-5초
///
/// - Example:
/// ```swift
/// ConfettiEffect(
///     intensity: .high,
///     isActive: $showConfetti
/// )
/// .frame(maxWidth: .infinity, maxHeight: .infinity)
/// .allowsHitTesting(false)
/// ```
struct ConfettiEffect: View {

    // MARK: - Properties

    /// 색종이 강도 레벨
    let intensity: ConfettiIntensity

    /// 애니메이션 활성화 여부
    @Binding var isActive: Bool

    /// 색종이 입자 상태
    @State private var particles: [ConfettiParticle] = []

    /// 애니메이션 시작 시간
    @State private var startTime: Date?

    // MARK: - Constants

    /// 색종이 색상 팔레트
    /// 📚 학습 포인트: Static Color Array
    /// 다양한 색상으로 축제 분위기 연출
    private let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange,
        .purple, .pink, .mint, .cyan, .indigo
    ]

    // MARK: - Body

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // 📚 학습 포인트: Canvas for Performance
                // SwiftUI의 Canvas는 고성능 2D 렌더링에 최적화
                // View 계층 없이 직접 그리기로 성능 향상

                // 애니메이션 진행 시간 계산
                guard let startTime = startTime else { return }
                let elapsed = timeline.date.timeIntervalSince(startTime)

                // 각 입자 렌더링
                for particle in particles {
                    let progress = elapsed - particle.birthTime

                    // 생명주기 종료된 입자는 스킵
                    if progress > particle.lifetime {
                        continue
                    }

                    // 입자 위치 계산 (중력 효과)
                    let position = calculatePosition(
                        particle: particle,
                        progress: progress,
                        canvasSize: size
                    )

                    // 화면 밖으로 벗어난 입자는 스킵
                    if position.y > size.height {
                        continue
                    }

                    // 입자 회전 계산
                    let rotation = Angle(degrees: particle.rotationSpeed * progress)

                    // 페이드 아웃 효과 (마지막 0.5초)
                    let fadeProgress = max(0, (particle.lifetime - progress) / 0.5)
                    let opacity = min(1.0, fadeProgress)

                    // 색종이 조각 그리기
                    var particleContext = context
                    particleContext.opacity = opacity
                    particleContext.translateBy(x: position.x, y: position.y)
                    particleContext.rotate(by: rotation)

                    let rect = CGRect(
                        x: -particle.size / 2,
                        y: -particle.size / 2,
                        width: particle.size,
                        height: particle.size * 1.5 // 직사각형 모양
                    )

                    particleContext.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
        .onAppear {
            if isActive {
                startAnimation()
            }
        }
    }

    // MARK: - Animation Control

    /// 애니메이션 시작
    private func startAnimation() {
        startTime = Date()
        particles = createParticles()

        // 애니메이션 종료 타이머 (최대 생명주기 + 여유)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            stopAnimation()
        }
    }

    /// 애니메이션 중지
    private func stopAnimation() {
        particles.removeAll()
        startTime = nil
        isActive = false
    }

    /// 입자 생성
    /// 📚 학습 포인트: Particle System Initialization
    /// 강도에 따라 입자 개수와 속도를 조정
    private func createParticles() -> [ConfettiParticle] {
        let count = intensity.particleCount
        var newParticles: [ConfettiParticle] = []

        for i in 0..<count {
            // 시간차를 두고 생성 (0 ~ 0.5초)
            let birthTime = Double(i) / Double(count) * 0.5

            let particle = ConfettiParticle(
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 8...14),
                position: CGPoint(
                    x: CGFloat.random(in: 0...1), // 0-1 비율, 나중에 실제 크기로 변환
                    y: -0.1 // 화면 위에서 시작
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -50...50),
                    dy: CGFloat.random(in: 100...300) // 아래로 떨어짐
                ),
                rotationSpeed: Double.random(in: -180...180),
                lifetime: Double.random(in: 3...5),
                birthTime: birthTime
            )

            newParticles.append(particle)
        }

        return newParticles
    }

    /// 입자 위치 계산 (물리 시뮬레이션)
    /// 📚 학습 포인트: Simple Physics Simulation
    /// 중력 효과와 초기 속도를 고려한 포물선 운동
    private func calculatePosition(
        particle: ConfettiParticle,
        progress: TimeInterval,
        canvasSize: CGSize
    ) -> CGPoint {
        // 초기 위치 (비율 → 실제 좌표)
        let startX = particle.position.x * canvasSize.width
        let startY = particle.position.y * canvasSize.height

        // 중력 가속도 (픽셀/초²)
        let gravity: CGFloat = 500

        // 물리 공식: position = initialPosition + velocity * time + 0.5 * acceleration * time²
        let x = startX + particle.velocity.dx * progress
        let y = startY + particle.velocity.dy * progress + 0.5 * gravity * progress * progress

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Supporting Types

/// 색종이 입자
/// 📚 학습 포인트: Particle Data Structure
/// 각 색종이 조각의 상태를 표현하는 데이터 모델
struct ConfettiParticle: Identifiable {
    let id = UUID()

    /// 색상
    let color: Color

    /// 크기 (포인트)
    let size: CGFloat

    /// 초기 위치 (0-1 비율)
    let position: CGPoint

    /// 속도 (포인트/초)
    let velocity: CGVector

    /// 회전 속도 (도/초)
    let rotationSpeed: Double

    /// 생명주기 (초)
    let lifetime: TimeInterval

    /// 생성 시간 (애니메이션 시작 후 경과 시간)
    let birthTime: TimeInterval
}

/// 색종이 강도
/// 📚 학습 포인트: Enum for Configuration Levels
/// 마일스톤에 따라 다른 강도의 색종이 효과 제공
public enum ConfettiIntensity {
    /// 낮음 (25% 마일스톤)
    case low

    /// 중간 (50% 마일스톤)
    case medium

    /// 높음 (75% 마일스톤)
    case high

    /// 매우 높음 (100% 목표 달성)
    case veryHigh

    /// 입자 개수
    var particleCount: Int {
        switch self {
        case .low: return 30
        case .medium: return 50
        case .high: return 70
        case .veryHigh: return 100
        }
    }

    /// 강도 이름 (디버깅용)
    var displayName: String {
        switch self {
        case .low: return "낮음"
        case .medium: return "중간"
        case .high: return "높음"
        case .veryHigh: return "매우 높음"
        }
    }
}

// MARK: - Milestone Extension

/// 마일스톤별 색종이 강도 매핑
/// 📚 학습 포인트: Domain Type Extension for Presentation
/// Domain 타입(Milestone)에 Presentation 로직 추가
extension Milestone {
    /// 마일스톤에 맞는 색종이 강도
    var confettiIntensity: ConfettiIntensity {
        switch self {
        case .quarter: return .low
        case .half: return .medium
        case .threeQuarters: return .high
        case .complete: return .veryHigh
        }
    }
}

// MARK: - Preview

#Preview("낮은 강도") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ConfettiEffect(
            intensity: .low,
            isActive: .constant(true)
        )
    }
}

#Preview("중간 강도") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ConfettiEffect(
            intensity: .medium,
            isActive: .constant(true)
        )
    }
}

#Preview("높은 강도") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ConfettiEffect(
            intensity: .high,
            isActive: .constant(true)
        )
    }
}

#Preview("매우 높은 강도 (목표 달성)") {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        ConfettiEffect(
            intensity: .veryHigh,
            isActive: .constant(true)
        )
    }
}
