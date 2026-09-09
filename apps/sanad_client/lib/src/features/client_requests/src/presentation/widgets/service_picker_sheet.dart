import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/catalogue_entities.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/catalogue_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Picks the catalogue service a request is for.
///
/// The client app has no catalogue browsing of its own, so this reads
/// `GET /services` directly. It loads one page at the backend maximum rather
/// than paginating: the catalogue is small and a picker that scroll-loads is
/// worse than one that filters.
///
/// Pops with the chosen [CatalogueService], or `null` when dismissed.
class ServicePickerSheet extends StatefulWidget {
  /// Creates the sheet.
  const ServicePickerSheet({required this.browseServices, super.key});

  /// Opens the sheet.
  static Future<CatalogueService?> show(
    BuildContext context, {
    required BrowseCatalogueServicesUseCase browseServices,
  }) => SheetNavigator.push<CatalogueService>(
    context,
    ServicePickerSheet(browseServices: browseServices),
    settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
  );

  /// Reads the catalogue.
  final BrowseCatalogueServicesUseCase browseServices;

  @override
  State<ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<ServicePickerSheet> {
  final TextEditingController _search = TextEditingController();

  RequestStatus _status = RequestStatus.initial;
  Failure? _failure;
  List<CatalogueService> _all = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = RequestStatus.loading);
    final result = await widget
        .browseServices(const CatalogueQuery(limit: kMaxPageLimit))
        .run();
    if (!mounted) return;
    result.match(
      (failure) => setState(() {
        _status = RequestStatus.failure;
        _failure = failure;
      }),
      (page) => setState(() {
        _status = RequestStatus.success;
        _all = page.items;
      }),
    );
  }

  List<CatalogueService> get _visible {
    if (_query.isEmpty) return _all;
    final needle = _query.toLowerCase();
    return _all
        .where((service) => service.name.toLowerCase().contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return SheetScaffold(
      title: 'client_requests.service_picker_title'.tr(),
      sheetSize: SheetSize.expanded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(
            controller: _search,
            hint: 'client_requests.service_search_placeholder'.tr(),
            showMicIcon: false,
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: switch (_status) {
              RequestStatus.loading || RequestStatus.initial => const Center(
                child: AppLoadingIndicator(),
              ),
              RequestStatus.failure => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _failure?.localizedSafeMessage() ?? '',
                      style: typography.bodySmall.copyWith(
                        color: colors.slate600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'client_requests.retry'.tr(),
                      onPressed: _load,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.small,
                    ),
                  ],
                ),
              ),
              RequestStatus.success =>
                _visible.isEmpty
                    ? Center(
                        child: Text(
                          'client_requests.service_picker_empty'.tr(),
                          style: typography.bodySmall.copyWith(
                            color: colors.slate600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _visible.length,
                        separatorBuilder: (_, _) => const AppDivider(),
                        itemBuilder: (context, index) {
                          final service = _visible[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            // `name` is localized server-side from `x-lang`,
                            // so it is rendered verbatim.
                            title: Text(
                              service.name,
                              style: typography.bodyMedium,
                            ),
                            subtitle: service.categoryName == null
                                ? null
                                : Text(
                                    service.categoryName!,
                                    style: typography.labelSmall.copyWith(
                                      color: colors.slate600,
                                    ),
                                  ),
                            onTap: () => SheetNavigator.pop<CatalogueService>(
                              context,
                              service,
                            ),
                          );
                        },
                      ),
            },
          ),
        ],
      ),
    );
  }
}
