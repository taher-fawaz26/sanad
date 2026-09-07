import 'dart:async';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media/media.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/organization_status_badge.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/header/organization_profile_sliver_header.dart';

class _MockUploadUseCase extends Mock
    implements UploadOrganizationMediaUseCase {}

class _MockRemoveUseCase extends Mock
    implements RemoveOrganizationMediaUseCase {}

class _MockRepository extends Mock implements OrganizationMediaRepository {}

final _media = EditedMedia(
  bytes: Uint8List.fromList([1, 2, 3]),
  width: 100,
  height: 100,
  mimeType: 'image/jpeg',
  fileName: 'logo.jpg',
  fileSize: 3,
  source: MediaSource.gallery,
);

const _coverUrl = 'https://cdn.example/cover.jpg';
const _logoUrl = 'https://cdn.example/logo.jpg';
const _surfaceSize = Size(390, 844);

Future<void> _pump(
  WidgetTester tester, {
  String? coverUrl,
  String? logoUrl,
  String? name,
  bool isLoading = false,
  TextDirection textDirection = TextDirection.ltr,
  ScrollController? controller,
}) {
  return tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                OrganizationProfileSliverHeader(
                  coverUrl: coverUrl,
                  logoUrl: logoUrl,
                  name: name,
                  status: OrganizationProfileStatus.published,
                  isLoading: isLoading,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

MediaAvatar _avatar(WidgetTester tester) =>
    tester.widget<MediaAvatar>(find.byType(MediaAvatar));

MediaCoverPhoto _cover(WidgetTester tester) =>
    tester.widget<MediaCoverPhoto>(find.byType(MediaCoverPhoto));

/// Opacity applied to the cover subtree (its collapse-driven fade).
double _coverOpacity(WidgetTester tester) {
  final opacity = tester.widget<Opacity>(
    find.ancestor(
      of: find.byType(MediaCoverPhoto),
      matching: find.byType(Opacity),
    ),
  );
  return opacity.opacity;
}

void main() {
  setUpAll(() {
    registerFallbackValue(OrganizationMediaSlot.cover);
    registerFallbackValue(
      UploadOrganizationMediaParams(
        slot: OrganizationMediaSlot.cover,
        media: _media,
      ),
    );
    registerFallbackValue(
      const RemoveOrganizationMediaParams(slot: OrganizationMediaSlot.cover),
    );
  });

  late _MockUploadUseCase uploadUseCase;
  late _MockRemoveUseCase removeUseCase;
  late _MockRepository repository;

  setUp(() {
    uploadUseCase = _MockUploadUseCase();
    removeUseCase = _MockRemoveUseCase();
    repository = _MockRepository();
    when(() => repository.cancelUpload(any())).thenAnswer((_) {});

    if (sl.isRegistered<IdentityHeaderBloc>()) {
      sl.unregister<IdentityHeaderBloc>();
    }
    sl.registerFactory<IdentityHeaderBloc>(
      () => IdentityHeaderBloc(
        uploadUseCase: uploadUseCase,
        removeUseCase: removeUseCase,
        repository: repository,
      ),
    );
  });

  tearDown(() {
    if (sl.isRegistered<IdentityHeaderBloc>()) {
      sl.unregister<IdentityHeaderBloc>();
    }
  });

  group('expanded layout', () {
    testWidgets('renders cover, full-size avatar, name and status badge', (
      tester,
    ) async {
      await _pump(
        tester,
        coverUrl: _coverUrl,
        logoUrl: _logoUrl,
        name: 'Company Pro',
      );
      await tester.pump();

      expect(find.byType(MediaCoverPhoto), findsOneWidget);
      expect(find.text('Company Pro'), findsOneWidget);
      expect(find.byType(OrganizationStatusBadge), findsOneWidget);

      // Fully expanded → avatar at its expanded size and cover fully opaque.
      expect(_avatar(tester).size, closeTo(76, 0.5));
      expect(_coverOpacity(tester), closeTo(1, 0.01));
    });

    testWidgets('shows the cover/logo urls that arrive on a LATER rebuild', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pump();
      expect(_cover(tester).imageUrl, isNull);
      expect(_avatar(tester).imageUrl, isNull);

      await _pump(tester, coverUrl: _coverUrl, logoUrl: _logoUrl);
      await tester.pump();

      expect(_cover(tester).imageUrl, _coverUrl);
      expect(_avatar(tester).imageUrl, _logoUrl);
    });

    testWidgets('isLoading shows shimmer skeletons for cover/avatar/name', (
      tester,
    ) async {
      await _pump(tester, name: 'Company Pro', isLoading: true);
      await tester.pump();

      expect(_cover(tester).isLoading, isTrue);
      expect(_avatar(tester).isLoading, isTrue);
      expect(find.byType(ShimmerBox), findsWidgets);
    });
  });

  group('scroll-driven collapse', () {
    testWidgets(
      'scrolling past the collapse range shrinks the avatar and fades the '
      'cover, while the name stays visible',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await _pump(
          tester,
          coverUrl: _coverUrl,
          logoUrl: _logoUrl,
          name: 'Company Pro',
          controller: controller,
        );
        await tester.pump();

        expect(_avatar(tester).size, closeTo(76, 0.5));

        // Collapse fully (range = maxExtent - minExtent = 188 - 56 = 132).
        controller.jumpTo(132);
        await tester.pump();

        expect(_avatar(tester).size, closeTo(40, 0.5));
        expect(_coverOpacity(tester), lessThan(0.1));
        // Compact pinned bar keeps the identity legible.
        expect(find.text('Company Pro'), findsOneWidget);
      },
    );

    testWidgets('avatar resizes continuously (no threshold jump)', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await _pump(
        tester,
        coverUrl: _coverUrl,
        logoUrl: _logoUrl,
        name: 'Company Pro',
        controller: controller,
      );
      await tester.pump();

      // Half-collapsed → avatar size strictly between compact and expanded.
      controller.jumpTo(66);
      await tester.pump();

      final size = _avatar(tester).size;
      expect(size, greaterThan(40));
      expect(size, lessThan(76));
    });
  });

  group('RTL', () {
    testWidgets('avatar docks to the trailing (right) edge under RTL', (
      tester,
    ) async {
      await _pump(
        tester,
        coverUrl: _coverUrl,
        logoUrl: _logoUrl,
        name: 'Company Pro',
        textDirection: TextDirection.rtl,
      );
      await tester.pump();

      final avatarLeft = tester.getTopLeft(find.byType(MediaAvatar)).dx;
      // start == right in RTL → avatar sits on the right half of the screen.
      expect(avatarLeft, greaterThan(_surfaceSize.width / 2));
    });

    testWidgets('avatar sits on the leading (left) edge under LTR', (
      tester,
    ) async {
      await _pump(
        tester,
        coverUrl: _coverUrl,
        logoUrl: _logoUrl,
        name: 'Company Pro',
      );
      await tester.pump();

      final avatarLeft = tester.getTopLeft(find.byType(MediaAvatar)).dx;
      expect(avatarLeft, lessThan(_surfaceSize.width / 2));
    });
  });

  group('media upload UX preserved', () {
    testWidgets('a failed logo upload shows the failure overlay', (
      tester,
    ) async {
      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );

      await _pump(tester);
      await tester.pump();

      tester
          .element(find.byType(MediaAvatar))
          .read<IdentityHeaderBloc>()
          .add(
            IdentityHeaderMediaSelected(
              slot: OrganizationMediaSlot.logo,
              media: _media,
            ),
          );
      await tester.pump();
      await tester.pump();

      expect(_avatar(tester).hasFailed, isTrue);
      expect(find.byType(MediaFailureOverlay), findsOneWidget);
    });

    testWidgets('tapping retry re-attempts the upload', (tester) async {
      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );

      await _pump(tester);
      await tester.pump();

      tester
          .element(find.byType(MediaAvatar))
          .read<IdentityHeaderBloc>()
          .add(
            IdentityHeaderMediaSelected(
              slot: OrganizationMediaSlot.logo,
              media: _media,
            ),
          );
      await tester.pump();
      await tester.pump();

      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.right(
          const OrganizationMediaEntity(url: 'https://cdn/ok.jpg'),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump();

      verify(() => uploadUseCase(any())).called(2);
      expect(_avatar(tester).imageUrl, 'https://cdn/ok.jpg');
      expect(_avatar(tester).hasFailed, isFalse);
    });

    testWidgets('tapping cancel on a busy cover upload cancels the upload', (
      tester,
    ) async {
      final completer = Completer<Either<Failure, OrganizationMediaEntity>>();
      when(
        () => uploadUseCase(any()),
      ).thenAnswer((_) => TaskEither(() => completer.future));

      await _pump(tester);
      await tester.pump();

      tester
          .element(find.byType(MediaCoverPhoto))
          .read<IdentityHeaderBloc>()
          .add(
            IdentityHeaderMediaSelected(
              slot: OrganizationMediaSlot.cover,
              media: _media,
            ),
          );
      await tester.pump();
      await tester.pump();

      expect(_cover(tester).isBusy, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      verify(
        () => repository.cancelUpload(OrganizationMediaSlot.cover),
      ).called(1);

      completer.complete(const Left(ServerFailure(message: 'boom')));
      await tester.pump();
      await tester.pump();

      // Cancelled upload must not surface as a failure.
      expect(_cover(tester).isBusy, isFalse);
      expect(_cover(tester).hasFailed, isFalse);
    });

    testWidgets('a successful cover upload shows the new url', (tester) async {
      when(() => uploadUseCase(any())).thenAnswer(
        (_) => TaskEither.right(
          const OrganizationMediaEntity(url: 'https://cdn/new-cover.jpg'),
        ),
      );

      await _pump(tester);
      await tester.pump();

      tester
          .element(find.byType(MediaCoverPhoto))
          .read<IdentityHeaderBloc>()
          .add(
            IdentityHeaderMediaSelected(
              slot: OrganizationMediaSlot.cover,
              media: _media,
            ),
          );
      await tester.pump();
      await tester.pump();

      expect(_cover(tester).imageUrl, 'https://cdn/new-cover.jpg');
      expect(_cover(tester).isBusy, isFalse);
    });
  });

  group('remove failure (SAN-699 — no documented remove endpoint)', () {
    testWidgets(
      'a failed logo removal does NOT render the persistent failure '
      'overlay — there is nothing to retry, so it must not stick on the '
      'image the way a retryable upload failure does',
      (tester) async {
        when(() => removeUseCase(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'errors.remove_image_not_supported',
            ),
          ),
        );

        await _pump(tester, coverUrl: _coverUrl, logoUrl: _logoUrl);
        await tester.pump();

        final bloc =
            tester.element(find.byType(MediaAvatar)).read<IdentityHeaderBloc>()
              ..add(
                const IdentityHeaderMediaRemoved(
                  slot: OrganizationMediaSlot.logo,
                ),
              );
        await tester.pump();
        await tester.pump();

        expect(find.byType(MediaFailureOverlay), findsNothing);
        expect(_avatar(tester).hasFailed, isFalse);
        expect(bloc.state.logo.hasError, isFalse);
      },
    );

    testWidgets(
      'a failed logo removal shows an AppSnackbar with the mapped message '
      'instead of a persistent overlay, and the existing image remains '
      'displayed throughout',
      (tester) async {
        when(() => removeUseCase(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'errors.remove_image_not_supported',
            ),
          ),
        );

        await _pump(tester, coverUrl: _coverUrl, logoUrl: _logoUrl);
        await tester.pump();

        tester
            .element(find.byType(MediaAvatar))
            .read<IdentityHeaderBloc>()
            .add(
              const IdentityHeaderMediaRemoved(
                slot: OrganizationMediaSlot.logo,
              ),
            );
        await tester.pump();
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.byType(AppSnackbar), findsOneWidget);
        // The image itself must remain — a failed removal never mutates it.
        expect(_avatar(tester).imageUrl, _logoUrl);
      },
    );

    testWidgets(
      'after the snackbar fires, the slot resets on its own — no navigate '
      'away/back needed, and no stale failure artifact remains',
      (tester) async {
        when(() => removeUseCase(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'errors.remove_image_not_supported',
            ),
          ),
        );

        await _pump(tester, coverUrl: _coverUrl, logoUrl: _logoUrl);
        await tester.pump();

        final bloc =
            tester.element(find.byType(MediaAvatar)).read<IdentityHeaderBloc>()
              ..add(
                const IdentityHeaderMediaRemoved(
                  slot: OrganizationMediaSlot.logo,
                ),
              );
        await tester.pump();
        await tester.pump();

        // The listener both shows the snackbar and immediately acknowledges
        // the failure in the same pass — nothing is left pending in state.
        expect(bloc.state.logo.status, RequestStatus.initial);
        expect(bloc.state.logo.hasError, isFalse);
        expect(bloc.state.logo.failure, isNull);
        expect(bloc.state.logo.imageUrl, _logoUrl);
      },
    );

    testWidgets(
      'a failed cover removal is handled the same way as logo — snackbar, '
      'no overlay, image untouched',
      (tester) async {
        when(() => removeUseCase(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'errors.remove_image_not_supported',
            ),
          ),
        );

        await _pump(tester, coverUrl: _coverUrl, logoUrl: _logoUrl);
        await tester.pump();

        final bloc =
            tester
                .element(find.byType(MediaCoverPhoto))
                .read<IdentityHeaderBloc>()
              ..add(
                const IdentityHeaderMediaRemoved(
                  slot: OrganizationMediaSlot.cover,
                ),
              );
        await tester.pump();
        await tester.pump();

        expect(find.byType(MediaFailureOverlay), findsNothing);
        expect(find.byType(AppSnackbar), findsOneWidget);
        expect(_cover(tester).imageUrl, _coverUrl);
        expect(bloc.state.cover.hasError, isFalse);
      },
    );

    testWidgets(
      'a RETRYABLE upload failure still renders the persistent overlay — '
      'this fix only changes non-retryable (remove) failures',
      (tester) async {
        when(() => uploadUseCase(any())).thenAnswer(
          (_) => TaskEither.left(const ServerFailure(message: 'boom')),
        );

        await _pump(tester, coverUrl: _coverUrl, logoUrl: _logoUrl);
        await tester.pump();

        tester
            .element(find.byType(MediaAvatar))
            .read<IdentityHeaderBloc>()
            .add(
              IdentityHeaderMediaSelected(
                slot: OrganizationMediaSlot.logo,
                media: _media,
              ),
            );
        await tester.pump();
        await tester.pump();

        expect(find.byType(MediaFailureOverlay), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });
}
