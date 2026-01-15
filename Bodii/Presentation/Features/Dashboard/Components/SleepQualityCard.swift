//
//  SleepQualityCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-15.
//

// 📚 학습 포인트: Sleep Quality Card Component
// 전날 밤 수면 정보 카드 - 수면 시간, 품질 상태, 이모지 인디케이터
// 💡 DailyLog의 사전 계산된 sleepDuration, sleepStatus 값을 사용하여 빠른 렌더링 보장

import SwiftUI

/// 수면 품질 카드
///
/// 전날 밤 수면 정보를 표시하는 카드 컴포넌트입니다.
/// 수면 시간, 품질 상태, 이모지 인디케이터를 시각적으로 표현합니다.
///
/// **표시 내용:**
/// - 수면 시간 (시간:분 형식)
/// - 수면 품질 라벨 (나쁨/보통/좋음/매우 좋음/과다 수면)
/// - 상태별 이모지 인디케이터
///
/// **이모지 규칙:**
/// - 🔴 나쁨: 5시간 30분 미만
/// - 🟡 보통: 5시간 30분 ~ 6시간 30분
/// - 🟢 좋음: 6시간 30분 ~ 7시간 30분
/// - 🔵 매우 좋음: 7시간 30분 ~ 9시간
/// - 🟠 과다 수면: 9시간 초과
///
/// - Note: DailyLog의 사전 계산된 값을 사용하여 빠른 렌더링을 보장합니다.
///
/// - Example:
/// ```swift
/// SleepQualityCard(
///     sleepDuration: 420,
///     sleepStatus: .good
/// )
/// ```
struct SleepQualityCard: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props Pattern
    // View의 입력 데이터는 let으로 선언하여 불변성 보장
    // 💡 Java 비교: final 필드와 유사

    /// 수면 시간 (분 단위, nil이면 기록 없음)
    let sleepDuration: Int32?

    /// 수면 상태 (nil이면 기록 없음)
    let sleepStatus: SleepStatus?

    // MARK: - Computed Properties

    /// 데이터가 비어있는지 여부
    private var isEmpty: Bool {
        sleepDuration == nil || sleepStatus == nil
    }

    /// 수면 시간을 "X시간 Y분" 형식으로 포맷팅
    private var formattedSleepTime: String {
        guard let duration = sleepDuration else { return "기록 없음" }
        return formatMinutes(duration)
    }

    /// 수면 품질 라벨 (예: "좋음", "매우 좋음")
    private var qualityLabel: String {
        sleepStatus?.displayName ?? "기록 없음"
    }

    /// 수면 상태별 이모지
    private var statusEmoji: String {
        guard let status = sleepStatus else { return "😴" }

        switch status {
        case .bad:
            return "🔴"
        case .soso:
            return "🟡"
        case .good:
            return "🟢"
        case .excellent:
            return "🔵"
        case .oversleep:
            return "🟠"
        }
    }

    /// 수면 상태별 색상
    private var statusColor: Color {
        guard let status = sleepStatus else { return .gray }

        switch status {
        case .bad:
            return .red
        case .soso:
            return .yellow
        case .good:
            return .green
        case .excellent:
            return .blue
        case .oversleep:
            return .orange
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 제목 섹션
            titleSection

            // 📚 학습 포인트: VStack Layout with Large Icon
            // 중앙에 큰 이모지와 수면 시간을 배치하여 시각적 강조
            // 💡 Java 비교: Column with centerHorizontalAlignment와 유사
            VStack(spacing: 16) {
                // 이모지 인디케이터
                Text(statusEmoji)
                    .font(.system(size: 80))
                    .padding(.top, 8)

                // 수면 시간
                VStack(spacing: 4) {
                    Text(formattedSleepTime)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(isEmpty ? .secondary : .primary)

                    // 품질 라벨 배지
                    Text(qualityLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(isEmpty ? .secondary : statusColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isEmpty ? Color(.systemGray5) : statusColor.opacity(0.15))
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            // 수면 설명 섹션 (데이터가 있을 때만)
            if !isEmpty {
                sleepInfoSection
            }
        }
        .padding(20)
        .background(cardBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - View Components

    /// 제목 섹션
    private var titleSection: some View {
        HStack {
            Text("어젯밤 수면")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(isEmpty ? .secondary : .primary)
            Spacer()
        }
    }

    /// 카드 배경
    private var cardBackground: some View {
        // 📚 학습 포인트: Material Background with Shadow
        // iOS 네이티브 느낌의 카드 디자인
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }

    /// 수면 정보 섹션
    ///
    /// 수면 상태별 설명과 추천 사항을 표시합니다.
    private var sleepInfoSection: some View {
        VStack(spacing: 8) {
            Divider()

            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.caption)
                    .foregroundStyle(statusColor)

                Text(sleepInfoMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }

    /// 수면 상태별 안내 메시지
    private var sleepInfoMessage: String {
        guard let status = sleepStatus else { return "" }

        switch status {
        case .bad:
            return "수면 시간이 부족합니다. 최소 6시간 30분 이상 수면을 권장합니다."
        case .soso:
            return "수면 시간이 다소 부족합니다. 조금 더 일찍 잠자리에 드세요."
        case .good:
            return "적정 수면 시간입니다. 이 패턴을 유지하세요."
        case .excellent:
            return "매우 좋은 수면 시간입니다. 건강한 수면 습관을 유지하고 있어요!"
        case .oversleep:
            return "수면 시간이 다소 깁니다. 9시간 이하로 조절하는 것을 권장합니다."
        }
    }

    // MARK: - Helper Methods

    /// 분 단위를 "X시간 Y분" 형식으로 변환
    ///
    /// - Parameter minutes: 분 단위 시간
    /// - Returns: 포맷팅된 문자열 (예: "7시간 30분", "6시간", "45분")
    ///
    /// - Example:
    /// ```swift
    /// formatMinutes(450)  // "7시간 30분"
    /// formatMinutes(360)  // "6시간"
    /// formatMinutes(45)   // "45분"
    /// ```
    private func formatMinutes(_ minutes: Int32) -> String {
        // 📚 학습 포인트: Integer Division and Modulo
        // Swift의 정수 나눗셈과 나머지 연산
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours > 0 {
            if remainingMinutes > 0 {
                return "\(hours)시간 \(remainingMinutes)분"
            } else {
                return "\(hours)시간"
            }
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Preview

// 📚 학습 포인트: Multiple Preview Configurations
// 다양한 상태를 미리 보며 개발 (나쁨/보통/좋음/매우 좋음/과다 수면/기록 없음)
// 💡 Java 비교: Compose의 @Preview와 유사

#Preview("Excellent Sleep") {
    VStack(spacing: 20) {
        // 매우 좋음 (8시간) - 🔵
        SleepQualityCard(
            sleepDuration: 480,
            sleepStatus: .excellent
        )

        // 매우 좋음 (7시간 45분) - 🔵
        SleepQualityCard(
            sleepDuration: 465,
            sleepStatus: .excellent
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Good Sleep") {
    VStack(spacing: 20) {
        // 좋음 (7시간) - 🟢
        SleepQualityCard(
            sleepDuration: 420,
            sleepStatus: .good
        )

        // 좋음 (7시간 15분) - 🟢
        SleepQualityCard(
            sleepDuration: 435,
            sleepStatus: .good
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Soso Sleep") {
    VStack(spacing: 20) {
        // 보통 (6시간) - 🟡
        SleepQualityCard(
            sleepDuration: 360,
            sleepStatus: .soso
        )

        // 보통 (6시간 15분) - 🟡
        SleepQualityCard(
            sleepDuration: 375,
            sleepStatus: .soso
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Bad Sleep") {
    VStack(spacing: 20) {
        // 나쁨 (5시간) - 🔴
        SleepQualityCard(
            sleepDuration: 300,
            sleepStatus: .bad
        )

        // 나쁨 (4시간 30분) - 🔴
        SleepQualityCard(
            sleepDuration: 270,
            sleepStatus: .bad
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Oversleep") {
    VStack(spacing: 20) {
        // 과다 수면 (9시간 30분) - 🟠
        SleepQualityCard(
            sleepDuration: 570,
            sleepStatus: .oversleep
        )

        // 과다 수면 (10시간) - 🟠
        SleepQualityCard(
            sleepDuration: 600,
            sleepStatus: .oversleep
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State") {
    VStack {
        // 수면 기록이 없는 경우 - 회색 톤으로 표시
        SleepQualityCard(
            sleepDuration: nil,
            sleepStatus: nil
        )
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("All Sleep States") {
    ScrollView {
        VStack(spacing: 20) {
            // 나쁨 (4시간 30분) - 🔴
            SleepQualityCard(
                sleepDuration: 270,
                sleepStatus: .bad
            )

            // 보통 (6시간) - 🟡
            SleepQualityCard(
                sleepDuration: 360,
                sleepStatus: .soso
            )

            // 좋음 (7시간) - 🟢
            SleepQualityCard(
                sleepDuration: 420,
                sleepStatus: .good
            )

            // 매우 좋음 (8시간) - 🔵
            SleepQualityCard(
                sleepDuration: 480,
                sleepStatus: .excellent
            )

            // 과다 수면 (10시간) - 🟠
            SleepQualityCard(
                sleepDuration: 600,
                sleepStatus: .oversleep
            )

            // 기록 없음
            SleepQualityCard(
                sleepDuration: nil,
                sleepStatus: nil
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Sleep Quality Card 구현
///
/// ### 주요 개념
///
/// 1. **이모지 상태 인디케이터**
///    - 큰 이모지(80pt)로 시각적 강조
///    - SleepStatus에 따라 다른 이모지 표시
///    - 직관적인 색상 구분 (🔴/🟡/🟢/🔵/🟠)
///
/// 2. **수면 시간 포맷팅**
///    - formatMinutes() 함수로 "X시간 Y분" 형식 변환
///    - 1시간 미만: "45분"
///    - 1시간 이상: "7시간 30분"
///    - 정확히 X시간: "8시간"
///
/// 3. **수면 상태별 색상 규칙**
///    - 나쁨 (bad): 빨간색 - 수면 부족 경고
///    - 보통 (soso): 노란색 - 개선 필요
///    - 좋음 (good): 초록색 - 적정 수면
///    - 매우 좋음 (excellent): 파란색 - 최적 수면
///    - 과다 수면 (oversleep): 주황색 - 조절 필요
///
/// 4. **Empty State 처리**
///    - sleepDuration, sleepStatus 모두 Optional
///    - nil일 때 "기록 없음" 메시지와 😴 이모지 표시
///    - 회색 톤으로 비활성 상태 표현
///
/// 5. **수면 정보 섹션**
///    - 각 수면 상태별 안내 메시지 제공
///    - 사용자에게 수면 개선 조언
///    - moon.stars.fill 아이콘으로 수면 테마 강조
///
/// ### 이모지 매핑
///
/// | 수면 상태 | 시간 범위 | 이모지 | 색상 | 라벨 |
/// |----------|----------|-------|------|------|
/// | Bad | < 5h 30m | 🔴 | Red | 나쁨 |
/// | Soso | 5h 30m ~ 6h 30m | 🟡 | Yellow | 보통 |
/// | Good | 6h 30m ~ 7h 30m | 🟢 | Green | 좋음 |
/// | Excellent | 7h 30m ~ 9h | 🔵 | Blue | 매우 좋음 |
/// | Oversleep | > 9h | 🟠 | Orange | 과다 수면 |
///
/// ### 시간 포맷팅 로직
///
/// | 입력 (분) | 출력 | 상태 |
/// |----------|------|------|
/// | 270 | "4시간 30분" | Bad |
/// | 360 | "6시간" | Soso |
/// | 420 | "7시간" | Good |
/// | 480 | "8시간" | Excellent |
/// | 600 | "10시간" | Oversleep |
/// | nil | "기록 없음" | Empty |
///
/// ### 레이아웃 구조
///
/// ```swift
/// VStack {
///     titleSection           // "어젯밤 수면"
///
///     VStack {
///         Text(emoji)        // 큰 이모지 (80pt)
///         VStack {
///             Text(time)      // 수면 시간
///             Text(label)     // 품질 배지
///         }
///     }
///
///     sleepInfoSection      // 안내 메시지 (있을 때만)
/// }
/// ```
///
/// ### Swift vs Java
///
/// | Swift (SwiftUI) | Java (Android) |
/// |-----------------|----------------|
/// | VStack(spacing: 16) | Column(verticalArrangement = spacedBy(16.dp)) |
/// | Text(emoji).font(.system(size: 80)) | Text(emoji, fontSize = 80.sp) |
/// | RoundedRectangle(cornerRadius: 12) | RoundedCornerShape(12.dp) |
/// | .foregroundStyle(color) | Modifier.color(color) |
/// | Optional (Int32?) | Nullable (Int?) |
///
/// ### 모범 사례
///
/// 1. **Props 최소화**: 필요한 2가지 값만 받기 (duration, status)
/// 2. **Computed Properties**: isEmpty, formattedSleepTime으로 로직 분리
/// 3. **색상 일관성**: 상태별 색상을 앱 전체에서 일관되게 사용
/// 4. **의미 있는 이모지**: 각 상태를 직관적으로 표현하는 이모지 선택
/// 5. **빈 상태 처리**: nil일 때도 UI가 깨지지 않도록 처리
/// 6. **사용자 친화적 메시지**: 각 상태별 실용적인 조언 제공
///
/// ### 사용 예시
///
/// ```swift
/// // DashboardView에서 사용
/// if let dailyLog = viewModel.dailyLog {
///     SleepQualityCard(
///         sleepDuration: dailyLog.sleepDuration,
///         sleepStatus: dailyLog.sleepStatus
///     )
/// }
/// ```
///
/// ### 성능 최적화
///
/// - DailyLog의 사전 계산된 값 사용 (sleepDuration, sleepStatus)
/// - SleepStatus enum에서 이미 상태가 결정되어 있음
/// - 추가 계산 없이 바로 표시 가능
/// - <0.5s 로딩 목표 달성에 기여
///
/// ### 접근성 (Accessibility)
///
/// - VoiceOver: "어젯밤 수면, 7시간, 좋음"으로 읽힘
/// - Dynamic Type: 시스템 폰트 크기에 자동 대응
/// - 색맹 지원: 이모지와 텍스트로 색상만 의존하지 않음
/// - 큰 이모지: 시각적으로 명확한 상태 표현
///
/// ### 디자인 의도
///
/// 이 카드는 사용자의 수면 품질을 한눈에 파악할 수 있도록 합니다:
/// - **큰 이모지**: 즉각적인 시각적 피드백
/// - **수면 시간**: 정확한 수면 시간 정보
/// - **품질 라벨**: 수면 상태를 한글로 명확하게 표현
/// - **안내 메시지**: 수면 개선을 위한 실용적인 조언
///
/// 수면은 건강 관리의 핵심 요소이므로, 명확하고 친근한 피드백으로
/// 사용자가 수면 패턴을 쉽게 이해하고 개선할 수 있도록 돕습니다.
///
