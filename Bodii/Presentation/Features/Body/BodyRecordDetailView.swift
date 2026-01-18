//
//  BodyRecordDetailView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Detail View Pattern
// 개별 데이터 레코드의 상세 정보를 표시하는 화면
// 💡 Java 비교: Android의 Detail Activity/Fragment와 유사하지만 더 선언적

import SwiftUI

// MARK: - BodyRecordDetailView

/// 신체 구성 개별 기록 상세 화면
/// 📚 학습 포인트: Detail View Pattern
/// - 선택한 기록의 모든 측정값 표시
/// - 이전 기록과의 비교 표시
/// - 편집 및 삭제 기능 제공
/// - BMR/TDEE 등 계산된 대사율 정보 표시
/// 💡 Java 비교: Android의 Detail Fragment와 유사
struct BodyRecordDetailView: View {

    // MARK: - Properties

    /// 표시할 신체 구성 기록
    /// 📚 학습 포인트: Required Data
    /// - View의 주요 데이터 소스
    let entry: BodyCompositionEntry

    /// 해당 기록의 대사율 데이터
    /// 📚 학습 포인트: Optional Related Data
    /// - BMR/TDEE 계산 결과 (있는 경우)
    let metabolismData: MetabolismData?

    /// 이전 기록 (비교용)
    /// 📚 학습 포인트: Comparison Data
    /// - 변화량 계산을 위한 이전 기록
    let previousEntry: BodyCompositionEntry?

    /// 편집 액션 콜백
    /// 📚 학습 포인트: Action Callback
    /// - 부모 View로 액션 전달
    /// 💡 Java 비교: Listener pattern과 유사
    let onEdit: () -> Void

    /// 삭제 액션 콜백
    let onDelete: () -> Void

    /// 화면 닫기 액션
    /// 📚 학습 포인트: Environment Dismiss
    /// - Sheet나 NavigationStack에서 화면을 닫을 때 사용
    /// 💡 Java 비교: finish() 또는 popBackStack()과 유사
    @Environment(\.dismiss) private var dismiss

