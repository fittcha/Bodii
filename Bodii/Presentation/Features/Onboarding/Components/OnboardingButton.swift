//
//  OnboardingButton.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-20.
//

import SwiftUI

/// 온보딩 공통 버튼
/// Primary/Secondary 스타일 지원
struct OnboardingButton: View {
    /// 버튼 스타일
    enum Style {
        case primary
        case secondary
    }

    let title: String
    var style: Style = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(backgroundColor)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? .blue : .gray.opacity(0.3)
        case .secondary:
            return .gray.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return isEnabled ? .white : .gray
        case .secondary:
            return .primary
        }
    }
}

// MARK: - Preview

#Preview("Primary Enabled") {
    OnboardingButton(title: "다음", style: .primary, isEnabled: true) {
        print("Tapped")
    }
    .padding()
}

#Preview("Primary Disabled") {
    OnboardingButton(title: "다음", style: .primary, isEnabled: false) {
        print("Tapped")
    }
    .padding()
}

#Preview("Secondary") {
    OnboardingButton(title: "이전", style: .secondary, isEnabled: true) {
        print("Tapped")
    }
    .padding()
}

#Preview("Button Group") {
    HStack(spacing: 16) {
        OnboardingButton(title: "이전", style: .secondary) {
            print("Previous")
        }

        OnboardingButton(title: "다음", style: .primary, isEnabled: true) {
            print("Next")
        }
    }
    .padding()
}
