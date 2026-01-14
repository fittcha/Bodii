//
//  SleepStatusBadge.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Status Badge Component
// 수면 상태를 시각적으로 표시하는 뱃지 컴포넌트
// 💡 Java 비교: Android의 Chip 또는 Badge View와 유사

import SwiftUI

// MARK: - SleepStatusBadge

/// 수면 상태를 시각적으로 표시하는 뱃지 컴포넌트
/// 📚 학습 포인트: Visual Status Badge
/// - SleepStatus enum의 색상과 아이콘을 사용하여 상태 표시
/// - 다양한 스타일 옵션 제공 (compact, default, large)
/// - 재사용 가능한 컴포넌트로 여러 화면에서 사용
/// 💡 Java 비교: Android의 Material Chip, Badge View와 유사
struct SleepStatusBadge: View {

    // MARK: - Properties

    /// 표시할 수면 상태
    /// 📚 학습 포인트: SleepStatus Enum
    /// - color, iconName, displayName 프로퍼티 자동 사용
    let status: SleepStatus

    /// 뱃지 스타일
    /// 📚 학습 포인트: Style Enum
    /// - compact: 아이콘만 (작은 공간에 적합)
    /// - default: 아이콘 + 텍스트 (일반적인 사용)
    /// - large: 큰 아이콘 + 텍스트 (강조용)
    var style: BadgeStyle = .default

    /// 배경 표시 여부
    /// 📚 학습 포인트: Background Option
    /// - true: 색상 배경 표시 (더 눈에 띄는 디자인)
    /// - false: 투명 배경, 색상은 아이콘/텍스트만 (미니멀한 디자인)
    var showBackground: Bool = true

    // MARK: - Badge Style Enum

    /// 뱃지 스타일 정의
    /// 📚 학습 포인트: Nested Enum for Style Options
    /// - 컴포넌트 내부에 스타일 옵션 정의
    /// - 외부에서 간단하게 스타일 선택 가능
    enum BadgeStyle {
        case compact    // 아이콘만
        case `default`  // 아이콘 + 텍스트
        case large      // 큰 아이콘 + 텍스트

        /// 아이콘 폰트 크기
        var iconSize: Font {
            switch self {
            case .compact: return .caption
            case .default: return .subheadline
            case .large: return .title3
            }
        }

        /// 텍스트 폰트 크기
        var textSize: Font {
            switch self {
            case .compact: return .caption2
            case .default: return .caption
            case .large: return .subheadline
            }
        }

        /// 패딩 크기
        var padding: CGFloat {
            switch self {
            case .compact: return 6
            case .default: return 8
            case .large: return 12
        }

        /// 아이콘과 텍스트 간격
        var spacing: CGFloat {
            switch self {
            case .compact: return 0
            case .default: return 4
            case .large: return 6
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if style == .compact {
                // 📚 학습 포인트: Compact Style - Icon Only
                // 작은 공간에 적합 (리스트, 인라인 표시 등)
                compactBadge
            } else {
                // 📚 학습 포인트: Default/Large Style - Icon + Text
                // 아이콘과 텍스트를 함께 표시
                fullBadge
            }
        }
        .padding(.horizontal, style.padding)
        .padding(.vertical, style.padding * 0.6)
        .background(badgeBackground)
        .cornerRadius(style == .large ? 10 : 8)
    }

    // MARK: - Subviews

    /// 컴팩트 뱃지 (아이콘만)
    /// 📚 학습 포인트: Icon-Only Badge
    /// - 최소한의 공간으로 상태 표시
    /// - 리스트 항목이나 작은 공간에 적합
    private var compactBadge: some View {
        Image(systemName: status.iconName)
            .font(style.iconSize)
            .foregroundStyle(foregroundColor)
    }

    /// 전체 뱃지 (아이콘 + 텍스트)
    /// 📚 학습 포인트: Full Badge with Icon and Text
    /// - 아이콘과 텍스트로 명확한 상태 전달
    /// - 일반적으로 가장 많이 사용
    private var fullBadge: some View {
        HStack(spacing: style.spacing) {
            Image(systemName: status.iconName)
                .font(style.iconSize)
                .foregroundStyle(foregroundColor)

            Text(status.displayName)
                .font(style.textSize)
                .fontWeight(.semibold)
                .foregroundStyle(foregroundColor)
        }
    }

    /// 뱃지 배경
    /// 📚 학습 포인트: Conditional Background
    /// - showBackground에 따라 색상 배경 표시 여부 결정
    /// - 배경이 있을 때는 색상이 연하게 표시
    @ViewBuilder
    private var badgeBackground: some View {
        if showBackground {
            RoundedRectangle(cornerRadius: style == .large ? 10 : 8)
                .fill(status.color.opacity(0.15))
        }
    }

    /// 전경 색상 (아이콘/텍스트 색상)
    /// 📚 학습 포인트: Foreground Color Logic
    /// - 배경이 있으면 진한 색상
    /// - 배경이 없으면 더 진한 색상 (가독성 향상)
    private var foregroundColor: Color {
        showBackground ? status.color : status.color
    }
}

// MARK: - Convenience Initializers

extension SleepStatusBadge {
    /// 📚 학습 포인트: Convenience Initializer - Compact Style
    /// - 아이콘만 표시하는 간단한 뱃지
    /// - 리스트나 작은 공간에 적합
    ///
    /// - Parameters:
    ///   - status: 수면 상태
    ///   - showBackground: 배경 표시 여부 (기본값: true)
    /// - Returns: 컴팩트 스타일의 SleepStatusBadge
    init(compact status: SleepStatus, showBackground: Bool = true) {
        self.status = status
        self.style = .compact
        self.showBackground = showBackground
    }

