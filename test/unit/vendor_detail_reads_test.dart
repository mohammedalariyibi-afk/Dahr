import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/review.dart';

void main() {
  late String vendorsProvider;

  setUpAll(() {
    vendorsProvider =
        File('lib/features/discovery/providers/vendors_provider.dart')
            .readAsStringSync();
  });

  group('review author names survive profiles RLS', () {
    test('names come from profile_public, not a profiles embed', () {
      // `profiles` only exposes your own row, so an embed renders every other
      // author (and all authors for a guest) with no name.
      expect(vendorsProvider, isNot(contains('profiles(full_name)')));
      expect(vendorsProvider, contains("from('profile_public')"));
      expect(vendorsProvider, contains("inFilter('id', ids)"));
    });

    test('a looked-up name replaces nothing else on the review', () {
      const review = Review(
        id: 'r1',
        vendorId: 'v1',
        consumerId: 'c1',
        bookingRequestId: 'b1',
        rating: 5,
        comment: 'Beautiful hall',
      );
      final named = review.withConsumerName('Salma');
      expect(named.consumerName, 'Salma');
      expect(named.id, review.id);
      expect(named.rating, review.rating);
      expect(named.comment, review.comment);
      expect(named.isHidden, isFalse);
      expect(named.withConsumerName(null).consumerName, isNull);
    });
  });

  group('vendor view count', () {
    test('the RPC is actually sent', () {
      // A Postgrest builder is lazy: the old fire-and-forget call was never
      // awaited, so the request never left the app.
      final counter = vendorsProvider.substring(
        vendorsProvider.indexOf('void _countVendorView'),
        vendorsProvider.indexOf('final vendorReviewsProvider'),
      );
      expect(counter, contains("rpc('increment_vendor_views'"));
      expect(counter, contains('.then('));
      expect(counter, contains('onError:'));
      expect(vendorsProvider, isNot(contains('ignore: unawaited_futures')));
    });

    test('one view per vendor per app run', () {
      expect(vendorsProvider, contains('_countedVendorViews'));
      expect(vendorsProvider, contains('if (!_countedVendorViews.add(vendorId)) return;'));
    });
  });
}
