//
//  PhotoCaptureService.swift
//  Bodii
//
//  Created by Auto-Claude on 2026-01-17.
//

// 📚 학습 포인트: Photo Capture Service
// 카메라와 사진 라이브러리 접근을 처리하는 서비스
// 💡 Java 비교: Camera Manager/Gallery Picker와 유사

import Foundation
import SwiftUI
import PhotosUI
import AVFoundation

/// 사진 소스 타입
///
/// 📚 학습 포인트: Enum으로 선택 옵션 정의
/// 사용자가 카메라 또는 사진 라이브러리 중 선택 가능
enum PhotoSource {
    /// 카메라로 촬영
    case camera
    /// 사진 라이브러리에서 선택
    case library
}

/// 권한 상태
///
/// 📚 학습 포인트: Permission States
/// iOS 권한 요청 결과를 명확하게 표현
/// 💡 Java 비교: Android Permission Result와 유사
enum PermissionStatus {
    /// 권한 승인됨
    case authorized
    /// 권한 거부됨
    case denied
    /// 권한 제한됨 (예: 자녀 보호 기능)
    case restricted
    /// 아직 권한을 요청하지 않음
    case notDetermined
}

/// 사진 캡처 서비스 프로토콜
///
/// 📚 학습 포인트: Protocol-Oriented Programming
/// 인터페이스를 정의하여 테스트와 Mock 객체 구현 용이
/// 💡 Java 비교: Interface와 동일한 역할
protocol PhotoCaptureServiceProtocol {
    /// 카메라 권한 상태 확인
    func getCameraPermissionStatus() -> PermissionStatus

    /// 사진 라이브러리 권한 상태 확인
    func getPhotoLibraryPermissionStatus() -> PermissionStatus

    /// 카메라 권한 요청
    func requestCameraPermission() async -> Bool

    /// 사진 라이브러리 권한 요청
    func requestPhotoLibraryPermission() async -> Bool

    /// 카메라 사용 가능 여부
    func isCameraAvailable() -> Bool

    /// 이미지 방향 수정
    func fixImageOrientation(_ image: UIImage) -> UIImage

    /// 설정 앱 열기
    func openSettings()
}

/// 사진 캡처 서비스 구현체
///
/// 📚 학습 포인트: Photo Capture Service
/// 카메라와 사진 라이브러리 접근을 통합 관리하는 서비스
/// 💡 Java 비교: CameraManager + GalleryPicker 결합 패턴
///
/// **주요 기능:**
/// - 카메라 권한 관리
/// - 사진 라이브러리 권한 관리
/// - 이미지 방향 자동 수정
/// - 메모리 효율적인 이미지 처리
///
/// **사용 예시:**
/// ```swift
/// let service = PhotoCaptureService()
///
/// // 카메라 권한 확인 및 요청
/// if service.isCameraAvailable() {
///     let granted = await service.requestCameraPermission()
///     if granted {
///         // 카메라 UI 표시
///     }
/// }
///
/// // 사진 라이브러리 권한 요청
/// let granted = await service.requestPhotoLibraryPermission()
/// if granted {
///     // PhotosPicker UI 표시
/// }
///
/// // 이미지 방향 수정
/// let fixedImage = service.fixImageOrientation(originalImage)
/// ```
final class PhotoCaptureService: PhotoCaptureServiceProtocol {

    // MARK: - Singleton

    /// 공유 인스턴스
    ///
    /// 📚 학습 포인트: Singleton Pattern
    /// 앱 전체에서 하나의 서비스 인스턴스만 사용
    /// 💡 Java 비교: @Singleton 어노테이션과 유사
    static let shared = PhotoCaptureService()

    // MARK: - Initialization

    /// 초기화
    ///
    /// 📚 학습 포인트: Private Init
    /// Singleton 패턴 구현을 위해 외부에서 인스턴스 생성 방지
    private init() {}

    // MARK: - Camera Permissions

