//
//  DurationInputView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Duration Input Pattern
// 시간 입력 컴포넌트 설계 - Quick Select + Fine Adjustment
// 💡 Java 비교: NumberPicker + ChipGroup 조합과 유사

import SwiftUI

// MARK: - Duration Input View

/// 운동 시간 입력 컴포넌트
///
/// 빠른 선택 버튼과 스테퍼를 결합하여 편리한 시간 입력을 제공합니다.
///
/// **표시 내용:**
/// - 현재 선택된 시간 (분)
/// - 빠른 선택 버튼 (15, 30, 45, 60분)
/// - 미세 조정 스테퍼 (±1분, ±5분)
///
/// **기능:**
/// - 탭 한 번으로 일반적인 운동 시간 선택
/// - 스테퍼로 정확한 시간 조정
/// - 최소 1분 제한
///
/// - Example:
/// ```swift
/// DurationInputView(
///     duration: $viewModel.duration,
///     onChange: { minutes in
///         print("Duration changed to: \(minutes)분")
///     }
/// )
/// ```
struct DurationInputView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @Binding for Two-Way Data Flow
    // 부모 View의 상태를 읽고 쓸 수 있는 양방향 바인딩
    // 💡 Java 비교: LiveData with Observer와 유사하지만 양방향

    /// 현재 운동 시간 (분)
    @Binding var duration: Int32

    /// 시간 변경 시 실행할 액션 핸들러 (옵셔널)
    let onChange: ((Int32) -> Void)?

    // MARK: - Quick Selection Presets

    // 📚 학습 포인트: Common Duration Presets
    // 대부분의 운동이 이 시간대에 해당하여 빠른 입력 가능

    /// 빠른 선택용 일반적인 운동 시간들
    private let quickDurations: [Int32] = [15, 30, 45, 60]

    // MARK: - Initialization

    /// DurationInputView 초기화
    ///
    /// - Parameters:
    ///   - duration: 현재 운동 시간 (바인딩)
    ///   - onChange: 시간 변경 시 실행할 액션 (옵셔널)
    init(
        duration: Binding<Int32>,
        onChange: ((Int32) -> Void)? = nil
    ) {
        self._duration = duration
        self.onChange = onChange
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // 현재 선택된 시간 표시
            currentDurationDisplay

            // 빠른 선택 버튼들
            quickSelectionButtons

            // 미세 조정 스테퍼
            fineAdjustmentSteppers
        }
        .padding(.vertical, 8)
    }

    // MARK: - View Components

    /// 현재 선택된 시간 표시
    @ViewBuilder
    private var currentDurationDisplay: some View {
        VStack(spacing: 4) {
            Text("운동 시간")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 📚 학습 포인트: Large Display for Primary Value
            // 사용자가 입력하는 주요 값은 크게 표시하여 가독성 향상
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(duration)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text("분")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            // 검증 메시지 (1분 미만일 때)
            if duration < 1 {
                Text("최소 1분 이상 입력해주세요")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        // 📚 학습 포인트: Animation for Value Changes
        // 숫자가 변경될 때 부드러운 애니메이션 제공
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duration)
    }

    /// 빠른 선택 버튼들
    ///
    /// 일반적인 운동 시간 (15, 30, 45, 60분)을 한 번의 탭으로 선택
    @ViewBuilder
    private var quickSelectionButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("빠른 선택")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            // 📚 학습 포인트: HStack with Equal Distribution
            // 4개의 버튼을 균등하게 분배
            HStack(spacing: 8) {
                ForEach(quickDurations, id: \.self) { minutes in
                    quickDurationButton(for: minutes)
                }
            }
        }
    }

    /// 빠른 선택 버튼
    ///
    /// - Parameter minutes: 버튼에 표시할 시간 (분)
    /// - Returns: 버튼 뷰
    @ViewBuilder
    private func quickDurationButton(for minutes: Int32) -> some View {
        let isSelected = duration == minutes

        // 📚 학습 포인트: Button with Selection State
        // 현재 선택된 시간과 일치하면 강조 표시
        Button(action: {
            handleQuickSelection(minutes)
        }) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.title3)
                    .fontWeight(isSelected ? .bold : .semibold)

                Text("분")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(isSelected ? .white : .blue)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? .blue.opacity(0.3) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        // 📚 학습 포인트: Animation tied to Value
        // isSelected 값이 변경될 때만 애니메이션 실행
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    /// 미세 조정 스테퍼
    ///
    /// ±1분, ±5분 버튼으로 정확한 시간 조정
    @ViewBuilder
    private var fineAdjustmentSteppers: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("미세 조정")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            // 📚 학습 포인트: Stepper Alternatives
            // 기본 Stepper 대신 커스텀 버튼으로 더 나은 UX 제공
            HStack(spacing: 12) {
                // -5분 버튼
                adjustmentButton(
                    label: "-5",
                    action: { adjustDuration(by: -5) },
                    isDestructive: false
                )

                // -1분 버튼
                adjustmentButton(
                    label: "-1",
                    action: { adjustDuration(by: -1) },
                    isDestructive: false
                )

                Spacer()

                // +1분 버튼
                adjustmentButton(
                    label: "+1",
                    action: { adjustDuration(by: 1) },
                    isDestructive: false
                )

                // +5분 버튼
                adjustmentButton(
                    label: "+5",
                    action: { adjustDuration(by: 5) },
                    isDestructive: false
                )
            }
        }
    }

    /// 조정 버튼
    ///
    /// - Parameters:
    ///   - label: 버튼 레이블
    ///   - action: 버튼 액션
    ///   - isDestructive: 경고 스타일 여부 (사용되지 않지만 확장성을 위해 유지)
    /// - Returns: 버튼 뷰
    @ViewBuilder
    private func adjustmentButton(
        label: String,
        action: @escaping () -> Void,
        isDestructive: Bool
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
                .frame(minWidth: 60)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    /// 빠른 선택 처리
    ///
    /// - Parameter minutes: 선택된 시간 (분)
    private func handleQuickSelection(_ minutes: Int32) {
        // 📚 학습 포인트: Haptic Feedback
        // 사용자 인터랙션에 촉각 피드백 제공
        // 💡 Java 비교: Vibrator 서비스와 유사
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // 시간 업데이트
        duration = minutes

        // 콜백 실행 (있는 경우)
        onChange?(minutes)
    }

    /// 시간 조정 처리
    ///
    /// - Parameter delta: 증감량 (분) - 음수이면 감소, 양수이면 증가
    private func adjustDuration(by delta: Int32) {
        // 📚 학습 포인트: Boundary Validation
        // 최소값(1분)과 최대값(300분 = 5시간) 제한
        let newDuration = max(1, min(300, duration + delta))

        // 값이 실제로 변경되었을 때만 햅틱 피드백
        guard newDuration != duration else { return }

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // 시간 업데이트
        duration = newDuration

        // 콜백 실행 (있는 경우)
        onChange?(newDuration)
    }
}

