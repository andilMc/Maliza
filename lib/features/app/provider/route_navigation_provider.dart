import 'package:maliza/features/app/presentation/pages/home_page.dart';
import 'package:maliza/features/app/presentation/pages/recherche_page.dart';
import 'package:maliza/features/app/presentation/pages/todo_page.dart';
import 'package:maliza/features/app/presentation/pages/weather_page.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:flutter/widgets.dart';

class RouteNavigationProvider extends ChangeNotifier {
  String _currentRoute = AppRoutes.homePage;
  Widget _currentPage = HomePage();

  String get currentRoute => _currentRoute;
  Widget get currentPage => _currentPage;
  
  int get index {
    switch (_currentRoute) {
      case AppRoutes.homePage:
        return 0;
      case AppRoutes.todoPage:
        return 1;
      // case AppRoutes.addTodoPage:
        // return 2;
      case AppRoutes.searchPage:
        return 3;
      case AppRoutes.weatherPage:
        return 4;
      default:
        return 0;
    }
  }

  void navigateToRoute(String route) {
    if (_currentRoute == route) return;
    
    _currentRoute = route;
    _currentPage = _getPageFromRoute(route);
    notifyListeners();
  }

  void navigateToIndex(int pageIndex) {
    final route = _getRouteFromIndex(pageIndex);
    navigateToRoute(route);
  }

  // Méthodes de navigation spécifiques
  void goToHome() => navigateToRoute(AppRoutes.homePage);
  void goToTodo() => navigateToRoute(AppRoutes.todoPage);
  // void goToAddTodo() => navigateToRoute(AppRoutes.addTodoPage);
  void goToSearch() => navigateToRoute(AppRoutes.searchPage);
  void goToWeather() => navigateToRoute(AppRoutes.weatherPage);

  Widget _getPageFromRoute(String route) {
    switch (route) {
      case AppRoutes.homePage:
        return HomePage();
      case AppRoutes.todoPage:
        return TodoPage();
      case AppRoutes.searchPage:
        return RecherchePage();
      case AppRoutes.weatherPage:
        return WeatherPage();
      default:
        return HomePage();
    }
  }

  String _getRouteFromIndex(int index) {
    switch (index) {
      case 0:
        return AppRoutes.homePage;
      case 1:
        return AppRoutes.todoPage;
      case 3:
        return AppRoutes.searchPage;
      case 4:
        return AppRoutes.weatherPage;
      default:
        return AppRoutes.homePage;
    }
  }

  bool isCurrentRoute(String route) => _currentRoute == route;

  @override
  void dispose() {
    _currentRoute = AppRoutes.homePage;
    _currentPage = HomePage();
    super.dispose();
  }
}

