import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../domain/app_user.dart';
import 'account_status_screen.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final destination = context.watch<AuthController>().destination;

    switch (destination) {
      case AccessDestination.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AccessDestination.unauthenticated:
        return const LoginScreen();
      case AccessDestination.farmerDashboard:
        return const HomeScreen();
      case AccessDestination.adminDashboard:
        return const AdminDashboardScreen();
      case AccessDestination.pendingApproval:
        return const PendingApprovalScreen();
      case AccessDestination.rejected:
        return const RejectedAccountScreen();
      case AccessDestination.blocked:
        return const BlockedAccountScreen();
      case AccessDestination.accessDenied:
        return const AccessDeniedScreen();
    }
  }
}