    func getCameraPermissionStatus() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return convertAVAuthorizationStatus(status)
    }

    func requestCameraPermission() async -> Bool {
        // 현재 권한 상태 확인
        let currentStatus = getCameraPermissionStatus()

        switch currentStatus {
        case .authorized:
            // 이미 권한이 있음
            return true

        case .denied, .restricted:
            // 거부되었거나 제한됨 - 설정에서 변경 필요
            return false

        case .notDetermined:
            // 아직 요청하지 않음 - 권한 요청
            return await AVCaptureDevice.requestAccess(for: .video)
        }
    }

    func isCameraAvailable() -> Bool {
        // 카메라 하드웨어가 있는지 확인
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    // MARK: - Photo Library Permissions

    func getPhotoLibraryPermissionStatus() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return convertPHAuthorizationStatus(status)
    }

    func requestPhotoLibraryPermission() async -> Bool {
        // 현재 권한 상태 확인
        let currentStatus = getPhotoLibraryPermissionStatus()

        switch currentStatus {
        case .authorized:
            // 이미 권한이 있음
            return true

        case .denied, .restricted:
            // 거부되었거나 제한됨 - 설정에서 변경 필요
            return false

        case .notDetermined:
            // 아직 요청하지 않음 - 권한 요청
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return status == .authorized || status == .limited
        }
    }

    // MARK: - Image Processing

    func fixImageOrientation(_ image: UIImage) -> UIImage {
        // 이미지 방향이 이미 올바른 경우 그대로 반환
        if image.imageOrientation == .up {
            return image
        }

        // 메모리 효율적으로 이미지 방향 수정
        guard let cgImage = image.cgImage else {
            return image
        }

        // 새로운 크기 계산 (회전을 고려)
        var transform = CGAffineTransform.identity

        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: .pi)

        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)

        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: -.pi / 2)

        default:
            break
        }

        // 미러링 처리
        switch image.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        default:
            break
        }

        // 그래픽 컨텍스트 생성 및 이미지 그리기
        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(image.size.width),
                height: Int(image.size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return image
        }

        context.concatenate(transform)

        // 이미지 방향에 따라 그리기 영역 설정
        let drawRect: CGRect
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            drawRect = CGRect(
                x: 0,
                y: 0,
                width: image.size.height,
                height: image.size.width
            )
        default:
            drawRect = CGRect(
                x: 0,
                y: 0,
                width: image.size.width,
                height: image.size.height
            )
        }

        context.draw(cgImage, in: drawRect)

        // 새로운 이미지 생성
        guard let newCGImage = context.makeImage() else {
            return image
        }

        return UIImage(
            cgImage: newCGImage,
            scale: image.scale,
            orientation: .up
        )
    }

    // MARK: - Settings

    func openSettings() {
        // 설정 앱의 이 앱 페이지로 이동
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }

    // MARK: - Private Helpers

    /// AVFoundation 권한 상태를 공통 PermissionStatus로 변환
    ///
    /// 📚 학습 포인트: Type Conversion
    /// 플랫폼 특정 타입을 앱 도메인 타입으로 변환
    /// 💡 Java 비교: Mapper 패턴
    ///
    /// - Parameter status: AVFoundation 권한 상태
    /// - Returns: 공통 권한 상태
    private func convertAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    /// Photos Framework 권한 상태를 공통 PermissionStatus로 변환
    ///
    /// 📚 학습 포인트: Type Conversion
    /// iOS 14+ limited 권한도 authorized로 처리
    /// (일부 사진만 접근 가능해도 기능 사용 가능)
    ///
    /// - Parameter status: Photos Framework 권한 상태
    /// - Returns: 공통 권한 상태
    private func convertPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited:
            // limited는 iOS 14+에서 일부 사진만 접근 가능한 상태
            // 사용자가 선택한 사진은 접근 가능하므로 authorized로 처리
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

// MARK: - UIImagePickerController Coordinator

/// UIKit의 UIImagePickerController를 SwiftUI에서 사용하기 위한 Coordinator
///
/// 📚 학습 포인트: SwiftUI + UIKit Integration
/// UIKit의 UIImagePickerController를 SwiftUI에서 사용하기 위한 브리지
/// 💡 Java 비교: Adapter 패턴
///
/// **사용 이유:**
/// - SwiftUI의 PhotosPicker는 iOS 16+에서만 사용 가능
/// - 카메라는 UIImagePickerController 사용 필요
/// - 하위 버전 호환성을 위해 UIKit 브리지 제공
class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties

    /// 이미지 선택 완료 콜백
    ///
    /// 📚 학습 포인트: Closure as Callback
    /// SwiftUI View로 결과를 전달하기 위한 콜백
    /// 💡 Java 비교: Callback Interface
    var onImagePicked: ((UIImage) -> Void)?

    /// 취소 콜백
    var onCancel: (() -> Void)?

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        // 편집된 이미지가 있으면 사용, 없으면 원본 사용
        if let image = info[.editedImage] as? UIImage {
            // 이미지 방향 수정
            let fixedImage = PhotoCaptureService.shared.fixImageOrientation(image)
            onImagePicked?(fixedImage)
        } else if let image = info[.originalImage] as? UIImage {
            // 이미지 방향 수정
            let fixedImage = PhotoCaptureService.shared.fixImageOrientation(image)
            onImagePicked?(fixedImage)
        }

        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        onCancel?()
        picker.dismiss(animated: true)
    }
}

