import 'package:maliza/features/app/presentation/pages/app.dart';
import 'package:flutter/material.dart';
import 'package:maliza/features/app/presentation/pages/profile_page.dart';
import 'package:maliza/features/auth/presentation/pages/login_page.dart';
import 'package:maliza/features/auth/presentation/pages/registration_page.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:maliza/core/widgets/default_page_wrapper.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return _buildRoute(LoginPage(), settings);

      case AppRoutes.register:
        return _buildRoute(RegistrationPage(), settings);

      case AppRoutes.splash:
      case AppRoutes.home:
        return _buildRoute(App(), settings);

      case AppRoutes.profile:
        return _buildRoute(ProfilePage(), settings);

      default:
        return _buildRoute(
          _NotFoundPage(routeName: settings.name ?? 'Unknown'),
          settings,
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => DefaultPageWrapper(child: page),
      settings: settings,
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  final String routeName;

  const _NotFoundPage({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Route: $routeName'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home),
              child: Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
