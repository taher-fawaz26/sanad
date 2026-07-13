abstract final class AuthApiPaths {
  AuthApiPaths._();

  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String register = 'auth/register';

  static String userDelete(String userSub) => 'user/delete/$userSub';
}
