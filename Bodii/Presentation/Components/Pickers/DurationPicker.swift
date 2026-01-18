//
//  DurationPicker.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-14.
//

// 📚 학습 포인트: Duration Picker Component
// SwiftUI Picker를 사용한 시간/분 선택 휠
// 💡 Java 비교: Android의 NumberPicker 또는 TimePicker와 유사

import SwiftUI

// MARK: - DurationPicker

/// 수면 시간 입력을 위한 시간/분 피커 컴포넌트
/// 📚 학습 포인트: Wheel Picker Pattern
/// - 시간 (0-24시간)과 분 (0, 10, 20, 30, 40, 50분) 선택
/// - 10분 단위로 입력하여 간단한 UX 제공
/// - @Binding을 통해 부모 뷰와 양방향 데이터 바인딩
/// - .pickerStyle(.wheel)로 네이티브 iOS 휠 스타일 사용
/// 💡 Java 비교: Android의 NumberPicker 또는 Material TimePicker와 유사
struct DurationPicker: View {

    // MARK: - Binding Properties

    /// 선택된 시간 (0-24)
    /// 📚 학습 포인트: @Binding
    /// - 부모 뷰의 hours와 양방향 바인딩
    /// - 사용자가 선택을 변경하면 부모 뷰에 즉시 반영
    /// 💡 Java 비교: Two-way data binding과 유사
    @Binding var hours: Int

    /// 선택된 분 (0, 10, 20, 30, 40, 50)
    /// 📚 학습 포인트: 10분 단위 입력
    /// - 더 간단한 선택을 위해 10분 간격으로 제한
    /// - 수면 시간 입력에 충분한 정밀도 제공
    @Binding var minutes: Int

    // MARK: - Optional Properties

    /// 레이블 표시 여부
    /// 📚 학습 포인트: Optional UI Element
    /// - true: "수면 시간" 레이블 표시
    /// - false: Picker만 표시 (더 컴팩트)
    var showLabel: Bool = true

    /// 커스텀 레이블 텍스트
    /// 📚 학습 포인트: Customizable Label
    /// - nil이면 기본값 "수면 시간" 사용
    /// - 값이 있으면 해당 텍스트 표시
    var customLabel: String?

    /// 시간 범위 (최대 시간)
    /// 📚 학습 포인트: Configurable Range
    /// - 기본값: 24시간
    /// - 필요시 다른 범위로 제한 가능 (예: 12시간)
    var maxHours: Int = 24

    /// 레이블 아이콘 표시 여부
    /// 📚 학습 포인트: Icon Customization
    /// - true: 시계 아이콘 표시
    /// - false: 텍스트만 표시
    var showIcon: Bool = true

    // MARK: - Private Constants

    /// 분 선택 옵션 (10분 단위)
    /// 📚 학습 포인트: Fixed Options
    /// - 0, 10, 20, 30, 40, 50분 옵션
    /// - 더 많은 옵션보다 간단한 선택이 UX에 유리
    private let minuteOptions = [0, 10, 20, 30, 40, 50]

    // MARK: - Computed Properties

    /// 표시할 레이블 텍스트
    private var labelText: String {
        customLabel ?? "수면 시간"
    }

    /// 총 수면 시간 (분 단위)
    /// 📚 학습 포인트: Computed Property
    /// - 시간과 분을 합산하여 총 분 단위로 변환
    var totalMinutes: Int {
        return hours * 60 + minutes
    }

    /// 포맷된 시간 문자열
    /// 📚 학습 포인트: Display Formatting
    /// - 사용자에게 보여줄 포맷된 문자열
    var formattedDuration: String {
        if minutes == 0 {
            return "\(hours)시간"
        } else {
            return "\(hours)시간 \(minutes)분"
        }
    }

    // MARK: - Initialization

