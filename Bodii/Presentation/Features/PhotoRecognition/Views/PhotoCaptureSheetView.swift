//
//  PhotoCaptureSheetView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Photo Capture Sheet View
// 사진 소스 선택 및 이미지 캡처를 처리하는 메인 뷰
// 💡 카메라/갤러리 선택, 권한 처리, 이미지 미리보기를 통합 관리

import SwiftUI
import PhotosUI

// MARK: - Photo Capture Sheet View

/// 사진 캡처 시트 뷰
///
/// 사용자가 카메라로 촬영하거나 사진 라이브러리에서 이미지를 선택할 수 있는 화면입니다.
///
/// **주요 기능:**
/// - 카메라/사진 라이브러리 선택 옵션
/// - 권한 요청 및 권한 거부 상태 처리
/// - 선택/촬영한 이미지 미리보기
/// - 재촬영 기능
/// - 이미지 확정 및 콜백
///
/// - Note: PhotoCaptureService를 사용하여 권한 관리 및 이미지 처리를 수행합니다.
///
/// - Example:
/// ```swift
/// PhotoCaptureSheetView(
///     viewModel: photoRecognitionViewModel,
///     photoCaptureService: PhotoCaptureService.shared,
///     onImageSelected: { image in
///         // 선택된 이미지 처리
///     },
///     onCancel: {
///         // 취소 처리
///     },
///     onManualEntry: {
///         // 수동 입력으로 전환
///     }
/// )
/// ```
struct PhotoCaptureSheetView: View {

    // MARK: - Properties

    /// ViewModel (할당량 정보를 위해)
    @ObservedObject var viewModel: PhotoRecognitionViewModel

    /// 사진 캡처 서비스
    let photoCaptureService: PhotoCaptureServiceProtocol

    /// 이미지 선택 완료 콜백
    let onImageSelected: (UIImage) -> Void

    /// 취소 콜백
    let onCancel: () -> Void

    /// 수동 입력 콜백 (할당량 초과 시)
    let onManualEntry: () -> Void

    // MARK: - State

    /// 현재 뷰 상태
    ///
    /// 📚 학습 포인트: View State Management
    /// Enum을 사용하여 뷰의 다양한 상태를 명확하게 관리
    @State private var viewState: ViewState = .selection

    /// 선택된 사진 소스
    @State private var selectedSource: PhotoSource?

    /// 선택/촬영된 이미지
    @State private var capturedImage: UIImage?

    /// 카메라 표시 여부
    @State private var showingCamera = false

    /// 사진 라이브러리 표시 여부
    @State private var showingPhotoLibrary = false

    /// PhotosPicker 선택 항목 (iOS 16+)
    @State private var selectedPhotoItem: PhotosPickerItem?

    /// 로딩 상태
    @State private var isLoading = false

    /// 권한 거부 알림 표시 여부
    @State private var showingPermissionAlert = false

