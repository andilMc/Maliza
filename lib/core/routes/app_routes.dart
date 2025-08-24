class AppRoutes {
  // Routes principales
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';

  static const String homePage = '/home/dashboard';
  static const String todoPage = '/home/todos';
  static const String searchPage = '/home/search';
  static const String weatherPage = '/home/weather';

  static const List<String> authRoutes = [login, register];
  static const List<String> appRoutes = [home, profile];
  static const List<String> bottomNavRoutes = [
    homePage,
    todoPage,
    searchPage,
    weatherPage,
  ];
}
