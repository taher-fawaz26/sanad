import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/identity_header/identity_header_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/header/organization_header.dart';

class _MockUploadUseCase extends Mock
    implements UploadOrganizationMediaUseCase {}

class _MockRemoveUseCase extends Mock
    implements RemoveOrganizationMediaUseCase {}

class _MockRepository extends Mock implements OrganizationMediaRepository {}

const _coverUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    '916d86ee-4c74-476d-b89a-31c7222ba752.jpg';
const _profileUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    'e53d2bf5-3b96-48ce-ba3b-da6aa7da9d28.jpg';

const _surfaceSize = Size(360, 800);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUp(() {
    if (sl.isRegistered<IdentityHeaderBloc>()) {
      sl.unregister<IdentityHeaderBloc>();
    }
    sl.registerFactory<IdentityHeaderBloc>(
      () => IdentityHeaderBloc(
        uploadUseCase: _MockUploadUseCase(),
        removeUseCase: _MockRemoveUseCase(),
        repository: _MockRepository(),
      ),
    );
  });

  tearDown(() {
    if (sl.isRegistered<IdentityHeaderBloc>()) {
      sl.unregister<IdentityHeaderBloc>();
    }
  });

  testWidgets(
    'shows the cover/logo URLs that arrive on a LATER rebuild, not just '
    "the ones present on the widget's first build — regression for the "
    'reported bug where fresh network/cache images never appeared because '
    'BlocProvider(create:) only seeds IdentityHeaderBloc once',
    (tester) async {
      // First frame: no data yet (matches the real page's skeleton-profile
      // first build, before the cache/network read resolves).
      await _pump(
        tester,
        const OrganizationHeader(),
      );
      await tester.pump();

      var header = tester.widget<EditableImageHeader>(
        find.byType(EditableImageHeader),
      );
      expect(header.coverUrl, isNull);
      expect(header.avatarUrl, isNull);

      // Same tree position, no key — this is exactly how
      // GeneralSettingsPage's BlocBuilder rebuilds OrganizationHeader once
      // OrganizationSettingsBloc emits the real (or cached) profile.
      await _pump(
        tester,
        const OrganizationHeader(
          coverUrl: _coverUrl,
          logoUrl: _profileUrl,
        ),
      );
      await tester.pump();

      header = tester.widget<EditableImageHeader>(
        find.byType(EditableImageHeader),
      );
      expect(header.coverUrl, _coverUrl);
      expect(header.avatarUrl, _profileUrl);
    },
  );

  testWidgets(
    'shows images immediately when they are already present on the very '
    'first build (e.g. instant cache-hit render)',
    (tester) async {
      await _pump(
        tester,
        const OrganizationHeader(
          coverUrl: _coverUrl,
          logoUrl: _profileUrl,
        ),
      );
      await tester.pump();

      final header = tester.widget<EditableImageHeader>(
        find.byType(EditableImageHeader),
      );
      expect(header.coverUrl, _coverUrl);
      expect(header.avatarUrl, _profileUrl);
    },
  );
}
