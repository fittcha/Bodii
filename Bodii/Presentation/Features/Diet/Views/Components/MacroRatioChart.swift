//
//  MacroRatioChart.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Macro Ratio Chart Component
// 매크로 영양소 비율을 시각적으로 표시하는 원형 차트 컴포넌트
// 💡 탄수화물, 단백질, 지방의 비율을 색상으로 구분하여 표시

import SwiftUI

/// 매크로 영양소 비율 차트
///
/// 탄수화물, 단백질, 지방의 비율을 원형 차트로 시각화합니다.
///
/// - Note: 비율이 모두 nil인 경우 회색 원을 표시합니다.
/// - Note: 각 매크로는 고유한 색상으로 구분됩니다 (탄수화물: 파란색, 단백질: 주황색, 지방: 보라색).
///
/// - Example:
/// ```swift
/// MacroRatioChart(
///     carbsRatio: 50,
///     proteinRatio: 25,
///     fatRatio: 25,
///     size: 120
/// )
/// ```
struct MacroRatioChart: View {

    // MARK: - Properties

    /// 탄수화물 비율 (%)
    let carbsRatio: Decimal?

    /// 단백질 비율 (%)
    let proteinRatio: Decimal?

    /// 지방 비율 (%)
    let fatRatio: Decimal?

    /// 차트 크기
    let size: CGFloat

    // MARK: - Constants

    /// 탄수화물 색상
    private let carbsColor = Color.blue

    /// 단백질 색상
    private let proteinColor = Color.orange

    /// 지방 색상
    private let fatColor = Color.purple

    /// 빈 상태 색상
    private let emptyColor = Color(.systemGray4)

    // MARK: - Body

    var body: some View {
        ZStack {
            // 데이터가 없는 경우 회색 원 표시
            if carbsRatio == nil && proteinRatio == nil && fatRatio == nil {
                Circle()
                    .fill(emptyColor)
                    .frame(width: size, height: size)
            } else {
                // 매크로 비율 차트
                macroChart
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Subviews

    /// 매크로 차트
    ///
    /// 각 매크로 영양소의 비율을 원형 차트로 표시합니다.
    private var macroChart: some View {
        ZStack {
            // 탄수화물 슬라이스
            if let carbs = carbsRatio, carbs > 0 {
                PieSlice(
                    startAngle: .degrees(0),
                    endAngle: .degrees(Double(truncating: carbs as NSNumber) * 3.6)
                )
                .fill(carbsColor)
            }

            // 단백질 슬라이스
            if let carbs = carbsRatio,
               let protein = proteinRatio,
               protein > 0 {
                let startAngle = Double(truncating: carbs as NSNumber) * 3.6
                PieSlice(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(startAngle + Double(truncating: protein as NSNumber) * 3.6)
                )
                .fill(proteinColor)
            }

            // 지방 슬라이스
            if let carbs = carbsRatio,
               let protein = proteinRatio,
               let fat = fatRatio,
               fat > 0 {
                let startAngle = Double(truncating: carbs as NSNumber) * 3.6 + Double(truncating: protein as NSNumber) * 3.6
                PieSlice(
                    startAngle: .degrees(startAngle),
                    endAngle: .degrees(startAngle + Double(truncating: fat as NSNumber) * 3.6)
                )
                .fill(fatColor)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Pie Slice Shape

/// 원형 차트의 조각 모양
///
/// 시작 각도와 종료 각도 사이의 부채꼴 모양을 그립니다.
///
/// - Note: 각도는 12시 방향을 기준으로 시계 방향으로 증가합니다.
///
/// - Example:
/// ```swift
/// PieSlice(startAngle: .degrees(0), endAngle: .degrees(90))
///     .fill(Color.blue)
/// ```
private struct PieSlice: Shape {

    // MARK: - Properties

    /// 시작 각도
    let startAngle: Angle

    /// 종료 각도
    let endAngle: Angle

    // MARK: - Shape Protocol

    /// 경로 생성
    ///
    /// 주어진 사각형 내에서 부채꼴 모양의 경로를 생성합니다.
    ///
    /// - Parameter rect: 그려질 사각형 영역
    /// - Returns: 부채꼴 모양의 경로
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // 중심에서 시작
        path.move(to: center)

        // 시작 각도 위치로 이동
        path.addLine(to: CGPoint(
            x: center.x + radius * CGFloat(cos(startAngle.radians - .pi / 2)),
            y: center.y + radius * CGFloat(sin(startAngle.radians - .pi / 2))
        ))

        // 호 그리기 (시계 방향)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle - .degrees(90),
            endAngle: endAngle - .degrees(90),
            clockwise: false
        )

        // 중심으로 돌아오기
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // 균형 잡힌 식단 예시
        VStack(spacing: 8) {
            Text("균형 잡힌 식단")
                .font(.headline)
            MacroRatioChart(
                carbsRatio: 50,
                proteinRatio: 25,
                fatRatio: 25,
                size: 120
            )
            HStack(spacing: 16) {
                Label("탄수화물 50%", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Label("단백질 25%", systemImage: "circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Label("지방 25%", systemImage: "circle.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
        }

        // 고탄수 식단 예시
        VStack(spacing: 8) {
            Text("고탄수 식단")
                .font(.headline)
            MacroRatioChart(
                carbsRatio: 70,
                proteinRatio: 15,
                fatRatio: 15,
                size: 120
            )
            HStack(spacing: 16) {
                Label("탄수화물 70%", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Label("단백질 15%", systemImage: "circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Label("지방 15%", systemImage: "circle.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
        }

        // 고단백 식단 예시
        VStack(spacing: 8) {
            Text("고단백 식단")
                .font(.headline)
            MacroRatioChart(
                carbsRatio: 30,
                proteinRatio: 40,
                fatRatio: 30,
                size: 120
            )
            HStack(spacing: 16) {
                Label("탄수화물 30%", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Label("단백질 40%", systemImage: "circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Label("지방 30%", systemImage: "circle.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
        }

        // 빈 상태 예시
        VStack(spacing: 8) {
            Text("식단 없음")
                .font(.headline)
            MacroRatioChart(
                carbsRatio: nil,
                proteinRatio: nil,
                fatRatio: nil,
                size: 120
            )
            Text("아직 식단이 기록되지 않았습니다")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
}
