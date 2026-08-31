import 'package:core/core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collected_details.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collection_cubit.dart';

void main() {
  test('all three fields start loading and are not complete', () {
    fakeAsync((async) {
      final cubit = UaePassCollectionCubit();

      expect(cubit.state.fullNameStatus, RequestStatus.loading);
      expect(cubit.state.verifiedIdentityStatus, RequestStatus.loading);
      expect(cubit.state.mobileNumberStatus, RequestStatus.loading);
      expect(cubit.state.isComplete, isFalse);
      expect(cubit.state.progress, 0);

      async.elapse(const Duration(seconds: 3));
      cubit.close();
    });
  });

  test('fields complete in order and isComplete flips once all three do', () {
    fakeAsync((async) {
      final cubit = UaePassCollectionCubit();

      async.elapse(const Duration(milliseconds: 700));
      expect(cubit.state.fullNameStatus, RequestStatus.success);
      expect(cubit.state.verifiedIdentityStatus, RequestStatus.loading);
      expect(cubit.state.mobileNumberStatus, RequestStatus.loading);
      expect(cubit.state.isComplete, isFalse);

      async.elapse(const Duration(milliseconds: 800));
      expect(cubit.state.verifiedIdentityStatus, RequestStatus.success);
      expect(cubit.state.mobileNumberStatus, RequestStatus.loading);
      expect(cubit.state.isComplete, isFalse);

      async.elapse(const Duration(milliseconds: 800));
      expect(cubit.state.mobileNumberStatus, RequestStatus.success);
      expect(cubit.state.isComplete, isTrue);
      expect(cubit.state.progress, 1);

      cubit.close();
    });
  });

  test('defaults to placeholder details when none are provided', () {
    fakeAsync((async) {
      final cubit = UaePassCollectionCubit();

      expect(cubit.state.details, UaePassCollectedDetails.placeholder());

      async.elapse(const Duration(seconds: 3));
      cubit.close();
    });
  });

  test('uses the provided details instead of the placeholder', () {
    fakeAsync((async) {
      const details = UaePassCollectedDetails(
        fullName: 'Sara Ahmed',
        verifiedIdentityLabel: 'Passport • Verified by UAE PASS',
        maskedMobileNumber: '+971 5 • • • • • • 99',
      );
      final cubit = UaePassCollectionCubit(details: details);

      expect(cubit.state.details, details);

      async.elapse(const Duration(seconds: 3));
      cubit.close();
    });
  });

  test('close cancels pending timers without emitting further states', () {
    fakeAsync((async) {
      final cubit = UaePassCollectionCubit()..close();

      // Should not throw despite pending timers at close time.
      async.elapse(const Duration(seconds: 3));
      expect(cubit.state.isComplete, isFalse);
    });
  });
}
