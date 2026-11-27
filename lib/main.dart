import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/soilsafe_theme.dart';
import 'features/assessment/data/assessment_repository.dart';
import 'features/auth/data/firebase_auth_service.dart';
import 'features/auth/data/user_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/devices/data/device_repository.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/notifications/data/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase.initializeApp failed: $e\n$stack');
  }
  runApp(const SoilSafeApp());
}

class SoilSafeApp extends StatelessWidget {
  const SoilSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseAuthService()),
        Provider(create: (_) => UserRepository()),
        Provider(create: (_) => DeviceRepository()),
        Provider(create: (_) => AssessmentRepository()),
        Provider(create: (_) => NotificationRepository()),
        Provider(
          create: (_) => PushNotificationService(),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            authService: context.read<FirebaseAuthService>(),
            userRepository: context.read<UserRepository>(),
            pushService: context.read<PushNotificationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'SoilSAFE',
        debugShowCheckedModeBanner: false,
        theme: SoilSafeTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
