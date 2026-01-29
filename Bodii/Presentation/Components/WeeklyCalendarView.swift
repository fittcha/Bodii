//
//  WeeklyCalendarView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-28.
//

import SwiftUI

// MARK: - Weekly Calendar View

/// 주간 캘린더 뷰 - 각 날짜에 반반원으로 수면/식단 점수 표시
///
/// **구성**:
/// - 요일 (일~토)
/// - 날짜 숫자
/// - 반반원 (좌: 수면 점수, 우: 식단 점수)
///
/// **색상 체계**:
/// - 수면 (5단계): blue/green/yellow/red/orange
/// - 식단 (4단계): blue/green/yellow/red
struct WeeklyCalendarView: View {

    // MARK: - Properties

    /// 주간 데이터 (날짜별 점수)
    let weekData: [DayScore]

    /// 오늘 날짜
    let today: Date

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Text("이번 주")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(weekRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 캘린더 그리드
            HStack(spacing: 0) {
                ForEach(weekData) { day in
                    dayColumn(for: day)
                }
            }

            // 범례
            legendView
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// 날짜 열
    private func dayColumn(for day: DayScore) -> some View {
        let isToday = Calendar.current.isDate(day.date, inSameDayAs: today)

        return VStack(spacing: 6) {
            // 요일
            Text(day.weekdayShort)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isToday ? .primary : .secondary)

            // 날짜
            Text("\(day.dayNumber)")
                .font(.subheadline)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .primary : .secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isToday ? Color.blue.opacity(0.15) : Color.clear)
                )

            // 반반원
            HalfHalfCircle(
                leftColor: day.sleepColor,
                rightColor: day.dietColor,
                size: 14
            )
            .frame(height: 14)
        }
        .frame(maxWidth: .infinity)
    }

    /// 범례
    private var legendView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                Text("수면")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("식단")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    /// 주간 범위 텍스트
    private var weekRangeText: String {
        guard let firstDate = weekData.first?.date,
              let lastDate = weekData.last?.date else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "M.d"
        formatter.locale = Locale(identifier: "ko_KR")

        return "\(formatter.string(from: firstDate)) ~ \(formatter.string(from: lastDate))"
    }
}

// MARK: - Day Score Model

/// 하루 점수 데이터
struct DayScore: Identifiable {
    let id = UUID()
    let date: Date
    let sleepStatus: SleepStatus?
    let dietScore: DietScore?

    /// 요일 (짧은 형태)
    var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 날짜 숫자
    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    /// 수면 점수 색상
    var sleepColor: Color? {
        sleepStatus?.color
    }

    /// 식단 점수 색상
    var dietColor: Color? {
        dietScore?.color
    }
}

// MARK: - Preview Data

extension DayScore {
    /// 샘플 주간 데이터 생성
    static func sampleWeek() -> [DayScore] {
        let calendar = Calendar.current
        let today = Date()

        // 이번 주 일요일 찾기
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!

            // 오늘 이후는 데이터 없음
            let isFuture = date > today

            let sleepStatus: SleepStatus? = isFuture ? nil : SleepStatus.allCases.randomElement()
            let dietScore: DietScore? = isFuture ? nil : DietScore.allCases.randomElement()

            return DayScore(
                date: date,
                sleepStatus: sleepStatus,
                dietScore: dietScore
            )
        }
    }
}

// MARK: - Preview

#Preview("주간 캘린더") {
    WeeklyCalendarView(
        weekData: DayScore.sampleWeek(),
        today: Date()
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("다크 모드") {
    WeeklyCalendarView(
        weekData: DayScore.sampleWeek(),
        today: Date()
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
