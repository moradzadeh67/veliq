# CURRENT_TASK.md

### T-113 · [L] Implement Swift ImageSourceHandler for iOS

- Files:
  ios/Runner/ImageSourceHandler.swift (new file — MUST be added to Runner target in Xcode)
  ios/Runner/AppDelegate.swift (register handler)

- Do:

  Step 1 — Create ios/Runner/ImageSourceHandler.swift with EXACTLY this code:

  import Flutter
  import UIKit
  import PhotosUI

  final class ImageSourceHandler: NSObject, ImageSourceApiProtocol {

      private weak var viewController: UIViewController?

      init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
      }

      func pickImageFromGallery(completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
        guard let root = viewController else {
          completion(.success(nil))
          return
        }
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        let delegate = GalleryPickerDelegate(completion: completion)
        picker.delegate = delegate
        objc_setAssociatedObject(picker, &galleryDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        root.present(picker, animated: true)
      }

      func takePhotoWithCamera(completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
        guard let root = viewController else {
          completion(.success(nil))
          return
        }
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
          completion(.success(nil))
          return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image"]
        let delegate = CameraPickerDelegate(completion: completion)
        picker.delegate = delegate
        objc_setAssociatedObject(picker, &cameraDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        root.present(picker, animated: true)
      }
  }

  private var galleryDelegateKey: UInt8 = 0
  private var cameraDelegateKey: UInt8 = 0

  // MARK: - Gallery

  private final class GalleryPickerDelegate: NSObject, PHPickerViewControllerDelegate {
  private let completion: (Result<FlutterStandardTypedData?, Error>) -> Void
  init(completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
  self.completion = completion
  }
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
  picker.dismiss(animated: true)
  guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
  completion(.success(nil))
  return
  }
  provider.loadObject(ofClass: UIImage.self) { [completion] object, error in
  if let error = error {
  completion(.failure(error))
  return
  }
  guard let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.9) else {
  completion(.success(nil))
  return
  }
  completion(.success(FlutterStandardTypedData(bytes: data)))
  }
  }
  }

  // MARK: - Camera

  private final class CameraPickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  private let completion: (Result<FlutterStandardTypedData?, Error>) -> Void
  init(completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void) {
  self.completion = completion
  }
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
  picker.dismiss(animated: true)
  completion(.success(nil))
  }
  func imagePickerController(_ picker: UIImagePickerController,
  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
  picker.dismiss(animated: true)
  guard let image = info[.originalImage] as? UIImage,
  let data = image.jpegData(compressionQuality: 0.9) else {
  completion(.success(nil))
  return
  }
  completion(.success(FlutterStandardTypedData(bytes: data)))
  }
  }

  Step 2 — Edit ios/Runner/AppDelegate.swift:

  Replace the existing didInitializeImplicitFlutterEngine method with:

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
  GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  let messenger = engineBridge.applicationBinaryMessenger
  let rootVC = self.window?.rootViewController ?? UIViewController()
  ImageSourceApiSetup.setUp(binaryMessenger: messenger, api: ImageSourceHandler(viewController: rootVC))
  }

  If the property name for the binary messenger differs from applicationBinaryMessenger,
  STOP and report the exact error and the properties available on engineBridge.

- Don't:
  - Do NOT modify any Dart file.
  - Do NOT touch macos/.
  - Do NOT change pigeons/messages.dart.
  - Do NOT add new Swift files other than ImageSourceHandler.swift.
  - Do NOT run git.

- Ctx: AGENTS.md, AGENTS.PROJECT.md, ios/Runner/AppDelegate.swift, ios/Runner/Messages.g.swift

- Done when:
  - Both files exist and contain the exact code above.
  - `flutter build ios --no-codesign` succeeds.
  - ImageSourceHandler.swift is added to Runner target in Xcode (manual step — user confirms).

- Status: TODO

## Handover
- Step 1 writes a new Swift file. It MUST be added to Runner target in Xcode.
  If the worker cannot do it, that is expected — the user adds it manually.
- If the build fails with an error about ImageSourceApiSetup not found or
  binaryMessenger property, STOP and report the exact error.