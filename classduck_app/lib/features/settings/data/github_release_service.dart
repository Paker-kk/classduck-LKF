import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// 直接调用 GitHub Release API 检查新版本，零后端依赖。
///
/// API 文档：https://docs.github.com/en/rest/releases/releases#get-the-latest-release
/// 未认证请求限制 60 次/小时/IP，对个人 App 完全够用。
class GitHubReleaseService {
  GitHubReleaseService({
    http.Client? client,
    this.owner = 'luyishui',
    this.repo = 'classduck',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String owner;
  final String repo;

  /// 检查 GitHub 上是否有比 [currentVersion] 更新的 Release。
  Future<GitHubReleaseResult> checkForUpdate(String currentVersion) async {
    final Uri uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/releases/latest',
    );

    final http.Response response = await _client.get(uri, headers: <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    });

    if (response.statusCode == 404) {
      // 还没有创建过 Release
      return GitHubReleaseResult(
        hasNewVersion: false,
        latestVersion: currentVersion,
        currentVersion: currentVersion,
        releaseNotes: '',
        updateUrl: '',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub API 请求失败 (${response.statusCode})',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    final String tagName = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
    final String body = json['body'] as String? ?? '';
    final String htmlUrl = json['html_url'] as String? ?? '';

    // 从 assets 中查找 APK 下载链接
    String apkUrl = '';
    final List<dynamic> assets = json['assets'] as List<dynamic>? ?? <dynamic>[];
    for (final dynamic asset in assets) {
      if (asset is Map<String, dynamic>) {
        final String name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }
    }

    // 根据平台选择更新 URL
    final String updateUrl = _resolveUpdateUrl(apkUrl, htmlUrl);

    return GitHubReleaseResult(
      hasNewVersion: _isNewer(tagName, currentVersion),
      latestVersion: tagName,
      currentVersion: currentVersion,
      releaseNotes: body,
      updateUrl: updateUrl,
    );
  }

  String _resolveUpdateUrl(String apkUrl, String htmlUrl) {
    if (kIsWeb) {
      // Web 端直接刷新页面即可，不需要跳转
      return '';
    }
    try {
      if (Platform.isAndroid && apkUrl.isNotEmpty) {
        return apkUrl;
      }
      if (Platform.isIOS) {
        // 未来上架后替换为 App Store 链接
        return htmlUrl;
      }
    } catch (_) {
      // Platform 在 Web 上不可用，已在上面处理
    }
    return htmlUrl;
  }

  /// 语义化版本比较：[remote] 是否比 [local] 新。
  static bool _isNewer(String remote, String local) => isNewerPublic(remote, local);

  /// 公开版本比较方法，供单测使用。
  static bool isNewerPublic(String remote, String local) {
    final List<int> r = _parseVersion(remote);
    final List<int> l = _parseVersion(local);
    final int length = r.length > l.length ? r.length : l.length;
    for (int i = 0; i < length; i++) {
      final int rv = i < r.length ? r[i] : 0;
      final int lv = i < l.length ? l[i] : 0;
      if (rv > lv) return true;
      if (rv < lv) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    return v
        .replaceFirst('v', '')
        .split('.')
        .map((String s) => int.tryParse(s) ?? 0)
        .toList();
  }
}

class GitHubReleaseResult {
  const GitHubReleaseResult({
    required this.hasNewVersion,
    required this.latestVersion,
    required this.currentVersion,
    required this.releaseNotes,
    required this.updateUrl,
  });

  final bool hasNewVersion;
  final String latestVersion;
  final String currentVersion;
  final String releaseNotes;
  final String updateUrl;
}
