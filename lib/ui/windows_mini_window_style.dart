import 'dart:io';

import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

Future<void> applyMiniWindowStyles() async {
  if (!Platform.isWindows) {
    return;
  }

  final hwnd = await windowManager.getId();
  final currentStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
  SetWindowLongPtr(
    hwnd,
    GWL_EXSTYLE,
    currentStyle | WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST,
  );
  SetWindowPos(
    hwnd,
    HWND_TOPMOST,
    0,
    0,
    0,
    0,
    SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED,
  );
}
