import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Opens the iOS camera through the app's own full-screen presenter.
class IosCameraPicker {
  static const _channel = MethodChannel('gears_flutter/camera');

  static Future<XFile?> pickImage() async {
    final path = await _channel.invokeMethod<String>('pickImage');
    if (path == null || path.isEmpty) return null;
    return XFile(path);
  }
}
