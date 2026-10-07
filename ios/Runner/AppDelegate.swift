import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let leaveCameraPicker = LeaveCameraPicker()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "gears_flutter/camera",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self else {
        result(
          FlutterError(
            code: "camera_unavailable",
            message: "Camera is not available.",
            details: nil
          )
        )
        return
      }
      self.leaveCameraPicker.pickImage(result: result)
    }
  }
}

/// Presents the system camera full screen on the visible view controller.
/// image_picker presents the camera inside a new transparent window, and iOS
/// drops that presentation, so the camera UI never appears.
private final class LeaveCameraPicker: NSObject, UIImagePickerControllerDelegate,
  UINavigationControllerDelegate
{
  private var result: FlutterResult?
  private var didFinish = false

  func pickImage(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
        result(
          FlutterError(
            code: "camera_unavailable",
            message: "Camera is not available on this device.",
            details: nil
          )
        )
        return
      }

      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
        self.presentCamera(result: result)
      case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
          DispatchQueue.main.async {
            if granted {
              self.presentCamera(result: result)
            } else {
              result(
                FlutterError(
                  code: "camera_access_denied",
                  message: "Camera access was denied.",
                  details: nil
                )
              )
            }
          }
        }
      default:
        result(
          FlutterError(
            code: "camera_access_denied",
            message: "Camera access was denied. Enable it in Settings.",
            details: nil
          )
        )
      }
    }
  }

  private func presentCamera(result: @escaping FlutterResult) {
    guard let presenter = Self.topViewController() else {
      result(
        FlutterError(
          code: "camera_unavailable",
          message: "Could not open the camera.",
          details: nil
        )
      )
      return
    }

    self.result = result
    didFinish = false

    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    picker.modalPresentationStyle = .fullScreen
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage,
      let data = image.jpegData(compressionQuality: 0.7)
    else {
      finish(nil)
      return
    }

    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("photo-\(Int(Date().timeIntervalSince1970)).jpg")
    do {
      try data.write(to: url)
      finish(url.path)
    } catch {
      finish(
        FlutterError(
          code: "camera_save_failed",
          message: "Could not save the photo.",
          details: nil
        )
      )
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    finish(nil)
  }

  private func finish(_ value: Any?) {
    guard !didFinish else { return }
    didFinish = true
    result?(value)
    result = nil
  }

  private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
    let root: UIViewController? = {
      if let base {
        return base
      }
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
      return scene?.windows.first { $0.isKeyWindow }?.rootViewController
        ?? scene?.windows.first?.rootViewController
    }()

    if let navigation = root as? UINavigationController {
      return topViewController(base: navigation.visibleViewController)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topViewController(base: selected)
    }
    if let presented = root?.presentedViewController {
      return topViewController(base: presented)
    }
    return root
  }
}