// MARK: - SwiftUI Representable

/// UIImagePickerController를 SwiftUI에서 사용하기 위한 Wrapper
///
/// 📚 학습 포인트: UIViewControllerRepresentable
/// UIKit ViewController를 SwiftUI View로 감싸기
/// 💡 Java 비교: Bridge 패턴
///
/// **사용 예시:**
/// ```swift
/// @State private var showImagePicker = false
/// @State private var selectedImage: UIImage?
///
/// .sheet(isPresented: $showImagePicker) {
///     ImagePicker(sourceType: .camera) { image in
///         selectedImage = image
///     }
/// }
/// ```
struct ImagePicker: UIViewControllerRepresentable {

    // MARK: - Properties

    /// 사진 소스 타입 (카메라 or 라이브러리)
    let sourceType: UIImagePickerController.SourceType

    /// 이미지 선택 완료 콜백
    let onImagePicked: (UIImage) -> Void

    /// Dismiss를 위한 환경 변수
    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator

        // 카메라의 경우 편집 허용
        if sourceType == .camera {
            picker.allowsEditing = true
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 업데이트 불필요
    }

    func makeCoordinator() -> ImagePickerCoordinator {
        let coordinator = ImagePickerCoordinator()

        coordinator.onImagePicked = { [onImagePicked] image in
            onImagePicked(image)
        }

        coordinator.onCancel = {
            dismiss()
        }

        return coordinator
    }
}

// MARK: - Testing Support

#if DEBUG
/// 테스트용 Mock Photo Capture Service
///
/// 📚 학습 포인트: Mock Objects for Testing
/// 테스트에서 실제 권한 요청 없이 동작 검증 가능
/// 💡 Java 비교: Mockito의 @Mock과 유사
final class MockPhotoCaptureService: PhotoCaptureServiceProtocol {

    // MARK: - Mock Properties

    /// Mock 카메라 권한 상태
    var cameraPermissionStatus: PermissionStatus = .notDetermined

    /// Mock 사진 라이브러리 권한 상태
    var photoLibraryPermissionStatus: PermissionStatus = .notDetermined

    /// Mock 카메라 사용 가능 여부
    var cameraAvailable: Bool = true

    /// 권한 요청 시 반환할 값
    var permissionGranted: Bool = true

    /// 호출 횟수 추적
    var requestCameraPermissionCallCount = 0
    var requestPhotoLibraryPermissionCallCount = 0

    // MARK: - Protocol Implementation

    func getCameraPermissionStatus() -> PermissionStatus {
        return cameraPermissionStatus
    }

    func getPhotoLibraryPermissionStatus() -> PermissionStatus {
        return photoLibraryPermissionStatus
    }

    func requestCameraPermission() async -> Bool {
        requestCameraPermissionCallCount += 1
        return permissionGranted
    }

    func requestPhotoLibraryPermission() async -> Bool {
        requestPhotoLibraryPermissionCallCount += 1
        return permissionGranted
    }

    func isCameraAvailable() -> Bool {
        return cameraAvailable
    }

    func fixImageOrientation(_ image: UIImage) -> UIImage {
        // 테스트에서는 그대로 반환
        return image
    }

    func openSettings() {
        // 테스트에서는 아무 동작 안 함
    }

    // MARK: - Test Helpers

    func reset() {
        cameraPermissionStatus = .notDetermined
        photoLibraryPermissionStatus = .notDetermined
        cameraAvailable = true
        permissionGranted = true
        requestCameraPermissionCallCount = 0
        requestPhotoLibraryPermissionCallCount = 0
    }
}
#endif