// MARK: - Preview

#Preview("Duration Input") {
    // 📚 학습 포인트: @State in Preview
    // Preview에서 상태 관리를 위한 @State 사용
    struct PreviewWrapper: View {
        @State private var duration: Int32 = 30

        var body: some View {
            VStack(spacing: 24) {
                // 상단 정보 카드 - 선택된 시간 표시
                VStack(spacing: 8) {
                    Text("현재 선택된 운동 시간")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(duration)")
                            .font(.system(size: 40, weight: .bold))

                        Text("분")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    // 예상 시간 표시 (시간:분 포맷)
                    if duration >= 60 {
                        let hours = duration / 60
                        let minutes = duration % 60
                        if minutes > 0 {
                            Text("\(hours)시간 \(minutes)분")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(hours)시간")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding(.horizontal)

                // 시간 입력 컴포넌트
                DurationInputView(
                    duration: $duration,
                    onChange: { minutes in
                        print("Duration changed to: \(minutes)분")
                    }
                )
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("Various Durations") {
    ScrollView {
        VStack(spacing: 24) {
            Text("다양한 운동 시간")
                .font(.headline)

            // 짧은 운동 (15분)
            DurationPreviewCard(initialDuration: 15, title: "짧은 운동")

            // 보통 운동 (30분)
            DurationPreviewCard(initialDuration: 30, title: "보통 운동")

            // 긴 운동 (60분)
            DurationPreviewCard(initialDuration: 60, title: "긴 운동")

            // 매우 긴 운동 (90분)
            DurationPreviewCard(initialDuration: 90, title: "매우 긴 운동")

            // 최소값 테스트 (1분)
            DurationPreviewCard(initialDuration: 1, title: "최소값 테스트")
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Preview Helpers

/// Preview용 시간 카드 컴포넌트
private struct DurationPreviewCard: View {
    @State private var duration: Int32

    let title: String

    init(initialDuration: Int32, title: String) {
        self._duration = State(initialValue: initialDuration)
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            DurationInputView(duration: $duration)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
}

#Preview("Interactive Demo") {
    struct PreviewWrapper: View {
        @State private var duration: Int32 = 30
        @State private var exerciseType: String = "달리기"
        @State private var userWeight: Double = 70.0

        var body: some View {
            VStack(spacing: 24) {
                // 상단 정보 카드
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("운동 종류")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(exerciseType)
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("체중")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(userWeight, specifier: "%.1f")kg")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }

                    Divider()

                    // 시간 입력
                    DurationInputView(
                        duration: $duration,
                        onChange: { minutes in
                            print("Duration changed: \(minutes)분")
                        }
                    )

                    Divider()

                    // 예상 칼로리 계산 (간단한 시뮬레이션)
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("예상 소모 칼로리")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // 간단한 MET 계산 (달리기 8.0 MET 가정)
                            let baseMET = 8.0
                            let hours = Double(duration) / 60.0
                            let calories = Int(baseMET * userWeight * hours)

                            Text("\(calories) kcal")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

// MARK: - Learning Notes

/// ## Duration Input Pattern
///
/// 시간 입력 컴포넌트는 빠른 선택과 정밀 조정을 결합한 하이브리드 입력 방식입니다.
///
/// ### 주요 특징
///
/// 1. **Quick Selection Buttons**:
///    - 일반적인 운동 시간 (15, 30, 45, 60분)을 한 번에 선택
///    - 대부분의 사용자는 이 버튼들만으로 입력 완료
///    - 빠르고 효율적인 입력 경험
///
/// 2. **Fine Adjustment Steppers**:
///    - ±1분, ±5분 버튼으로 정확한 시간 조정
///    - Quick Selection으로 대략적인 시간 선택 후 미세 조정
///    - 유연성과 정확성 제공
///
/// 3. **Large Display**:
///    - 현재 선택된 시간을 크게 표시
///    - 숫자가 주요 정보이므로 가독성 최우선
///    - 애니메이션으로 변경사항 명확히 표시
///
/// ### 디자인 철학
///
/// **80/20 Rule**:
/// - 80%의 사용자는 Quick Selection Buttons만 사용
/// - 20%의 사용자는 Fine Adjustment로 정확한 시간 입력
/// - 두 그룹 모두 만족시키는 하이브리드 디자인
///
/// **Progressive Disclosure**:
/// - 먼저 간단한 옵션 (Quick Selection) 제시
/// - 필요시 고급 옵션 (Fine Adjustment) 사용
/// - 복잡성을 단계적으로 공개
///
/// ### 구현 패턴
///
/// **1. Two-Way Binding with Callback**:
/// ```swift
/// @Binding var duration: Int32
/// let onChange: ((Int32) -> Void)?
/// ```
///
/// - @Binding: 부모 View와 상태 공유
/// - onChange: 추가 로직 실행 가능 (옵셔널)
///
/// **2. Boundary Validation**:
/// ```swift
/// let newDuration = max(1, min(300, duration + delta))
/// ```
///
/// - 최소값: 1분 (0분 운동은 의미 없음)
/// - 최대값: 300분 = 5시간 (일반적인 운동 범위)
///
/// **3. Numeric Transition Animation**:
/// ```swift
/// Text("\(duration)")
///     .contentTransition(.numericText())
/// ```
///
/// - iOS 17+의 새로운 기능
/// - 숫자가 변경될 때 부드러운 애니메이션
/// - 카운터 느낌 제공
///
/// ### 대안 디자인 비교
///
/// **1. Stepper Only**:
/// ```swift
/// Stepper("\(duration)분", value: $duration, in: 1...300)
/// ```
///
/// 장점:
/// - ✅ 코드 간결
/// - ✅ iOS 네이티브 컴포넌트
///
/// 단점:
/// - ❌ 큰 변경에 많은 탭 필요 (15분 → 60분까지 45번 탭)
/// - ❌ 커스터마이징 제한적
///
/// **2. Slider Only**:
/// ```swift
/// Slider(value: Binding(get: { Double(duration) }, set: { duration = Int32($0) }), in: 1...300)
/// ```
///
/// 장점:
/// - ✅ 빠른 범위 이동
/// - ✅ 시각적 피드백
///
/// 단점:
/// - ❌ 정확한 값 입력 어려움
/// - ❌ 터치 영역이 작아 조작 까다로움
///
/// **3. Picker Wheel**:
/// ```swift
/// Picker("시간", selection: $duration) {
///     ForEach(1..<301) { Text("\($0)분").tag(Int32($0)) }
/// }
/// .pickerStyle(.wheel)
/// ```
///
/// 장점:
/// - ✅ 정확한 값 선택
/// - ✅ iOS 네이티브 느낌
///
/// 단점:
/// - ❌ 공간을 많이 차지
/// - ❌ 스크롤이 번거로움
///
/// **4. Hybrid Approach (이 컴포넌트)**:
/// ```swift
/// DurationInputView(duration: $duration)
/// ```
///
/// 장점:
/// - ✅ Quick Selection으로 빠른 입력
/// - ✅ Fine Adjustment로 정확한 조정
/// - ✅ 최소 공간 사용
/// - ✅ 직관적인 UI/UX
///
/// 단점:
/// - ❌ 코드가 더 복잡
///
/// ### 사용자 경험 최적화
///
/// **1. Haptic Feedback**:
/// ```swift
/// let generator = UIImpactFeedbackGenerator(style: .light)
/// generator.impactOccurred()
/// ```
///
/// - 버튼 탭 시 촉각 피드백
/// - 물리적 버튼을 누르는 느낌
/// - 값이 실제로 변경되었을 때만 발생
///
/// **2. Animation**:
/// ```swift
/// .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duration)
/// ```
///
/// - 시간이 변경될 때 부드러운 전환
/// - 스프링 애니메이션으로 자연스러움
/// - 사용자에게 변경사항 명확히 전달
///
/// **3. Visual Feedback**:
/// ```swift
/// let isSelected = duration == minutes
/// .foregroundStyle(isSelected ? .white : .blue)
/// .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
/// ```
///
/// - Quick Selection 버튼의 선택 상태 강조
/// - 현재 값과 일치하는 버튼 하이라이트
/// - 사용자 현재 위치 명확히 표시
///
/// ### Integration with ViewModel
///
/// ```swift
/// struct ExerciseInputView: View {
///     @State var viewModel: ExerciseInputViewModel
///
///     var body: some View {
///         VStack {
///             // 시간 입력
///             DurationInputView(
///                 duration: $viewModel.duration,
///                 onChange: { minutes in
///                     // 시간 변경 시 추가 로직
///                     print("Duration: \(minutes)분")
///                 }
///             )
///
///             // 실시간 칼로리 미리보기
///             // duration 변경 시 previewCalories 자동 재계산
///             Text("예상 소모: \(viewModel.previewCalories)kcal")
///                 .font(.headline)
///         }
///     }
/// }
/// ```
///
/// ### Accessibility Considerations
///
/// 현재 구현의 접근성:
/// - ✅ Button 사용으로 VoiceOver 자동 지원
/// - ✅ 큰 터치 영역으로 조작 용이
/// - ✅ 명확한 레이블과 값 표시
///
/// 추가 개선 가능:
/// ```swift
/// Button(action: { ... }) {
///     // ...
/// }
/// .accessibilityLabel("\(minutes)분 선택")
/// .accessibilityHint("탭하여 운동 시간을 \(minutes)분으로 설정")
/// ```
///
/// ### Best Practices
///
/// 1. **User-Centered Design**:
///    - 대부분의 사용자가 15, 30, 45, 60분 운동
///    - Quick Selection이 80%의 사용 케이스 커버
///
/// 2. **Progressive Enhancement**:
///    - 기본 입력 (Quick Selection) 먼저 제공
///    - 고급 입력 (Fine Adjustment) 나중에 제공
///
/// 3. **Clear Feedback**:
///    - 시각적 피드백 (애니메이션, 색상)
///    - 촉각 피드백 (햅틱)
///    - 청각 피드백 (시스템 사운드, 옵셔널)
///
/// 4. **Validation**:
///    - 입력 시점에 경계값 검증 (1-300분)
///    - 에러 메시지 명확히 표시
///
/// 5. **Reusability**:
///    - @Binding으로 어디서든 재사용 가능
///    - onChange 콜백으로 유연성 제공
///
