import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:maps/src/domain/entities/city_entity.dart';
import 'package:maps/src/domain/usecases/get_cities_usecase.dart';

/// A form field that displays the currently selected [CityEntity] and opens
/// a searchable bottom-sheet picker when tapped.
///
/// All user-facing strings are injected as parameters to keep [maps] generic.
class CitySelectField extends StatelessWidget {
  const CitySelectField({
    required this.label,
    required this.hint,
    required this.pickerTitle,
    required this.searchHint,
    required this.emptyLabel,
    required this.retryLabel,
    required this.onCitySelected,
    this.selectedCity,
    this.localizedName,
    super.key,
  });

  final String label;
  final String hint;
  final String pickerTitle;
  final String searchHint;
  final String emptyLabel;
  final String retryLabel;
  final CityEntity? selectedCity;

  /// Resolves the display name for a given city. Defaults to [CityEntity.nameEn]
  /// when null.
  final String Function(CityEntity city)? localizedName;

  final ValueChanged<CityEntity> onCitySelected;

  @override
  Widget build(BuildContext context) {
    final displayName = selectedCity == null ? null : _nameOf(selectedCity!);

    return AppSelectField(
      label: label,
      value: displayName,
      hint: hint,
      onTap: () => _openPicker(context),
    );
  }

  String _nameOf(CityEntity city) =>
      localizedName != null ? localizedName!(city) : city.nameEn;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<CityEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x80000000),
      builder: (_) => _CityPickerSheet(
        title: pickerTitle,
        searchHint: searchHint,
        emptyLabel: emptyLabel,
        retryLabel: retryLabel,
        localizedName: localizedName,
      ),
    );
    if (result != null) {
      onCitySelected(result);
    }
  }
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({
    required this.title,
    required this.searchHint,
    required this.emptyLabel,
    required this.retryLabel,
    this.localizedName,
  });

  final String title;
  final String searchHint;
  final String emptyLabel;
  final String retryLabel;
  final String Function(CityEntity city)? localizedName;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchController = TextEditingController();

  List<CityEntity> _cities = const [];
  String _query = '';
  bool _isLoading = true;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await sl<GetCitiesUseCase>()(const NoParams()).run();

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _failure = failure;
      }),
      (cities) => setState(() {
        _isLoading = false;
        _cities = cities;
      }),
    );
  }

  List<CityEntity> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _cities;
    return _cities.where((c) {
      return c.nameEn.toLowerCase().contains(q) ||
          c.nameAr.contains(_query.trim());
    }).toList();
  }

  String _nameOf(CityEntity city) =>
      widget.localizedName != null ? widget.localizedName!(city) : city.nameEn;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return AppActionSheet(
      title: widget.title,
      showCancel: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: AppSearchField(
              controller: _searchController,
              hint: widget.searchHint,
              showMicIcon: false,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failure != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _failure!.message,
                textAlign: TextAlign.center,
                style: context.appTypography.regularNormal.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              AppButtonPresets.outline(
                label: widget.retryLabel,
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }

    final cities = _filtered;

    if (cities.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            widget.emptyLabel,
            textAlign: TextAlign.center,
            style: context.appTypography.regularNormal.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: cities.length,
      separatorBuilder: (_, __) => const AppDivider(),
      itemBuilder: (context, index) {
        final city = cities[index];
        return AppTableRow(
          title: _nameOf(city),
          onTap: () => Navigator.of(context).pop(city),
        );
      },
    );
  }
}
