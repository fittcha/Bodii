//
//  TrendPeriodPicker.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Segmented Control Component
// SwiftUI Picker를 사용한 세그먼트 컨트롤
// 💡 Java 비교: Android의 TabLayout 또는 Segmented Button과 유사

import SwiftUI

// MARK: - TrendPeriodPicker

/// 차트 기간 선택을 위한 세그먼트 컨트롤
/// 📚 학습 포인트: Segmented Picker Pattern
/// - 사용자가 차트 기간을 선택할 수 있는 UI 컴포넌트
/// - 7일/30일/90일 옵션 제공
/// - @Binding을 통해 부모 뷰와 동기화
/// 💡 Java 비교: Material Design의 Segmented Button과 유사
struct TrendPeriodPicker: View {

    // MARK: - Binding Properties

    /// 선택된 기간 바인딩
    /// 📚 학습 포인트: @Binding
    /// - 부모 뷰의 selectedPeriod와 양방향 바인딩
    /// - 사용자가 선택을 변경하면 부모 뷰에 즉시 반영
    /// 💡 Java 비교: Two-way data binding과 유사
    @Binding var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod

    // MARK: - Optional Properties

    /// 레이블 표시 여부
    /// 📚 학습 포인트: Optional UI Element
    /// - true: "기간" 레이블 표시
    /// - false: Picker만 표시 (더 컴팩트)
    var showLabel: Bool = true

    /// 커스텀 레이블 텍스트
    /// 📚 학습 포인트: Customizable Label
    /// - nil이면 기본값 "기간" 사용
    /// - 값이 있으면 해당 텍스트 표시
    var customLabel: String?

    /// 전체 너비 사용 여부
    /// 📚 학습 포인트: Layout Control
    /// - true: maxWidth: .infinity 사용
    /// - false: 내용물에 맞춤
    var useFullWidth: Bool = false

    // MARK: - Computed Properties

    /// 표시할 레이블 텍스트
    private var labelText: String {
        customLabel ?? "기간"
    }

    // MARK: - Initialization

    /// TrendPeriodPicker 초기화
    /// 📚 학습 포인트: Flexible Initializer
    /// - 기본값을 제공하여 편리하게 사용
    ///
    /// - Parameters:
    ///   - selectedPeriod: 선택된 기간 바인딩
    ///   - showLabel: 레이블 표시 여부 (기본값: true)
    ///   - customLabel: 커스텀 레이블 텍스트 (기본값: nil)
    ///   - useFullWidth: 전체 너비 사용 여부 (기본값: false)
    init(
        selectedPeriod: Binding<FetchBodyTrendsUseCase.TrendPeriod>,
        showLabel: Bool = true,
        customLabel: String? = nil,
        useFullWidth: Bool = false
    ) {
        self._selectedPeriod = selectedPeriod
        self.showLabel = showLabel
        self.customLabel = customLabel
        self.useFullWidth = useFullWidth
    }

    // MARK: - Body

    var body: some View {
        // 📚 학습 포인트: Conditional Layout
        // 레이블 표시 여부에 따라 다른 레이아웃 사용
        if showLabel {
            labeledPickerView
        } else {
            pickerView
        }
    }

    // MARK: - Subviews

    /// 레이블이 있는 Picker 뷰
    /// 📚 학습 포인트: VStack Layout
    /// - 레이블과 Picker를 수직으로 배치
    private var labeledPickerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 레이블
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(labelText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }

            // Picker
            pickerView
        }
        .frame(maxWidth: useFullWidth ? .infinity : nil, alignment: .leading)
    }

    /// Picker 뷰
    /// 📚 학습 포인트: Segmented Picker
    /// - .pickerStyle(.segmented)로 세그먼트 컨트롤 스타일 적용
    /// - TrendPeriod.allCases를 순회하여 모든 옵션 표시
    /// 💡 Java 비교: RadioGroup 또는 TabLayout과 유사
    private var pickerView: some View {
        Picker("기간 선택", selection: $selectedPeriod) {
            // 📚 학습 포인트: ForEach with CaseIterable
            // TrendPeriod는 CaseIterable을 conform하므로 .allCases로 순회 가능
            ForEach(FetchBodyTrendsUseCase.TrendPeriod.allCases, id: \.self) { period in
                // 📚 학습 포인트: Text with tag
                // tag는 선택된 값을 식별하는 데 사용됨
                Text(period.displayName)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: useFullWidth ? .infinity : nil)
    }
}

