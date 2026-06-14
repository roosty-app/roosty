import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:roosty/sources/share_intent_source.dart';

void main() {
  test('converts initial shared text into an item and resets it', () async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [
        SharedMediaFile(
          path: '分享链接 https://mp.weixin.qq.com/s/example',
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      ],
      mediaStream: const Stream.empty(),
    );

    final item = await ShareIntentSource().watch().first;
    await Future<void>.delayed(Duration.zero);

    expect(item.url, 'https://mp.weixin.qq.com/s/example');
    expect(item.source, 'wechat');
    expect(await ReceiveSharingIntent.instance.getInitialMedia(), isEmpty);
  });

  test('converts hot shared URL stream into items', () async {
    final streamController = StreamController<List<SharedMediaFile>>();
    ReceiveSharingIntent.setMockValues(
      initialMedia: const [],
      mediaStream: streamController.stream,
    );
    addTearDown(streamController.close);

    final emitted = ShareIntentSource().watch().first;
    streamController.add([
      SharedMediaFile(
        path: 'https://x.com/roosty/status/1',
        type: SharedMediaType.url,
      ),
    ]);

    final item = await emitted;
    expect(item.url, 'https://x.com/roosty/status/1');
    expect(item.source, 'x');
  });

  test('keeps plain shared text as raw text fallback', () {
    final item = itemFromSharedMedia(
      SharedMediaFile(path: '一段没有链接的分享文本', type: SharedMediaType.text),
    );

    expect(item, isNotNull);
    expect(item!.url, startsWith('roosty://shared-text/'));
    expect(item.title, '一段没有链接的分享文本');
    expect(item.rawText, '一段没有链接的分享文本');
  });

  test('detects known source platforms from URL host', () {
    expect(detectSourcePlatform('https://mp.weixin.qq.com/s/a'), 'wechat');
    expect(detectSourcePlatform('https://x.com/user/status/1'), 'x');
    expect(detectSourcePlatform('https://twitter.com/user/status/1'), 'x');
    expect(detectSourcePlatform('https://mobile.twitter.com/user/1'), 'x');
    expect(
      detectSourcePlatform('https://www.xiaohongshu.com/explore/1'),
      'xiaohongshu',
    );
    expect(detectSourcePlatform('https://youtu.be/video'), 'video');
    expect(detectSourcePlatform('https://example.com'), 'web');
  });
}
