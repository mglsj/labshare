import 'package:flutter/material.dart';
import 'package:labshare/app.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  await SystemTheme.accentColor.load();
  await windowManager.ensureInitialized();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle("LabShare");
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setPreventClose(true);
    await windowManager.center();
    await windowManager.show();
  });

  runApp(const App());
}
