//
//  SleepRecordRow.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: List Row Component Pattern
// 수면 기록을 리스트에 표시하기 위한 재사용 가능한 Row 컴포넌트
// 💡 Java 비교: Android의 RecyclerView Item Layout/Compose ListItem과 유사

import SwiftUI

// MARK: - SleepRecordRow

/// 수면 기록을 리스트에 표시하기 위한 Row 컴포넌트
/// 📚 학습 포인트: Reusable List Row
/// - 날짜, 수면 시간, 수면 상태를 한 줄에 표시
/// - SleepStatusBadge를 사용하여 상태 시각화
/// - List, ForEach 등과 함께 사용
/// 💡 Java 비교: RecyclerView ViewHolder 패턴과 유사
struct SleepRecordRow: View {

    // MARK: - Properties

    /// 표시할 수면 기록
    /// 📚 학습 포인트: Domain Model as Input
    /// - 도메인 엔티티를 직접 받아서 표시
    /// - View는 데이터 변환 없이 표시만 담당
    let record: SleepRecord

    /// Row 스타일
    /// 📚 학습 포인트: Style Options
    /// - default: 기본 스타일 (List에서 사용)
    /// - compact: 작은 공간에 적합
    /// - detailed: 더 많은 정보 표시
    var style: RowStyle = .default

    /// 날짜 표시 형식
    /// 📚 학습 포인트: Date Format Options
    /// - short: 간략한 형식 (1/14)
    /// - medium: 중간 형식 (1월 14일)
    /// - long: 긴 형식 (2026년 1월 14일)
    var dateFormat: DateFormatter.Style = .medium

    // MARK: - Row Style Enum

    /// Row 스타일 정의
    /// 📚 학습 포인트: Nested Enum for Style Options
    /// - 컴포넌트 내부에 스타일 옵션 정의
    /// - 외부에서 간단하게 스타일 선택 가능
    enum RowStyle {
        case `default`  // 기본 스타일
        case compact    // 작은 크기
        case detailed   // 상세 정보 포함

        /// 수직 간격
        var spacing: CGFloat {
            switch self {
            case .default: return 4
            case .compact: return 2
            case .detailed: return 6
            }
        }

        /// 폰트 크기 (날짜)
        var dateFont: Font {
            switch self {
            case .default: return .subheadline
            case .compact: return .caption
            case .detailed: return .headline
            }
        }

        /// 폰트 크기 (수면 시간)
        var durationFont: Font {
            switch self {
            case .default: return .caption
            case .compact: return .caption2
            case .detailed: return .subheadline
            }
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 날짜 및 수면 시간 정보
            VStack(alignment: .leading, spacing: style.spacing) {
                // 날짜
                Text(formatDate(record.date))
                    .font(style.dateFont)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                // 수면 시간
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(style.durationFont)
                        .foregroundStyle(.secondary)

                    Text(formatDuration(record.duration))
                        .font(style.durationFont)
                        .foregroundStyle(.secondary)
                }

                // 상세 모드에서는 생성일시 표시
                if style == .detailed {
                    Text("기록: \(formatDateTime(record.createdAt))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // 수면 상태 뱃지
            sleepStatusBadge
        }
        .padding(.vertical, style == .compact ? 4 : 8)
    }

    // MARK: - Subviews

    /// 수면 상태 뱃지
    /// 📚 학습 포인트: Badge Display
    /// - 스타일에 따라 뱃지 크기 조정
    private var sleepStatusBadge: some View {
        Group {
            switch style {
            case .compact:
                SleepStatusBadge(compact: record.status)
            case .default:
                SleepStatusBadge(status: record.status)
            case .detailed:
                SleepStatusBadge(large: record.status)
            }
        }
    }

    // MARK: - Helper Methods

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    /// - 수면 기준일을 사용자에게 보기 좋게 표시
    ///
    /// - Parameter date: 수면 기준일
    /// - Returns: 포맷된 문자열
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateFormat
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 날짜와 시간 포맷팅
    /// 📚 학습 포인트: DateTime Formatting
    /// - 생성일시 등을 표시할 때 사용
    ///
    /// - Parameter date: 날짜와 시간
    /// - Returns: 포맷된 문자열
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 수면 시간 포맷팅
    /// 📚 학습 포인트: Duration Formatting
    /// - 분 단위를 시간:분 형식으로 변환
    ///
    /// - Parameter minutes: 수면 시간 (분)
    /// - Returns: 포맷된 문자열 (예: "7시간 30분")
    private func formatDuration(_ minutes: Int32) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if mins == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(mins)분"
        }
    }
}

// MARK: - Convenience Initializers

