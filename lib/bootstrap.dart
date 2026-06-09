import 'package:flutter/material.dart';
import 'package:gears_flutter/app.dart';
import 'package:gears_flutter/core/storage/device_id_storage.dart';
import 'package:gears_flutter/core/storage/session_storage.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStorage.init();
  await DeviceIdStorage.init();
  runApp(const GearsErpApp());
}
