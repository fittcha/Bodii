//
//  BodyCompositionInputCard.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

import SwiftUI

// MARK: - BodyCompositionInputCard

/// 신체 구성 데이터 입력을 위한 재사용 가능한 카드 컴포넌트
struct BodyCompositionInputCard: View {

    // MARK: - Binding Properties

    /// 체중 입력 바인딩 (kg)
    @Binding var weight: String

    /// 체지방률 입력 바인딩 (%)
    @Binding var bodyFatPercent: String

    /// 근육량 입력 바인딩 (kg)
    @Binding var muscleMass: String

    // MARK: - Optional Properties

    /// 검증 에러 메시지 배열
    var validationMessages: [String]?

    /// 입력 필드가 활성화되어 있는지 여부
    var isEnabled: Bool = true

    /// 입력 변경 시 호출되는 콜백
    var onInputChanged: (() -> Void)?

    // MARK: - Focus State

    /// 현재 포커스된 필드
    @FocusState private var focusedField: Field?

    /// 포커스 가능한 필드 열거형
    private enum Field: Hashable {
        case weight
        case bodyFatPercent
        case muscleMass
    }

    // MARK: - Body

    var body: some View {
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
                TextField(placeholder, text: value)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: field)
                    .disabled(!isEnabled)
                    .onChange(of: value.wrappedValue) { _, _ in
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
    private func validationErrorsSection(messages: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
    /// 간편 생성자
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
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}
