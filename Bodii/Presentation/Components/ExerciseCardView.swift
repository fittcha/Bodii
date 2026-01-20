//
//  ExerciseCardView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Reusable Component Pattern
// 재사용 가능한 카드 컴포넌트 설계
// 💡 Java 비교: RecyclerView의 ViewHolder와 유사한 역할

import SwiftUI

// MARK: - Exercise Card View

/// 운동 기록 카드 컴포넌트
///
/// 운동 기록의 주요 정보를 카드 형태로 표시하는 재사용 가능한 뷰입니다.
///
/// **표시 내용:**
/// - 운동 종류 아이콘 및 이름
/// - 운동 시간 (분)
/// - 운동 강도 (저/중/고)
/// - 소모 칼로리
///
/// **기능:**
/// - 스와이프 삭제 제스처 지원 (iOS 기본 동작)
///
/// - Example:
/// ```swift
/// ExerciseCardView(exercise: exerciseRecord) {
///     // 삭제 액션
///     viewModel.delete(exerciseRecord)
/// }
/// ```
struct ExerciseCardView: View {

    // MARK: - Properties

    // 📚 학습 포인트: Immutable Props
    // View의 입력 데이터는 let으로 선언
    // 💡 Java 비교: final 필드와 유사

    /// 표시할 운동 기록
    let exercise: ExerciseRecord

    /// 삭제 액션 핸들러 (옵셔널)
    let onDelete: (() -> Void)?

    // MARK: - Initialization

    // 📚 학습 포인트: Trailing Closure Parameter
    // 마지막 파라미터가 클로저인 경우 trailing closure 문법 사용 가능

    /// ExerciseCardView 초기화
    /// - Parameters:
    ///   - exercise: 표시할 운동 기록
    ///   - onDelete: 삭제 시 실행할 액션 (옵셔널)
    init(exercise: ExerciseRecord, onDelete: (() -> Void)? = nil) {
        self.exercise = exercise
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: HStack Layout
        // 가로로 요소를 배치하는 레이아웃 컨테이너
        // 💡 Java 비교: LinearLayout(horizontal)과 유사
        HStack(spacing: 16) {
            iconSection
            contentSection
            Spacer()
            caloriesSection
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // 📚 학습 포인트: Badge Overlay for Data Source
        // HealthKit에서 가져온 데이터인 경우 Apple Watch 아이콘 표시
        .overlay(alignment: .topTrailing) {
            if exercise.fromHealthKit {
                healthKitBadge
            }
        }
        // 📚 학습 포인트: swipeActions modifier (iOS 15+)
        // 스와이프 제스처로 액션 버튼 표시
        // 💡 Java 비교: RecyclerView의 ItemTouchHelper와 유사
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if onDelete != nil {
                Button(role: .destructive, action: { onDelete?() }) {
                    Label("삭제", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Computed Properties (Type Conversion)

    /// 운동 종류 (Int16 → ExerciseType 변환)
    private var exerciseType: ExerciseType {
        ExerciseType(rawValue: exercise.exerciseType) ?? .other
    }

    /// 운동 강도 (Int16 → Intensity 변환)
    private var intensity: Intensity {
        Intensity(rawValue: exercise.intensity) ?? .medium
    }

    // MARK: - View Components

    // 📚 학습 포인트: Computed Properties for View Composition
    // 복잡한 View를 작은 단위로 분리하여 가독성 향상

    /// 운동 종류 아이콘 섹션
    private var iconSection: some View {
        Image(systemName: exerciseType.systemIconName)
            .font(.system(size: 32))
            .foregroundStyle(exerciseType.accentColor)
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(exerciseType.accentColor.opacity(0.1))
            )
    }

    /// 운동 정보 (이름, 강도, 시간) 섹션
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 운동 종류 이름
            Text(exerciseType.displayName)
                .font(.headline)
                .foregroundStyle(.primary)

            // 강도 및 시간 정보
            HStack(spacing: 8) {
                // 강도 뱃지
                Text(intensity.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(intensityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(intensityColor.opacity(0.15))
                    )

                // 시간
                Label("\(exercise.duration)분", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// 소모 칼로리 섹션
    private var caloriesSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(exercise.caloriesBurned)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text("kcal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// 카드 배경
    private var cardBackground: some View {
        // 📚 학습 포인트: Material Background
        // iOS 네이티브 느낌의 반투명 배경 효과
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    /// HealthKit 데이터 출처 뱃지
    /// 📚 학습 포인트: Data Source Indicator
    /// - Apple Health/Apple Watch에서 가져온 데이터임을 시각적으로 표시
    /// - 사용자가 수동 입력한 데이터와 구분
    /// 💡 Java 비교: Badge view pattern과 유사
    private var healthKitBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "applewatch")
                .font(.caption2)
                .fontWeight(.medium)

            Text("동기화")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
        .shadow(color: .green.opacity(0.3), radius: 2, x: 0, y: 1)
        .offset(x: -8, y: 8)
        .help("Apple Health에서 동기화된 데이터")
    }

    // MARK: - Computed Properties

    /// 강도별 색상
    private var intensityColor: Color {
        // 📚 학습 포인트: switch expression
        // Swift의 switch는 표현식으로 사용 가능 (값 반환)
        switch intensity {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - ExerciseType Extension

// 📚 학습 포인트: Extension으로 기능 확장
// 기존 타입에 새로운 computed property 추가
// 💡 Java 비교: Extension method (Kotlin)와 유사

extension ExerciseType {

    /// SF Symbol 아이콘 이름
    var systemIconName: String {
        switch self {
        case .walking:
            return "figure.walk"
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .swimming:
            return "figure.pool.swim"
        case .weight:
            return "dumbbell.fill"
        case .crossfit:
            return "figure.strengthtraining.traditional"
        case .yoga:
            return "figure.yoga"
        case .other:
            return "figure.mixed.cardio"
        }
    }

    /// 액센트 컬러
    var accentColor: Color {
        switch self {
        case .walking:
            return .green
        case .running:
            return .blue
        case .cycling:
            return .cyan
        case .swimming:
            return .teal
        case .weight:
            return .purple
        case .crossfit:
            return .orange
        case .yoga:
            return .pink
        case .other:
            return .gray
        }
    }
}

// MARK: - Preview
// Preview는 Core Data 엔티티 초기화 문제로 인해 임시 비활성화
// TODO: PreviewHelpers를 사용한 Preview 구현 필요

// 📚 학습 포인트: Core Data 엔티티 Preview 제한
// ExerciseRecord는 Core Data 엔티티이므로 직접 초기화 불가
// TODO: Phase 7에서 Preview용 Core Data context helper 구현

#Preview("Placeholder") {
    Text("ExerciseCardView Preview")
        .font(.headline)
        .padding()
}
