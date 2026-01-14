//
//  ExerciseTypeGridView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Selectable Grid Pattern
// 선택 가능한 그리드 컴포넌트 설계
// 💡 Java 비교: RecyclerView with GridLayoutManager와 유사

import SwiftUI

// MARK: - Exercise Type Grid View

/// 운동 종류 선택 그리드 컴포넌트
///
/// 8가지 운동 종류를 그리드 형태로 표시하고, 사용자가 하나를 선택할 수 있습니다.
///
/// **표시 내용:**
/// - 모든 운동 종류 (ExerciseType.allCases)
/// - 각 운동의 아이콘 (SF Symbols)
/// - 각 운동의 한글 이름
///
/// **기능:**
/// - 단일 선택 (Single Selection)
/// - 선택 상태 시각적 피드백
/// - 탭 애니메이션
///
/// - Example:
/// ```swift
/// ExerciseTypeGridView(
///     selectedType: $viewModel.selectedExerciseType,
///     onSelect: { type in
///         viewModel.selectExerciseType(type)
///     }
/// )
/// ```
struct ExerciseTypeGridView: View {

    // MARK: - Properties

    // 📚 학습 포인트: @Binding for Two-Way Data Flow
    // 부모 View의 상태를 읽고 쓸 수 있는 양방향 바인딩
    // 💡 Java 비교: LiveData with Observer와 유사하지만 양방향

    /// 현재 선택된 운동 종류
    @Binding var selectedType: ExerciseType

    /// 선택 시 실행할 액션 핸들러 (옵셔널)
    let onSelect: ((ExerciseType) -> Void)?

    // MARK: - Layout Configuration

    // 📚 학습 포인트: Grid Layout Configuration
    // LazyVGrid는 flexible 또는 fixed width column을 사용
    // adaptive는 화면 크기에 따라 자동으로 열 개수 조정