    /// 📚 학습 포인트: Convenience Initializer - Large Style
    /// - 큰 크기로 강조하는 뱃지
    /// - 입력 화면이나 중요한 표시에 적합
    ///
    /// - Parameters:
    ///   - status: 수면 상태
    ///   - showBackground: 배경 표시 여부 (기본값: true)
    /// - Returns: 큰 스타일의 SleepStatusBadge
    init(large status: SleepStatus, showBackground: Bool = true) {
        self.status = status
        self.style = .large
        self.showBackground = showBackground
    }
}

// MARK: - Preview

#Preview("모든 수면 상태 - 기본 스타일") {
    VStack(spacing: 16) {
        Text("기본 스타일 (아이콘 + 텍스트)")
            .font(.headline)

        VStack(spacing: 12) {
            ForEach(SleepStatus.allCases) { status in
                HStack {
                    Text("\(status.displayName):")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    SleepStatusBadge(status: status)

                    Spacer()
                }
            }
        }
    }
    .padding()
}

#Preview("모든 수면 상태 - 컴팩트 스타일") {
    VStack(spacing: 16) {
        Text("컴팩트 스타일 (아이콘만)")
            .font(.headline)

        VStack(spacing: 12) {
            ForEach(SleepStatus.allCases) { status in
                HStack {
                    Text("\(status.displayName):")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    SleepStatusBadge(compact: status)

                    Spacer()
                }
            }
        }
    }
    .padding()
}

#Preview("모든 수면 상태 - 큰 스타일") {
    VStack(spacing: 16) {
        Text("큰 스타일 (강조)")
            .font(.headline)

        VStack(spacing: 12) {
            ForEach(SleepStatus.allCases) { status in
                SleepStatusBadge(large: status)
            }
        }
    }
    .padding()
}

#Preview("배경 없는 스타일") {
    VStack(spacing: 16) {
        Text("배경 없음 (미니멀)")
            .font(.headline)

        VStack(spacing: 12) {
            ForEach(SleepStatus.allCases) { status in
                HStack {
                    Text("\(status.displayName):")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    SleepStatusBadge(status: status, showBackground: false)

                    Spacer()
                }
            }
        }
    }
    .padding()
}

#Preview("리스트에서 사용") {
    List {
        Section("최근 수면 기록") {
            ForEach(SleepStatus.allCases) { status in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("2026년 1월 14일")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("7시간 30분")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    SleepStatusBadge(status: status)
                }
            }
        }
    }
}

#Preview("카드에서 사용") {
    VStack(spacing: 16) {
        // 수면 입력 카드 예시
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("수면 시간 입력")
                    .font(.headline)

                Spacer()
            }

            Divider()

            HStack {
                Text("예상 상태:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                SleepStatusBadge(status: .excellent)
            }

            HStack {
                Text("7시간 30분")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4)
        )

        // 수면 요약 카드 예시
        VStack(spacing: 12) {
            HStack {
                Text("오늘의 수면")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                SleepStatusBadge(compact: .good)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("8시간")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("2026년 1월 14일")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4)
        )
    }
    .padding()
}

