//
//  SleepDisplayCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Reusable Sleep Dashboard Card Component
// SwiftUI의 재사용 가능한 수면 대시보드 카드 컴포넌트
// 💡 Java 비교: Android의 Custom View/Compose Component와 유사

import SwiftUI

// MARK: - SleepDisplayCard

/// 수면 기록을 표시하는 대시보드 카드 컴포넌트
/// 📚 학습 포인트: Dashboard Display Component
/// - 읽기 전용 정보 표시 (입력 없음)
/// - 수면 시간과 품질 상태를 시각적으로 표현
/// - 컴팩트한 디자인으로 대시보드에 적합
/// 💡 Java 비교: React Component, Android Compose Component와 유사
struct SleepDisplayCard: View {

    // MARK: - Properties

    /// 수면 시간 (분 단위)
    /// 📚 학습 포인트: Optional Value
    /// - nil이면 데이터 없음 상태 표시
    let durationMinutes: Int32?

    /// 수면 상태
    let status: SleepStatus?

    /// 수면 기록 날짜
    /// 📚 학습 포인트: Date Display
    /// - 어느 날의 수면 기록인지 표시
    let date: Date?

    /// 로딩 상태
    /// 📚 학습 포인트: Loading State
    /// - 데이터 로드 중 로딩 인디케이터 표시
    let isLoading: Bool

    /// 탭 액션 콜백
    /// 📚 학습 포인트: Callback Pattern
    /// - 카드 탭 시 수면 탭으로 이동 등의 액션
    /// 💡 Java 비교: OnClickListener와 유사
    let onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // 카드 헤더
                cardHeader

                if isLoading {
                    // 로딩 상태
                    loadingView
                } else if let duration = durationMinutes, let status = status {
                    // 데이터가 있는 경우
                    VStack(alignment: .leading, spacing: 12) {
                        // 수면 시간 섹션
                        sleepDurationSection(duration: duration)

                        Divider()

                        // 수면 상태 섹션
                        sleepStatusSection(status: status)

                        // 날짜 표시 (있는 경우)
                        if let date = date {
                            Divider()
                            dateSection(date: date)
                        }
                    }
                } else {
                    // 데이터가 없는 경우
                    emptyStateView
                }
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Subviews

    /// 카드 헤더
    private var cardHeader: some View {
        HStack {
            // 📚 학습 포인트: SF Symbols
            // Apple이 제공하는 시스템 아이콘
            Image(systemName: "moon.zzz.fill")
                .font(.title2)
                .foregroundStyle(.purple)

            Text("수면 기록")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            // 화살표 아이콘 (탭 가능 표시)
            if onTap != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 수면 시간 섹션
    /// 📚 학습 포인트: Duration Display
    /// - 분 단위를 시간:분 형식으로 변환하여 표시
    ///
    /// - Parameter duration: 수면 시간 (분)
    /// - Returns: 수면 시간 표시 뷰
    private func sleepDurationSection(duration: Int32) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: "bed.double.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text("수면 시간")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(formatDuration(minutes: duration))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }

    /// 수면 상태 섹션
    /// 📚 학습 포인트: Status Badge Display
    /// - SleepStatusBadge 컴포넌트를 활용한 상태 표시
    ///
    /// - Parameter status: 수면 상태
    /// - Returns: 수면 상태 표시 뷰
    private func sleepStatusSection(status: SleepStatus) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text("수면 품질")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                SleepStatusBadge(status: status, style: .default, showBackground: true)
            }

            Spacer()
        }
    }

    /// 날짜 섹션
    /// 📚 학습 포인트: Date Display
    /// - 수면 기록의 날짜 표시
    ///
    /// - Parameter date: 날짜
    /// - Returns: 날짜 표시 뷰
    private func dateSection(date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(.gray)

            Text(formatDate(date))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    /// 로딩 뷰
    /// 📚 학습 포인트: Loading State UI
    private var loadingView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("수면 데이터 로드 중...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    /// 빈 상태 뷰
    /// 📚 학습 포인트: Empty State UI
    /// - 데이터가 없을 때 사용자에게 안내
    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "moon.stars")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)

                Text("수면 기록이 없습니다")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text("오늘의 수면 시간을 기록하면\n여기에 표시됩니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }

    /// 카드 배경
    /// 📚 학습 포인트: Adaptive Colors
    /// - 라이트/다크 모드에 자동 대응하는 색상
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
    }

    // MARK: - Helper Methods

    /// 수면 시간 포맷팅 (분 -> 시간:분)
    /// 📚 학습 포인트: Duration Formatting
    /// - 분 단위를 읽기 쉬운 형식으로 변환
    ///
    /// - Parameter minutes: 수면 시간 (분)
    /// - Returns: 포맷된 문자열 (예: "7시간 30분")
    private func formatDuration(minutes: Int32) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if mins == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(mins)분"
        }
    }

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "1월 14일")
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

// MARK: - Convenience Initializers