// MARK: - Convenience Initializers

extension TrendPeriodPicker {
    /// 📚 학습 포인트: Convenience Initializer - Compact Style
    /// - 레이블 없는 간단한 스타일
    /// - 대시보드나 작은 공간에 적합
    ///
    /// - Parameter selectedPeriod: 선택된 기간 바인딩
    /// - Returns: 레이블 없는 TrendPeriodPicker
    init(compactStyle selectedPeriod: Binding<FetchBodyTrendsUseCase.TrendPeriod>) {
        self._selectedPeriod = selectedPeriod
        self.showLabel = false
        self.customLabel = nil
        self.useFullWidth = false
    }

    /// 📚 학습 포인트: Convenience Initializer - Full Width Style
    /// - 전체 너비를 사용하는 스타일
    /// - 카드나 전체 화면에 적합
    ///
    /// - Parameters:
    ///   - selectedPeriod: 선택된 기간 바인딩
    ///   - label: 커스텀 레이블 (기본값: "기간")
    /// - Returns: 전체 너비 TrendPeriodPicker
    init(fullWidth selectedPeriod: Binding<FetchBodyTrendsUseCase.TrendPeriod>, label: String = "기간") {
        self._selectedPeriod = selectedPeriod
        self.showLabel = true
        self.customLabel = label
        self.useFullWidth = true
    }
}

// MARK: - Preview

