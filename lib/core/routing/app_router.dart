import 'package:flutter/material.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/root/root_nav_page.dart';
import '../../features/stores/presentation/stores_map_page.dart';
import '../../features/auth/presentation/complete_profile_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const completeProfile = '/profile/complete';
  static const home = '/home';
  static const storesMap = '/stores/map';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return MaterialPageRoute(builder: (_) => const SplashPage());
    case AppRoutes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case AppRoutes.completeProfile:
      return MaterialPageRoute(builder: (_) => const CompleteProfilePage());
    case AppRoutes.home:
      return MaterialPageRoute(builder: (_) => const RootNavPage());
    case AppRoutes.storesMap:
      return MaterialPageRoute(builder: (_) => const StoresMapPage());
    default:
      return MaterialPageRoute(builder: (_) => const SplashPage());
  }
}
