import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/viewmodels/auth_provider.dart';
import 'features/dashboard/views/dashboard_shell_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: '.env');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Metiss Partner Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.user != null
          ? const DashboardShellView()
          : const LoginView(),
    );
  }
}
