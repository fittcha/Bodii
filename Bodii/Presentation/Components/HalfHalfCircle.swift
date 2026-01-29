//
//  HalfHalfCircle.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-28.
//

import SwiftUI

// MARK: - Half-Half Circle Component

/// 반반원 컴포넌트 - 좌/우 반원에 다른 색상 표시
///
/// **용도**: 주간 캘린더에서 수면 점수와 식단 점수를 한 원에 표시
/// - 좌측 반원: 수면 점수 색상 (SleepStatus)
/// - 우측 반원: 식단 점수 색상 (DietScore)
/// - 데이터 없으면 해당 반원은 투명
///
/// - Example:
/// ```swift
/// HalfHalfCircle(
///     leftColor: SleepStatus.good.color,  // 녹색
///     rightColor: DietScore.great.color   // 녹색
/// )
/// ```
struct HalfHalfCircle: View {

    // MARK: - Properties

    /// 좌측 반원 색상 (수면 점수)
    /// nil이면 투명
    let leftColor: Color?

    /// 우측 반원 색상 (식단 점수)
    /// nil이면 투명
    let rightColor: Color?

    /// 원의 크기
    let size: CGFloat

    // MARK: - Initialization

    init(
        leftColor: Color? = nil,
        rightColor: Color? = nil,
        size: CGFloat = 16
    ) {
        self.leftColor = leftColor
        self.rightColor = rightColor
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 좌측 반원 (수면)
            if let leftColor = leftColor {
                HalfCircle(isLeft: true)
                    .fill(leftColor)
            }

            // 우측 반원 (식단)
            if let rightColor = rightColor {
                HalfCircle(isLeft: false)
                    .fill(rightColor)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Half Circle Shape

/// 반원 Shape
struct HalfCircle: Shape {

    /// true면 좌측 반원, false면 우측 반원
    let isLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        if isLeft {
            // 좌측 반원 (90도 ~ 270도)
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                clockwise: false
            )
            path.closeSubpath()
        } else {
            // 우측 반원 (-90도 ~ 90도)
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
            )
            path.closeSubpath()
        }

        return path
    }
}

// MARK: - Preview

#Preview("반반원 - 둘 다 있음") {
    VStack(spacing: 20) {
        HalfHalfCircle(
            leftColor: .blue,  // 수면 excellent
            rightColor: .green, // 식단 great
            size: 24
        )

        HalfHalfCircle(
            leftColor: .green,  // 수면 good
            rightColor: .yellow, // 식단 good
            size: 24
        )

        HalfHalfCircle(
            leftColor: .red,    // 수면 bad
            rightColor: .red,   // 식단 needsWork
            size: 24
        )
    }
    .padding()
}

#Preview("반반원 - 하나만 있음") {
    VStack(spacing: 20) {
        HalfHalfCircle(
            leftColor: .blue,
            rightColor: nil,
            size: 24
        )

        HalfHalfCircle(
            leftColor: nil,
            rightColor: .green,
            size: 24
        )
    }
    .padding()
}

#Preview("반반원 - 둘 다 없음") {
    HalfHalfCircle(
        leftColor: nil,
        rightColor: nil,
        size: 24
    )
    .padding()
}

#Preview("다양한 크기") {
    HStack(spacing: 16) {
        HalfHalfCircle(leftColor: .blue, rightColor: .green, size: 12)
        HalfHalfCircle(leftColor: .blue, rightColor: .green, size: 16)
        HalfHalfCircle(leftColor: .blue, rightColor: .green, size: 20)
        HalfHalfCircle(leftColor: .blue, rightColor: .green, size: 24)
    }
    .padding()
}