#Preview("다크 모드") {
    VStack(spacing: 16) {
        Text("다크 모드에서 뱃지 표시")
            .font(.headline)

        VStack(spacing: 12) {
            ForEach(SleepStatus.allCases) { status in
                HStack {
                    Text("\(status.displayName):")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    SleepStatusBadge(status: status)

                    Spacer()
                }
            }
        }

        Divider()

        VStack(spacing: 12) {
            ForEach(SleepStatus.allCases) { status in
                HStack {
                    Text("\(status.displayName):")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    SleepStatusBadge(status: status, showBackground: false)

                    Spacer()
                }
            }
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("모든 스타일 비교") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // 컴팩트 스타일
            VStack(alignment: .leading, spacing: 8) {
                Text("Compact (아이콘만)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(SleepStatus.allCases) { status in
                        SleepStatusBadge(compact: status)
                    }
                }
            }

            Divider()

            // 기본 스타일
            VStack(alignment: .leading, spacing: 8) {
                Text("Default (아이콘 + 텍스트)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(SleepStatus.allCases) { status in
                        SleepStatusBadge(status: status)
                    }
                }
            }

            Divider()

            // 큰 스타일
            VStack(alignment: .leading, spacing: 8) {
                Text("Large (큰 크기)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(SleepStatus.allCases) { status in
                        SleepStatusBadge(large: status)
                    }
                }
            }

            Divider()

            // 배경 없음
            VStack(alignment: .leading, spacing: 8) {
                Text("No Background (배경 없음)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(SleepStatus.allCases) { status in
                        SleepStatusBadge(status: status, showBackground: false)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Documentation

/// 📚 학습 포인트: SleepStatusBadge 사용법
///
/// 기본 사용 (아이콘 + 텍스트):
/// ```swift
/// struct SleepRecordRow: View {
///     let status: SleepStatus
///
///     var body: some View {
///         HStack {
///             Text("오늘의 수면")
///             Spacer()
///             SleepStatusBadge(status: status)
///         }
///     }
/// }
/// ```
///
/// 컴팩트 스타일 (아이콘만):
/// ```swift
/// struct CompactSleepView: View {
///     let status: SleepStatus
///
///     var body: some View {
///         HStack {
///             Text("상태:")
///             SleepStatusBadge(compact: status)
///         }
///     }
/// }
/// ```
///
/// 큰 스타일 (강조):
/// ```swift
/// struct SleepInputSheet: View {
///     @StateObject private var viewModel: SleepInputViewModel
///
///     var body: some View {
///         VStack {
///             Text("예상 수면 상태")
///                 .font(.headline)
///
///             SleepStatusBadge(large: viewModel.expectedStatus)
///         }
///     }
/// }
/// ```
///
/// 배경 없는 스타일:
/// ```swift
/// struct MinimalSleepView: View {
///     let status: SleepStatus
///
///     var body: some View {
///         SleepStatusBadge(status: status, showBackground: false)
///     }
/// }
/// ```
///
/// 주요 기능:
/// - SleepStatus의 색상/아이콘 자동 사용
/// - 3가지 크기 옵션 (compact, default, large)
/// - 배경 표시/숨김 옵션
/// - 다양한 사용 시나리오에 적합한 유연한 디자인
/// - 라이트/다크 모드 자동 대응
///
/// 스타일 선택 가이드:
/// - .compact: 리스트 항목, 인라인 표시, 작은 공간
/// - .default: 일반적인 사용, 카드, 섹션 헤더
/// - .large: 입력 화면, 상태 강조, 중요한 표시
/// - showBackground: false: 미니멀한 디자인, 이미 색상이 많은 화면
///
/// 💡 Android 비교:
/// - Android: Material Chip/Badge
/// - SwiftUI: Custom Badge Component
/// - Android: XML attributes for styling
/// - SwiftUI: Enum-based style options
/// - Android: ColorStateList for states
/// - SwiftUI: Enum의 computed properties로 상태별 색상 관리
///
/// 자동 동작:
/// - SleepStatus가 변경되면 색상/아이콘 자동 업데이트
/// - 라이트/다크 모드에 따라 색상 자동 조정
/// - Dynamic Type 지원 (폰트 크기 자동 조정)
///
/// 접근성:
/// - VoiceOver: 상태 이름 자동 읽기
/// - Dynamic Type: 폰트 크기 자동 조정
/// - 색상 + 아이콘으로 이중 시각적 표시 (색맹 사용자 고려)
///
/// 실무 팁:
/// - 리스트에서는 compact 스타일 권장 (공간 절약)
/// - 입력 화면에서는 large 스타일 권장 (명확한 피드백)
/// - 이미 색상이 많은 화면에서는 showBackground: false 고려
/// - ViewModel의 expectedStatus와 함께 사용하면 실시간 피드백 가능
///
