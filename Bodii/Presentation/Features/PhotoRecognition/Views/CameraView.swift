//
//  CameraView.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Custom Camera View
// AVFoundation을 사용한 커스텀 카메라 프리뷰 뷰
// 💡 더 세밀한 카메라 제어와 커스텀 UI를 위한 기반 제공

import SwiftUI
import AVFoundation

// MARK: - Camera View

/// 커스텀 카메라 뷰
///
/// AVFoundation을 사용하여 카메라 프리뷰와 촬영 기능을 제공합니다.
///
/// **주요 기능:**
/// - 실시간 카메라 프리뷰
/// - 커스텀 촬영 버튼 UI
/// - 플래시 제어
/// - 전면/후면 카메라 전환
/// - 사진 촬영 및 콜백
///
/// - Note: 현재는 기본 구현으로 ImagePicker를 사용하며, 향후 확장 가능
///
/// - Example:
/// ```swift
/// CameraView { image in
///     // 촬영된 이미지 처리
///     handleCapturedImage(image)
/// }
/// ```
struct CameraView: View {

    // MARK: - Properties

    /// 이미지 캡처 완료 콜백
    let onCapture: (UIImage) -> Void

    // MARK: - State

    /// 카메라 컨트롤러 표시 여부
    @State private var isPresented = true

    /// Dismiss를 위한 환경 변수
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            // 📚 학습 포인트: UIKit Integration
            // 현재는 UIImagePickerController를 사용하여 카메라 기능 제공
            // 향후 AVCaptureSession을 사용한 커스텀 카메라로 확장 가능
            Color.black
                .ignoresSafeArea()

            if isPresented {
                ImagePicker(sourceType: .camera) { image in
                    onCapture(image)
                    isPresented = false
                }
            }
        }
    }
}

// MARK: - Custom Camera View (AVFoundation 기반)

/// AVFoundation 기반 커스텀 카메라 뷰 컨트롤러
///
/// 📚 학습 포인트: AVFoundation Camera Implementation
/// 더 세밀한 카메라 제어가 필요할 때 사용할 수 있는 커스텀 구현
/// 💡 Java 비교: Camera2 API와 유사한 저수준 카메라 제어
///
/// **향후 확장 가능 기능:**
/// - 음식 촬영에 최적화된 카메라 설정
/// - 격자 가이드 표시
/// - 노출/초점 수동 조절
/// - HDR 활성화
/// - 이미지 안정화
///
/// - Note: 현재는 참고용 구현이며, 필요시 활성화하여 사용
class CameraViewController: UIViewController {

    // MARK: - Properties

    /// 카메라 세션
    ///
    /// 📚 학습 포인트: AVCaptureSession
    /// 카메라 입력과 출력을 관리하는 중앙 컨트롤러
    private var captureSession: AVCaptureSession?

    /// 사진 출력
    ///
    /// 📚 학습 포인트: AVCapturePhotoOutput
    /// 고품질 정지 이미지를 캡처하기 위한 출력 객체
    private var photoOutput: AVCapturePhotoOutput?

    /// 프리뷰 레이어
    ///
    /// 📚 학습 포인트: AVCaptureVideoPreviewLayer
    /// 카메라 프리뷰를 화면에 표시하는 레이어
    private var previewLayer: AVCaptureVideoPreviewLayer?

    /// 촬영 완료 콜백
    var onCapture: ((UIImage) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - Setup

    /// 카메라 설정
    ///
    /// 📚 학습 포인트: Camera Setup Flow
    /// 1. AVCaptureSession 생성
    /// 2. 입력 디바이스 추가 (카메라)
    /// 3. 출력 추가 (사진)
    /// 4. 프리뷰 레이어 설정
    /// 5. 세션 시작
    private func setupCamera() {
        // 세션 생성
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // 후면 카메라 가져오기
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }

        do {
            // 카메라 입력 생성
            let input = try AVCaptureDeviceInput(device: camera)

            // 입력 추가
            if session.canAddInput(input) {
                session.addInput(input)
            }

            // 사진 출력 생성
            let output = AVCapturePhotoOutput()

            // 출력 추가
            if session.canAddOutput(output) {
                session.addOutput(output)
                photoOutput = output
            }

            // 프리뷰 레이어 생성
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)

            self.previewLayer = previewLayer
            self.captureSession = session

            // 세션 시작 (백그라운드 스레드에서)
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }

        } catch {
            print("카메라 설정 실패: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    /// 사진 촬영
    ///
    /// 📚 학습 포인트: Photo Capture
    /// AVCapturePhotoOutput을 사용하여 고품질 사진 촬영
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }

        // 사진 설정
        let photoSettings = AVCapturePhotoSettings()

        // 플래시 자동 모드
        if photoOutput.supportedFlashModes.contains(.auto) {
            photoSettings.flashMode = .auto
        }

        // 고품질 우선
        photoSettings.isHighResolutionPhotoEnabled = true

        // 촬영
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    // MARK: - Cleanup

    /// 카메라 정리
    ///
    /// 📚 학습 포인트: Resource Cleanup
    /// 카메라 세션을 중지하고 리소스를 해제
    func stopCamera() {
        captureSession?.stopRunning()
        captureSession = nil
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {

    /// 사진 촬영 완료
    ///
    /// 📚 학습 포인트: Photo Capture Delegate
    /// 촬영된 사진 데이터를 UIImage로 변환하여 콜백 호출
    ///
    /// - Parameters:
    ///   - output: 사진 출력 객체
    ///   - photo: 촬영된 사진 객체
    ///   - error: 에러 (있는 경우)
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("사진 촬영 실패: \(error.localizedDescription)")
            return
        }

        // 사진 데이터 가져오기
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }

        // 이미지 방향 수정
        let fixedImage = PhotoCaptureService.shared.fixImageOrientation(image)

        // 콜백 호출
        onCapture?(fixedImage)
    }
}

// MARK: - SwiftUI Representable

/// CameraViewController를 SwiftUI에서 사용하기 위한 Wrapper
///
/// 📚 학습 포인트: UIViewController to SwiftUI Bridge
/// UIKit의 ViewController를 SwiftUI View로 감싸기
///
/// - Note: 현재는 참고용 구현이며, 기본적으로 ImagePicker를 사용
struct CustomCameraView: UIViewControllerRepresentable {

    // MARK: - Properties

    /// 촬영 완료 콜백
    let onCapture: (UIImage) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onCapture = onCapture
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 업데이트 불필요
    }

    static func dismantleUIViewController(_ uiViewController: CameraViewController, coordinator: ()) {
        // 리소스 정리
        uiViewController.stopCamera()
    }
}

// MARK: - Preview

#Preview("Camera View") {
    CameraView { image in
        print("Captured image: \(image.size)")
    }
}

#if DEBUG
#Preview("Custom Camera View") {
    CustomCameraView { image in
        print("Captured image: \(image.size)")
    }
}
#endif
