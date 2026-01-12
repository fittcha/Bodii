//
//  BodyCompositionInputCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Reusable UI Component
// SwiftUI의 재사용 가능한 카드 컴포넌트
// 💡 Java 비교: Android의 Custom View/Compose Component와 유사

import SwiftUI

// MARK: - BodyCompositionInputCard

/// 신체 구성 데이터 입력을 위한 재사용 가능한 카드 컴포넌트
/// 📚 학습 포인트: Component-Based Architecture
/// - 재사용 가능한 UI 컴포넌트로 코드 중복 제거
/// - @Binding을 통해 부모 뷰와 데이터 동기화
/// - 입력 검증 및 에러 메시지 표시 기능 내장
/// 💡 Java 비교: React Component, Android Compose Component와 유사
struct BodyCompositionInputCard: View {

    // MARK: - Binding Properties

    /// 체중 입력 바인딩 (kg)
    /// 📚 학습 포인트: @Binding
    /// - 부모 뷰의 상태와 양방향 바인딩
    /// - 이 컴포넌트에서 값을 변경하면 부모 뷰의 값도 변경됨
    /// 💡 Java 비교: Two-way data binding과 유사
    @Binding var weight: String

    /// 체지방률 입력 바인딩 (%)
    @Binding var bodyFatPercent: String

    /// 근육량 입력 바인딩 (kg)
    @Binding var muscleMass: String

    // MARK: - Optional Properties

    /// 검증 에러 메시지 배열
    /// 📚 학습 포인트: Optional Parameter
    /// - 부모 뷰에서 검증 메시지를 전달받아 표시
    /// - nil이거나 빈 배열이면 에러 메시지 미표시
    var validationMessages: [String]?

    /// 입력 필드가 활성화되어 있는지 여부
    /// 📚 학습 포인트: Disabled State
    /// - 로딩 중이거나 저장 중일 때 입력 필드 비활성화
    var isEnabled: Bool = true

    /// 입력 변경 시 호출되는 콜백
    /// 📚 학습 포인트: Callback Pattern
    /// - 입력이 변경될 때마다 부모 뷰에 알림
    /// - 실시간 검증에 사용
    /// 💡 Java 비교: Listener pattern과 유사
    var onInputChanged: (() -> Void)?

    // MARK: - Focus State

    /// 현재 포커스된 필드
    /// 📚 학습 포인트: @FocusState
    /// - SwiftUI에서 키보드 포커스 관리
    /// - 필드 간 이동 및 키보드 제어에 사용
    @FocusState private var focusedField: Field?

    /// 포커스 가능한 필드 열거형
    private enum Field: Hashable {
        case weight
        case bodyFatPercent
        case muscleMass
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: VStack (Vertical Stack)
        // 수직으로 뷰를 배치하는 컨테이너
        // 💡 Java 비교: LinearLayout with vertical orientation
        VStack(alignment: .leading, spacing: 16) {
            // 카드 헤더
            cardHeader

            // 입력 필드 섹션
            inputFieldsSection

            // 검증 에러 메시지 (있는 경우)
            if let messages = validationMessages, !messages.isEmpty {
                validationErrorsSection(messages: messages)
            }

            // 도움말 텍스트
            helpTextSection
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// 카드 헤더
    private var cardHeader: some View {
        HStack {
            // 📚 학습 포인트: SF Symbols
            // Apple이 제공하는 시스템 아이콘
            Image(systemName: "figure.stand")
                .font(.title2)
                .foregroundStyle(.blue)

            Text("신체 구성 입력")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()
        }
    }

    /// 입력 필드 섹션
    private var inputFieldsSection: some View {
        VStack(spacing: 12) {
            // 체중 입력 필드
            inputField(
                title: "체중",
                value: $weight,
                unit: "kg",
                placeholder: "예: 70.5",
                icon: "scalemass",
                field: .weight
            )

            // 체지방률 입력 필드
            inputField(
                title: "체지방률",
                value: $bodyFatPercent,
                unit: "%",
                placeholder: "예: 18.5",
                icon: "percent",
                field: .bodyFatPercent
            )

            // 근육량 입력 필드
            inputField(
                title: "근육량",
                value: $muscleMass,
                unit: "kg",
                placeholder: "예: 32.0",
                icon: "figure.strengthtraining.traditional",
                field: .muscleMass
            )
        }
    }

    /// 개별 입력 필드
    /// 📚 학습 포인트: Extracted View Function
    /// - 반복되는 UI 패턴을 함수로 추출
    /// - 코드 재사용성 향상
    ///
    /// - Parameters:
    ///   - title: 필드 제목
    ///   - value: 바인딩된 값
    ///   - unit: 단위 (kg, % 등)
    ///   - placeholder: 플레이스홀더 텍스트
    ///   - icon: SF Symbol 아이콘 이름
    ///   - field: 포커스 필드 식별자
    /// - Returns: 입력 필드 뷰
    private func inputField(
        title: String,
        value: Binding<String>,
        unit: String,
        placeholder: String,
        icon: String,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 필드 레이블
            Label {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 입력 필드와 단위
            HStack(spacing: 8) {
                // 📚 학습 포인트: TextField
                // 사용자 입력을 받는 텍스트 필드
                // 💡 Java 비교: EditText와 유사
                TextField(placeholder, text: value)
                    .keyboardType(.decimalPad)  // 숫자 + 소수점 키보드
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: field)
                    .disabled(!isEnabled)
                    .onChange(of: value.wrappedValue) { _, _ in
                        // 📚 학습 포인트: onChange Modifier
                        // 값이 변경될 때마다 콜백 호출
                        onInputChanged?()
                    }

                // 단위 표시
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .leading)
            }
        }
    }

