part of 'role_form_bloc.dart';

enum RoleFormSubmitStatus { idle, submitting, success, failure }

class RoleFormState extends Equatable {
  const RoleFormState({
    this.catalogStatus = RequestStatus.initial,
    this.permissions = const [],
    this.selectedPermissionIds = const {},
    this.submitStatus = RoleFormSubmitStatus.idle,
    this.failure,
    this.savedRole,
  });

  final RequestStatus catalogStatus;
  final List<PermissionEntity> permissions;
  final Set<String> selectedPermissionIds;
  final RoleFormSubmitStatus submitStatus;
  final Failure? failure;
  final RoleEntity? savedRole;

  bool get isCatalogLoading => catalogStatus == RequestStatus.loading;
  bool get isSubmitting => submitStatus == RoleFormSubmitStatus.submitting;
  bool get canSubmit => selectedPermissionIds.isNotEmpty && !isSubmitting;

  RoleFormState copyWith({
    RequestStatus? catalogStatus,
    List<PermissionEntity>? permissions,
    Set<String>? selectedPermissionIds,
    RoleFormSubmitStatus? submitStatus,
    Failure? failure,
    RoleEntity? savedRole,
  }) => RoleFormState(
    catalogStatus: catalogStatus ?? this.catalogStatus,
    permissions: permissions ?? this.permissions,
    selectedPermissionIds: selectedPermissionIds ?? this.selectedPermissionIds,
    submitStatus: submitStatus ?? this.submitStatus,
    failure: failure,
    savedRole: savedRole ?? this.savedRole,
  );

  @override
  List<Object?> get props => [
    catalogStatus,
    permissions,
    selectedPermissionIds,
    submitStatus,
    failure,
    savedRole,
  ];
}
