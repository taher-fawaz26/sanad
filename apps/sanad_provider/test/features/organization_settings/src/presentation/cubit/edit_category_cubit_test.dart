import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/cubit/edit_category_cubit.dart';

void main() {
  group('EditCategoryCubit', () {
    test('seeds state from initialSelectedIds', () {
      final cubit = EditCategoryCubit(initialSelectedIds: {'cat-1'});
      expect(cubit.state.selectedIds, {'cat-1'});
      cubit.close();
    });

    test('defaults to an empty selection', () {
      final cubit = EditCategoryCubit();
      expect(cubit.state.selectedIds, isEmpty);
      cubit.close();
    });

    blocTest<EditCategoryCubit, EditCategorySelection>(
      'toggle adds an unselected id',
      build: EditCategoryCubit.new,
      act: (cubit) => cubit.toggle('cat-1'),
      expect: () => [
        const EditCategorySelection(selectedIds: {'cat-1'}),
      ],
    );

    blocTest<EditCategoryCubit, EditCategorySelection>(
      'toggle removes an already-selected id',
      build: () => EditCategoryCubit(initialSelectedIds: {'cat-1', 'cat-2'}),
      act: (cubit) => cubit.toggle('cat-1'),
      expect: () => [
        const EditCategorySelection(selectedIds: {'cat-2'}),
      ],
    );

    blocTest<EditCategoryCubit, EditCategorySelection>(
      'toggling the same id twice returns to the original selection',
      build: EditCategoryCubit.new,
      act: (cubit) => cubit
        ..toggle('cat-1')
        ..toggle('cat-1'),
      expect: () => [
        const EditCategorySelection(selectedIds: {'cat-1'}),
        const EditCategorySelection(),
      ],
    );
  });
}