    /// 삭제 확인 알림 표시 여부
    /// 📚 학습 포인트: Alert State
    /// - 사용자 확인이 필요한 위험 작업
    @State private var showDeleteConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // 📚 학습 포인트: ScrollView with LazyVStack
            // 성능 최적화를 위해 보이는 부분만 렌더링
            ScrollView {
                VStack(spacing: 20) {
                    // 측정 날짜 헤더
                    dateHeaderSection

                    // 신체 측정값 섹션
                    measurementSection

                    // 계산된 값 섹션
                    calculatedValuesSection

                    // 대사율 섹션 (있는 경우)
                    if metabolismData != nil {
                        metabolismSection
                    }

                    // 이전 기록과 비교 섹션 (있는 경우)
                    if previousEntry != nil {
                        comparisonSection
                    }

                    // 액션 버튼들
                    actionButtonsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .navigationTitle("기록 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
            }
            // 📚 학습 포인트: Alert for Confirmation
            // 위험한 작업 (삭제)에 대한 사용자 확인
            .alert("기록 삭제", isPresented: $showDeleteConfirmation) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("이 기록을 삭제하시겠습니까?\n삭제된 기록은 복구할 수 없습니다.")
            }
        }
    }

    // MARK: - Subviews

    /// 날짜 헤더 섹션
    /// 📚 학습 포인트: Header Section
    /// - 기록 날짜를 강조하여 표시
    private var dateHeaderSection: some View {
        VStack(spacing: 8) {
            // 날짜
            Text(formatDate(entry.date, style: .long))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // 시간
            Text(formatTime(entry.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // HealthKit 출처 표시
            if entry.isFromHealthKit {
                HStack(spacing: 6) {
                    Image(systemName: "applewatch")
                        .font(.caption)
                    Text("Apple Health에서 동기화됨")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.teal],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .green.opacity(0.3), radius: 3, x: 0, y: 2)
            }

            // 기록 ID (디버깅용, 작은 글씨)
            Text("ID: \(entry.id.uuidString.prefix(8))...")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    /// 신체 측정값 섹션
    /// 📚 학습 포인트: Data Display Section
    /// - 주요 측정값을 카드 형태로 표시
    private var measurementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "신체 측정값",
                icon: "figure.stand"
            )

            // 측정값 카드
            VStack(spacing: 16) {
                // 체중
                measurementRow(
                    icon: "scalemass",
                    label: "체중",
                    value: formatWeight(entry.weight),
                    color: .blue,
                    change: calculateWeightChange()
                )

                Divider()

                // 체지방률
                measurementRow(
                    icon: "percent",
                    label: "체지방률",
                    value: formatBodyFat(entry.bodyFatPercent),
                    color: .orange,
                    change: calculateBodyFatChange()
                )

                Divider()

                // 근육량
                measurementRow(
                    icon: "figure.strengthtraining.traditional",
                    label: "근육량",
                    value: formatWeight(entry.muscleMass),
                    color: .green,
                    change: calculateMuscleMassChange()
                )

                Divider()

                // 체지방량
                measurementRow(
                    icon: "drop.fill",
                    label: "체지방량",
                    value: formatWeight(entry.bodyFatMass),
                    color: .red,
                    change: calculateBodyFatMassChange()
                )
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    /// 계산된 값 섹션
    /// 📚 학습 포인트: Computed Values Display
    /// - 측정값으로부터 계산된 값들 표시
    private var calculatedValuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "계산된 값",
                icon: "function"
            )

            // 계산된 값 카드
            VStack(spacing: 16) {
                // 제지방량
                infoRow(
                    icon: "heart.fill",
                    label: "제지방량 (LBM)",
                    value: formatWeight(entry.leanBodyMass),
                    description: "체중 - 체지방량",
                    color: .purple
                )

                Divider()

                // 골격근 비율
                infoRow(
                    icon: "figure.walk",
                    label: "골격근 비율",
                    value: formatBodyFat(entry.musclePercentage),
                    description: "근육량 / 체중 × 100",
                    color: .teal
                )
            }
            .padding(16)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    /// 대사율 섹션
    /// 📚 학습 포인트: Related Data Section
    /// - 신체 기록과 연관된 대사율 데이터 표시
    private var metabolismSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "대사율 정보",
                icon: "flame.fill"
            )

            if let metabolism = metabolismData {
                metabolismCard(metabolism: metabolism)
            }
        }
    }

    /// 대사율 카드
    /// 📚 학습 포인트: Reusable Component Function
    /// - BMR/TDEE 정보를 카드로 표시
    ///
    /// - Parameter metabolism: 대사율 데이터
    /// - Returns: 대사율 표시 카드
    private func metabolismCard(metabolism: MetabolismData) -> some View {
        VStack(spacing: 16) {
            // BMR/TDEE 값
            HStack(spacing: 20) {
                // BMR
                metabolismValueItem(
                    title: "BMR",
                    subtitle: "기초대사량",
                    value: formatCalories(metabolism.bmr),
                    icon: "bed.double.fill",
                    color: .blue
                )

                Divider()
                    .frame(height: 60)

                // TDEE
                metabolismValueItem(
                    title: "TDEE",
                    subtitle: "총 소비 칼로리",
                    value: formatCalories(metabolism.tdee),
                    icon: "figure.walk",
                    color: .green
                )
            }

            Divider()

            // 활동 수준
            HStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundStyle(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("활동 수준")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(metabolism.activityLevel.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                // 활동 계수 표시
                Text("\(String(format: "%.2f", metabolism.activityLevel.multiplier))x")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }

            // 활동 칼로리
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("활동 칼로리")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text(formatCalories(metabolism.activityCalories))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text("kcal/일")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 개별 대사량 값 아이템
    /// 📚 학습 포인트: Reusable Component Function
    ///
    /// - Parameters:
    ///   - title: 제목 (BMR, TDEE 등)
    ///   - subtitle: 부제목 설명
    ///   - value: 칼로리 값
    ///   - icon: SF Symbol 아이콘 이름
    ///   - color: 아이콘 색상
    /// - Returns: 값 표시 뷰
    private func metabolismValueItem(
        title: String,
        subtitle: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 아이콘과 레이블
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // 값
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            // 단위
            Text("kcal/일")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 이전 기록과 비교 섹션
    /// 📚 학습 포인트: Comparison Section
    /// - 이전 기록 대비 변화량 표시
    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            sectionHeader(
                title: "변화량",
                icon: "arrow.left.arrow.right"
            )

            if let previous = previousEntry {
                comparisonCard(previous: previous)
            }
        }
    }

    /// 비교 카드
    /// 📚 학습 포인트: Comparison Display
    /// - 이전 기록과 현재 기록의 차이 표시
    ///
    /// - Parameter previous: 이전 기록
    /// - Returns: 비교 카드 뷰
    private func comparisonCard(previous: BodyCompositionEntry) -> some View {
        VStack(spacing: 16) {
            // 이전 기록 날짜
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("이전 기록: \(formatDate(previous.date, style: .short))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(daysBetween(from: previous.date, to: entry.date))일 경과")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
            }

            Divider()

            // 변화량 그리드
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // 체중 변화
                changeItem(
                    label: "체중",
                    change: entry.weight - previous.weight,
                    unit: "kg",
                    icon: "scalemass",
                    lowerIsBetter: false
                )

                // 체지방률 변화
                changeItem(
                    label: "체지방률",
                    change: entry.bodyFatPercent - previous.bodyFatPercent,
                    unit: "%",
                    icon: "percent",
                    lowerIsBetter: true
                )

                // 근육량 변화
                changeItem(
                    label: "근육량",
                    change: entry.muscleMass - previous.muscleMass,
                    unit: "kg",
                    icon: "figure.strengthtraining.traditional",
                    lowerIsBetter: false
                )

                // 체지방량 변화
                changeItem(
                    label: "체지방량",
                    change: entry.bodyFatMass - previous.bodyFatMass,
                    unit: "kg",
                    icon: "drop.fill",
                    lowerIsBetter: true
                )
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// 변화량 아이템
    /// 📚 학습 포인트: Change Indicator
    /// - 변화량을 색상으로 구분하여 표시
    ///
    /// - Parameters:
    ///   - label: 측정 항목명
    ///   - change: 변화량
    ///   - unit: 단위
    ///   - icon: SF Symbol 아이콘
    ///   - lowerIsBetter: 값이 낮을수록 좋은지 여부
    /// - Returns: 변화량 표시 뷰
    private func changeItem(
        label: String,
        change: Decimal,
        unit: String,
        icon: String,
        lowerIsBetter: Bool
    ) -> some View {
        let isPositive = change > 0
        let isGood = lowerIsBetter ? !isPositive : isPositive
        let color: Color = change == 0 ? .gray : (isGood ? .blue : .orange)

        return VStack(alignment: .leading, spacing: 8) {
            // 아이콘과 레이블
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 변화량
            HStack(spacing: 4) {
                Image(systemName: change > 0 ? "arrow.up" : (change < 0 ? "arrow.down" : "minus"))
                    .font(.caption)
                    .foregroundStyle(color)

                Text(formatChange(change))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(color)

                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }

    /// 액션 버튼 섹션
    /// 📚 학습 포인트: Action Buttons
    /// - 편집 및 삭제 버튼 제공
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 편집 버튼
            Button(action: {
                onEdit()
                dismiss()
            }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.body)

                    Text("편집")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                )
                .foregroundStyle(.white)
            }

            // 삭제 버튼
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.body)

                    Text("삭제")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(0.1))
                )
                .foregroundStyle(.red)
            }
        }
        .padding(.top, 8)
    }

    /// 측정값 행
    /// 📚 학습 포인트: Measurement Row Component
    /// - 측정값과 변화량을 함께 표시
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - label: 측정 항목명
    ///   - value: 측정값
    ///   - color: 강조 색상
    ///   - change: 변화량 (선택적)
    /// - Returns: 측정값 행 뷰
    private func measurementRow(
        icon: String,
        label: String,
        value: String,
        color: Color,
        change: Decimal? = nil
    ) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            // 레이블과 값
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // 변화량 (있는 경우)
            if let change = change {
                changeBadge(change: change)
            }
        }
    }

    /// 정보 행
    /// 📚 학습 포인트: Info Row Component
    /// - 계산된 값과 설명을 함께 표시
    ///
    /// - Parameters:
    ///   - icon: SF Symbol 아이콘
    ///   - label: 항목명
    ///   - value: 값
    ///   - description: 설명
    ///   - color: 강조 색상
    /// - Returns: 정보 행 뷰
    private func infoRow(
        icon: String,
        label: String,
        value: String,
        description: String,
        color: Color
    ) -> some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            // 레이블과 값
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
    }

    /// 변화량 뱃지
    /// 📚 학습 포인트: Change Badge Component
    /// - 변화량을 색상이 있는 뱃지로 표시
    ///
    /// - Parameter change: 변화량
    /// - Returns: 뱃지 뷰
    private func changeB adge(change: Decimal) -> some View {
        HStack(spacing: 4) {
            Image(systemName: change > 0 ? "arrow.up" : (change < 0 ? "arrow.down" : "minus"))
                .font(.caption2)

            Text(formatChange(change))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(change > 0 ? Color.orange.opacity(0.1) : (change < 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1)))
        )
        .foregroundStyle(change > 0 ? .orange : (change < 0 ? .blue : .gray))
    }

    /// 닫기 버튼
    /// 📚 학습 포인트: Toolbar Item
    /// - 네비게이션 바에 닫기 버튼 추가
    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                Text("닫기")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.blue)
        }
    }

    /// 섹션 헤더
    /// 📚 학습 포인트: Section Header Component
    ///
    /// - Parameters:
    ///   - title: 섹션 제목
    ///   - icon: SF Symbol 아이콘
    /// - Returns: 섹션 헤더 뷰
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
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

    /// 체중 변화량 계산
    /// 📚 학습 포인트: Change Calculation
    /// - 이전 기록과 비교하여 변화량 계산
    ///
    /// - Returns: 체중 변화량 (kg), 이전 기록이 없으면 nil
    private func calculateWeightChange() -> Decimal? {
        guard let previous = previousEntry else { return nil }
        return entry.weight - previous.weight
    }

    /// 체지방률 변화량 계산
    private func calculateBodyFatChange() -> Decimal? {
        guard let previous = previousEntry else { return nil }
        return entry.bodyFatPercent - previous.bodyFatPercent
    }

    /// 근육량 변화량 계산
    private func calculateMuscleMassChange() -> Decimal? {
        guard let previous = previousEntry else { return nil }
        return entry.muscleMass - previous.muscleMass
    }

    /// 체지방량 변화량 계산
    private func calculateBodyFatMassChange() -> Decimal? {
        guard let previous = previousEntry else { return nil }
        return entry.bodyFatMass - previous.bodyFatMass
    }

    /// 두 날짜 사이의 일수 계산
    /// 📚 학습 포인트: Date Calculation
    /// - Calendar를 사용한 날짜 연산
    ///
    /// - Parameters:
    ///   - from: 시작 날짜
    ///   - to: 종료 날짜
    /// - Returns: 일수 차이
    private func daysBetween(from: Date, to: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: from, to: to)
        return components.day ?? 0
    }

    /// 날짜 포맷팅
    /// 📚 학습 포인트: Date Formatting
    ///
    /// - Parameters:
    ///   - date: 날짜
    ///   - style: 날짜 스타일 (기본값: .medium)
    /// - Returns: 포맷된 문자열
    private func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    /// 시간 포맷팅
    /// 📚 학습 포인트: Time Formatting
    ///
    /// - Parameter date: 날짜
    /// - Returns: 포맷된 문자열 (예: "14:30")
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    /// 체중 포맷팅
    /// 📚 학습 포인트: Weight Formatting
    /// - 소수점 1자리 + "kg" 단위
    ///
    /// - Parameter weight: 체중
    /// - Returns: 포맷된 문자열 (예: "70.5 kg")
    private func formatWeight(_ weight: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: weight)
        return (formatter.string(from: number) ?? "\(weight)") + " kg"
    }

    /// 체지방률 포맷팅
    /// 📚 학습 포인트: Percentage Formatting
    /// - 소수점 1자리 + "%" 기호
    ///
    /// - Parameter bodyFat: 체지방률
    /// - Returns: 포맷된 문자열 (예: "18.5%")
    private func formatBodyFat(_ bodyFat: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1

        let number = NSDecimalNumber(decimal: bodyFat)
        return (formatter.string(from: number) ?? "\(bodyFat)") + "%"
    }

    /// 칼로리 값 포맷팅
    /// 📚 학습 포인트: Number Formatting
    ///
    /// - Parameter calories: 칼로리 값
    /// - Returns: 포맷된 문자열 (예: "1,650")
    private func formatCalories(_ calories: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0

        let number = NSDecimalNumber(decimal: calories)
        return formatter.string(from: number) ?? "\(calories)"
    }

    /// 변화량 포맷팅
    /// 📚 학습 포인트: Signed Number Formatting
    /// - 양수는 +, 음수는 - 기호 포함
    ///
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "+1.5", "-0.8", "0.0")
    private func formatChange(_ change: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.positivePrefix = "+"
        formatter.negativePrefix = "-"

        let number = NSDecimalNumber(decimal: change)
        return formatter.string(from: number) ?? "\(change)"
    }
}

