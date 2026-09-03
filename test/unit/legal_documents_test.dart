import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/legal/legal_documents.dart';

void main() {
  bool covers(LegalDocument doc, List<String> needles) {
    final text = doc.fullText.toLowerCase();
    return needles.every((n) => text.contains(n.toLowerCase()));
  }

  group('LegalDocuments privacy', () {
    test('EN names accounts, OTP, photos, WhatsApp, storage region, no cards', () {
      final doc = LegalDocuments.of(LegalDocumentKind.privacy, 'en');
      expect(doc.title, 'Privacy policy');
      expect(
        covers(doc, [
          LegalFacts.startingPolicyEn,
          'OTP',
          'phone',
          'email',
          'vendor-photos',
          'WhatsApp',
          'booking',
          'eu-west-1',
          'card',
          LegalFacts.contactEmail,
          'Profile',
          'Delete account',
          '10%',
        ]),
        isTrue,
      );
      expect(doc.fullText.toLowerCase(), contains('does not store card numbers'));
      expect(doc.fullText.toLowerCase(), isNot(contains('zeen')));
    });

    test('AR covers the same topics', () {
      final doc = LegalDocuments.of(LegalDocumentKind.privacy, 'ar');
      expect(doc.title, 'سياسة الخصوصية');
      expect(
        covers(doc, [
          LegalFacts.startingPolicyAr,
          'OTP',
          'واتساب',
          'eu-west-1',
          'بطاقات',
          LegalFacts.contactEmail,
          'حذف الحساب',
          '10٪',
        ]),
        isTrue,
      );
    });
  });

  group('LegalDocuments terms', () {
    test('EN describes off-platform pay, commission, and self-serve deletion', () {
      final doc = LegalDocuments.of(LegalDocumentKind.terms, 'en');
      expect(doc.title, 'Terms of use');
      expect(
        covers(doc, [
          'off-platform',
          '10%',
          'WhatsApp',
          'Delete',
          LegalFacts.contactEmail,
          'Libya',
        ]),
        isTrue,
      );
    });

    test('AR is the default-language terms document', () {
      final doc = LegalDocuments.of(LegalDocumentKind.terms, 'ar');
      expect(doc.title, 'شروط الاستخدام');
      expect(doc.fullText, contains('10٪'));
      expect(doc.fullText, contains(LegalFacts.contactEmail));
    });
  });

  test('unknown language codes fall back to English', () {
    expect(
      LegalDocuments.of(LegalDocumentKind.privacy, 'fr').title,
      'Privacy policy',
    );
  });
}
