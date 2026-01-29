//
//  BodyCompositionChartView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-28.
//

import SwiftUI
import Charts

// MARK: - Body Composition Chart View

/// 체성분 변화 그래프 뷰
///
/// **표시 항목**:
/// - 체중 (kg) - 파란색 선
/// - 체지방률 (%) - 주황색 선 (옵션)
///
/// **기간**: 최근 7일 또는 30일
struct BodyCompositionChartView: View {

    // MARK: - Properties

    /// 체성분 데이터
    let data: [BodyChartData]

    /// 표시 옵션
    var showBodyFat: Bool = true

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Text("체성분 변화")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // 범례
                HStack(spacing: 12) {
                    legendItem(color: .blue, label: "체중")
                    if showBodyFat {
                        legendItem(color: .orange, label: "체지방")
                    }
                }
            }

            // 차트
            if data.isEmpty {
                emptyStateView
            } else {
                chartView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// 차트 뷰
    private var chartView: some View {
        Chart {
            // 체중 라인
            ForEach(data) { item in
                LineMark(
                    x: .value("날짜", item.date, unit: .day),
                    y: .value("체중", item.weight)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                }
            }

            // 체지방 라인 (옵션)
            if showBodyFat {
                ForEach(data.filter { $0.bodyFat != nil }) { item in
                    LineMark(
                        x: .value("날짜", item.date, unit: .day),
                        y: .value("체지방", item.bodyFat ?? 0)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDate(date))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 150)
    }

    /// 빈 상태 뷰
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("데이터가 없습니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("체성분을 기록하면 변화를 확인할 수 있습니다")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    /// 범례 아이템
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 날짜 포맷
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Body Chart Data Model

/// 체성분 차트 데이터
struct BodyChartData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let bodyFat: Double?
    let muscleMass: Double?

    init(date: Date, weight: Double, bodyFat: Double? = nil, muscleMass: Double? = nil) {
        self.date = date
        self.weight = weight
        self.bodyFat = bodyFat
        self.muscleMass = muscleMass
    }
}

// MARK: - Preview Data

extension BodyChartData {
    /// 샘플 데이터 생성
    static func sampleData() -> [BodyChartData] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let weight = 70.0 + Double.random(in: -1.0...1.0)
            let bodyFat = 20.0 + Double.random(in: -0.5...0.5)

            return BodyChartData(
                date: date,
                weight: weight,
                bodyFat: bodyFat
            )
        }
    }
}

// MARK: - Preview

#Preview("체성분 그래프") {
    BodyCompositionChartView(data: BodyChartData.sampleData())
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("빈 상태") {
    BodyCompositionChartView(data: [])
        .padding()
        .background(Color(.systemGroupedBackground))
}

#Preview("다크 모드") {
    BodyCompositionChartView(data: BodyChartData.sampleData())
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.dark)
}
