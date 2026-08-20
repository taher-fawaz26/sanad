import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Multi-select draft for [EditCategoryBottomSheet] — which category ids are
/// currently checked, before the user taps Save.
class EditCategorySelection extends Equatable {
  const EditCategorySelection({this.selectedIds = const {}});

  final Set<String> selectedIds;

  EditCategorySelection copyWith({Set<String>? selectedIds}) =>
      EditCategorySelection(selectedIds: selectedIds ?? this.selectedIds);

  @override
  List<Object?> get props => [selectedIds];
}

/// Owns the edit-category sheet's local selection draft.
///
/// Dependency-free and widget-scoped (seeded from the sheet's
/// `initialSelectedIds`), so it's provided inline via `BlocProvider` at the
/// sheet, not registered in the service locator — same pattern as
/// `RegistrationDetailsCubit`.
class EditCategoryCubit extends Cubit<EditCategorySelection> {
  EditCategoryCubit({Set<String> initialSelectedIds = const {}})
    : super(EditCategorySelection(selectedIds: Set.of(initialSelectedIds)));

  void toggle(String id) {
    final updated = Set<String>.of(state.selectedIds);
    if (!updated.remove(id)) updated.add(id);
    emit(state.copyWith(selectedIds: updated));
  }
}
