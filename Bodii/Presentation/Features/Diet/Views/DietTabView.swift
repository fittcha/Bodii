//
//  DietTabView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-13.
//

// 📚 학습 포인트: Diet Tab View
// 식단 탭의 루트 뷰 - 일일 식단, 음식 검색, 상세, 수동 입력 화면을 연결
// 💡 NavigationStack을 사용한 계층적 네비게이션 구조

import SwiftUI

// MARK: - Diet Tab View

/// 식단 탭 뷰
///
/// 식단 관련 모든 화면의 루트 뷰이며 네비게이션 흐름을 관리합니다.
///
/// - Note: DailyMealView를 루트로 하여 음식 검색, 상세, 수동 입력 화면으로 네비게이션합니다.
/// - Note: 현재는 임시 사용자 데이터를 사용하며, 향후 사용자 세션 관리가 추가될 예정입니다.
///
/// - Example:
/// ```swift
/// TabView {
///     DietTabView()
///         .tabItem {
///             Label("식단", systemImage: "fork.knife")
///         }
/// }
/// ```
struct DietTabView: View {

    // MARK: - Properties

    /// 임시 사용자 ID
    /// TODO: Phase 7.2에서 사용자 세션 관리로 교체 예정
    private let userId: UUID

    /// 임시 BMR (기초대사량)
    /// TODO: Phase 7.2에서 실제 사용자 BMR로 교체 예정
    private let bmr: Int32 = 1650

    /// 임시 TDEE (활동대사량)
    /// TODO: Phase 7.2에서 실제 사용자 TDEE로 교체 예정
    private let tdee: Int32 = 2310

    // MARK: - State Objects

    /// 일일 식단 ViewModel
    @StateObject private var dailyMealViewModel: DailyMealViewModel

    /// 음식 검색 ViewModel
    @StateObject private var foodSearchViewModel: FoodSearchViewModel

    /// 사진 인식 ViewModel
    @StateObject private var photoRecognitionViewModel: PhotoRecognitionViewModel

    // MARK: - State

    /// 음식 검색 시트 표시 여부
    @State private var showingFoodSearch = false

    /// 선택된 끼니 타입
    @State private var selectedMealType: MealType = .breakfast

    /// 선택된 음식 ID (음식 상세 화면으로 네비게이션)
    @State private var selectedFoodId: UUID?

    /// 수동 입력 시트 표시 여부
    @State private var showingManualEntry = false

    /// 사진 인식 시트 표시 여부
    @State private var showingPhotoRecognition = false

    // MARK: - Initialization

