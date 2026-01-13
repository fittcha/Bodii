//
//  ServingSizePicker.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Serving Size Picker Component
// 섭취량 선택 컴포넌트 - 프리셋 배수와 커스텀 입력
// 💡 빠른 선택을 위한 프리셋 버튼과 정확한 입력을 위한 커스텀 필드 제공

import SwiftUI

/// 섭취량 선택 컴포넌트
///
/// 프리셋 배수 버튼과 커스텀 수량 입력 필드를 제공하는 재사용 가능한 컴포넌트입니다.
///
/// - Note: 인분(serving)과 그램(grams) 단위를 지원합니다.
/// - Note: 프리셋 배수(0.25x, 0.5x, 1x, 1.5x, 2x)로 빠르게 선택할 수 있습니다.
/// - Note: 커스텀 입력 필드로 정확한 수량을 입력할 수 있습니다.
///
/// - Example:
/// ```swift
/// ServingSizePicker(
///     quantity: $viewModel.quantity,
///     quantityUnit: $viewModel.quantityUnit,
///     quantityError: viewModel.quantityError,
///     presetMultipliers: [0.25, 0.5, 1.0, 1.5, 2.0],
///     onSetQuantityMultiplier: { multiplier in
///         viewModel.setQuantityMultiplier(multiplier)
///     },
///     onChangeUnit: { newUnit in
///         viewModel.changeUnit(to: newUnit)
///     }
/// )
/// ```
struct ServingSizePicker: View {

    // MARK: - Properties

    /// 섭취량 (Binding)
    @Binding var quantity: Decimal

    /// 섭취량 단위 (Binding)
    @Binding var quantityUnit: QuantityUnit

    /// 수량 유효성 검증 에러 메시지
    let quantityError: String?

    /// 프리셋 배수 목록
    let presetMultipliers: [Decimal]

    /// 프리셋 배수 선택 시 호출되는 콜백
    let onSetQuantityMultiplier: (Decimal) -> Void

    /// 단위 변경 시 호출되는 콜백
    let onChangeUnit: (QuantityUnit) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 헤더
            Text("섭취량")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            VStack(spacing: 16) {
                // 프리셋 배수 버튼
                presetButtonsSection

                Divider()

                // 커스텀 수량 입력
                customInputSection
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Subviews

    /// 프리셋 배수 버튼 섹션
    ///
    /// 빠른 선택을 위한 프리셋 배수 버튼들을 표시합니다.
    private var presetButtonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("빠른 선택")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(presetMultipliers, id: \.self) { multiplier in
                    presetButton(multiplier: multiplier)
                }
            }
        }
    }

    /// 커스텀 수량 입력 섹션
    ///
    /// 직접 입력을 위한 텍스트 필드와 단위 선택 피커를 표시합니다.
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("직접 입력")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // 수량 입력 필드
                TextField("수량", value: $quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)

                // 단위 선택 (인분 / 그램)
                Picker("단위", selection: $quantityUnit) {
                    ForEach(QuantityUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: quantityUnit) { oldValue, newValue in
                    if oldValue != newValue {
                        onChangeUnit(newValue)
                    }
                }

                Spacer()
            }

            // 유효성 검증 에러 메시지
            if let quantityError = quantityError {
                Text(quantityError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    /// 프리셋 배수 버튼
    ///
    /// 빠른 선택을 위한 프리셋 배수 버튼입니다.
    ///
    /// - Parameter multiplier: 배수 값
    /// - Returns: 프리셋 버튼 뷰
    private func presetButton(multiplier: Decimal) -> some View {
        Button(action: {
            onSetQuantityMultiplier(multiplier)
        }) {
            Text("\(formatMultiplier(multiplier))x")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(
                    isServingBased && quantity == multiplier
                        ? .white
                        : .primary
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isServingBased && quantity == multiplier
                        ? Color.blue
                        : Color(.systemGray5)
                )
                .cornerRadius(8)
        }
    }

    // MARK: - Helpers

    /// 현재 섭취량이 인분 기준인지 여부
    private var isServingBased: Bool {
        quantityUnit == .serving
    }

    /// 배수 값을 포맷팅
    ///
    /// 배수 값을 간결하게 표시합니다 (예: 0.25, 0.5, 1, 1.5, 2)
    ///
    /// - Parameter value: 배수 값
    /// - Returns: 포맷팅된 문자열
    private func formatMultiplier(_ value: Decimal) -> String {
        let nsDecimal = value as NSDecimalNumber
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: nsDecimal) ?? "1"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // 인분 단위 예시 (1.0인분 선택됨)
        ServingSizePicker(
            quantity: .constant(1.0),
            quantityUnit: .constant(.serving),
            quantityError: nil,
            presetMultipliers: [0.25, 0.5, 1.0, 1.5, 2.0],
            onSetQuantityMultiplier: { multiplier in
                print("Set multiplier: \(multiplier)")
            },
            onChangeUnit: { newUnit in
                print("Change unit to: \(newUnit)")
            }
        )

        // 그램 단위 예시 (150g 입력됨)
        ServingSizePicker(
            quantity: .constant(150),
            quantityUnit: .constant(.grams),
            quantityError: nil,
            presetMultipliers: [0.25, 0.5, 1.0, 1.5, 2.0],
            onSetQuantityMultiplier: { multiplier in
                print("Set multiplier: \(multiplier)")
            },
            onChangeUnit: { newUnit in
                print("Change unit to: \(newUnit)")
            }
        )

        // 에러 상태 예시
        ServingSizePicker(
            quantity: .constant(0.05),
            quantityUnit: .constant(.serving),
            quantityError: "섭취량은 최소 0.1 이상이어야 합니다.",
            presetMultipliers: [0.25, 0.5, 1.0, 1.5, 2.0],
            onSetQuantityMultiplier: { multiplier in
                print("Set multiplier: \(multiplier)")
            },
            onChangeUnit: { newUnit in
                print("Change unit to: \(newUnit)")
            }
        )

        // 프리셋 선택됨 (0.5x)
        ServingSizePicker(
            quantity: .constant(0.5),
            quantityUnit: .constant(.serving),
            quantityError: nil,
            presetMultipliers: [0.25, 0.5, 1.0, 1.5, 2.0],
            onSetQuantityMultiplier: { multiplier in
                print("Set multiplier: \(multiplier)")
            },
            onChangeUnit: { newUnit in
                print("Change unit to: \(newUnit)")
            }
        )
    }
    .background(Color(.systemGroupedBackground))
}
