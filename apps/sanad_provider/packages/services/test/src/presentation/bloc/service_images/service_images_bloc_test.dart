// blocTest act: lambdas prevent Dart from inferring const at call-sites.
// ignore_for_file: prefer_const_constructors

import 'package:asset_picker/asset_picker.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/add_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/presentation/bloc/service_images/service_images_bloc.dart';

class _MockRepo extends Mock implements ProviderServicesRepository {}

const _serverFailure = ServerFailure(message: 'boom');

ProviderServiceEntity _service({
  String id = 'svc-1',
  List<ProviderServiceImageEntity> images = const [],
}) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-1',
  serviceName: 'Wash Car',
  category: const CategoryRefEntity(id: 'cat-1', name: 'Car', description: null),
  description: 'desc',
  status: ProviderServiceStatus.active,
  images: images,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
  });

  ServiceImagesBloc buildBloc({ProviderServiceEntity? initialService}) =>
      ServiceImagesBloc(
        addProviderServiceImageUseCase: AddProviderServiceImageUseCase(repo),
        deleteProviderServiceImageUseCase: DeleteProviderServiceImageUseCase(
          repo,
        ),
        setPrimaryProviderServiceImageUseCase:
            SetPrimaryProviderServiceImageUseCase(repo),
        initialService: initialService ?? _service(),
      );

  group('ServiceImagesBloc — add flow (upload → attach)', () {
    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'a newly-succeeded upload item is attached with its mediaId — never '
      'the image row id',
      setUp: () => when(
        () => repo.addImage(id: 'svc-1', mediaId: 'media-new'),
      ).thenAnswer(
        (_) => TaskEither.of(
          _service(
            images: [
              const ProviderServiceImageEntity(
                id: 'row-new',
                mediaId: 'media-new',
                url: '',
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(
        ServiceImagesUploadStateChanged([
          MediaUploadItem.remote(mediaId: 'media-new', url: ''),
        ]),
      ),
      expect: () => [
        isA<ServiceImagesState>().having(
          (s) => s.attachStatus['media-new'],
          'attachStatus[media-new]',
          ServiceImagesAttachStatus.attaching,
        ),
        isA<ServiceImagesState>()
            .having(
              (s) => s.attachStatus.containsKey('media-new'),
              'still tracked',
              isFalse,
            )
            .having((s) => s.service.images, 'images', hasLength(1)),
      ],
      verify: (_) {
        verify(
          () => repo.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).called(1);
        verifyNever(
          () => repo.addImage(id: any(named: 'id'), mediaId: 'row-new'),
        );
      },
    );

    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'an item still uploading/failed (upload-side) is ignored — never '
      'attached',
      build: buildBloc,
      act: (bloc) => bloc.add(
        ServiceImagesUploadStateChanged([
          const MediaUploadItem(
            localId: 'local-1',
            asset: PickedAsset(
              name: 'photo.jpg',
              path: '/tmp/photo.jpg',
              mimeType: 'image/jpeg',
              size: 1024,
              assetType: AssetType.image,
            ),
            status: MediaUploadStatus.failure,
            failure: UploadRequestFailure('boom'),
          ),
        ]),
      ),
      verify: (_) {
        verifyNever(
          () => repo.addImage(
            id: any(named: 'id'),
            mediaId: any(named: 'mediaId'),
          ),
        );
      },
    );

    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'attach failure marks the item failed and never re-uploads; retry '
      'only re-calls addImage',
      setUp: () {
        var attempt = 0;
        when(() => repo.addImage(id: 'svc-1', mediaId: 'media-new')).thenAnswer((
          _,
        ) {
          attempt++;
          return attempt == 1
              ? TaskEither.left(_serverFailure)
              : TaskEither.of(_service());
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(
          ServiceImagesUploadStateChanged([
            MediaUploadItem.remote(mediaId: 'media-new', url: ''),
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ServiceImagesAttachRetryRequested(
            localId: 'media-new',
            mediaId: 'media-new',
          ),
        );
      },
      verify: (bloc) {
        expect(
          bloc.state.attachStatus.containsKey('media-new'),
          isFalse,
          reason: 'retry succeeded, should be folded into service.images',
        );
        verify(
          () => repo.addImage(id: 'svc-1', mediaId: 'media-new'),
        ).called(2);
      },
    );

    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'partial batch: one image fully attaches while another fails at '
      'attach — the successful one is unaffected',
      setUp: () {
        when(
          () => repo.addImage(id: 'svc-1', mediaId: 'media-a'),
        ).thenAnswer((_) => TaskEither.of(_service()));
        when(
          () => repo.addImage(id: 'svc-1', mediaId: 'media-b'),
        ).thenAnswer((_) => TaskEither.left(_serverFailure));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        ServiceImagesUploadStateChanged([
          MediaUploadItem.remote(mediaId: 'media-a', url: ''),
          MediaUploadItem.remote(mediaId: 'media-b', url: ''),
        ]),
      ),
      verify: (bloc) {
        verify(
          () => repo.addImage(id: 'svc-1', mediaId: 'media-a'),
        ).called(1);
        verify(
          () => repo.addImage(id: 'svc-1', mediaId: 'media-b'),
        ).called(1);
        expect(bloc.state.attachStatus['media-a'], isNull);
        expect(
          bloc.state.attachStatus['media-b'],
          ServiceImagesAttachStatus.failed,
        );
      },
    );

    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'ServiceImagesInProgressRemoved drops tracking without touching the '
      'service',
      build: buildBloc,
      seed: () => ServiceImagesState(
        service: _service(),
        attachStatus: const {'local-1': ServiceImagesAttachStatus.failed},
      ),
      act: (bloc) => bloc.add(const ServiceImagesInProgressRemoved('local-1')),
      expect: () => [
        isA<ServiceImagesState>().having(
          (s) => s.attachStatus,
          'attachStatus',
          isEmpty,
        ),
      ],
    );
  });

  group('ServiceImagesBloc — set primary (uses the image ROW id)', () {
    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'success calls setPrimaryImage with the row id and folds the '
      'returned service',
      setUp: () => when(
        () => repo.setPrimaryImage(id: 'svc-1', imageId: 'row-1'),
      ).thenAnswer(
        (_) => TaskEither.of(
          _service(
            images: [
              const ProviderServiceImageEntity(
                id: 'row-1',
                mediaId: 'media-1',
                url: '',
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const ServiceImagesSetPrimaryRequested('row-1')),
      expect: () => [
        isA<ServiceImagesState>().having(
          (s) => s.busyImageId,
          'busyImageId',
          'row-1',
        ),
        isA<ServiceImagesState>()
            .having((s) => s.busyImageId, 'busyImageId', isNull)
            .having(
              (s) => s.service.images.single.isPrimary,
              'isPrimary',
              isTrue,
            ),
      ],
      verify: (_) {
        verify(
          () => repo.setPrimaryImage(id: 'svc-1', imageId: 'row-1'),
        ).called(1);
        verifyNever(
          () => repo.setPrimaryImage(id: any(named: 'id'), imageId: 'media-1'),
        );
      },
    );

    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'failure clears busyImageId and bumps failureNonce',
      setUp: () => when(
        () => repo.setPrimaryImage(id: 'svc-1', imageId: 'row-1'),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const ServiceImagesSetPrimaryRequested('row-1')),
      verify: (bloc) {
        expect(bloc.state.busyImageId, isNull);
        expect(bloc.state.mutationFailure, _serverFailure);
        expect(bloc.state.failureNonce, 1);
      },
    );

    // Regression: making a non-first image primary must not reorder the
    // list — "Main" is a per-image flag, never a sort key. The bloc folds
    // whatever order the backend returns verbatim; this pins that down
    // with a 3-image response where the newly-primary image is in the
    // middle.
    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'setting a non-first image primary preserves image order',
      setUp: () => when(
        () => repo.setPrimaryImage(id: 'svc-1', imageId: 'row-2'),
      ).thenAnswer(
        (_) => TaskEither.of(
          _service(
            images: const [
              ProviderServiceImageEntity(
                id: 'row-1',
                mediaId: 'media-1',
                url: '',
                isPrimary: false,
              ),
              ProviderServiceImageEntity(
                id: 'row-2',
                mediaId: 'media-2',
                url: '',
                isPrimary: true,
              ),
              ProviderServiceImageEntity(
                id: 'row-3',
                mediaId: 'media-3',
                url: '',
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const ServiceImagesSetPrimaryRequested('row-2')),
      verify: (bloc) {
        expect(
          bloc.state.service.images.map((i) => i.id).toList(),
          ['row-1', 'row-2', 'row-3'],
        );
        expect(
          bloc.state.service.images.where((i) => i.isPrimary).single.id,
          'row-2',
        );
      },
    );
  });

  group('ServiceImagesBloc — delete (uses the image ROW id)', () {
    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'success calls deleteImage with the row id and folds the returned '
      'service',
      setUp: () => when(
        () => repo.deleteImage(id: 'svc-1', imageId: 'row-1'),
      ).thenAnswer((_) => TaskEither.of(_service())),
      build: () => buildBloc(
        initialService: _service(
          images: [
            const ProviderServiceImageEntity(
              id: 'row-1',
              mediaId: 'media-1',
              url: '',
              isPrimary: true,
            ),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const ServiceImagesDeleteRequested('row-1')),
      verify: (bloc) {
        verify(
          () => repo.deleteImage(id: 'svc-1', imageId: 'row-1'),
        ).called(1);
        verifyNever(
          () => repo.deleteImage(id: any(named: 'id'), imageId: 'media-1'),
        );
        expect(bloc.state.service.images, isEmpty);
        expect(bloc.state.busyImageId, isNull);
      },
    );

    blocTest<ServiceImagesBloc, ServiceImagesState>(
      'failure preserves the service and bumps failureNonce',
      setUp: () => when(
        () => repo.deleteImage(id: 'svc-1', imageId: 'row-1'),
      ).thenAnswer((_) => TaskEither.left(_serverFailure)),
      build: () => buildBloc(
        initialService: _service(
          images: [
            const ProviderServiceImageEntity(
              id: 'row-1',
              mediaId: 'media-1',
              url: '',
              isPrimary: true,
            ),
          ],
        ),
      ),
      act: (bloc) => bloc.add(const ServiceImagesDeleteRequested('row-1')),
      verify: (bloc) {
        expect(bloc.state.service.images, hasLength(1));
        expect(bloc.state.mutationFailure, _serverFailure);
        expect(bloc.state.failureNonce, 1);
      },
    );
  });
}