extension SleepDisplayCard {
    /// 📚 학습 포인트: Convenience Initializer with SleepRecord
    /// - SleepRecord로부터 직접 값을 가져오는 편의 생성자
    /// - View에서 쉽게 사용 가능
    ///
    /// - Parameters:
    ///   - sleepRecord: SleepRecord 인스턴스 (nil 가능)
    ///   - isLoading: 로딩 상태
    ///   - onTap: 탭 액션 콜백
    init(sleepRecord: SleepRecord?, isLoading: Bool = false, onTap: (() -> Void)? = nil) {
        self.durationMinutes = sleepRecord?.duration
        self.status = sleepRecord?.status
        self.date = sleepRecord?.date
        self.isLoading = isLoading
        self.onTap = onTap
    }

    /// 📚 학습 포인트: Convenience Initializer for Manual Values
    /// - 개별 값을 직접 전달하는 생성자
    /// - Preview나 테스트에서 유용
    ///
    /// - Parameters:
    ///   - durationMinutes: 수면 시간 (분)
    ///   - status: 수면 상태
    ///   - date: 날짜
    ///   - isLoading: 로딩 상태
    ///   - onTap: 탭 액션 콜백
    init(
        durationMinutes: Int32?,
        status: SleepStatus?,
        date: Date? = nil,
        isLoading: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.durationMinutes = durationMinutes
        self.status = status
        self.date = date
        self.isLoading = isLoading
        self.onTap = onTap
    }
}

// MARK: - Preview

#Preview("데이터 있음 - 좋음") {
    ScrollView {
        SleepDisplayCard(
            durationMinutes: 450,  // 7시간 30분
            status: .excellent,
            date: Date(),
            onTap: {
                print("Card tapped")
            }
        )
        .padding()
    }
}

#Preview("데이터 있음 - 보통") {
    ScrollView {
        SleepDisplayCard(
            durationMinutes: 360,  // 6시간
            status: .soso,
            date: Date()
        )
        .padding()
    }
}

#Preview("데이터 있음 - 나쁨") {
    ScrollView {
        SleepDisplayCard(
            durationMinutes: 300,  // 5시간
            status: .bad,
            date: Date()
        )
        .padding()
    }
}

#Preview("빈 상태") {
    ScrollView {
        SleepDisplayCard(
            durationMinutes: nil,
            status: nil
        )
        .padding()
    }
}

#Preview("로딩 상태") {
    ScrollView {
        SleepDisplayCard(
            durationMinutes: nil,
            status: nil,
            isLoading: true
        )
        .padding()
    }
}

#Preview("다크 모드 - 데이터 있음") {
    ScrollView {
        SleepDisplayCard(
            durationMinutes: 480,  // 8시간
            status: .excellent,
            date: Date()
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("다양한 수면 시간") {
    ScrollView {
        VStack(spacing: 16) {
            SleepDisplayCard(
                durationMinutes: 300,  // 5시간
                status: .bad,
                date: Date()
            )

            SleepDisplayCard(
                durationMinutes: 360,  // 6시간
                status: .soso,
                date: Date()
            )

            SleepDisplayCard(
                durationMinutes: 420,  // 7시간
                status: .good,
                date: Date()
            )

            SleepDisplayCard(
                durationMinutes: 480,  // 8시간
                status: .excellent,
                date: Date()
            )

            SleepDisplayCard(
                durationMinutes: 600,  // 10시간
                status: .oversleep,
                date: Date()
            )
        }
        .padding()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepDisplayCard 사용법
///
/// SleepRecord와 함께 사용 (권장):
/// ```swift
/// struct DashboardView: View {
///     @State private var todaysSleep: SleepRecord?
///     @State private var isLoading = false
///
///     var body: some View {
///         SleepDisplayCard(
///             sleepRecord: todaysSleep,
///             isLoading: isLoading,
///             onTap: {
///                 // 수면 탭으로 이동
///                 selectedTab = .sleep
///             }
///         )
///     }
/// }
/// ```
///
/// 개별 값으로 사용:
/// ```swift
/// struct MyView: View {
///     var body: some View {
///         SleepDisplayCard(
///             durationMinutes: 450,  // 7시간 30분
///             status: .excellent,
///             date: Date()
///         )
///     }
/// }
/// ```
///
/// 빈 상태 표시:
/// ```swift
/// SleepDisplayCard(
///     durationMinutes: nil,
///     status: nil
/// )
/// ```
///
/// 주요 기능:
/// - 수면 시간을 시간:분 형식으로 명확하게 표시
/// - SleepStatusBadge로 수면 품질 시각화
/// - 수면 기록 날짜 표시
/// - 빈 상태와 로딩 상태 지원
/// - 탭 가능하여 상세 페이지로 이동 가능
/// - 라이트/다크 모드 자동 대응
/// - 컴팩트한 디자인으로 대시보드에 적합
///
/// 💡 Android 비교:
/// - Android: CardView + Data Binding
/// - SwiftUI: Card component with @Binding
/// - Android: LiveData 관찰
/// - SwiftUI: @Published + ObservableObject
///
/// 실무 팁:
/// - 대시보드에서는 오늘의 수면만 표시 (최근 기록)
/// - 탭하면 전체 수면 히스토리로 이동
/// - 빈 상태에서는 수면 입력을 유도하는 메시지 표시
/// - 로딩 상태를 통해 사용자에게 데이터 로드 진행 상황 전달
///
