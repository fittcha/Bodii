//
//  PhotoRecognitionOfflineView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Offline State Handling
// 네트워크 연결이 없을 때 사용자에게 명확한 안내를 제공하는 뷰
// 💡 Java 비교: Error State View Component와 유사

import SwiftUI

/// 오프라인 상태 뷰
///
/// 네트워크 연결이 없어 사진 인식 기능을 사용할 수 없을 때 표시되는 뷰입니다.
///
/// **주요 기능:**
/// - 오프라인 상태 설명
/// - 네트워크 연결 확인 유도
/// - 수동 음식 검색 대안 제시
/// - 재시도 기능
///
/// **사용 예시:**
/// ```swift
/// if isOffline {
///     PhotoRecognitionOfflineView(
///         onRetry: {
///             // 네트워크 상태 재확인 및 재시도
///         },
///         onManualEntry: {
///             // 수동 검색 화면으로 이동
///         }
///     )
/// }
/// ```
///
/// - Note: Vision API는 네트워크가 필수이지만, 음식 검색은 캐시된 데이터로 오프라인에서도 작동합니다.
struct PhotoRecognitionOfflineView: View {

    // MARK: - Properties

    /// 재시도 콜백
    let onRetry: () -> Void

    /// 수동 입력으로 전환 콜백
    let onManualEntry: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {

            // 상단 여백
            Spacer()

            // 오프라인 아이콘
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            // 제목
            Text("네트워크 연결이 필요해요")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // 설명
            VStack(spacing: 12) {
                Text("사진 인식 기능은 AI 분석을 위해")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("네트워크 연결이 필요합니다")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)

            // 대안 제시 카드
            VStack(alignment: .leading, spacing: 12) {

                Label("다른 방법으로 기록하기", systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("음식 이름으로 직접 검색")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("캐시된 음식 데이터는 오프라인에서도 검색 가능")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("최근 먹은 음식 빠른 추가")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
            )
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()

            // 액션 버튼들
            VStack(spacing: 12) {

                // 재시도 버튼
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("다시 시도")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                // 수동 검색 버튼
                Button(action: onManualEntry) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("직접 검색하기")
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#if DEBUG
struct PhotoRecognitionOfflineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode
            PhotoRecognitionOfflineView(
                onRetry: {
                    print("Retry tapped")
                },
                onManualEntry: {
                    print("Manual entry tapped")
                }
            )
            .previewDisplayName("Light Mode")

            // Dark mode
            PhotoRecognitionOfflineView(
                onRetry: {
                    print("Retry tapped")
                },
                onManualEntry: {
                    print("Manual entry tapped")
                }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif
