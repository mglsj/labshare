import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: 32),
      child: WindowCaption(
        brightness: brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
