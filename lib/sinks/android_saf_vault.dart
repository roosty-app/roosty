// v1: deferred — mobile/Android features are frozen but preserved.
// See DECISIONS.md §移动端暂缓决策记录 for restoration conditions.

import 'package:flutter/services.dart';

class AndroidSafVault {
  const AndroidSafVault({
    MethodChannel channel = const MethodChannel('roosty/android_saf'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<String?> pickDirectory() {
    return _channel.invokeMethod<String>('pickDirectory');
  }

  Future<void> ensureDirectory({
    required String treeUri,
    required String directoryName,
  }) async {
    final ensured = await _channel.invokeMethod<bool>('ensureDirectory', {
      'treeUri': treeUri,
      'directoryName': directoryName,
    });
    if (ensured != true) {
      throw PlatformException(
        code: 'empty_result',
        message: 'Android SAF ensureDirectory returned no confirmation.',
      );
    }
  }

  Future<String> writeTextFile({
    required String treeUri,
    required String directoryName,
    required String fileName,
    required String content,
  }) async {
    final writtenName = await _channel.invokeMethod<String>('writeTextFile', {
      'treeUri': treeUri,
      'directoryName': directoryName,
      'fileName': fileName,
      'content': content,
    });
    if (writtenName == null || writtenName.isEmpty) {
      throw PlatformException(
        code: 'empty_result',
        message: 'Android SAF write returned no file name.',
      );
    }
    return writtenName;
  }
}