extension SleepRecordRow {
    /// 📚 학습 포인트: Convenience Initializer - Compact Style
    /// - 작은 공간에 적합한 간단한 Row
    ///
    /// - Parameters:
    ///   - record: 수면 기록
    ///   - dateFormat: 날짜 표시 형식 (기본값: .short)
    /// - Returns: 컴팩트 스타일의 SleepRecordRow
    init(compact record: SleepRecord, dateFormat: DateFormatter.Style = .short) {
        self.record = record
        self.style = .compact
        self.dateFormat = dateFormat
    }

    /// 📚 학습 포인트: Convenience Initializer - Detailed Style
    /// - 더 많은 정보를 표시하는 상세 Row
    ///
    /// - Parameters:
    ///   - record: 수면 기록
    ///   - dateFormat: 날짜 표시 형식 (기본값: .long)
    /// - Returns: 상세 스타일의 SleepRecordRow
    init(detailed record: SleepRecord, dateFormat: DateFormatter.Style = .long) {
        self.record = record
        self.style = .detailed
        self.dateFormat = dateFormat
    }
}

// MARK: - Preview

#Preview("모든 수면 상태 - 기본 스타일") {
    List {
        Section("최근 수면 기록") {
            ForEach(SleepStatus.allCases) { status in
                SleepRecordRow(record: SleepRecord.sampleRecord(status: status))
            }
        }
    }
}

#Preview("모든 수면 상태 - 컴팩트 스타일") {
    List {
        Section("수면 기록") {
            ForEach(SleepStatus.allCases) { status in
                SleepRecordRow(compact: SleepRecord.sampleRecord(status: status))
            }
        }
    }
}

#Preview("모든 수면 상태 - 상세 스타일") {
    List {
        Section("수면 기록 상세") {
            ForEach(SleepStatus.allCases) { status in
                SleepRecordRow(detailed: SleepRecord.sampleRecord(status: status))
            }
        }
    }
}

#Preview("다양한 날짜 형식") {
    List {
        Section("Short 형식") {
            SleepRecordRow(record: SleepRecord.sampleRecord(), dateFormat: .short)
        }

        Section("Medium 형식 (기본값)") {
            SleepRecordRow(record: SleepRecord.sampleRecord(), dateFormat: .medium)
        }

        Section("Long 형식") {
            SleepRecordRow(record: SleepRecord.sampleRecord(), dateFormat: .long)
        }
    }
}