    init() {
        // 임시 사용자 ID 생성
        // TODO: Phase 7.2에서 실제 로그인된 사용자 ID로 교체
        let tempUserId = UUID()
        self.userId = tempUserId

        // 📚 학습 포인트: Repository 및 Service 초기화
        // Core Data 컨텍스트를 공유하여 일관된 데이터 접근
        let context = PersistenceController.shared.container.viewContext

        // Repositories 초기화
        let foodRepository = FoodRepository(context: context)
        let foodRecordRepository = FoodRecordRepository(context: context)
        let dailyLogRepository = DailyLogRepository(context: context)

        // Services 초기화
        let foodRecordService = FoodRecordService(
            foodRecordRepository: foodRecordRepository,
            foodRepository: foodRepository,
            dailyLogRepository: dailyLogRepository
        )

        let localFoodSearchService = LocalFoodSearchService(
            foodRepository: foodRepository
        )

        let recentFoodsService = RecentFoodsService(
            foodRepository: foodRepository
        )

        // ViewModels 초기화
        _dailyMealViewModel = StateObject(wrappedValue: DailyMealViewModel(
            foodRecordService: foodRecordService,
            dailyLogRepository: dailyLogRepository,
            foodRepository: foodRepository
        ))

        _foodSearchViewModel = StateObject(wrappedValue: FoodSearchViewModel(
            foodSearchService: localFoodSearchService,
            recentFoodsService: recentFoodsService
        ))

        // 📚 학습 포인트: Photo Recognition Services 초기화
        // AI 사진 인식에 필요한 서비스들을 초기화합니다
        let apiConfig = APIConfig.shared
        let networkManager = NetworkManager(apiConfig: apiConfig)

        let visionAPIService = VisionAPIService(
            networkManager: networkManager,
            apiConfig: apiConfig,
            usageTracker: VisionAPIUsageTracker.shared
        )

        let foodLabelMatcher = FoodLabelMatcherService(
            foodSearchService: localFoodSearchService
        )

        _photoRecognitionViewModel = StateObject(wrappedValue: PhotoRecognitionViewModel(
            visionAPIService: visionAPIService,
            foodLabelMatcher: foodLabelMatcher,
            foodRecordService: foodRecordService,
            usageTracker: VisionAPIUsageTracker.shared
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            // 일일 식단 화면 (루트)
            DailyMealView(
                viewModel: dailyMealViewModel,
                userId: userId,
                bmr: bmr,
                tdee: tdee,
                onAddFood: { mealType in
                    // 음식 추가 버튼 클릭 시
                    selectedMealType = mealType
                    showingFoodSearch = true
                }
            )
            .sheet(isPresented: $showingFoodSearch) {
                // 음식 검색 화면 (시트로 표시)
                foodSearchSheet
            }
            .sheet(isPresented: $showingPhotoRecognition) {
                // 사진 인식 화면 (시트로 표시)
                photoRecognitionSheet
            }
        }
    }

    // MARK: - Subviews

    /// 음식 검색 시트
    ///
    /// 음식을 검색하고 선택하면 FoodDetailView로 네비게이션합니다.
    private var foodSearchSheet: some View {
        NavigationStack {
            FoodSearchView(
                viewModel: foodSearchViewModel,
                userId: userId,
                mealType: selectedMealType,
                onSelectFood: { food in
                    // 음식 선택 시 상세 화면으로 이동
                    selectedFoodId = food.id
                },
                onManualEntry: {
                    // 수동 입력 버튼 클릭 시
                    showingManualEntry = true
                },
                onPhotoRecognition: {
                    // 사진 인식 버튼 클릭 시
                    showingPhotoRecognition = true
                }
            )
            .navigationDestination(isPresented: Binding(
                get: { selectedFoodId != nil },
                set: { if !$0 { selectedFoodId = nil } }
            )) {
                // 음식 상세 화면
                if let foodId = selectedFoodId {
                    foodDetailView(foodId: foodId)
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                // 수동 입력 화면
                manualEntrySheet
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        showingFoodSearch = false
                    }
                }
            }
        }
    }

    /// 음식 상세 화면
    ///
    /// - Parameter foodId: 음식 ID
    /// - Returns: FoodDetailView
    private func foodDetailView(foodId: UUID) -> some View {
        let context = PersistenceController.shared.container.viewContext
        let foodRepository = FoodRepository(context: context)
        let foodRecordRepository = FoodRecordRepository(context: context)
        let dailyLogRepository = DailyLogRepository(context: context)
        let foodRecordService = FoodRecordService(
            foodRecordRepository: foodRecordRepository,
            foodRepository: foodRepository,
            dailyLogRepository: dailyLogRepository
        )

        let viewModel = FoodDetailViewModel(
            foodRepository: foodRepository,
            foodRecordService: foodRecordService
        )

        return FoodDetailView(
            viewModel: viewModel,
            foodId: foodId,
            userId: userId,
            date: dailyMealViewModel.selectedDate,
            initialMealType: selectedMealType,
            bmr: bmr,
            tdee: tdee,
            onSave: {
                // 저장 완료 시 음식 검색 시트 닫기 및 데이터 새로고침
                showingFoodSearch = false
                selectedFoodId = nil
                dailyMealViewModel.loadData(userId: userId, bmr: bmr, tdee: tdee)
            }
        )
    }

