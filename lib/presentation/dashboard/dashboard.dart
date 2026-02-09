import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './dashboard_initial_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  // ALL CustomBottomBar routes in EXACT order matching the bottom navigation items
  final List<String> routes = [
    '/dashboard',
    '/analytics-view',
    '/wellness-goals',
    '/recovery-guidance',
    '/settings',
    '/subscription-management', // Profile tab maps to subscription management
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/dashboard',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/dashboard' || '/':
              return MaterialPageRoute(
                builder: (context) => const DashboardInitialPage(),
                settings: settings,
              );
            default:
              // Check AppRoutes.routes for all other routes
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // For the routes that are not in the AppRoutes.routes, do not navigate to them.
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
