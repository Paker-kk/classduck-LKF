import 'package:flutter_test/flutter_test.dart';
import 'package:classduck_app/features/settings/data/github_release_service.dart';

void main() {
  group('GitHubReleaseService 版本比较', () {
    test('远程版本较高 → 有新版本', () {
      expect(GitHubReleaseService.isNewerPublic('1.1.0', '1.0.0'), isTrue);
    });

    test('远程版本相同 → 无新版本', () {
      expect(GitHubReleaseService.isNewerPublic('1.0.0', '1.0.0'), isFalse);
    });

    test('远程版本较低 → 无新版本', () {
      expect(GitHubReleaseService.isNewerPublic('0.9.0', '1.0.0'), isFalse);
    });

    test('patch 版本更新', () {
      expect(GitHubReleaseService.isNewerPublic('1.0.1', '1.0.0'), isTrue);
    });

    test('major 版本更新', () {
      expect(GitHubReleaseService.isNewerPublic('2.0.0', '1.9.9'), isTrue);
    });

    test('带 v 前缀', () {
      expect(GitHubReleaseService.isNewerPublic('v1.1.0', 'v1.0.0'), isTrue);
    });

    test('不同长度版本号', () {
      expect(GitHubReleaseService.isNewerPublic('1.0.0.1', '1.0.0'), isTrue);
    });

    test('空版本号 → 无新版本', () {
      expect(GitHubReleaseService.isNewerPublic('', '1.0.0'), isFalse);
    });
  });
}
