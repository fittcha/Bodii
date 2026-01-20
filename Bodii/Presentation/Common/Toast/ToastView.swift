//
//  ToastView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Toast Notification Component
// 사용자에게 일시적인 피드백을 제공하는 토스트 알림
// 💡 성공, 오류, 정보 메시지를 표시하는 재사용 가능한 컴포넌트

import SwiftUI

// MARK: - Toast Type

/// 토스트 메시지 타입
///
/// 토스트의 색상과 아이콘을 결정합니다.
enum ToastType {
    /// 성공 메시지 (녹색)
    case success
    /// 오류 메시지 (빨간색)
    case error
    /// 정보 메시지 (파란색)
    case info

    /// 아이콘 이름
    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    /// 배경색
    var backgroundColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        }
    }
}

// MARK: - Toast View

/// 토스트 알림 뷰
///
/// 화면 상단에 일시적으로 표시되는 알림 메시지입니다.
///
/// - Note: 자동으로 사라지는 애니메이션을 포함합니다.
/// - Note: VoiceOver 접근성을 지원합니다.
///
/// - Example:
/// ```swift
/// ToastView(
///     message: "식단에 추가되었습니다",
///     type: .success
/// )
/// ```
struct ToastView: View {

    // MARK: - Properties

    /// 표시할 메시지
    let message: String

    /// 토스트 타입
    let type: ToastType

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // 아이콘
            Image(systemName: type.iconName)
                .font(.title3)
                .foregroundColor(.white)
                .accessibilityHidden(true)

            // 메시지
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Toast Modifier

/// 토스트 알림을 표시하는 View Modifier
///
/// 뷰에 토스트 알림 기능을 추가합니다.
///
/// - Example:
/// ```swift
/// YourView()
///     .toast(message: $toastMessage, type: .success)
/// ```
struct ToastModifier: ViewModifier {

    // MARK: - Properties

    /// 토스트 메시지 (nil이면 표시하지 않음)
    @Binding var message: String?

    /// 토스트 타입
    let type: ToastType

    /// 표시 시간 (초)
    let duration: Double

    // MARK: - State

    /// 토스트 표시 여부
    @State private var isShowing = false

    // MARK: - Body

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            // 토스트 뷰
            if isShowing, let toastMessage = message {
                ToastView(message: toastMessage, type: type)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // 일정 시간 후 자동으로 사라짐
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                                self.message = nil
                            }
                        }
                    }
            }
        }
        .onChange(of: message) { newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isShowing = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// 성공 토스트 표시
    ///
    /// - Parameters:
    ///   - message: 표시할 메시지 (nil이면 표시하지 않음)
    ///   - duration: 표시 시간 (초, 기본값: 2.5초)
    /// - Returns: 토스트가 적용된 뷰
    func successToast(message: Binding<String?>, duration: Double = 2.5) -> some View {
        modifier(ToastModifier(message: message, type: .success, duration: duration))
    }

    /// 오류 토스트 표시
    ///
    /// - Parameters:
    ///   - message: 표시할 메시지 (nil이면 표시하지 않음)
    ///   - duration: 표시 시간 (초, 기본값: 3.0초)
    /// - Returns: 토스트가 적용된 뷰
    func errorToast(message: Binding<String?>, duration: Double = 3.0) -> some View {
        modifier(ToastModifier(message: message, type: .error, duration: duration))
    }

    /// 정보 토스트 표시
    ///
    /// - Parameters:
    ///   - message: 표시할 메시지 (nil이면 표시하지 않음)
    ///   - duration: 표시 시간 (초, 기본값: 2.5초)
    /// - Returns: 토스트가 적용된 뷰
    func infoToast(message: Binding<String?>, duration: Double = 2.5) -> some View {
        modifier(ToastModifier(message: message, type: .info, duration: duration))
    }
}

// MARK: - Preview

#Preview("Success Toast") {
    VStack {
        Text("Main Content")
            .font(.headline)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .successToast(message: .constant("식단에 추가되었습니다"))
}

#Preview("Error Toast") {
    VStack {
        Text("Main Content")
            .font(.headline)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .errorToast(message: .constant("음식을 불러오는데 실패했습니다"))
}

#Preview("Info Toast") {
    VStack {
        Text("Main Content")
            .font(.headline)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .infoToast(message: .constant("데이터를 새로고침했습니다"))
}
