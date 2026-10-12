import Flutter
import UIKit
import PhotosUI

final class ImageSourceHandler: NSObject, ImageSourceApi {

  private weak var viewController: UIViewController?

  init(viewController: UIViewController) {
    self.viewController = viewController
    super.init()
  }

  @MainActor
  func pickImageFromGallery() async throws -> FlutterStandardTypedData? {
    guard let root = viewController else {
      return nil
    }
    return await withCheckedContinuation { continuation in
      var config = PHPickerConfiguration()
      config.filter = .images
      config.selectionLimit = 1
      let picker = PHPickerViewController(configuration: config)
      let delegate = GalleryPickerDelegate { result in
        continuation.resume(returning: result)
      }
      picker.delegate = delegate
      objc_setAssociatedObject(picker, &galleryDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      root.present(picker, animated: true)
    }
  }

  @MainActor
  func takePhotoWithCamera() async throws -> FlutterStandardTypedData? {
    guard let root = viewController, UIImagePickerController.isSourceTypeAvailable(.camera) else {
      return nil
    }
    return await withCheckedContinuation { continuation in
      let picker = UIImagePickerController()
      picker.sourceType = .camera
      picker.mediaTypes = ["public.image"]
      let delegate = CameraPickerDelegate { result in
        continuation.resume(returning: result)
      }
      picker.delegate = delegate
      objc_setAssociatedObject(picker, &cameraDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      root.present(picker, animated: true)
    }
  }
}

private var galleryDelegateKey: UInt8 = 0
private var cameraDelegateKey: UInt8 = 0

// MARK: - Gallery

private final class GalleryPickerDelegate: NSObject, PHPickerViewControllerDelegate {
  private let completion: (FlutterStandardTypedData?) -> Void

  init(completion: @escaping (FlutterStandardTypedData?) -> Void) {
    self.completion = completion
  }

  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
      completion(nil)
      return
    }
    provider.loadObject(ofClass: UIImage.self) { object, _ in
      guard let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.9) else {
        self.completion(nil)
        return
      }
      self.completion(FlutterStandardTypedData(bytes: data))
    }
  }
}

// MARK: - Camera

private final class CameraPickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let completion: (FlutterStandardTypedData?) -> Void

  init(completion: @escaping (FlutterStandardTypedData?) -> Void) {
    self.completion = completion
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    completion(nil)
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage,
          let data = image.jpegData(compressionQuality: 0.9) else {
      completion(nil)
      return
    }
    completion(FlutterStandardTypedData(bytes: data))
  }
}
