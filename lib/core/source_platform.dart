String detectSourcePlatform(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  if (host == 'mp.weixin.qq.com') {
    return 'wechat';
  }
  if (host == 'x.com' || host.endsWith('.x.com') || host == 'twitter.com') {
    return 'x';
  }
  if (host.endsWith('.twitter.com')) {
    return 'x';
  }
  if (host.contains('xiaohongshu.com') || host == 'xhslink.com') {
    return 'xiaohongshu';
  }
  if (host.contains('youtube.com') ||
      host == 'youtu.be' ||
      host.contains('bilibili.com') ||
      host.contains('douyin.com') ||
      host.contains('kuaishou.com')) {
    return 'video';
  }
  return 'web';
}
