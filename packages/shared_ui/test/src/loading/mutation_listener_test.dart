import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

/// Minimal cubit whose state is just a [RequestStatus], to drive the listener.
class _MutationCubit extends Cubit<RequestStatus> {
  _MutationCubit() : super(RequestStatus.initial);
  void loading() => emit(RequestStatus.loading);
  void success() => emit(RequestStatus.success);
  void failure() => emit(RequestStatus.failure);
}

Future<void> _pump(WidgetTester tester, _MutationCubit cubit, Widget child) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BlocProvider<_MutationCubit>.value(value: cubit, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('MutationListener', () {
    tearDown(AppProgress.reset);

    testWidgets('shows dialog on loading, dismisses + fires onSuccess', (
      tester,
    ) async {
      final cubit = _MutationCubit();
      var successCalls = 0;

      await _pump(
        tester,
        cubit,
        MutationListener<_MutationCubit, RequestStatus>(
          status: (state) => state,
          title: (_) => 'Saving',
          onSuccess: (_, _) => successCalls++,
          child: const SizedBox.shrink(),
        ),
      );

      cubit.loading();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsOneWidget);

      cubit.success();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsNothing);
      expect(successCalls, 1);

      await cubit.close();
    });

    testWidgets('dismisses + fires onFailure on failure', (tester) async {
      final cubit = _MutationCubit();
      var failureCalls = 0;

      await _pump(
        tester,
        cubit,
        MutationListener<_MutationCubit, RequestStatus>(
          status: (state) => state,
          title: (_) => 'Saving',
          onFailure: (_, _) => failureCalls++,
          child: const SizedBox.shrink(),
        ),
      );

      cubit.loading();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsOneWidget);

      cubit.failure();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AppProgressDialog), findsNothing);
      expect(failureCalls, 1);

      await cubit.close();
    });
  });
}
