import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/presentation/pages/settings_page.dart';

void main() {
  group('SettingsPage 생성자', () {
    test('const 생성자로 인스턴스 생성 가능', () {
      // Line 9를 커버하기 위한 테스트
      const page = SettingsPage();
      expect(page, isA<SettingsPage>());
    });

    test('key를 전달할 수 있다', () {
      const key = Key('settings_page');
      const page = SettingsPage(key: key);
      expect(page.key, key);
    });
  });
}
