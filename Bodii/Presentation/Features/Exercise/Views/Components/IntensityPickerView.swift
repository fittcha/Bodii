//
//  IntensityPickerView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Segmented Control Pattern
// 세그먼트 컨트롤 스타일의 선택 컴포넌트 설계
// 💡 Java 비교: SegmentedButton (Material Design 3)와 유사

import SwiftUI

// MARK: - Intensity Picker View

/// 운동 강도 선택 컴포넌트
///
/// 3가지 강도(저/중/고)를 세그먼트 컨트롤 형태로 표시하고, 사용자가 하나를 선택할 수 있습니다.
///
/// **표시 내용:**
/// - 저강도 (MET × 0.8)
/// - 중강도 (MET × 1.0) - 기본값
/// - 고강도 (MET × 1.2)
///
/// **기능:**
/// - 단일 선택 (Single Selection)
/// - 선택 상태 시각적 피드백
/// - 탭 애니메이션
/// - 선택적 MET 배수 정보 표시
///
/// - Example:
/// ```swift
/// IntensityPickerView(
///     selectedIntensity: $viewModel.selectedIntensity,
///     showMetMultiplier: true,
///     onSelect: { intensity in
///         viewModel.selectIntensity(intensity)
///     }
/// )
/// ```
struct IntensityPickerView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @Binding for Two-Way Data Flow
    // 부모 View의 상태를 읽고 쓸 수 있는 양방향 바인딩
    // 💡 Java 비교: LiveData with Observer와 유사하지만 양방향

    /// 현재 선택된 강도
    @Binding var selectedIntensity: Intensity

    /// MET 배수 정보 표시 여부
    let showMetMultiplier: Bool

    /// 선택 시 실행할 액션 핸들러 (옵셔널)
    let onSelect: ((Intensity) -> Void)?

    // MARK: - Initialization

    /// IntensityPickerView 초기화
    ///
    /// - Parameters:
    ///   - selectedIntensity: 현재 선택된 강도 (바인딩)
    ///   - showMetMultiplier: MET 배수 정보 표시 여부 (기본값: false)
    ///   - onSelect: 선택 시 실행할 액션 (옵셔널)
    init(
        selectedIntensity: Binding<Intensity>,
        showMetMultiplier: Bool = false,
        onSelect: ((Intensity) -> Void)? = nil
    ) {
        self._selectedIntensity = selectedIntensity
        self.showMetMultiplier = showMetMultiplier
        self.onSelect = onSelect
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // 📚 학습 포인트: HStack for Horizontal Layout
            // 세그먼트 컨트롤은 수평으로 배치된 버튼들의 조합
            HStack(spacing: 0) {
                // 📚 학습 포인트: ForEach with CaseIterable
                // Intensity.allCases로 모든 케이스를 순회
                ForEach(Intensity.allCases) { intensity in
                    intensityButton(for: intensity)
                }
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // MET 배수 정보 (선택사항)
            if showMetMultiplier {
                metMultiplierInfo
            }
        }
    }

    // MARK: - View Components

    /// 강도 버튼
    ///
    /// - Parameter intensity: 표시할 강도
    /// - Returns: 버튼 뷰
    @ViewBuilder
    private func intensityButton(for intensity: Intensity) -> some View {
        let isSelected = selectedIntensity == intensity

        // 📚 학습 포인트: Button with Custom Styling
        // SwiftUI의 Button은 onTapGesture와 달리 접근성 기능이 자동 지원됨
        Button(action: {
            handleSelection(intensity)
        }) {
            VStack(spacing: 4) {
                // 강도 이름
                Text(intensity.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                // 선택된 상태일 때 아이콘 표시
                if isSelected {
                    intensityIcon(for: intensity)
                        .font(.caption2)
                }
            }
            .foregroundStyle(
                isSelected ? .white : intensity.accentColor
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected
                            ? intensity.accentColor
                            : Color.clear
                    )
            )
            // 📚 학습 포인트: Padding for Segmented Style
            // 세그먼트 간 간격을 위한 padding
            .padding(4)
        }
        .buttonStyle(.plain) // 기본 버튼 스타일 제거하여 커스텀 스타일 적용
        // 📚 학습 포인트: Animation Modifier
        // 상태 변경 시 자동으로 애니메이션 적용
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    /// 강도에 따른 아이콘
    ///
    /// - Parameter intensity: 강도
    /// - Returns: SF Symbol 아이콘 이름
    @ViewBuilder
    private func intensityIcon(for intensity: Intensity) -> some View {
        switch intensity {
        case .low:
            Image(systemName: "hare.fill")
        case .medium:
            Image(systemName: "figure.walk")
        case .high:
            Image(systemName: "bolt.fill")
        }
    }

    /// MET 배수 정보 표시
    @ViewBuilder
    private var metMultiplierInfo: some View {
        HStack(spacing: 0) {
            ForEach(Intensity.allCases) { intensity in
                Text("×\(intensity.metMultiplier, specifier: "%.1f")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Actions

    /// 강도 선택 처리
    ///
    /// - Parameter intensity: 선택된 강도
    private func handleSelection(_ intensity: Intensity) {
        // 이미 선택된 항목을 다시 탭한 경우 무시
        guard selectedIntensity != intensity else { return }

        // 📚 학습 포인트: Haptic Feedback
        // 사용자 인터랙션에 촉각 피드백 제공
        // 💡 Java 비교: Vibrator 서비스와 유사
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // 선택 상태 업데이트
        selectedIntensity = intensity

        // 콜백 실행 (있는 경우)
        onSelect?(intensity)
    }
}

// MARK: - Intensity Extension

extension Intensity {

    /// 강도별 강조 색상
    ///
    /// - 저강도: 녹색 (가볍고 편안함)
    /// - 중강도: 주황색 (보통 노력)
    /// - 고강도: 빨간색 (격렬하고 힘듦)
    var accentColor: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Preview

#Preview("Intensity Picker") {
    // 📚 학습 포인트: @State in Preview
    // Preview에서 상태 관리를 위한 @State 사용
    struct PreviewWrapper: View {
        @State private var selectedIntensity: Intensity = .medium

        var body: some View {
            VStack(spacing: 24) {
                // 선택된 강도 정보 표시
                VStack(spacing: 8) {
                    Text("선택된 강도")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text(selectedIntensity.displayName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("MET ×\(selectedIntensity.metMultiplier, specifier: "%.1f")")
                            .font(.title3)
                            .foregroundStyle(.secondary)
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

                // 강도 선택기 (MET 배수 없음)
                VStack(alignment: .leading, spacing: 8) {
                    Text("기본 스타일")
                        .font(.headline)
                        .padding(.horizontal)

                    IntensityPickerView(
                        selectedIntensity: $selectedIntensity,
                        showMetMultiplier: false,
                        onSelect: { intensity in
                            print("Selected: \(intensity.displayName)")
                        }
                    )
                    .padding(.horizontal)
                }

                // 강도 선택기 (MET 배수 포함)
                VStack(alignment: .leading, spacing: 8) {
                    Text("MET 배수 표시")
                        .font(.headline)
                        .padding(.horizontal)

                    IntensityPickerView(
                        selectedIntensity: $selectedIntensity,
                        showMetMultiplier: true
                    )
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("All Intensities") {
    ScrollView {
        VStack(spacing: 24) {
            Text("모든 강도 레벨")
                .font(.headline)

            // 각 강도를 개별적으로 표시
            ForEach(Intensity.allCases) { intensity in
                VStack(spacing: 12) {
                    HStack {
                        Text(intensity.displayName)
                            .font(.title3)
                            .fontWeight(.bold)

                        Spacer()

                        Text("MET ×\(intensity.metMultiplier, specifier: "%.1f")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    IntensityPickerView(
                        selectedIntensity: .constant(intensity),
                        showMetMultiplier: true
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Interactive Demo") {
    struct PreviewWrapper: View {
        @State private var selectedIntensity: Intensity = .medium
        @State private var duration: Int = 30
        @State private var userWeight: Double = 70.0

        var body: some View {
            VStack(spacing: 24) {
                // 상단 정보 카드
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("운동 시간")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(duration)분")
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("체중")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(userWeight, specifier: "%.1f")kg")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    Divider()

                    // 강도 선택기
                    VStack(alignment: .leading, spacing: 8) {
                        Text("운동 강도")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        IntensityPickerView(
                            selectedIntensity: $selectedIntensity,
                            showMetMultiplier: true
                        )
                    }

                    Divider()

                    // 예상 칼로리 계산 (간단한 시뮬레이션)
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("예상 소모 칼로리")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            let baseMET = 6.0 // 예시: 중간 강도 유산소 운동
                            let adjustedMET = baseMET * selectedIntensity.metMultiplier
                            let hours = Double(duration) / 60.0
                            let calories = Int(adjustedMET * userWeight * hours)

                            Text("\(calories) kcal")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(selectedIntensity.accentColor)
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

                // 슬라이더로 시간 조정
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동 시간 조정")
                        .font(.headline)

                    Slider(value: Binding(
                        get: { Double(duration) },
                        set: { duration = Int($0) }
                    ), in: 5...120, step: 5)
                }
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

/// ## Segmented Control Pattern
///
/// 세그먼트 컨트롤은 관련된 몇 개의 옵션 중 하나를 선택하는 UI 패턴입니다.
///
/// ### 주요 특징
///
/// 1. **Mutually Exclusive Selection**:
///    - 여러 옵션 중 하나만 선택 가능
///    - 항상 하나의 옵션이 선택된 상태 유지
///
/// 2. **Visual Grouping**:
///    - 관련된 옵션들이 하나의 그룹으로 표시
///    - 선택된 항목이 명확히 구분됨
///
/// 3. **Limited Options**:
///    - 보통 2-5개의 옵션에 적합
///    - 너무 많은 옵션은 Picker나 List 사용 권장
///
/// ### 구현 방식 비교
///
/// **1. Native Picker (Segmented Style)**:
/// ```swift
/// Picker("강도", selection: $selectedIntensity) {
///     ForEach(Intensity.allCases) { intensity in
///         Text(intensity.displayName).tag(intensity)
///     }
/// }
/// .pickerStyle(.segmented)
/// ```
///
/// 장점:
/// - ✅ 간결한 코드
/// - ✅ iOS 네이티브 스타일
///
/// 단점:
/// - ❌ 커스터마이징 제한적
/// - ❌ 추가 정보 표시 어려움 (MET 배수 등)
/// - ❌ 아이콘 추가 불가
///
/// **2. Custom Segmented Control (이 컴포넌트)**:
/// ```swift
/// IntensityPickerView(
///     selectedIntensity: $selectedIntensity,
///     showMetMultiplier: true
/// )
/// ```
///
/// 장점:
/// - ✅ 완전한 커스터마이징 가능
/// - ✅ 아이콘, 색상, 애니메이션 자유롭게 조절
/// - ✅ 추가 정보 표시 가능 (MET 배수)
/// - ✅ 햅틱 피드백 추가 가능
///
/// 단점:
/// - ❌ 코드가 더 복잡
/// - ❌ 접근성 기능 직접 구현 필요
///
/// ### 색상 코딩 전략
///
/// 강도별로 의미 있는 색상을 사용하여 직관성을 높임:
///
/// ```swift
/// extension Intensity {
///     var accentColor: Color {
///         switch self {
///         case .low:    return .green   // 안전, 편안함
///         case .medium: return .orange  // 적당한 노력
///         case .high:   return .red     // 격렬함, 주의
///         }
///     }
/// }
/// ```
///
/// 이 색상 체계는:
/// - 신호등 색상과 유사하여 직관적
/// - 심박수 존 색상과 일치
/// - 국제적으로 널리 사용되는 강도 표현 방식
///
/// ### Layout Pattern
///
/// **HStack with Equal Width Distribution**:
/// ```swift
/// HStack(spacing: 0) {
///     ForEach(Intensity.allCases) { intensity in
///         // 각 버튼
///             .frame(maxWidth: .infinity)  // 균등 분배
///     }
/// }
/// ```
///
/// - `spacing: 0`: 버튼 간 간격 제거
/// - `.frame(maxWidth: .infinity)`: 남은 공간을 균등 분배
/// - `.padding(4)`: 각 버튼에 내부 여백 추가
///
/// 결과: 3개의 버튼이 정확히 1:1:1 비율로 분배
///
/// ### Animation Strategy
///
/// **Spring Animation for Natural Feel**:
/// ```swift
/// .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
/// ```
///
/// - `response: 0.3`: 빠른 반응 (0.3초)
/// - `dampingFraction: 0.7`: 약간의 튕김 효과
/// - `value: isSelected`: 이 값이 변경될 때만 애니메이션
///
/// 스프링 애니메이션을 사용하는 이유:
/// - 더 자연스러운 움직임
/// - iOS 네이티브 느낌
/// - 사용자 입력에 즉각 반응
///
/// ### Haptic Feedback Best Practices
///
/// ```swift
/// private func handleSelection(_ intensity: Intensity) {
///     guard selectedIntensity != intensity else { return }  // 중복 방지
///
///     let generator = UIImpactFeedbackGenerator(style: .light)
///     generator.impactOccurred()
///
///     selectedIntensity = intensity
/// }
/// ```
///
/// **햅틱 피드백 가이드라인**:
/// - ✅ 선택 변경 시에만 발생 (중복 탭 무시)
/// - ✅ .light 스타일: 가벼운 탭 느낌
/// - ✅ 애니메이션과 동시 발생
///
/// **햅틱 스타일 선택**:
/// - `.light`: 가벼운 선택 (이 경우 적합)
/// - `.medium`: 중간 강도 선택
/// - `.heavy`: 중요한 액션
/// - `.rigid`: 단단한 느낌
/// - `.soft`: 부드러운 느낌
///
/// ### Integration with Form
///
/// ```swift
/// struct ExerciseInputView: View {
///     @State var viewModel: ExerciseInputViewModel
///
///     var body: some View {
///         VStack(spacing: 20) {
///             // 강도 선택
///             IntensityPickerView(
///                 selectedIntensity: $viewModel.selectedIntensity,
///                 showMetMultiplier: true,
///                 onSelect: { intensity in
///                     // 선택 시 추가 로직 (옵셔널)
///                     print("강도 변경: \(intensity.displayName)")
///                 }
///             )
///
///             // 실시간 칼로리 미리보기
///             // selectedIntensity 변경 시 previewCalories 자동 재계산
///             Text("예상 소모: \(viewModel.previewCalories)kcal")
///                 .font(.headline)
///         }
///     }
/// }
/// ```
///
/// ### Accessibility Considerations
///
/// 현재 구현의 접근성 개선 방안:
///
/// ```swift
/// Button(action: { ... }) {
///     // ...
/// }
/// .accessibilityLabel("\(intensity.displayName), MET 배수 \(intensity.metMultiplier)")
/// .accessibilityHint("탭하여 운동 강도 선택")
/// .accessibilityAddTraits(isSelected ? [.isSelected] : [])
/// ```
///
/// 추가 개선 사항:
/// - VoiceOver 지원 강화
/// - Dynamic Type 지원
/// - Reduce Motion 설정 감지
///
/// ### Best Practices
///
/// 1. **Visual Clarity**:
///    - 선택된 항목이 명확히 구분되도록 충분한 대비
///    - 색상만 의존하지 않고 형태로도 구분 (배경색 + 텍스트 굵기)
///
/// 2. **Performance**:
///    - 간단한 3개 버튼이므로 성능 이슈 없음
///    - 애니메이션도 가벼워서 부담 없음
///
/// 3. **Reusability**:
///    - @Binding으로 어떤 부모 View에서도 사용 가능
///    - showMetMultiplier 옵션으로 유연성 제공
///
/// 4. **Consistency**:
///    - Intensity.accentColor 확장으로 색상 일관성 유지
///    - 앱 전체에서 강도 색상 재사용 가능
///
/// 5. **User Experience**:
///    - 햅틱 피드백으로 물리적 버튼 느낌
///    - 스프링 애니메이션으로 자연스러운 전환
///    - MET 배수 정보로 사용자 이해도 향상
///
