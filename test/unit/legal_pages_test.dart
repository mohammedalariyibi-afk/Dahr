import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/legal/legal_documents.dart';

void main() {
  String html(String relativePath) =>
      File(relativePath).readAsStringSync();

  test('GitHub Pages privacy HTML includes the same AR+EN policy text', () {
    final page = html('legal-pages/privacy/index.html');
    final en = LegalDocuments.of(LegalDocumentKind.privacy, 'en');
    final ar = LegalDocuments.of(LegalDocumentKind.privacy, 'ar');
    expect(page, contains(en.title));
    expect(page, contains(ar.title));
    expect(page, contains(en.intro));
    expect(page, contains(ar.intro));
    expect(page, contains('vendor-photos'));
    expect(page, contains('eu-west-1'));
    expect(page, contains(LegalFacts.contactEmail));
    expect(page, contains('does not store card numbers'));
    expect(page, contains('حذف الحساب'));
    expect(page.toLowerCase(), isNot(contains('zeen')));
    for (final section in [...en.sections, ...ar.sections]) {
      expect(page, contains(section.heading));
      expect(page, contains(section.body));
    }
  });

  test('GitHub Pages terms HTML includes the same AR+EN terms text', () {
    final page = html('legal-pages/terms/index.html');
    final en = LegalDocuments.of(LegalDocumentKind.terms, 'en');
    final ar = LegalDocuments.of(LegalDocumentKind.terms, 'ar');
    expect(page, contains(en.title));
    expect(page, contains(ar.title));
    expect(page, contains('off-platform'));
    expect(page, contains('10%'));
    expect(page, contains('10٪'));
    expect(page, contains(LegalFacts.contactEmail));
    for (final section in [...en.sections, ...ar.sections]) {
      expect(page, contains(section.heading));
      expect(page, contains(section.body));
    }
  });

  test('legal-pages index links to privacy and terms without Vercel', () {
    final home = html('legal-pages/index.html');
    expect(home, contains('privacy/'));
    expect(home, contains('terms/'));
    expect(home.toLowerCase(), isNot(contains('vercel')));
    expect(File('legal-pages/.nojekyll').existsSync(), isTrue);
  });
}
