import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../features/settings/data/github_release_service.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/widgets/duck_modal.dart';

/// 应用启动时静默检查 GitHub Release，若发现新版本则弹出软提示。
///
/// 用法：在 [AppShell] 的 initState 中调用 [UpdateChecker.checkOnStartup]。
class UpdateChecker {
  UpdateChecker._();

  static const String currentVersion = '1.0.0';

  /// 启动后延迟检查，避免阻塞首屏渲染。
  static Future<void> checkOnStartup(BuildContext context) async {
    // 延迟 2 秒，等首屏渲染完毕
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;

    try {
      final GitHubReleaseService service = GitHubReleaseService();
      final GitHubReleaseResult result =
          await service.checkForUpdate(currentVersion);

      if (!result.hasNewVersion) return;
      if (!context.mounted) return;

      await _showUpdateDialog(context, result);
    } catch (_) {
      // 静默失败，不打扰用户
    }
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    GitHubReleaseResult result,
  ) {
    return DuckModal.show<void>(
      context: context,
      barrierColor: const Color(0x66000000),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 336,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
          decoration: BoxDecoration(
            color: AppTokens.pageBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '发现新版本 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTokens.textMain,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'v${result.latestVersion} 已发布',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8F8A84),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (result.releaseNotes.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      result.releaseNotes,
                      style: const TextStyle(
                        color: Color(0xFF7D7770),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFF2EFE8),
                          foregroundColor: AppTokens.textMain,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('稍后再说'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).maybePop();
                          _launchUrl(result.updateUrl);
                        },
                        style: FilledButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppTokens.duckYellow,
                          foregroundColor: AppTokens.textMain,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('立即更新'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
