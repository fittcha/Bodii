//
//  QuotaWarningView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Quota Warning View
// Vision API 할당량 경고 및 초과 상태를 표시하는 컴포넌트
// 💡 90% 사용 시 경고, 100% 초과 시 기능 비활성화 UI 제공

import SwiftUI

/// Vision API 할당량 경고 뷰
///
/// Google Cloud Vision API의 월간 무료 할당량(1,000 요청/월) 사용 현황을 표시하고,
/// 경고 또는 초과 상태에 따라 적절한 UI를 제공합니다.
///
/// **주요 기능:**
/// - 90% 사용 시 경고 배너 표시
/// - 남은 API 호출 횟수 표시
/// - 할당량 초기화까지 남은 일수 표시
/// - 할당량 초과 시 비활성화 상태 UI
/// - 수동 음식 입력으로 대체 안내
///
/// - Note: PhotoRecognitionViewModel의 할당량 추적 데이터를 표시합니다.
/// - Note: VisionAPIUsageTracker 서비스와 연동하여 실시간 할당량 정보 제공
///
/// - Example:
/// ```swift
/// QuotaWarningView(
///     showWarning: viewModel.showQuotaWarning,
///     remainingQuota: viewModel.remainingQuota,
///     daysUntilReset: viewModel.daysUntilReset,
///     isQuotaExceeded: viewModel.isQuotaExceeded,
///     onManualEntryTapped: {
///         // 수동 음식 입력 화면으로 이동
///     }
/// )
/// ```
struct QuotaWarningView: View {

    // MARK: - Properties

    /// 경고 표시 여부 (90% 이상 사용 시)
    let showWarning: Bool

    /// 남은 API 호출 횟수
    let remainingQuota: Int

    /// 할당량 초기화까지 남은 일수
    let daysUntilReset: Int

    /// 할당량 초과 여부
    let isQuotaExceeded: Bool

    /// 수동 입력 버튼 탭 콜백
    let onManualEntryTapped: () -> Void

    // MARK: - Body

    var body: some View {
        if isQuotaExceeded {
            // 할당량 초과 상태 - 전체 화면 차단
            quotaExceededView
        } else if showWarning {
            // 경고 배너 - 상단에 표시
            warningBannerView
        }
    }

    // MARK: - Subviews

    /// 경고 배너 뷰
    ///
    /// 90% 사용 시 상단에 표시되는 경고 배너입니다.
    ///
    /// 📚 학습 포인트: Warning Banner Pattern
    /// 사용자의 주의를 끌면서도 기능 사용을 방해하지 않는 경고 UI
    private var warningBannerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 경고 아이콘
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                // 경고 메시지
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 인식 할당량 부족")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("남은 횟수: \(remainingQuota)회 · \(daysUntilReset)일 후 초기화")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 정보 아이콘
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    /// 할당량 초과 뷰
    ///
    /// 할당량 초과 시 표시되는 전체 화면 안내입니다.
    ///
    /// 📚 학습 포인트: Disabled State with Alternative
    /// 기능 차단 시 대체 방법을 제공하여 사용자 경험 개선
    private var quotaExceededView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 초과 아이콘
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 8)

            // 안내 메시지
            VStack(spacing: 12) {
                Text("AI 인식 할당량 초과")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                VStack(spacing: 8) {
                    Text("이번 달 무료 할당량을 모두 사용했습니다")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.caption)

                        Text("\(daysUntilReset)일 후 자동으로 초기화됩니다")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // 할당량 정보 카드
            quotaInfoCard
                .padding(.horizontal)

            Spacer()

            // 대체 방법 안내
            VStack(spacing: 16) {
                Text("대체 방법")
                    .font(.headline)
                    .foregroundColor(.primary)

                // 수동 입력 버튼
                Button(action: onManualEntryTapped) {
                    HStack {
                        Image(systemName: "keyboard")
                            .font(.title3)

                        Text("수동으로 음식 입력하기")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                // 안내 텍스트
                Text("검색 기능을 사용하여 음식을 직접 추가할 수 있습니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }

    /// 할당량 정보 카드
    ///
    /// 현재 할당량 사용 현황을 표시하는 카드입니다.
    private var quotaInfoCard: some View {
        VStack(spacing: 16) {
            // 제목
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)

                Text("월간 할당량 현황")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()
            }

            Divider()

            // 할당량 정보
            VStack(spacing: 12) {
                // 사용량
                HStack {
                    Text("이번 달 사용량")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("1,000 / 1,000회")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                // 남은 횟수
                HStack {
                    Text("남은 횟수")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(remainingQuota)회")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(remainingQuota > 0 ? .orange : .red)
                }

                // 초기화 날짜
                HStack {
                    Text("다음 초기화")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)

                        Text("\(daysUntilReset)일 후")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.primary)
                }
            }

            // 프로그레스 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 배경
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    // 사용량 바
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geometry.size.width, height: 8)
                }
            }
            .frame(height: 8)

            // 안내 텍스트
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption)

                Text("Google Cloud Vision API 무료 티어 기준")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Warning Banner - 90% Usage") {
    VStack {
        QuotaWarningView(
            showWarning: true,
            remainingQuota: 95,
            daysUntilReset: 7,
            isQuotaExceeded: false,
            onManualEntryTapped: {
                print("Manual entry tapped")
            }
        )

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Warning Banner - Low Quota") {
    VStack {
        QuotaWarningView(
            showWarning: true,
            remainingQuota: 15,
            daysUntilReset: 3,
            isQuotaExceeded: false,
            onManualEntryTapped: {
                print("Manual entry tapped")
            }
        )

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Quota Exceeded") {
    QuotaWarningView(
        showWarning: false,
        remainingQuota: 0,
        daysUntilReset: 12,
        isQuotaExceeded: true,
        onManualEntryTapped: {
            print("Manual entry tapped")
        }
    )
    .background(Color(.systemGroupedBackground))
}

#Preview("No Warning - Normal State") {
    VStack {
        QuotaWarningView(
            showWarning: false,
            remainingQuota: 850,
            daysUntilReset: 15,
            isQuotaExceeded: false,
            onManualEntryTapped: {
                print("Manual entry tapped")
            }
        )

        Text("정상 상태 - 경고 미표시")
            .foregroundColor(.secondary)

        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