    /// 권한 거부된 소스
    @State private var deniedSource: PhotoSource?

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                // 배경색
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                // 할당량 초과 시 전체 화면 차단
                if viewModel.isQuotaExceeded {
                    QuotaWarningView(
                        showWarning: viewModel.showQuotaWarning,
                        remainingQuota: viewModel.remainingQuota,
                        daysUntilReset: viewModel.daysUntilReset,
                        isQuotaExceeded: viewModel.isQuotaExceeded,
                        onManualEntryTapped: {
                            onManualEntry()
                        }
                    )
                } else {
                    // 메인 컨텐츠
                    VStack(spacing: 0) {
                        // 할당량 경고 배너
                        if viewModel.showQuotaWarning {
                            QuotaWarningView(
                                showWarning: viewModel.showQuotaWarning,
                                remainingQuota: viewModel.remainingQuota,
                                daysUntilReset: viewModel.daysUntilReset,
                                isQuotaExceeded: viewModel.isQuotaExceeded,
                                onManualEntryTapped: {
                                    onManualEntry()
                                }
                            )
                        }

                        // 메인 컨텐츠
                        switch viewState {
                        case .selection:
                            sourceSelectionView
                        case .preview:
                            imagePreviewView
                        case .loading:
                            loadingView
                        }
                    }
                }
            }
            .navigationTitle("사진 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onCancel()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                if photoCaptureService.isCameraAvailable() {
                    ImagePicker(sourceType: .camera) { image in
                        handleImageCapture(image)
                    }
                }
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    handleImageCapture(image)
                }
            }
            .alert("권한 필요", isPresented: $showingPermissionAlert) {
                Button("설정으로 이동") {
                    photoCaptureService.openSettings()
                }
                Button("취소", role: .cancel) {
                    deniedSource = nil
                }
            } message: {
                if let source = deniedSource {
                    Text(source == .camera
                        ? "카메라 사용을 위해 설정에서 권한을 허용해주세요."
                        : "사진 라이브러리 접근을 위해 설정에서 권한을 허용해주세요.")
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem = newItem else { return }
                loadPhotoFromPicker(newItem)
            }
        }
    }

    // MARK: - Subviews

    /// 소스 선택 뷰
    ///
    /// 카메라 또는 사진 라이브러리 선택 옵션을 표시합니다.
    private var sourceSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 안내 아이콘
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 8)

            // 안내 텍스트
            VStack(spacing: 8) {
                Text("사진으로 음식 추가")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("사진을 찍거나 갤러리에서 선택하세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // 선택 버튼들
            VStack(spacing: 16) {
                // 카메라 버튼
                Button(action: handleCameraButtonTap) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title3)

                        Text("카메라로 촬영")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(!photoCaptureService.isCameraAvailable())
                .opacity(photoCaptureService.isCameraAvailable() ? 1.0 : 0.5)

                // 사진 라이브러리 버튼
                Button(action: handlePhotoLibraryButtonTap) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)

                        Text("사진 라이브러리")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }

    /// 이미지 미리보기 뷰
    ///
    /// 선택/촬영한 이미지를 미리보고 확정하거나 재촬영할 수 있습니다.
    private var imagePreviewView: some View {
        VStack(spacing: 0) {
            // 이미지 미리보기
            if let image = capturedImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .background(Color.black)
            } else {
                // 이미지가 없는 경우 (오류 상태)
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("이미지를 불러올 수 없습니다")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }

            // 액션 버튼들
            VStack(spacing: 12) {
                // 사진 사용 버튼
                Button(action: handleUsePhoto) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)

                        Text("이 사진 사용")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(capturedImage != nil ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(capturedImage == nil)

                // 재촬영 버튼
                Button(action: handleRetake) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)

                        Text("다시 선택")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    /// 로딩 뷰
    ///
    /// 이미지 처리 중 표시되는 로딩 인디케이터입니다.
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

            Text("이미지 처리 중...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    /// 카메라 버튼 탭 처리
    ///
    /// 카메라 권한을 확인하고 카메라 UI를 표시합니다.
    private func handleCameraButtonTap() {
        Task {
            let hasPermission = await requestCameraPermission()

            if hasPermission {
                await MainActor.run {
                    selectedSource = .camera
                    showingCamera = true
                }
            } else {
                await MainActor.run {
                    deniedSource = .camera
                    showingPermissionAlert = true
                }
            }
        }
    }

    /// 사진 라이브러리 버튼 탭 처리
    ///
    /// 사진 라이브러리 권한을 확인하고 선택 UI를 표시합니다.
    private func handlePhotoLibraryButtonTap() {
        Task {
            let hasPermission = await requestPhotoLibraryPermission()

            if hasPermission {
                await MainActor.run {
                    selectedSource = .library
                    showingPhotoLibrary = true
                }
            } else {
                await MainActor.run {
                    deniedSource = .library
                    showingPermissionAlert = true
                }
            }
        }
    }

    /// 이미지 캡처 처리
    ///
    /// 카메라 또는 사진 라이브러리에서 선택한 이미지를 처리합니다.
    ///
    /// - Parameter image: 선택된 이미지
    private func handleImageCapture(_ image: UIImage) {
        // 시트 닫기
        showingCamera = false
        showingPhotoLibrary = false

        // 이미지 저장 및 미리보기 표시
        capturedImage = image
        viewState = .preview
    }

    /// PhotosPicker에서 이미지 로드
    ///
    /// 📚 학습 포인트: PhotosPicker Integration (iOS 16+)
    /// PhotosPickerItem에서 이미지 데이터를 비동기로 로드
    ///
    /// - Parameter item: 선택된 PhotosPickerItem
    private func loadPhotoFromPicker(_ item: PhotosPickerItem) {
        Task {
            await MainActor.run {
                viewState = .loading
                isLoading = true
            }

            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // 이미지 방향 수정
                    let fixedImage = photoCaptureService.fixImageOrientation(image)

                    await MainActor.run {
                        capturedImage = fixedImage
                        viewState = .preview
                        isLoading = false
                    }
                } else {
                    await MainActor.run {
                        viewState = .selection
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    viewState = .selection
                    isLoading = false
                }
            }
        }
    }

    /// 사진 사용 처리
    ///
    /// 미리보기에서 사진 확정 시 호출됩니다.
    private func handleUsePhoto() {
        guard let image = capturedImage else { return }
        onImageSelected(image)
    }

    /// 재촬영 처리
    ///
    /// 미리보기에서 다시 선택 시 호출됩니다.
    private func handleRetake() {
        capturedImage = nil
        selectedPhotoItem = nil
        viewState = .selection
    }

    // MARK: - Permissions

    /// 카메라 권한 요청
    ///
    /// 📚 학습 포인트: Async Permission Request
    /// 비동기로 권한을 요청하고 결과를 반환
    ///
    /// - Returns: 권한 승인 여부
    private func requestCameraPermission() async -> Bool {
        let status = photoCaptureService.getCameraPermissionStatus()

        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await photoCaptureService.requestCameraPermission()
        }
    }

    /// 사진 라이브러리 권한 요청
    ///
    /// 📚 학습 포인트: Async Permission Request
    /// 비동기로 권한을 요청하고 결과를 반환
    ///
    /// - Returns: 권한 승인 여부
    private func requestPhotoLibraryPermission() async -> Bool {
        let status = photoCaptureService.getPhotoLibraryPermissionStatus()

        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await photoCaptureService.requestPhotoLibraryPermission()
        }
    }
}

// MARK: - View State

/// 뷰 상태
///
/// 📚 학습 포인트: View State Enum
/// 뷰의 다양한 상태를 명확하게 정의하여 UI 관리 용이
private enum ViewState {
    /// 소스 선택 상태
    case selection
    /// 이미지 미리보기 상태
    case preview
    /// 로딩 상태
    case loading
}

// MARK: - Preview
// Preview는 Core Data 엔티티 초기화 문제로 인해 임시 비활성화
// TODO: PreviewHelpers를 사용한 Preview 구현 필요

#Preview {
    Text("PhotoCaptureSheetView Preview")
        .font(.title)
        .foregroundColor(.secondary)
}