    /// 사진 인식 시트
    ///
    /// 사진으로 음식을 인식하고 자동으로 추가합니다.
    private var photoRecognitionSheet: some View {
        NavigationStack {
            PhotoCaptureSheetView(
                viewModel: photoRecognitionViewModel,
                photoCaptureService: PhotoCaptureService.shared,
                onImageSelected: { image in
                    // 이미지 선택 완료 후 분석 시작
                    Task {
                        do {
                            // ViewModel 초기화 (현재 날짜와 선택된 끼니 타입)
                            photoRecognitionViewModel.onAppear(
                                userId: userId,
                                date: dailyMealViewModel.selectedDate,
                                mealType: selectedMealType,
                                bmr: bmr,
                                tdee: tdee
                            )

                            // 이미지 분석 시작
                            try await photoRecognitionViewModel.analyzeImage(image)

                        } catch {
                            // 에러는 ViewModel에서 처리됨
                            #if DEBUG
                            print("❌ Photo recognition error: \(error)")
                            #endif
                        }
                    }
                },
                onCancel: {
                    // 사진 촬영 취소
                    showingPhotoRecognition = false
                },
                onManualEntry: {
                    // 할당량 초과 시 수동 음식 입력으로 전환
                    showingPhotoRecognition = false
                    // FoodSearchView로 자동 전환 (이미 NavigationStack 내부)
                }
            )
            // 📚 학습 포인트: Navigation Destination Based on ViewModel State
            // ViewModel의 상태에 따라 자동으로 결과 화면으로 전환
            .navigationDestination(isPresented: Binding(
                get: { photoRecognitionViewModel.hasResults },
                set: { if !$0 { photoRecognitionViewModel.resetState() } }
            )) {
                // 분석 결과 화면
                if case .results(let matches) = photoRecognitionViewModel.state {
                    RecognitionResultsView(
                        viewModel: photoRecognitionViewModel,
                        capturedImage: photoRecognitionViewModel.capturedImage,
                        matches: matches,
                        onContinue: { selectedMatches in
                            // 저장 완료 후 처리 (저장은 RecognitionConfirmView에서 이미 완료됨)
                            // 모든 시트 닫기 및 데이터 새로고침
                            showingPhotoRecognition = false
                            showingFoodSearch = false
                            dailyMealViewModel.loadData(userId: userId, bmr: bmr, tdee: tdee)
                        },
                        onAddMoreFoods: {
                            // 추가 음식 검색 (음식 검색 화면 열기)
                            // TODO: 구현 필요 - 현재는 단순히 닫기
                            #if DEBUG
                            print("ℹ️ Add more foods requested")
                            #endif
                        },
                        onRetry: {
                            // 재시도 - 다시 사진 촬영으로 돌아가기
                            Task {
                                try? await photoRecognitionViewModel.retry()
                            }
                        },
                        onCancel: {
                            // 취소 - 시트 닫기
                            showingPhotoRecognition = false
                        }
                    )
                }
            }
        }
    }

    /// 수동 입력 시트
    ///
    /// 데이터베이스에 없는 음식을 직접 입력합니다.
    private var manualEntrySheet: some View {
        NavigationStack {
            let context = PersistenceController.shared.container.viewContext
            let foodRepository = FoodRepository(context: context)
            let foodRecordRepository = FoodRecordRepository(context: context)
            let dailyLogRepository = DailyLogRepository(context: context)
            let foodRecordService = FoodRecordService(
                foodRecordRepository: foodRecordRepository,
                foodRepository: foodRepository,
                dailyLogRepository: dailyLogRepository
            )

            let viewModel = ManualFoodEntryViewModel(
                foodRepository: foodRepository,
                foodRecordService: foodRecordService
            )

            ManualFoodEntryView(
                viewModel: viewModel,
                userId: userId,
                date: dailyMealViewModel.selectedDate,
                mealType: selectedMealType,
                bmr: bmr,
                tdee: tdee,
                onSave: {
                    // 저장 완료 시 모든 시트 닫기 및 데이터 새로고침
                    showingManualEntry = false
                    showingFoodSearch = false
                    dailyMealViewModel.loadData(userId: userId, bmr: bmr, tdee: tdee)
                }
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        showingManualEntry = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DietTabView()
}
