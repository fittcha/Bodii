//
//  SleepDisplayCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-19.
//

// 📚 학습 포인트: Sleep Display Card
// 수면 기록을 표시하는 대시보드 카드 컴포넌트
// 💡 SleepRecord 데이터를 시각적으로 표현

import SwiftUI

/// 수면 표시 카드
///
/// 오늘의 수면 기록을 표시하는 카드입니다.
///
/// **표시 내용:**
/// - 수면 시간 (시간:분 형식)
/// - 수면 품질 상태
/// - 로딩 상태
/// - 데이터 없음 상태
///
/// - Example:
/// ```swift
/// SleepDisplayCard(
///     sleepRecord: todaysSleep,
///     isLoading: isSleepLoading,
///     onTap: { }
/// )
/// ```
struct SleepDisplayCard: View {

    // MARK: - Properties

    /// 수면 기록 (nil이면 데이터 없음)
    let sleepRecord: SleepRecord?

    /// 로딩 상태
    let isLoading: Bool

    /// 탭 핸들러
    var onTap: (() -> Void)?

    // MARK: - Computed Properties

    /// 수면 상태
    private var sleepStatus: SleepStatus? {
        guard let record = sleepRecord else { return nil }
        return SleepStatus(rawValue: record.status)
    }

    /// 수면 시간 포맷
    private var formattedDuration: String {
        guard let record = sleepRecord else { return "-- 시간 -- 분" }
        let hours = record.duration / 60
        let minutes = record.duration % 60
        return "\(hours)시간 \(minutes)분"
    }

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // 헤더
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.indigo)
                        .font(.title2)

                    Text("수면")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isLoading {
                    // 로딩 상태
                    HStack {
                        ProgressView()
                        Text("로딩 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let status = sleepStatus {
                    // 데이터 표시
                    HStack(spacing: 16) {
                        // 수면 시간
                        VStack(alignment: .leading, spacing: 4) {
                            Text("수면 시간")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formattedDuration)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }

                        Spacer()

                        // 수면 상태
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("상태")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: status.iconName)
                                    .foregroundColor(status.color)
                                Text(status.displayName)
                                    .fontWeight(.medium)
                                    .foregroundColor(status.color)
                            }
                        }
                    }
                } else {
                    // 데이터 없음 상태
                    HStack {
                        Image(systemName: "zzz")
                            .foregroundColor(.secondary)
                        Text("수면 기록이 없습니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
