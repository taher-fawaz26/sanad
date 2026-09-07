import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/oauth/oauth_routes.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collected_details.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_collection_cubit.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_details_card.dart';
import 'package:sanad_client/src/features/oauth/uae_pass_device_connection_illustration.dart';

/// Figma `#ebebec` progress-track color (`7043:28739`) — not on the shared
/// track-color token (nearest, `dark.shade200`, is a visibly different
/// gray); a bespoke one-off like this feature's other illustration colors
/// (see `_deviceOutline` in `uae_pass_device_connection_illustration.dart`).
const _progressTrackColor = Color(0xFFEBEBEC);

/// We collect data from UAE PASS (Figma `7020:28255`).
///
/// UI-only for this phase (see `OAuthUaePassPage`'s class doc): the staged
/// per-field reveal is driven by [UaePassCollectionCubit]'s local pacing, not
/// a real UAE PASS response — see that cubit's class doc.
class OAuthUaePassCollectingPage extends StatelessWidget {
  /// Creates an [OAuthUaePassCollectingPage].
  const OAuthUaePassCollectingPage({this.details, super.key});

  /// Pre-seeded details (e.g. once a real integration exists). Defaults to
  /// [UaePassCollectedDetails.placeholder] when omitted.
  final UaePassCollectedDetails? details;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UaePassCollectionCubit(details: details),
      child: const _CollectingView(),
    );
  }
}

class _CollectingView extends StatelessWidget {
  const _CollectingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      appBar: AppNavBar(
        title: '',
        showBackButton: true,
        onLeadingTap: () => context.pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveDimension(AppSpacing.xxl),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // No staggered entrance here (unlike the other UAE PASS
                  // screens): this screen's continue-button enablement is
                  // driven by `UaePassCollectionCubit`'s wall-clock timers, and
                  // an entrance animation would make the harness's
                  // `pumpAndSettle` advance that same clock, shifting the
                  // staged reveal timing. The per-row loading→verified
                  // crossfade (in `UaePassDetailsCard`) carries the motion.
                  child: Column(
                    children: [
                      SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
                      const UaePassDeviceConnectionIllustration(),
                      SizedBox(height: responsiveDimension(AppSpacing.xl)),
                      Text(
                        'oauth.uae_pass_collecting_title'.tr(),
                        textAlign: TextAlign.center,
                        style: typography.regularNone.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.md)),
                      BlocBuilder<
                        UaePassCollectionCubit,
                        UaePassCollectionState
                      >(
                        buildWhen: (previous, current) =>
                            previous.progress != current.progress,
                        builder: (context, state) => SizedBox(
                          width: responsiveDimension(260),
                          child: AppProgressBar(
                            value: state.progress,
                            height: responsiveDimension(8),
                            borderRadius: BorderRadius.circular(
                              responsiveDimension(4),
                            ),
                            trackColor: _progressTrackColor,
                          ),
                        ),
                      ),
                      SizedBox(height: responsiveDimension(AppSpacing.xl)),
                      BlocBuilder<
                        UaePassCollectionCubit,
                        UaePassCollectionState
                      >(
                        builder: (context, state) => UaePassDetailsCard(
                          title: 'oauth.uae_pass_collecting_card_title'.tr(),
                          rows: _rows(state),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<UaePassCollectionCubit, UaePassCollectionState>(
                buildWhen: (previous, current) =>
                    previous.isComplete != current.isComplete,
                builder: (context, state) => AppButton(
                  label: 'oauth.continue_to_sanad'.tr(),
                  onPressed: state.isComplete
                      ? () => context.push(
                          OAuthRoutes.uaePassSuccess,
                          extra: state.details,
                        )
                      : null,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }

  List<UaePassDetailRowData> _rows(UaePassCollectionState state) {
    UaePassDetailRowStatus toRowStatus(RequestStatus status) =>
        status == RequestStatus.success
        ? UaePassDetailRowStatus.completed
        : UaePassDetailRowStatus.loading;

    return [
      UaePassDetailRowData(
        iconAsset: AppSvgs.registrationProfile,
        label: 'oauth.uae_pass_detail_full_name_label'.tr(),
        value: state.details.fullName,
        status: toRowStatus(state.fullNameStatus),
      ),
      UaePassDetailRowData(
        iconAsset: AppSvgs.uaePassVerifiedIdentity,
        label: 'oauth.uae_pass_detail_verified_identity_label'.tr(),
        value: state.details.verifiedIdentityLabel,
        status: toRowStatus(state.verifiedIdentityStatus),
      ),
      UaePassDetailRowData(
        iconAsset: AppSvgs.uaePassMobileNumber,
        label: 'oauth.uae_pass_detail_mobile_number_label'.tr(),
        value: state.details.maskedMobileNumber,
        status: toRowStatus(state.mobileNumberStatus),
      ),
    ];
  }
}
