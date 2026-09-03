import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/supabase/write_guard.dart';

void main() {
  group('requireMutatedRows fails closed', () {
    test('null and empty results are rejected', () {
      expect(() => requireMutatedRows(null), throwsStateError);
      expect(() => requireMutatedRows(<dynamic>[]), throwsStateError);
      // Regression: an empty Map was accepted while an empty List was
      // rejected, so a zero-row write could read as success.
      expect(() => requireMutatedRows(<String, dynamic>{}), throwsStateError);
    });

    test('rejects with the caller code so copy stays safe', () {
      expect(
        () => requireMutatedRows(null, code: 'not_vendor'),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'not_vendor'),
        ),
      );
    });

    test('non-row results are rejected', () {
      expect(() => requireMutatedRows('ok'), throwsStateError);
      expect(() => requireMutatedRows(1), throwsStateError);
    });

    test('returns rows for a populated list or single row', () {
      expect(
        requireMutatedRows([
          {'id': 'a'},
        ]),
        [
          {'id': 'a'},
        ],
      );
      expect(requireMutatedRows({'id': 'b'}), [
        {'id': 'b'},
      ]);
    });
  });
}