    /// 검증 에러 메시지 섹션
    /// 📚 학습 포인트: Conditional View
    /// - 에러가 있을 때만 표시되는 섹션
    ///
    /// - Parameter messages: 에러 메시지 배열
    /// - Returns: 에러 메시지 뷰
    private func validationErrorsSection(messages: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 📚 학습 포인트: Divider
            // 섹션을 구분하는 구분선
            Divider()

            ForEach(messages, id: \.self) { message in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    /// 도움말 텍스트 섹션
    private var helpTextSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("입력 범위:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    Text("• 체중: 20-500 kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("• 체지방률: 1-60%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("• 근육량: 10-100 kg (체중보다 작아야 함)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
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
}

// MARK: - Convenience Initializers

extension BodyCompositionInputCard {
    /// 📚 학습 포인트: Convenience Initializer
    /// - 선택적 매개변수를 기본값으로 설정한 간편 생성자
    /// - 더 간단한 호출 방법 제공
    ///
    /// - Parameters:
    ///   - weight: 체중 바인딩
    ///   - bodyFatPercent: 체지방률 바인딩
    ///   - muscleMass: 근육량 바인딩
    init(
        weight: Binding<String>,
        bodyFatPercent: Binding<String>,
        muscleMass: Binding<String>
    ) {
        self._weight = weight
        self._bodyFatPercent = bodyFatPercent
        self._muscleMass = muscleMass
        self.validationMessages = nil
        self.isEnabled = true
        self.onInputChanged = nil
    }
}

// MARK: - Preview

#Preview("기본 상태") {
    // 📚 학습 포인트: @State in Preview
    // Preview에서 바인딩을 테스트하기 위한 상태 생성
    struct PreviewWrapper: View {
        @State private var weight = ""
        @State private var bodyFatPercent = ""
        @State private var muscleMass = ""

        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    BodyCompositionInputCard(
                        weight: $weight,
                        bodyFatPercent: $bodyFatPercent,
                        muscleMass: $muscleMass
                    )

                    Text("체중: \(weight.isEmpty ? "미입력" : weight) kg")
                        .font(.caption)
                    Text("체지방률: \(bodyFatPercent.isEmpty ? "미입력" : bodyFatPercent)%")
                        .font(.caption)
                    Text("근육량: \(muscleMass.isEmpty ? "미입력" : muscleMass) kg")
                        .font(.caption)
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("입력된 상태") {
    struct PreviewWrapper: View {
        @State private var weight = "70.5"
        @State private var bodyFatPercent = "18.5"
        @State private var muscleMass = "32.0"

        var body: some View {
            ScrollView {
                BodyCompositionInputCard(
                    weight: $weight,
                    bodyFatPercent: $bodyFatPercent,
                    muscleMass: $muscleMass
                )
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("에러 상태") {
    struct PreviewWrapper: View {
        @State private var weight = "600"
        @State private var bodyFatPercent = "80"
        @State private var muscleMass = "150"

        var body: some View {
            ScrollView {
                BodyCompositionInputCard(
                    weight: $weight,
                    bodyFatPercent: $bodyFatPercent,
                    muscleMass: $muscleMass,
                    validationMessages: [
                        "체중은 500kg 이하여야 합니다.",
                        "체지방률은 60% 이하여야 합니다.",
                        "근육량은 체중보다 작아야 합니다."
                    ]
                )
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("비활성화 상태") {
    struct PreviewWrapper: View {
        @State private var weight = "70.5"
        @State private var bodyFatPercent = "18.5"
        @State private var muscleMass = "32.0"

        var body: some View {
            ScrollView {
                BodyCompositionInputCard(
                    weight: $weight,
                    bodyFatPercent: $bodyFatPercent,
                    muscleMass: $muscleMass,
                    isEnabled: false
                )
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("다크 모드") {
    struct PreviewWrapper: View {
        @State private var weight = "70.5"
        @State private var bodyFatPercent = "18.5"
        @State private var muscleMass = "32.0"

        var body: some View {
            ScrollView {
                BodyCompositionInputCard(
                    weight: $weight,
                    bodyFatPercent: $bodyFatPercent,
                    muscleMass: $muscleMass
                )
                .padding()
            }
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}

// MARK: - Documentation

/// 📚 학습 포인트: BodyCompositionInputCard 사용법
///
/// 기본 사용:
/// ```swift
/// struct MyView: View {
///     @State private var weight = ""
///     @State private var bodyFatPercent = ""
///     @State private var muscleMass = ""
///
///     var body: some View {
///         BodyCompositionInputCard(
///             weight: $weight,
///             bodyFatPercent: $bodyFatPercent,
///             muscleMass: $muscleMass
///         )
///     }
/// }
/// ```
///
/// 검증 메시지와 함께 사용:
/// ```swift
/// struct MyView: View {
///     @State private var weight = ""
///     @State private var bodyFatPercent = ""
///     @State private var muscleMass = ""
///     @State private var errors: [String] = []
///
///     var body: some View {
///         BodyCompositionInputCard(
///             weight: $weight,
///             bodyFatPercent: $bodyFatPercent,
///             muscleMass: $muscleMass,
///             validationMessages: errors,
///             onInputChanged: {
///                 // 입력이 변경될 때마다 검증
///                 validateInputs()
///             }
///         )
///     }
///
///     func validateInputs() {
///         errors = []
///         if let w = Decimal(string: weight), w > 500 {
///             errors.append("체중은 500kg 이하여야 합니다.")
///         }
///         // ... 추가 검증
///     }
/// }
/// ```
///
/// ViewModel과 함께 사용:
/// ```swift
/// struct BodyCompositionView: View {
///     @StateObject private var viewModel: BodyCompositionViewModel
///
///     var body: some View {
///         BodyCompositionInputCard(
///             weight: $viewModel.weightInput,
///             bodyFatPercent: $viewModel.bodyFatPercentInput,
///             muscleMass: $viewModel.muscleMassInput,
///             validationMessages: viewModel.validationMessages,
///             isEnabled: !viewModel.isSaving,
///             onInputChanged: {
///                 viewModel.validateInputs()
///             }
///         )
///     }
/// }
/// ```
///
/// 주요 기능:
/// - @Binding을 통한 양방향 데이터 바인딩
/// - 숫자 키보드 (소수점 지원)
/// - 실시간 입력 검증
/// - 에러 메시지 표시
/// - 라이트/다크 모드 자동 대응
/// - 입력 필드 활성화/비활성화 제어
/// - 입력 변경 콜백 지원
///
/// 💡 Android 비교:
/// - Android: TextInputLayout + TextInputEditText
/// - SwiftUI: TextField with @Binding
/// - Android: LiveData + Two-way binding
/// - SwiftUI: @Binding for automatic sync
///
