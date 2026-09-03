import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/constants/app_constants.dart';

void main() {
  group('WhatsApp deep link', () {
    test('only builds https wa.me URLs from digits', () {
      final url = AppConstants.whatsappUrl('+218912345678');
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/218912345678');
    });

    test('strips non-digits so a javascript URL cannot be launched', () {
      final url = AppConstants.whatsappUrl('javascript:alert(1)');
      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path.contains('javascript'), isFalse);
    });
  });
}
