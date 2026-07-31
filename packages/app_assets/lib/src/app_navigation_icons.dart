/// Bottom navigation SVG paths — Figma `Nab-Bar` (`3148:27106`).
///
/// Load with `AppSvgPicture.asset(AppNavigationIcons.x)` inside design-system
/// components. Legacy aliases also exist on [AppSvgs].
abstract final class AppNavigationIcons {  AppNavigationIcons._();

  static const String _base = 'assets/icons/navigation';

  static const String home = '$_base/home.svg';
  static const String service = '$_base/service.svg';
  static const String messages = '$_base/messages.svg';
  static const String settings = '$_base/settings.svg';
  static const String centerAction = '$_base/center_action.svg';
}
