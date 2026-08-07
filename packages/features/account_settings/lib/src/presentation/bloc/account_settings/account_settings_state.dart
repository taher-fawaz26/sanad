part of 'account_settings_bloc.dart';

class AccountSettingsState extends Equatable {
  const AccountSettingsState({
    this.loadStatus = RequestStatus.initial,
    this.saveStatus = RequestStatus.initial,
    this.settings,
    this.failure,
    this.saveFailure,
  });

  final RequestStatus loadStatus;
  final RequestStatus saveStatus;
  final AccountSettingsEntity? settings;
  final Failure? failure;
  final Failure? saveFailure;

  String? get name => settings?.name;
  String? get email => settings?.email;
  String? get phone => settings?.phone;
  PreferredLanguage? get preferredLanguage => settings?.preferredLanguage;

  bool get hasPhone => settings?.hasPhone ?? false;

  AccountSettingsState copyWith({
    RequestStatus? loadStatus,
    RequestStatus? saveStatus,
    AccountSettingsEntity? settings,
    Failure? failure,
    Failure? saveFailure,
    bool clearFailure = false,
    bool clearSaveFailure = false,
  }) {
    return AccountSettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      settings: settings ?? this.settings,
      failure: clearFailure ? null : (failure ?? this.failure),
      saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    saveStatus,
    settings,
    failure,
    saveFailure,
  ];
}