#Preview("실제 사용 예시") {
    NavigationStack {
        List {
            Section("이번 주 수면 기록") {
                ForEach(SleepRecord.sampleWeekRecords()) { record in
                    SleepRecordRow(record: record)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                print("Delete: \(record.id)")
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                print("Edit: \(record.id)")
                            } label: {
                                Label("편집", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .navigationTitle("수면 기록")
    }
}

#Preview("다크 모드") {
    List {
        Section("수면 기록") {
            ForEach(SleepStatus.allCases) { status in
                SleepRecordRow(record: SleepRecord.sampleRecord(status: status))
            }
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("빈 상태 및 로딩") {
    NavigationStack {
        List {
            Section("수면 기록") {
                if false {
                    ForEach(0..<3) { _ in
                        SleepRecordRow(record: SleepRecord.sampleRecord())
                            .redacted(reason: .placeholder)
                    }
                } else {
                    ContentUnavailableView(
                        "수면 기록이 없습니다",
                        systemImage: "moon.zzz",
                        description: Text("수면 시간을 입력하면\n여기에 표시됩니다.")
                    )
                }
            }
        }
        .navigationTitle("수면 기록")
    }
}

// MARK: - SleepRecord Preview Extensions

#if DEBUG
extension SleepRecord {
    /// 📚 학습 포인트: Preview Sample Data
    /// SwiftUI Preview를 위한 샘플 수면 기록
    ///
    /// - Parameter status: 수면 상태 (기본값: .good)
    /// - Returns: 샘플 수면 기록
    static func sampleRecord(status: SleepStatus = .good) -> SleepRecord {
        let duration: Int32 = {
            switch status {
            case .bad: return 300        // 5시간
            case .soso: return 360       // 6시간
            case .good: return 450       // 7시간 30분
            case .excellent: return 480  // 8시간
            case .oversleep: return 570  // 9시간 30분
            }
        }()

        let calendar = Calendar.current
        let today = Date()

        return SleepRecord(
            id: UUID(),
            userId: UUID(),
            date: today,
            duration: duration,
            status: status,
            createdAt: today,
            updatedAt: today
        )
    }

    /// 📚 학습 포인트: Sample Week Data
    /// 일주일치 샘플 수면 기록 생성
    ///
    /// - Returns: 7일간의 샘플 수면 기록 배열
    static func sampleWeekRecords() -> [SleepRecord] {
        let calendar = Calendar.current
        let today = Date()

        let statuses: [SleepStatus] = [.excellent, .good, .good, .soso, .good, .bad, .excellent]
        let durations: [Int32] = [480, 450, 420, 360, 450, 300, 510]

        return (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: -index, to: today)!

            return SleepRecord(
                id: UUID(),
                userId: UUID(),
                date: date,
                duration: durations[index],
                status: statuses[index],
                createdAt: date,
                updatedAt: date
            )
        }
    }
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: SleepRecordRow 사용법
///
/// 기본 사용 (List에서):
/// ```swift
/// struct SleepHistoryView: View {
///     let records: [SleepRecord]
///
///     var body: some View {
///         List {
///             ForEach(records) { record in
///                 SleepRecordRow(record: record)
///             }
///         }
///     }
/// }
/// ```
///
/// 컴팩트 스타일:
/// ```swift
/// List {
///     ForEach(records) { record in
///         SleepRecordRow(compact: record)
///     }
/// }
/// ```
///
/// 상세 스타일:
/// ```swift
/// NavigationLink {
///     SleepDetailView(record: record)
/// } label: {
///     SleepRecordRow(detailed: record)
/// }
/// ```
///
/// Swipe Actions와 함께 사용:
/// ```swift
/// List {
///     ForEach(records) { record in
///         SleepRecordRow(record: record)
///             .swipeActions(edge: .trailing) {
///                 Button(role: .destructive) {
///                     deleteRecord(record)
///                 } label: {
///                     Label("삭제", systemImage: "trash")
///                 }
///             }
///             .swipeActions(edge: .leading) {
///                 Button {
///                     editRecord(record)
///                 } label: {
///                     Label("편집", systemImage: "pencil")
///                 }
///                 .tint(.blue)
///             }
///     }
/// }
/// ```
///
/// 탭 액션과 함께 사용:
/// ```swift
/// List {
///     ForEach(records) { record in
///         SleepRecordRow(record: record)
///             .onTapGesture {
///                 selectedRecord = record
///             }
///     }
/// }
/// .sheet(item: $selectedRecord) { record in
///     SleepDetailView(record: record)
/// }
/// ```
///
/// 날짜 형식 커스터마이징:
/// ```swift
/// // 짧은 형식 (1/14)
/// SleepRecordRow(record: record, dateFormat: .short)
///
/// // 중간 형식 (1월 14일) - 기본값
/// SleepRecordRow(record: record, dateFormat: .medium)
///
/// // 긴 형식 (2026년 1월 14일)
/// SleepRecordRow(record: record, dateFormat: .long)
/// ```
///
/// 주요 기능:
/// - 날짜, 수면 시간, 수면 상태를 한 줄에 표시
/// - SleepStatusBadge를 사용하여 상태 시각화
/// - 3가지 스타일 옵션 (default, compact, detailed)
/// - 날짜 형식 커스터마이징 가능
/// - List, ForEach 등과 함께 사용
/// - Swipe Actions, Tap Gesture 등과 호환
///
/// 스타일 선택 가이드:
/// - .default: 일반적인 리스트 (권장)
/// - .compact: 많은 데이터를 표시해야 할 때
/// - .detailed: 상세 정보가 필요한 경우
///
/// 💡 Android 비교:
/// - Android: RecyclerView.ViewHolder with item layout
/// - SwiftUI: Reusable View component
/// - Android: Data binding in XML
/// - SwiftUI: Direct property access in View
/// - Android: ViewHolder pattern with findViewById
/// - SwiftUI: Declarative view composition
///
/// 자동 동작:
/// - SleepRecord가 Identifiable이므로 ForEach에서 자동으로 id 사용
/// - SleepStatus의 색상/아이콘이 자동으로 뱃지에 반영
/// - 라이트/다크 모드에 따라 색상 자동 조정
/// - Dynamic Type 지원 (폰트 크기 자동 조정)
///
/// 접근성:
/// - VoiceOver: 날짜, 수면 시간, 상태 자동 읽기
/// - Dynamic Type: 폰트 크기 자동 조정
/// - 충분한 터치 영역 (최소 44pt 높이)
/// - 색상 + 아이콘으로 이중 시각적 표시
///
/// 실무 팁:
/// - List에서 사용할 때는 기본 스타일 권장
/// - Swipe actions를 추가하여 편집/삭제 기능 제공
/// - onTapGesture로 상세 화면 연결
/// - NavigationLink로 감싸서 네비게이션 구현
/// - .searchable modifier와 함께 사용하여 검색 기능 추가
/// - Section으로 날짜별 그룹화하여 가독성 향상
///
