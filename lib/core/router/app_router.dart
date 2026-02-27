import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/operator_home_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/operators/screens/operators_screen.dart';
import '../../features/client/screens/register_screen.dart';
import '../../features/client/screens/client_home_screen.dart';
import '../../features/client/screens/new_order_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/orders/screens/orders_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String operatorHome = '/operator/home';
  static const String adminHome = '/admin/home';
  static const String operatorsManagement = '/admin/operators';
  static const String clientHome = '/client/home';
  static const String newOrder = '/client/new-order';
  static const String orders = '/orders';
  static const String adminOrders = '/admin/orders';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fade(const SplashScreen());
      case login:
        return _fade(const LoginScreen());
      case register:
        return _fade(const RegisterScreen());
      case forgotPassword:
        return _fade(const ForgotPasswordScreen());
      case operatorHome:
        return _fade(const OperatorHomeScreen());
      case adminHome:
        return _fade(const AdminHomeScreen());
      case operatorsManagement:
        return _fade(const OperatorsScreen());
      case clientHome:
        return _fade(const ClientHomeScreen());
      case newOrder:
        return _fade(const NewOrderScreen());
      case orders:
        return _fade(const OrdersScreen(isAdmin: false));
      case adminOrders:
        return _fade(const OrdersScreen(isAdmin: true));
      default:
        return _fade(const LoginScreen());
    }
  }

  static PageRoute _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
