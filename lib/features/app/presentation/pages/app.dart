import 'package:maliza/core/data/account_cache.dart';
import 'package:maliza/core/routes/app_routes.dart';
import 'package:maliza/features/app/presentation/bloc/add_task_bloc.dart';
import 'package:maliza/features/app/presentation/widget/top_bar.dart';
import 'package:maliza/features/app/provider/route_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  _init() async {
    final bool isLogined = await AccountCache.isLogined() ?? false;

    if (!isLogined) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FToaster(
      child: Consumer<RouteNavigationProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: FScaffold(header: TopBar(), child: provider.currentPage),
            bottomNavigationBar: FBottomNavigationBar(
              index: provider.index,
              onChange: (pageIndex) {
                provider.navigateToIndex(pageIndex);
              },
              children: const [
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.house),
                  label: Text('Accueil'),
                ),
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.clipboardCheck),
                  label: Text('Todos'),
                ),
                FBottomNavigationBarItem(
                  icon: AddTaskBloc(),
                  label: Text("Add Todo"),
                ),
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.search),
                  label: Text('Recherche'),
                ),
                FBottomNavigationBarItem(
                  icon: Icon(FIcons.cloudSun),
                  label: Text('Météo'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