    /// DurationPicker 초기화
    /// 📚 학습 포인트: Flexible Initializer
    /// - 기본값을 제공하여 편리하게 사용
    ///
    /// - Parameters:
    ///   - hours: 선택된 시간 바인딩
    ///   - minutes: 선택된 분 바인딩
    ///   - showLabel: 레이블 표시 여부 (기본값: true)
    ///   - customLabel: 커스텀 레이블 텍스트 (기본값: nil)
    ///   - maxHours: 최대 시간 (기본값: 24)
    ///   - showIcon: 아이콘 표시 여부 (기본값: true)
    init(
        hours: Binding<Int>,
        minutes: Binding<Int>,
        showLabel: Bool = true,
        customLabel: String? = nil,
        maxHours: Int = 24,
        showIcon: Bool = true
    ) {
        self._hours = hours
        self._minutes = minutes
        self.showLabel = showLabel
        self.customLabel = customLabel
        self.maxHours = maxHours
        self.showIcon = showIcon
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: Conditional Layout
        // 레이블 표시 여부에 따라 다른 레이아웃 사용
        VStack(alignment: .leading, spacing: 12) {
            if showLabel {
                labelView
            }

            pickerView
        }
    }

    // MARK: - Subviews

    /// 레이블 뷰
    /// 📚 학습 포인트: Header Label
    /// - 아이콘과 텍스트를 조합한 레이블
    private var labelView: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: "bed.double.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            Text(labelText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    /// Picker 뷰
    /// 📚 학습 포인트: Horizontal Wheel Pickers
    /// - 시간과 분을 나란히 배치
    /// - .pickerStyle(.wheel)로 iOS 네이티브 휠 스타일
    /// - GeometryReader 없이 균등한 공간 배분
    /// 💡 Java 비교: Android의 NumberPicker와 유사
    private var pickerView: some View {
        HStack(spacing: 0) {
            // 시간 피커
            Picker("시간", selection: $hours) {
                // 📚 학습 포인트: Range-based ForEach
                // 0부터 maxHours까지 순회
                ForEach(0...maxHours, id: \.self) { hour in
                    Text("\(hour)시간")
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            // 📚 학습 포인트: Accessibility Label for Picker
            // VoiceOver가 피커의 목적을 명확히 읽어줄 수 있도록 레이블 추가
            .accessibilityLabel("수면 시간 선택")
            .accessibilityValue("\(hours)시간")

            // 분 피커
            Picker("분", selection: $minutes) {
                // 📚 학습 포인트: Array-based ForEach
                // 10분 단위 옵션만 표시
                ForEach(minuteOptions, id: \.self) { minute in
                    Text("\(minute)분")
                        .tag(minute)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            // 📚 학습 포인트: Accessibility Label for Picker
            // VoiceOver가 피커의 목적을 명확히 읽어줄 수 있도록 레이블 추가
            .accessibilityLabel("수면 분 선택")
            .accessibilityValue("\(minutes)분")
        }
        .frame(height: 120)
        // 📚 학습 포인트: Accessibility for Picker Container
        // 전체 피커 컨테이너에 대한 설명 추가
        .accessibilityElement(children: .contain)
        .accessibilityLabel("수면 시간 입력")
        .accessibilityHint("위아래로 스와이프하여 시간과 분을 선택하세요")
    }
}

// MARK: - Convenience Initializers

extension DurationPicker {
    /// 📚 학습 포인트: Convenience Initializer - Compact Style
    /// - 레이블 없는 간단한 스타일
    /// - 팝업이나 작은 공간에 적합
    ///
    /// - Parameters:
    ///   - hours: 선택된 시간 바인딩
    ///   - minutes: 선택된 분 바인딩
    /// - Returns: 레이블 없는 DurationPicker
    init(compactStyle hours: Binding<Int>, minutes: Binding<Int>) {
        self._hours = hours
        self._minutes = minutes
        self.showLabel = false
        self.customLabel = nil
        self.maxHours = 24
        self.showIcon = true
    }

    /// 📚 학습 포인트: Convenience Initializer - 12-Hour Style
    /// - 12시간 형식 (예: 낮잠 기록)
    /// - 더 짧은 시간 입력에 적합
    ///
    /// - Parameters:
    ///   - hours: 선택된 시간 바인딩
    ///   - minutes: 선택된 분 바인딩
    ///   - label: 커스텀 레이블
    /// - Returns: 12시간 제한 DurationPicker
    init(
        shortDuration hours: Binding<Int>,
        minutes: Binding<Int>,
        label: String = "낮잠 시간"
    ) {
        self._hours = hours
        self._minutes = minutes
        self.showLabel = true
        self.customLabel = label
        self.maxHours = 12
        self.showIcon = true
    }
}

// MARK: - Preview

#Preview("기본 스타일") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 7
        @State private var minutes: Int = 30

        var body: some View {
            VStack(spacing: 20) {
                DurationPicker(
                    hours: $hours,
                    minutes: $minutes
                )

                Divider()

                VStack(spacing: 8) {
                    Text("선택된 시간")
                        .font(.caption)
                        .fontWeight(.semibold)

                    Text("\(hours)시간 \(minutes)분")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)

                    Text("총 \(hours * 60 + minutes)분")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("컴팩트 스타일 (레이블 없음)") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 8
        @State private var minutes: Int = 0

        var body: some View {
            VStack(spacing: 20) {
                Text("얼마나 주무셨나요?")
                    .font(.headline)

                DurationPicker(
                    compactStyle: $hours,
                    minutes: $minutes
                )

                Divider()

                Text("\(hours)시간 \(minutes)분")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("12시간 형식 (낮잠)") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 1
        @State private var minutes: Int = 30

        var body: some View {
            VStack(spacing: 20) {
                DurationPicker(
                    shortDuration: $hours,
                    minutes: $minutes,
                    label: "낮잠 시간"
                )

                Divider()

                Text("\(hours)시간 \(minutes)분")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("커스텀 레이블") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 7
        @State private var minutes: Int = 30

        var body: some View {
            VStack(spacing: 20) {
                DurationPicker(
                    hours: $hours,
                    minutes: $minutes,
                    customLabel: "어젯밤 수면 시간"
                )

                Divider()

                Text("\(hours)시간 \(minutes)분")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("아이콘 없음") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 6
        @State private var minutes: Int = 0

        var body: some View {
            VStack(spacing: 20) {
                DurationPicker(
                    hours: $hours,
                    minutes: $minutes,
                    showIcon: false
                )

                Divider()

                Text("\(hours)시간 \(minutes)분")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("시트 안에 포함") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 7
        @State private var minutes: Int = 30
        @State private var showSheet = false

        var body: some View {
            Button("수면 입력하기") {
                showSheet = true
            }
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    VStack(spacing: 24) {
                        // 제목
                        VStack(spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.blue)

                            Text("수면 시간 입력")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("어젯밤 몇 시간 주무셨나요?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // 피커
                        DurationPicker(
                            compactStyle: $hours,
                            minutes: $minutes
                        )

                        // 요약
                        VStack(spacing: 8) {
                            Text("총 수면 시간")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text("\(hours)시간 \(minutes)분")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )

                        Spacer()

                        // 저장 버튼
                        Button(action: {
                            showSheet = false
                        }) {
                            Text("저장")
                                .font(.body)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                )
                                .foregroundStyle(.white)
                        }
                    }
                    .padding()
                    .navigationTitle("수면 기록")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("취소") {
                                showSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    return PreviewWrapper()
}

#Preview("다크 모드") {
    struct PreviewWrapper: View {
        @State private var hours: Int = 7
        @State private var minutes: Int = 30

        var body: some View {
            VStack(spacing: 20) {
                DurationPicker(
                    hours: $hours,
                    minutes: $minutes
                )

                Divider()

                DurationPicker(
                    compactStyle: $hours,
                    minutes: $minutes
                )

                Divider()

                Text("\(hours)시간 \(minutes)분")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}

#Preview("모든 시간 범위") {
    struct PreviewWrapper: View {
        @State private var hours1: Int = 4
        @State private var minutes1: Int = 0
        @State private var hours2: Int = 7
        @State private var minutes2: Int = 30
        @State private var hours3: Int = 10
        @State private var minutes3: Int = 0

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 짧은 수면 (4시간)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("짧은 수면 (4시간)")
                            .font(.headline)

                        DurationPicker(
                            hours: $hours1,
                            minutes: $minutes1,
                            customLabel: "수면 시간"
                        )

                        Text("상태: 수면 부족")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Divider()

                    // 적정 수면 (7.5시간)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("적정 수면 (7시간 30분)")
                            .font(.headline)

                        DurationPicker(
                            hours: $hours2,
                            minutes: $minutes2,
                            customLabel: "수면 시간"
                        )

                        Text("상태: 좋음")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Divider()

                    // 긴 수면 (10시간)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("긴 수면 (10시간)")
                            .font(.headline)

                        DurationPicker(
                            hours: $hours3,
                            minutes: $minutes3,
                            customLabel: "수면 시간"
                        )

                        Text("상태: 과다 수면")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

// MARK: - Documentation

/// 📚 학습 포인트: DurationPicker 사용법
///
/// 기본 사용 (레이블 포함):
/// ```swift
/// struct SleepInputSheet: View {
///     @State private var hours: Int = 7
///     @State private var minutes: Int = 0
///
///     var body: some View {
///         DurationPicker(
///             hours: $hours,
///             minutes: $minutes
///         )
///     }
/// }
/// ```
///
/// 컴팩트 스타일 (레이블 없음):
/// ```swift
/// struct CompactSleepView: View {
///     @State private var hours: Int = 7
///     @State private var minutes: Int = 0
///
///     var body: some View {
///         DurationPicker(
///             compactStyle: $hours,
///             minutes: $minutes
///         )
///     }
/// }
/// ```
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct SleepInputSheet: View {
///     @StateObject private var viewModel: SleepInputViewModel
///
///     var body: some View {
///         VStack {
///             DurationPicker(
///                 hours: $viewModel.hours,
///                 minutes: $viewModel.minutes
///             )
///
///             // 예상 상태 자동 표시
///             SleepStatusBadge(status: viewModel.expectedStatus)
///             Text(viewModel.statusDescription())
///
///             // 저장 버튼
///             Button("저장") {
///                 Task {
///                     await viewModel.saveSleep()
///                 }
///             }
///             .disabled(!viewModel.canSave)
///         }
///     }
/// }
/// ```
///
/// 12시간 형식 (낮잠 기록):
/// ```swift
/// struct NapInputView: View {
///     @State private var hours: Int = 1
///     @State private var minutes: Int = 30
///
///     var body: some View {
///         DurationPicker(
///             shortDuration: $hours,
///             minutes: $minutes,
///             label: "낮잠 시간"
///         )
///     }
/// }
/// ```
///
/// 주요 기능:
/// - 휠 스타일 피커 (iOS 네이티브 UI)
/// - @Binding을 통한 양방향 데이터 바인딩
/// - 시간 (0-24시간) 및 분 (0, 10, 20, 30, 40, 50분) 선택
/// - 10분 단위 입력으로 간단한 UX
/// - 레이블 표시/숨김 옵션
/// - 커스텀 레이블 지원
/// - 12시간/24시간 형식 선택
/// - 아이콘 표시/숨김 옵션
/// - 라이트/다크 모드 자동 대응
///
/// 스타일 옵션:
/// 1. 기본 스타일: 레이블 + 아이콘 + Picker (일반적인 사용)
/// 2. 컴팩트 스타일: Picker만 (팝업/시트에 적합)
/// 3. 12시간 형식: 0-12시간 범위 (낮잠/짧은 수면)
/// 4. 아이콘 없음: 레이블만 + Picker (미니멀한 디자인)
///
/// 💡 Android 비교:
/// - Android: NumberPicker 또는 Material TimePicker
/// - SwiftUI: Picker with .wheel style
/// - Android: OnValueChangeListener
/// - SwiftUI: @Binding for automatic updates
/// - Android: 복잡한 커스텀 뷰 필요
/// - SwiftUI: 네이티브 Picker로 간단히 구현
///
/// 자동 동작:
/// - hours/minutes가 변경되면 @Binding을 통해 부모 뷰에 즉시 반영
/// - ViewModel의 $hours, $minutes에 바인딩하면 자동으로 expectedStatus 업데이트
/// - Picker는 iOS 네이티브 컴포넌트라 스크롤 동작이 자연스러움
///
/// 접근성:
/// - VoiceOver 지원 (iOS 표준 Picker 사용)
/// - Dynamic Type 지원 (자동 폰트 크기 조정)
/// - 휠 스크롤은 iOS 접근성 기능 완벽 지원
///
/// 실무 팁:
/// - 10분 단위로 제한하여 선택 옵션 줄이기 (UX 개선)
/// - 시간/분 Picker를 나란히 배치하여 직관적인 입력
/// - 시트나 팝업에는 컴팩트 스타일 사용 권장
/// - ViewModel과 바인딩하면 실시간 상태 계산 가능
///
