import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/qroster_app.dart';
import 'src/state/qroster_controller.dart';
import 'src/storage/qroster_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final controller = QrosterController(
    store: SharedPreferencesQrosterStore(preferences),
  );
  await controller.load();

  runApp(
    ChangeNotifierProvider.value(value: controller, child: const QrosterApp()),
  );
}
