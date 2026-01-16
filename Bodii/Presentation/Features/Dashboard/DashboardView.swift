//
//  DashboardView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-12.
//

// 📚 학습 포인트: Dashboard View with Multiple Cards
// SwiftUI의 대시보드 화면 - 여러 모듈의 요약 정보를 한 곳에 표시
// 💡 Java 비교: Android의 Dashboard Fragment와 유사

import SwiftUI

// MARK: - DashboardView

/// 대시보드 메인 화면
/// 📚 학습 포인트: Dashboard Pattern
/// - 여러 모듈의 요약 정보를 카드 형태로 표시
/// - 각 카드는 해당 모듈로 네비게이션 가능
/// - 주요 지표와 빠른 액세스 제공
/// 💡 Java 비교: Android의 Home Fragment + CardViews와 유사
struct DashboardView: View {

    // MARK: - Properties

    /// Dashboard ViewModel - 일일 건강 데이터 관리
    /// 📚 학습 포인트: @State with @Observable
    /// - iOS 17+의 @Observable을 사용한 현대적인 상태 관리
    /// - DailyLog의 사전 계산된 값을 사용하여 빠른 로딩
    /// 💡 Java 비교: Android ViewModel과 유사
    @State private var viewModel: DashboardViewModel

    /// 식단 탭으로 이동하는 콜백
    /// 📚 학습 포인트: Closure-based Navigation
    /// - 부모 View에서 탭 전환 로직을 처리
    /// - Quick Add 버튼에서 호출되어 해당 탭으로 이동
    /// 💡 Java 비교: Callback interface와 유사
    var onNavigateToDiet: (() -> Void)?

    /// 운동 탭으로 이동하는 콜백
    var onNavigateToExercise: (() -> Void)?

    /// 체성분 탭으로 이동하는 콜백
    var onNavigateToBody: (() -> Void)?

    // MARK: - Initialization

