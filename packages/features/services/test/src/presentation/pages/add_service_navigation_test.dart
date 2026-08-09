import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/presentation/pages/add_service_page.dart';
import 'package:services/src/presentation/pages/request_new_service_page.dart';
import 'package:shared_ui/shared_ui.dart';

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

Future<void> _pumpRouter(WidgetTester tester) async {
  // The Category/Service Name modal sheets can exceed the default (small)
  // test surface — use a realistic device-sized surface instead.
  await tester.binding.setSurfaceSize(const Size(1080, 2400));
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  // AddServicePage calls context.push(ServiceRoutes.requestNew) =
  // '/services/request-new', an absolute path, so the test router must
  // register that same real path (flat, since nesting under a bare
  // '/services' parent would need its own builder/redirect that isn't
  // relevant to this test).
  final router = GoRouter(
    initialLocation: '/services/add',
    routes: [
      GoRoute(
        path: '/services/add',
        builder: (context, state) => const AddServicePage(),
      ),
      GoRoute(
        path: '/services/request-new',
        builder: (context, state) => const RequestNewServicePage(),
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      minTextAdapt: true,
      builder: (_, _) => MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    final repository = _MockMediaUploadRepository();
    sl.registerFactoryParam<MediaUploadBloc, MediaUploadConfig, void>(
      (config, _) => MediaUploadBloc(repository: repository, config: config),
    );
  });

  tearDownAll(() => sl.unregister<MediaUploadBloc>());

  testWidgets(
    'tapping the header "Request a New Service" button navigates to '
    'RequestNewServicePage',
    (tester) async {
      await _pumpRouter(tester);

      await tester.tap(find.text('services.add_service.request_new_service'));
      await tester.pumpAndSettle();

      expect(find.byType(RequestNewServicePage), findsOneWidget);
      expect(find.byType(AddServicePage), findsNothing);
    },
  );

  testWidgets(
    'tapping the inline "Request New service" link navigates to '
    'RequestNewServicePage',
    (tester) async {
      await _pumpRouter(tester);

      // Select a category so the inline link becomes visible.
      await tester.tap(find.byType(AppSelectField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Car'));
      await tester.pumpAndSettle();

      // AppInlineLinkText renders leading text + link as a single
      // Text.rich; its own widget tests already confirm only the link span
      // is tappable, so invoke the callback directly rather than trying to
      // hit-test a specific glyph run.
      final linkWidget = tester.widget<AppInlineLinkText>(
        find.byType(AppInlineLinkText),
      );
      linkWidget.onLinkTap();
      await tester.pumpAndSettle();

      expect(find.byType(RequestNewServicePage), findsOneWidget);
      expect(find.byType(AddServicePage), findsNothing);
    },
  );
}