// MARK: - Preview

#if DEBUG
#Preview("기본 상태") {
    BodyRecordDetailView(
        entry: .sample,
        metabolismData: .sample,
        previousEntry: nil,
        onEdit: { print("편집") },
        onDelete: { print("삭제") }
    )
}

#Preview("이전 기록 포함") {
    BodyRecordDetailView(
        entry: BodyCompositionEntry(
            date: Date(),
            weight: Decimal(70.5),
            bodyFatPercent: Decimal(18.5),
            muscleMass: Decimal(32.0)
        ),
        metabolismData: .sample,
        previousEntry: BodyCompositionEntry(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            weight: Decimal(72.0),
            bodyFatPercent: Decimal(20.0),
            muscleMass: Decimal(31.0)
        ),
        onEdit: { print("편집") },
        onDelete: { print("삭제") }
    )
}

#Preview("대사율 없음") {
    BodyRecordDetailView(
        entry: .sample,
        metabolismData: nil,
        previousEntry: nil,
        onEdit: { print("편집") },
        onDelete: { print("삭제") }
    )
}

#Preview("다크 모드") {
    BodyRecordDetailView(
        entry: .sample,
        metabolismData: .sample,
        previousEntry: BodyCompositionEntry(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            weight: Decimal(72.0),
            bodyFatPercent: Decimal(20.0),
            muscleMass: Decimal(31.0)
        ),
        onEdit: { print("편집") },
        onDelete: { print("삭제") }
    )
    .preferredColorScheme(.dark)
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: BodyRecordDetailView 사용법
///
/// 기본 사용:
/// ```swift
/// struct BodyCompositionView: View {
///     @State private var selectedEntry: BodyCompositionEntry?
///     @State private var showDetailView = false
///
///     var body: some View {
///         List(entries) { entry in
///             Button(action: {
///                 selectedEntry = entry
///                 showDetailView = true
///             }) {
///                 EntryRow(entry: entry)
///             }
///         }
///         .sheet(isPresented: $showDetailView) {
///             if let entry = selectedEntry {
///                 BodyRecordDetailView(
///                     entry: entry,
///                     metabolismData: getMetabolismData(for: entry),
///                     previousEntry: getPreviousEntry(before: entry),
///                     onEdit: {
///                         // 편집 화면으로 이동
///                         navigateToEdit(entry)
///                     },
///                     onDelete: {
///                         // 기록 삭제
///                         deleteEntry(entry)
///                     }
///                 )
///             }
///         }
///     }
/// }
/// ```
///
/// 주요 기능:
/// - 모든 신체 측정값 표시 (체중, 체지방률, 근육량, 체지방량)
/// - 계산된 값 표시 (제지방량, 골격근 비율)
/// - BMR/TDEE 대사율 정보 표시
/// - 이전 기록과의 비교 및 변화량 표시
/// - 편집 및 삭제 액션
///
/// 화면 구성:
/// 1. 날짜 헤더: 측정 날짜와 시간
/// 2. 신체 측정값: 주요 측정 데이터 (변화량 포함)
/// 3. 계산된 값: LBM, 골격근 비율 등
/// 4. 대사율 정보: BMR, TDEE, 활동 수준 (선택적)
/// 5. 변화량: 이전 기록과의 비교 (선택적)
/// 6. 액션 버튼: 편집 및 삭제
///
/// 네비게이션:
/// - NavigationStack 사용
/// - 닫기 버튼으로 dismiss
/// - Environment dismiss 사용
///
/// 삭제 확인:
/// - 위험한 작업이므로 확인 알림 표시
/// - 취소 가능
///
/// 💡 Android 비교:
/// - Android: Detail Activity/Fragment + ViewModel
/// - SwiftUI: Detail View + Bindings + Callbacks
/// - Android: RecyclerView for data list
/// - SwiftUI: ScrollView + VStack for data sections
///
/// 접근성:
/// - VoiceOver 지원
/// - Dynamic Type 지원
/// - 충분한 터치 영역
/// - 명확한 레이블과 힌트
///
/// 데이터 표시:
/// - 측정값: 아이콘, 레이블, 값, 변화량
/// - 계산값: 설명 포함
/// - 대사율: 시각적 강조
/// - 비교: 색상으로 구분 (증가/감소)
///