#Preview("기본 스타일") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week

        var body: some View {
            VStack(spacing: 20) {
                TrendPeriodPicker(selectedPeriod: $selectedPeriod)

                Text("선택된 기간: \(selectedPeriod.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                Text("설명:")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("• \(selectedPeriod.days)일 간의 데이터")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("컴팩트 스타일 (레이블 없음)") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .month

        var body: some View {
            VStack(spacing: 20) {
                TrendPeriodPicker(compactStyle: $selectedPeriod)

                Text("선택된 기간: \(selectedPeriod.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("전체 너비 스타일") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .quarter

        var body: some View {
            VStack(spacing: 20) {
                TrendPeriodPicker(fullWidth: $selectedPeriod)

                Text("선택된 기간: \(selectedPeriod.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("커스텀 레이블") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week

        var body: some View {
            VStack(spacing: 20) {
                TrendPeriodPicker(
                    selectedPeriod: $selectedPeriod,
                    customLabel: "차트 표시 기간"
                )

                Text("선택된 기간: \(selectedPeriod.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("카드 안에 포함") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week

        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    // 제목
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        Text("체중 트렌드")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Spacer()
                    }

                    // 기간 선택기
                    TrendPeriodPicker(fullWidth: $selectedPeriod)

                    Divider()

                    // 차트 영역 (placeholder)
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            Text("차트가 여기에 표시됩니다")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8)
                )
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

#Preview("다크 모드") {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .month

        var body: some View {
            VStack(spacing: 20) {
                TrendPeriodPicker(selectedPeriod: $selectedPeriod)

                TrendPeriodPicker(compactStyle: $selectedPeriod)

                TrendPeriodPicker(fullWidth: $selectedPeriod)

                Text("선택된 기간: \(selectedPeriod.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .preferredColorScheme(.dark)
        }
    }

    return PreviewWrapper()
}

#Preview("모든 기간 옵션") {
    struct PreviewWrapper: View {
        @State private var period1: FetchBodyTrendsUseCase.TrendPeriod = .week
        @State private var period2: FetchBodyTrendsUseCase.TrendPeriod = .month
        @State private var period3: FetchBodyTrendsUseCase.TrendPeriod = .quarter

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 7일 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("7일 기간 (주간)")
                            .font(.headline)

                        TrendPeriodPicker(selectedPeriod: $period1)
                    }

                    Divider()

                    // 30일 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("30일 기간 (월간)")
                            .font(.headline)

                        TrendPeriodPicker(selectedPeriod: $period2)
                    }

                    Divider()

                    // 90일 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("90일 기간 (분기)")
                            .font(.headline)

                        TrendPeriodPicker(selectedPeriod: $period3)
                    }
                }
                .padding()
            }
        }
    }

    return PreviewWrapper()
}

// MARK: - Documentation

/// 📚 학습 포인트: TrendPeriodPicker 사용법
///
/// 기본 사용 (레이블 포함):
/// ```swift
/// struct MyView: View {
///     @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week
///
///     var body: some View {
///         TrendPeriodPicker(selectedPeriod: $selectedPeriod)
///     }
/// }
/// ```
///
/// 컴팩트 스타일 (레이블 없음):
/// ```swift
/// struct MyView: View {
///     @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week
///
///     var body: some View {
///         TrendPeriodPicker(compactStyle: $selectedPeriod)
///     }
/// }
/// ```
///
/// 전체 너비 스타일:
/// ```swift
/// struct MyView: View {
///     @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week
///
///     var body: some View {
///         TrendPeriodPicker(fullWidth: $selectedPeriod, label: "차트 기간")
///     }
/// }
/// ```
///
/// ViewModel과 함께 사용 (권장):
/// ```swift
/// struct BodyTrendsView: View {
///     @StateObject private var viewModel: BodyTrendsViewModel
///
///     var body: some View {
///         VStack {
///             TrendPeriodPicker(selectedPeriod: $viewModel.selectedPeriod)
///
///             // 차트는 자동으로 새로운 기간의 데이터를 표시
///             WeightTrendChart(viewModel: viewModel)
///         }
///     }
/// }
/// ```
///
/// 카드 컴포넌트 안에 사용:
/// ```swift
/// struct TrendCard: View {
///     @State private var selectedPeriod: FetchBodyTrendsUseCase.TrendPeriod = .week
///
///     var body: some View {
///         VStack(spacing: 16) {
///             // 제목
///             Text("체중 트렌드")
///                 .font(.headline)
///
///             // 기간 선택기
///             TrendPeriodPicker(fullWidth: $selectedPeriod)
///
///             // 차트
///             WeightTrendChart(
///                 dataPoints: dataPoints,
///                 period: selectedPeriod
///             )
///         }
///         .padding()
///         .background(Color(.systemBackground))
///         .cornerRadius(12)
///     }
/// }
/// ```
///
/// 주요 기능:
/// - 세그먼트 컨트롤 스타일 (iOS 표준 UI)
/// - @Binding을 통한 양방향 데이터 바인딩
/// - 7일/30일/90일 옵션 자동 표시
/// - 레이블 표시/숨김 옵션
/// - 전체 너비 또는 내용물 크기 선택
/// - 커스텀 레이블 지원
/// - 라이트/다크 모드 자동 대응
///
/// 스타일 옵션:
/// 1. 기본 스타일: 레이블 + Picker (일반적인 사용)
/// 2. 컴팩트 스타일: Picker만 (공간이 제한적인 경우)
/// 3. 전체 너비 스타일: maxWidth: .infinity (카드나 전체 화면)
///
/// 💡 Android 비교:
/// - Android: TabLayout 또는 MaterialButtonToggleGroup
/// - SwiftUI: Picker with .segmented style
/// - Android: ViewPager2 + TabLayout
/// - SwiftUI: Picker + content switching
/// - Android: OnTabSelectedListener
/// - SwiftUI: @Binding for automatic updates
///
/// 자동 동작:
/// - selectedPeriod가 변경되면 @Binding을 통해 부모 뷰에 즉시 반영
/// - ViewModel의 $selectedPeriod에 바인딩하면 자동으로 차트 데이터 새로고침
/// - TrendPeriod.allCases를 사용하여 모든 옵션 자동 표시
///
/// 접근성:
/// - VoiceOver 지원 (iOS 표준 Picker 사용)
/// - Dynamic Type 지원 (자동 폰트 크기 조정)
/// - 터치 영역 충분 (iOS 표준 세그먼트 컨트롤)
///
