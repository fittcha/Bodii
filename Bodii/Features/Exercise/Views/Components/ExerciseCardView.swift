//
//  ExerciseCardView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

import SwiftUI

/// 운동 기록 카드 뷰
///
/// 단일 운동 기록을 표시하는 재사용 가능한 카드 컴포넌트입니다.
///
/// **표시 정보**:
/// - 운동 종류 아이콘 (색상 원형 배경)
/// - 운동 종류 이름
/// - 운동 시간 (분)
/// - 강도 레벨 (저/중/고강도)
/// - 소모 칼로리
///
/// - Example:
/// ```swift
/// ExerciseCardView(exercise: exerciseRecord)
/// ```
struct ExerciseCardView: View {

    // MARK: - Properties

    /// 표시할 운동 기록
    let exercise: ExerciseRecord

    // MARK: - Body

    var body: some View {
        HStack(spacing: 16) {
            // 운동 종류 아이콘
            ZStack {
                Circle()
                    .fill(exerciseTypeColor(for: exercise.exerciseType).opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: exerciseTypeIcon(for: exercise.exerciseType))
                    .font(.title3)
                    .foregroundStyle(exerciseTypeColor(for: exercise.exerciseType))
            }

            // 운동 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseType.displayName)
                    .font(.headline)

                HStack(spacing: 12) {
                    Label("\(exercise.duration)분", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(exercise.intensity.displayName, systemImage: intensityIcon(for: exercise.intensity))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 칼로리
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(exercise.caloriesBurned)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)

                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    /// 운동 종류별 아이콘
    private func exerciseTypeIcon(for type: ExerciseType) -> String {
        switch type {
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
            return "figure.cross.training"
        case .yoga:
            return "figure.yoga"
        case .other:
            return "figure.mixed.cardio"
        }
    }

    /// 운동 종류별 색상
    private func exerciseTypeColor(for type: ExerciseType) -> Color {
        switch type {
        case .walking:
            return .green
        case .running:
            return .blue
        case .cycling:
            return .orange
        case .swimming:
            return .cyan
        case .weight:
            return .red
        case .crossfit:
            return .purple
        case .yoga:
            return .pink
        case .other:
            return .gray
        }
    }

    /// 강도별 아이콘
    private func intensityIcon(for intensity: Intensity) -> String {
        switch intensity {
        case .low:
            return "circle"
        case .medium:
            return "circle.lefthalf.filled"
        case .high:
            return "circle.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // 러닝 고강도
        ExerciseCardView(
            exercise: ExerciseRecord(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                exerciseType: .running,
                duration: 30,
                intensity: .high,
                caloriesBurned: 350,
                createdAt: Date()
            )
        )

        // 걷기 저강도
        ExerciseCardView(
            exercise: ExerciseRecord(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                exerciseType: .walking,
                duration: 45,
                intensity: .low,
                caloriesBurned: 120,
                createdAt: Date()
            )
        )

        // 웨이트 중강도
        ExerciseCardView(
            exercise: ExerciseRecord(
                id: UUID(),
                userId: UUID(),
                date: Date(),
                exerciseType: .weight,
                duration: 60,
                intensity: .medium,
                caloriesBurned: 280,
                createdAt: Date()
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
