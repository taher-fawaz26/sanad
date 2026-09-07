part of 'branch_schedule_editor_bloc.dart';

class BranchScheduleEditorState extends Equatable {
  const BranchScheduleEditorState({
    required this.mode,
    required this.customSchedule,
    required this.companySchedule,
    required this.initialMode,
    required this.initialCustomSchedule,
    this.rejection,
  });

  /// Seeds the initial state from the caller's `initialMode` +
  /// `initialCustomSchedule`. Populates the custom draft with a copy of the
  /// company schedule when custom mode is entered with no prior custom hours
  /// on file, matching the original sheet's [initState] behavior.
  factory BranchScheduleEditorState.initial({
    required BranchAvailabilityMode initialMode,
    required List<BranchAvailabilityEntity> initialCustomSchedule,
    required List<BranchAvailabilityEntity> companySchedule,
  }) {
    final mode = initialMode == BranchAvailabilityMode.custom
        ? BranchScheduleMode.custom
        : BranchScheduleMode.company;
    var custom = List<BranchAvailabilityEntity>.of(initialCustomSchedule);
    if (mode == BranchScheduleMode.custom && custom.isEmpty) {
      custom = List.of(companySchedule);
    }
    return BranchScheduleEditorState(
      mode: mode,
      customSchedule: custom,
      companySchedule: companySchedule,
      initialMode: mode,
      initialCustomSchedule: List.of(initialCustomSchedule),
    );
  }

  final BranchScheduleMode mode;
  final List<BranchAvailabilityEntity> customSchedule;
  final List<BranchAvailabilityEntity> companySchedule;

  final BranchScheduleMode initialMode;
  final List<BranchAvailabilityEntity> initialCustomSchedule;

  final ScheduleSlotRejection? rejection;

  bool get isValid =>
      mode == BranchScheduleMode.company || customSchedule.isNotEmpty;

  bool get hasChanges {
    if (mode != initialMode) return true;
    if (mode == BranchScheduleMode.company) return false;
    return !_scheduleEquals(customSchedule, initialCustomSchedule);
  }

  bool get canSubmit => isValid && hasChanges;

  /// The resolved schedule for the [WorkingHoursEditResult] — company hours
  /// when in company mode, the custom draft otherwise.
  List<BranchAvailabilityEntity> get resolvedAvailability =>
      mode == BranchScheduleMode.company ? companySchedule : customSchedule;

  BranchAvailabilityMode get resolvedAvailabilityMode =>
      mode == BranchScheduleMode.custom
      ? BranchAvailabilityMode.custom
      : BranchAvailabilityMode.coreHours;

  BranchScheduleEditorState copyWith({
    BranchScheduleMode? mode,
    List<BranchAvailabilityEntity>? customSchedule,
    ScheduleSlotRejection? rejection,
    bool clearRejection = false,
  }) => BranchScheduleEditorState(
    mode: mode ?? this.mode,
    customSchedule: customSchedule ?? this.customSchedule,
    companySchedule: companySchedule,
    initialMode: initialMode,
    initialCustomSchedule: initialCustomSchedule,
    rejection: clearRejection ? null : (rejection ?? this.rejection),
  );

  @override
  List<Object?> get props => [
    mode,
    customSchedule,
    companySchedule,
    initialMode,
    initialCustomSchedule,
    rejection,
  ];

  static bool _scheduleEquals(
    List<BranchAvailabilityEntity> a,
    List<BranchAvailabilityEntity> b,
  ) {
    if (a.length != b.length) return false;
    final byDayA = {for (final entry in a) entry.day: entry};
    final byDayB = {for (final entry in b) entry.day: entry};
    if (byDayA.keys.toSet().difference(byDayB.keys.toSet()).isNotEmpty) {
      return false;
    }
    for (final day in byDayA.keys) {
      if (byDayA[day] != byDayB[day]) return false;
    }
    return true;
  }
}