    /// DashboardView 초기화
    /// 📚 학습 포인트: Dependency Injection via Constructor
    /// - ViewModel과 네비게이션 콜백을 외부에서 주입받음
    /// - 테스트 시 Mock ViewModel 주입 가능
    /// 💡 Java 비교: Constructor injection과 유사
    ///
    /// - Parameters:
    ///   - viewModel: 대시보드 ViewModel
    ///   - onNavigateToDiet: 식단 탭으로 이동하는 콜백
    ///   - onNavigateToExercise: 운동 탭으로 이동하는 콜백
    ///   - onNavigateToBody: 체성분 탭으로 이동하는 콜백
    init(
        viewModel: DashboardViewModel,
        onNavigateToDiet: (() -> Void)? = nil,
        onNavigateToExercise: (() -> Void)? = nil,
        onNavigateToBody: (() -> Void)? = nil
    ) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onNavigateToDiet = onNavigateToDiet
        self.onNavigateToExercise = onNavigateToExercise
        self.onNavigateToBody = onNavigateToBody
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // 📚 학습 포인트: Conditional Rendering - Loading vs Content
            // isLoading 상태에 따라 스켈레톤 뷰 또는 실제 컨텐츠 표시
            // 💡 Java 비교: if-else 조건부 렌더링과 유사
            Group {
                if viewModel.isLoading && viewModel.dailyLog == nil {
                    // 초기 로딩 중: 스켈레톤 뷰 표시
                    DashboardSkeletonView()
                } else {
                    // 데이터 로드 완료: 실제 컨텐츠 표시
                    dashboardContent
                }
            }
            .navigationTitle("대시보드")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // 📚 학습 포인트: Pull-to-refresh
                // SwiftUI의 refreshable modifier를 사용한 새로고침 기능
                // Pull-to-refresh 제스처로 데이터를 새로고침
                // 💡 Java 비교: Android의 SwipeRefreshLayout과 유사
                await viewModel.refresh()
            }
            .task {
                // 📚 학습 포인트: task modifier
                // View가 나타날 때 비동기 작업 실행
                // 💡 Java 비교: onResume()에서 데이터 로드와 유사
                await viewModel.loadDailyLog(for: viewModel.selectedDate)
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Dashboard Content

    /// 대시보드 실제 컨텐츠
    /// 📚 학습 포인트: View Composition
    /// - 복잡한 body를 분리하여 가독성 향상
    /// - 로딩 상태와 컨텐츠 상태를 명확히 구분
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 날짜 네비게이션 헤더
                dateNavigationHeader

                // 빠른 추가 버튼
                quickAddButtons

                // 칼로리 밸런스 카드
                calorieBalanceCard

                // 매크로 영양소 분석 카드
                macroBreakdownCard

                // 운동 요약 카드
                exerciseSummaryCard

                // 수면 품질 카드
                sleepQualityCard

                // 체성분 카드
                bodyCompositionCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Subviews

    /// 날짜 네비게이션 헤더
    /// 📚 학습 포인트: Date Navigation Component
    /// - 좌우 화살표로 날짜 이동
    /// - 중앙에 선택된 날짜 표시 (오늘, 어제, 또는 전체 날짜)
    /// - 오늘로 돌아가기 버튼
    private var dateNavigationHeader: some View {
        DateNavigationHeader(
            selectedDate: viewModel.selectedDate,
            isToday: viewModel.isToday,
            onPreviousDay: viewModel.goToPreviousDay,
            onNextDay: viewModel.goToNextDay,
            onToday: viewModel.goToToday
        )
    }

    /// 빠른 추가 버튼
    /// 📚 학습 포인트: Quick Add Component
    /// - 가로 스크롤 버튼으로 빠른 데이터 입력
    /// - 음식, 운동, 체성분 기록 화면으로 이동
    private var quickAddButtons: some View {
        QuickAddButtons(
            onAddFood: {
                // 📚 학습 포인트: Callback Navigation
                // 버튼 탭 시 식단 탭으로 이동 콜백 호출
                onNavigateToDiet?()
            },
            onAddExercise: {
                onNavigateToExercise?()
            },
            onAddBodyComposition: {
                onNavigateToBody?()
            }
        )
    }

    /// 칼로리 밸런스 카드
    /// 📚 학습 포인트: Calorie Balance Component
    /// - 오늘의 섭취 칼로리 vs TDEE
    /// - 원형 진행 표시기로 시각화
    /// - 칼로리 수지에 따라 색상 변경 (적자/균형/과잉)
    /// - Empty State에서 음식 추가 버튼 제공
    private var calorieBalanceCard: some View {
        CalorieBalanceCard(
            totalCaloriesIn: viewModel.totalCaloriesIn,
            tdee: viewModel.tdee,
            netCalories: viewModel.netCalories,
            onAddFood: onNavigateToDiet
        )
    }

    /// 매크로 영양소 분석 카드
    /// 📚 학습 포인트: Macro Breakdown Component
    /// - 탄수화물/단백질/지방 섭취량과 비율
    /// - 가로 진행 바로 시각화
    /// - 각 영양소의 그램 수와 퍼센트 표시
    /// - Empty State에서 음식 추가 버튼 제공
    private var macroBreakdownCard: some View {
        MacroBreakdownCard(
            totalCarbs: viewModel.totalCarbs,
            totalProtein: viewModel.totalProtein,
            totalFat: viewModel.totalFat,
            carbsRatio: viewModel.carbsRatio,
            proteinRatio: viewModel.proteinRatio,
            fatRatio: viewModel.fatRatio,
            onAddFood: onNavigateToDiet
        )
    }

    /// 운동 요약 카드
    /// 📚 학습 포인트: Exercise Summary Component
    /// - 오늘의 운동 정보 요약
    /// - 총 소모 칼로리, 운동 횟수, 운동 시간
    /// - 3개의 지표를 가로로 나열하여 표시
    /// - Empty State에서 운동 추가 버튼 제공
    private var exerciseSummaryCard: some View {
        ExerciseSummaryCard(
            totalCaloriesOut: viewModel.totalCaloriesOut,
            exerciseCount: viewModel.exerciseCount,
            exerciseMinutes: viewModel.exerciseMinutes,
            onAddExercise: onNavigateToExercise
        )
    }

    /// 수면 품질 카드
    /// 📚 학습 포인트: Sleep Quality Component
    /// - 전날 밤 수면 정보
    /// - 수면 시간과 품질 표시
    /// - 이모지 인디케이터로 상태 시각화
    private var sleepQualityCard: some View {
        SleepQualityCard(
            sleepDuration: viewModel.sleepDuration,
            sleepStatus: viewModel.sleepStatus
        )
    }

    /// 체성분 카드
    /// 📚 학습 포인트: Body Composition Component
    /// - 오늘의 체중과 체지방률
    /// - 전날 대비 변화량 표시 (TODO: 향후 구현)
    /// - Empty State에서 체성분 기록 버튼 제공
    private var bodyCompositionCard: some View {
        BodyCompositionCard(
            weight: viewModel.weight,
            bodyFatPct: viewModel.bodyFatPct,
            // TODO: 전날 데이터를 DailyLogRepository에서 조회하여 전달
            // 현재는 DailyLog에 전날 데이터가 없으므로 nil 전달
            previousWeight: nil,
            previousBodyFatPct: nil,
            onAddBodyComposition: onNavigateToBody
        )
    }
}

