//
//  MetabolismDisplayCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-19.
//

// 📚 학습 포인트: Metabolism Display Card
// 대사율 정보(BMR/TDEE)를 표시하는 카드 컴포넌트
// 💡 MetabolismViewModel의 데이터를 시각적으로 표현

import SwiftUI

/// 대사율 표시 카드
///
/// BMR(기초대사량)과 TDEE(총 에너지 소비량)를 표시하는 카드입니다.
///
/// **표시 내용:**
/// - BMR: 기초대사량 (kcal)
/// - TDEE: 총 에너지 소비량 (kcal)
/// - 로딩 및 에러 상태
///
/// - Example:
/// ```swift
/// MetabolismDisplayCard(
///     viewModel: metabolismViewModel,
///     onTap: { }
/// )
/// ```
struct MetabolismDisplayCard: View {

    // MARK: - Properties

    /// 대사율 ViewModel
    @ObservedObject var viewModel: MetabolismViewModel

    /// 탭 핸들러
    var onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // 헤더
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)

                    Text("대사율")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if viewModel.isLoading {
                    // 로딩 상태
                    HStack {
                        ProgressView()
                        Text("로딩 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if let error = viewModel.errorMessage {
                    // 에러 상태
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    // 데이터 표시
                    HStack(spacing: 24) {
                        // BMR
                        VStack(alignment: .leading, spacing: 4) {
                            Text("기초대사량")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.bmr) kcal")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }

                        // TDEE
                        VStack(alignment: .leading, spacing: 4) {
                            Text("활동대사량")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(viewModel.tdee) kcal")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
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
