---
name: bloc
description: Create a BLoC — events, states, UseCase wiring, TaskEither fold, BlocProvider setup
---

# BLoC Skill

Create a feature BLoC following Sanad conventions.

## File Structure

```
presentation/bloc/
  feature_bloc.dart
  feature_event.dart    # or part file
  feature_state.dart    # or part file
```

## Event Template

```dart
sealed class FeatureEvent extends Equatable {
  const FeatureEvent();
  @override
  List<Object?> get props => [];
}

final class FeatureFetchEvent extends FeatureEvent {
  const FeatureFetchEvent({required this.id});
  final String id;
  @override
  List<Object?> get props => [id];
}
```

## State Template

```dart
sealed class FeatureState extends Equatable {
  const FeatureState();
  @override
  List<Object?> get props => [];
}

final class FeatureInitialState extends FeatureState {}
final class FeatureLoadingState extends FeatureState {}
final class FeatureSuccessState extends FeatureState {
  const FeatureSuccessState(this.data);
  final Entity data;
  @override
  List<Object?> get props => [data];
}
final class FeatureFailureState extends FeatureState {
  const FeatureFailureState(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

## BLoC Template

```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  FeatureBloc(this._getDataUseCase) : super(const FeatureInitialState()) {
    on<FeatureFetchEvent>(_onFetch);
  }

  final GetDataUseCase _getDataUseCase;

  Future<void> _onFetch(FeatureFetchEvent event, Emitter<FeatureState> emit) async {
    emit(const FeatureLoadingState());
    final result = await _getDataUseCase(GetDataParams(id: event.id)).run();
    result.fold(
      (failure) => emit(FeatureFailureState(failure)),
      (data) => emit(FeatureSuccessState(data)),
    );
  }
}
```

## BlocProvider Setup

In route builder:
```dart
GoRoute(
  path: FeatureRoutes.list,
  builder: (context, state) => BlocProvider(
    create: (_) => sl<FeatureBloc>()..add(const FeatureFetchEvent()),
    child: const FeaturePage(),
  ),
),
```

## Rules

- No `BuildContext` in BLoC
- No direct repository calls — UseCase only
- Use `BaseRequestBloc` for standard fetch/refresh/retry patterns
