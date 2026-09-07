part of 'account_settings_bloc.dart';

class AccountSettingsState extends Equatable {
  const AccountSettingsState({
    this.loadStatus = RequestStatus.initial,
    this.saveStatus = RequestStatus.initial,
    this.settings,
    this.failure,
    this.saveFailure,
    this.languageSyncFailure,
  });

  final RequestStatus loadStatus;
  final RequestStatus saveStatus;
  final AccountSettingsEntity? settings;
  final Failure? failure;
  final Failure? saveFailure;

  /// Failure of the best-effort `preferredLanguage` sync.
  ///
  /// Kept apart from [saveFailure] because the language change is applied
  /// locally and never rolled back — a failed sync only means backend-generated
  /// content (emails, notifications) is still on the old language, which is a
  /// notice rather than a failed save.
  final Failure? languageSyncFailure;

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
    Failure? languageSyncFailure,
    bool clearFailure = false,
    bool clearSaveFailure = false,
    bool clearLanguageSyncFailure = false,
  }) {
    return AccountSettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      settings: settings ?? this.settings,
      failure: clearFailure ? null : (failure ?? this.failure),
      saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
      languageSyncFailure: clearLanguageSyncFailure
          ? null
          : (languageSyncFailure ?? this.languageSyncFailure),
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    saveStatus,
    settings,
    failure,
    saveFailure,
    languageSyncFailure,
  ];
}