    /// 그리드 컬럼 레이아웃
    ///
    /// - adaptive: 최소 100pt 크기로 화면에 맞게 자동 조정
    /// - 보통 iPhone에서 3-4열, iPad에서 6-8열 표시
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]

    // MARK: - Initialization

    /// ExerciseTypeGridView 초기화
    ///
    /// - Parameters:
    ///   - selectedType: 현재 선택된 운동 종류 (바인딩)
    ///   - onSelect: 선택 시 실행할 액션 (옵셔널)
    init(
        selectedType: Binding<ExerciseType>,
        onSelect: ((ExerciseType) -> Void)? = nil
    ) {
        self._selectedType = selectedType
        self.onSelect = onSelect
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: LazyVGrid
        // 필요할 때만 View를 생성하는 효율적인 그리드 레이아웃
        // 💡 Java 비교: RecyclerView의 뷰 재사용과 유사
        LazyVGrid(columns: columns, spacing: 12) {
            // 📚 학습 포인트: ForEach with CaseIterable
            // ExerciseType.allCases로 모든 케이스를 순회
            // id: \.self는 각 case를 고유 식별자로 사용
            ForEach(ExerciseType.allCases, id: \.self) { exerciseType in
                exerciseTypeButton(for: exerciseType)
            }
        }
    }

    // MARK: - View Components

    /// 운동 종류 버튼
    ///
    /// - Parameter exerciseType: 표시할 운동 종류
    /// - Returns: 버튼 뷰
    @ViewBuilder
    private func exerciseTypeButton(for exerciseType: ExerciseType) -> some View {
        let isSelected = selectedType == exerciseType

        // 📚 학습 포인트: Button with Custom Styling
        // SwiftUI의 Button은 onTapGesture와 달리 접근성 기능이 자동 지원됨
        Button(action: {
            handleSelection(exerciseType)
        }) {
            VStack(spacing: 8) {
                // 아이콘
                Image(systemName: exerciseType.systemIconName)
                    .font(.system(size: 32))
                    .foregroundStyle(
                        isSelected ? .white : exerciseType.accentColor
                    )
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                isSelected
                                    ? exerciseType.accentColor
                                    : exerciseType.accentColor.opacity(0.1)
                            )
                    )

                // 운동 종류 이름
                Text(exerciseType.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(
                        isSelected ? exerciseType.accentColor : .primary
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? exerciseType.accentColor.opacity(0.1)
                            : Color(.systemBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? exerciseType.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(
                color: isSelected
                    ? exerciseType.accentColor.opacity(0.3)
                    : .black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain) // 기본 버튼 스타일 제거하여 커스텀 스타일 적용
        // 📚 학습 포인트: Animation Modifier
        // 상태 변경 시 자동으로 애니메이션 적용
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Actions

    /// 운동 종류 선택 처리
    ///
    /// - Parameter exerciseType: 선택된 운동 종류
    private func handleSelection(_ exerciseType: ExerciseType) {
        // 📚 학습 포인트: Haptic Feedback
        // 사용자 인터랙션에 촉각 피드백 제공
        // 💡 Java 비교: Vibrator 서비스와 유사
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // 선택 상태 업데이트
        selectedType = exerciseType

        // 콜백 실행 (있는 경우)
        onSelect?(exerciseType)
    }
}

// MARK: - Preview

#Preview("Exercise Type Grid") {
    // 📚 학습 포인트: @State in Preview
    // Preview에서 상태 관리를 위한 @State 사용
    struct PreviewWrapper: View {
        @State private var selectedType: ExerciseType = .running

        var body: some View {
            VStack(spacing: 20) {
                // 선택된 운동 정보 표시
                VStack(spacing: 8) {
                    Text("선택된 운동")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: selectedType.systemIconName)
                            .font(.title)
                            .foregroundStyle(selectedType.accentColor)

                        Text(selectedType.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding()

                // 운동 종류 그리드
                ScrollView {
                    ExerciseTypeGridView(
                        selectedType: $selectedType,
                        onSelect: { type in
                            print("Selected: \(type.displayName)")
                        }
                    )
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    return PreviewWrapper()
}

#Preview("All Exercise Types") {
    ScrollView {
        VStack(spacing: 16) {
            Text("모든 운동 종류")
                .font(.headline)

            // 각 운동 종류를 개별적으로 표시하여 모든 아이콘과 색상 확인
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(ExerciseType.allCases, id: \.self) { type in
                    VStack(spacing: 8) {
                        Image(systemName: type.systemIconName)
                            .font(.system(size: 32))
                            .foregroundStyle(type.accentColor)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(type.accentColor.opacity(0.1))
                            )

                        Text(type.displayName)
                            .font(.caption)

                        Text("\(type.baseMET, specifier: "%.1f") MET")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
    }
    .background(Color(.systemGroupedBackground))
}

// MARK: - Learning Notes

/// ## Selectable Grid Pattern
///
/// 선택 가능한 그리드는 사용자가 여러 옵션 중 하나 또는 여러 개를 선택할 수 있는 UI 패턴입니다.
///
/// ### 주요 구성 요소
///
/// 1. **LazyVGrid Layout**:
///    ```swift
///    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
///        // 아이템들
///    }
///    ```
///    - `.adaptive(minimum:)`: 화면 크기에 맞게 열 개수 자동 조정
///    - `.flexible()`: 고정된 열 개수로 너비 균등 분배
///    - `.fixed()`: 고정된 너비의 열
///
/// 2. **Selection State**:
///    ```swift
///    @Binding var selectedType: ExerciseType
///    let isSelected = selectedType == exerciseType
///    ```
///    - @Binding으로 부모 View와 상태 공유
///    - 선택 상태에 따라 다른 스타일 적용
///
/// 3. **Visual Feedback**:
///    - 선택된 항목: 배경색, 테두리, 그림자 강조
///    - 선택되지 않은 항목: 기본 스타일
///    - 애니메이션: 상태 전환 시 부드러운 효과
///
/// 4. **Haptic Feedback**:
///    ```swift
///    let generator = UIImpactFeedbackGenerator(style: .light)
///    generator.impactOccurred()
///    ```
///    - 탭 시 촉각 피드백으로 사용자 경험 향상
///
/// ### SwiftUI의 그리드 레이아웃
///
/// **LazyVGrid vs VStack + HStack**:
///
/// LazyVGrid:
/// - ✅ 성능: 필요할 때만 View 생성
/// - ✅ 유연성: 화면 크기에 자동 대응
/// - ✅ 간결성: 코드가 단순함
///
/// VStack + HStack:
/// - ❌ 성능: 모든 View 미리 생성
/// - ❌ 복잡성: 수동으로 행/열 관리
/// - ✅ 제어: 세밀한 레이아웃 조정 가능
///
/// ### Selection Pattern 비교
///
/// **Single Selection** (이 컴포넌트):
/// ```swift
/// @Binding var selectedType: ExerciseType
/// let isSelected = selectedType == exerciseType
/// ```
///
/// **Multiple Selection**:
/// ```swift
/// @Binding var selectedTypes: Set<ExerciseType>
/// let isSelected = selectedTypes.contains(exerciseType)
///
/// // 토글 로직
/// if isSelected {
///     selectedTypes.remove(exerciseType)
/// } else {
///     selectedTypes.insert(exerciseType)
/// }
/// ```
///
/// ### Styling Pattern
///
/// **조건부 스타일링**:
/// ```swift
/// .foregroundStyle(isSelected ? .white : exerciseType.accentColor)
/// .background(isSelected ? exerciseType.accentColor : .clear)
/// .overlay(
///     RoundedRectangle(cornerRadius: 12)
///         .stroke(isSelected ? exerciseType.accentColor : .clear, lineWidth: 2)
/// )
/// ```
///
/// 이 패턴은:
/// - 선택 상태를 시각적으로 명확히 구분
/// - 각 운동 종류의 고유 색상 활용
/// - 일관된 디자인 언어 유지
///
/// ### Animation
///
/// **Spring Animation**:
/// ```swift
/// .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
/// ```
///
/// - `response`: 애니메이션 지속 시간 (0.3초)
/// - `dampingFraction`: 감쇠 비율 (0.7 = 약간 튕김)
/// - `value`: 이 값이 변경될 때만 애니메이션 실행
///
/// ### Integration with ViewModel
///
/// ```swift
/// struct ExerciseInputView: View {
///     @State var viewModel: ExerciseInputViewModel
///
///     var body: some View {
///         VStack {
///             ExerciseTypeGridView(
///                 selectedType: $viewModel.selectedExerciseType,
///                 onSelect: { type in
///                     // 추가 로직 실행 (옵셔널)
///                     print("User selected: \(type.displayName)")
///                 }
///             )
///
///             // 실시간 칼로리 미리보기
///             // selectedExerciseType 변경 시 previewCalories 자동 재계산
///             Text("예상 소모: \(viewModel.previewCalories)kcal")
///         }
///     }
/// }
/// ```
///
/// ### Accessibility
///
/// Button 사용의 장점:
/// - VoiceOver 자동 지원
/// - 키보드 네비게이션 가능
/// - Dynamic Type 자동 적용
///
/// 추가 개선 가능:
/// ```swift
/// .accessibilityLabel("\(exerciseType.displayName), \(isSelected ? "선택됨" : "선택되지 않음")")
/// .accessibilityHint("탭하여 운동 종류 선택")
/// ```
///
/// ### Best Practices
///
/// 1. **Performance**:
///    - LazyVGrid 사용으로 성능 최적화
///    - 8개 항목은 적은 수이지만 확장성 고려
///
/// 2. **Reusability**:
///    - @Binding으로 어떤 부모 View에서도 사용 가능
///    - onSelect 콜백으로 추가 로직 지원
///
/// 3. **Visual Consistency**:
///    - ExerciseType.accentColor 재사용
///    - ExerciseType.systemIconName 재사용
///    - 전체 앱에서 일관된 디자인 유지
///
/// 4. **User Experience**:
///    - 햅틱 피드백으로 상호작용 강화
///    - 애니메이션으로 부드러운 전환
///    - 명확한 선택 상태 표시
///
