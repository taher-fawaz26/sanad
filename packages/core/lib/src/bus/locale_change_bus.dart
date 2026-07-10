/// Abstract contract for a locale-change broadcast bus.
///
/// Concrete implementation lives in `sand_localization` (AppLocaleRefreshBus).
/// Defining the interface here lets sand_core host BaseRequestBloc
/// without creating a circular dependency on sand_localization.
abstract class LocaleChangeBus {
  Stream<void> get changes;
}