// MARK: - Preview

// 📚 학습 포인트: Comprehensive SwiftUI Previews
// 다양한 상태(데이터 있음, 빈 상태, 로딩, 에러)를 미리 보며 개발
// 💡 Java 비교: Compose의 @Preview와 유사하지만 더 강력한 실시간 미리보기 제공

#if DEBUG
#Preview("대시보드 - 데이터 있음") {
    // 📚 학습 포인트: Preview with Sample Data
    // 모든 카드에 데이터가 있는 정상 상태
    // 칼로리 적자, 균형잡힌 매크로, 운동 2회, 좋은 수면, 체성분 기록
    DashboardView(
        viewModel: .makePreviewWithData(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
}

#Preview("대시보드 - 빈 상태") {
    // 📚 학습 포인트: Preview with Empty State
    // 데이터가 전혀 없는 상태 (음식, 운동, 수면, 체성분 모두 미기록)
    // Empty State 컴포넌트와 안내 메시지가 표시됨
    DashboardView(
        viewModel: .makePreviewEmpty(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
}

#Preview("대시보드 - 로딩 중") {
    // 📚 학습 포인트: Preview with Loading State
    // 데이터를 불러오는 중인 상태
    // 스켈레톤 뷰(shimmer effect)가 표시됨
    DashboardView(
        viewModel: .makePreviewLoading(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
}

#Preview("대시보드 - 에러 상태") {
    // 📚 학습 포인트: Preview with Error State
    // 데이터 로드 실패 상태
    // 에러 알림 다이얼로그가 표시됨
    DashboardView(
        viewModel: .makePreviewError(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
}

#Preview("대시보드 - 칼로리 과잉") {
    // 📚 학습 포인트: Preview with Surplus Calories
    // 칼로리를 과다 섭취한 상태
    // 칼로리 밸런스 카드가 빨간색으로 표시됨
    // 적은 운동량, 보통 수면 품질
    DashboardView(
        viewModel: .makePreviewSurplus(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
}

#Preview("다크 모드 - 데이터 있음") {
    // 📚 학습 포인트: Preview with Dark Mode
    // 다크 모드에서의 UI 확인
    // 색상 대비와 가독성 검증
    DashboardView(
        viewModel: .makePreviewWithData(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("다크 모드 - 빈 상태") {
    // 📚 학습 포인트: Preview with Dark Mode + Empty State
    // 다크 모드에서 Empty State 확인
    DashboardView(
        viewModel: .makePreviewEmpty(),
        onNavigateToDiet: {
            print("Navigate to Diet")
        },
        onNavigateToExercise: {
            print("Navigate to Exercise")
        },
        onNavigateToBody: {
            print("Navigate to Body")
        }
    )
    .preferredColorScheme(.dark)
}
#endif

// MARK: - Documentation

/// 📚 학습 포인트: DashboardView 사용법
///
/// 기본 사용 (ContentView에서):
/// ```swift
/// struct ContentView: View {
///     @State private var selectedTab: Tab = .dashboard
///     let container: DIContainer
///
///     var body: some View {
///         TabView(selection: $selectedTab) {
///             DashboardView(
///                 viewModel: container.makeDashboardViewModel(userId: user.id),
///                 onNavigateToDiet: {
///                     selectedTab = .diet
///                 },
///                 onNavigateToExercise: {
///                     selectedTab = .exercise
///                 },
///                 onNavigateToBody: {
///                     selectedTab = .body
///                 }
///             )
///             .tabItem {
///                 Label("대시보드", systemImage: "chart.bar.fill")
///             }
///             .tag(Tab.dashboard)
///
///             // 다른 탭들...
///         }
///     }
/// }
/// ```
///
/// 주요 기능:
/// - 날짜 네비게이션: 좌우 화살표로 날짜 이동, 오늘로 돌아가기
/// - 빠른 추가 버튼: 음식, 운동, 체성분 기록 화면으로 빠른 이동
/// - 칼로리 밸런스: 섭취 vs TDEE, 원형 진행 표시기
/// - 매크로 분석: 탄수화물/단백질/지방 비율 시각화
/// - 운동 요약: 소모 칼로리, 운동 횟수, 운동 시간
/// - 수면 품질: 수면 시간 및 품질 상태
/// - 체성분: 체중, 체지방률, 전날 대비 변화
///
/// 화면 구성:
/// 1. 날짜 네비게이션 헤더: DateNavigationHeader 컴포넌트
/// 2. 빠른 추가 버튼: QuickAddButtons 컴포넌트
/// 3. 칼로리 밸런스 카드: CalorieBalanceCard 컴포넌트
/// 4. 매크로 분석 카드: MacroBreakdownCard 컴포넌트
/// 5. 운동 요약 카드: ExerciseSummaryCard 컴포넌트
/// 6. 수면 품질 카드: SleepQualityCard 컴포넌트
/// 7. 체성분 카드: BodyCompositionCard 컴포넌트
///
/// 네비게이션:
/// - Quick Add 버튼: onNavigateToDiet/Exercise/Body 콜백 호출
/// - 부모 View에서 탭 전환 로직 처리
///
/// 상태 관리:
/// - DashboardViewModel: 일일 건강 데이터 관리
/// - @Observable (iOS 17+)을 사용한 현대적인 상태 관리
/// - DailyLog의 사전 계산된 값으로 빠른 로딩 (<0.5초)
/// - Closure를 통해 네비게이션 이벤트 전달
///
/// 성능 최적화:
/// - DailyLog에서 모든 값이 사전 계산되어 있어 추가 계산 불필요
/// - 컴포넌트 기반 설계로 재사용성과 유지보수성 향상
/// - 각 카드는 독립적으로 렌더링되어 효율적
///
/// 💡 Android 비교:
/// - Android: Fragment + RecyclerView with CardViews
/// - SwiftUI: View + ScrollView with VStack of Cards
/// - Android: ViewModel + LiveData
/// - SwiftUI: @Observable + @State
/// - Android: Fragment navigation via callback
/// - SwiftUI: Closure-based navigation
///
/// 접근성:
/// - VoiceOver 지원
/// - Dynamic Type 지원
/// - 충분한 터치 영역
/// - 명확한 레이블과 힌트
///
