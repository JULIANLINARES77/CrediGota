import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'data/database/database_helper.dart';
import 'logic/providers/gota_provider.dart';
import 'logic/services/notificacion_service.dart';
import 'ui/screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) await DatabaseHelper.instance.database;
  await NotificacionService.instance.inicializarNotificaciones();
  runApp(
    ChangeNotifierProvider(
      create: (_) => GotaProvider()..cargarDatos(),
      child: const GotaControlApp(),
    ),
  );
}

class GotaControlApp extends StatelessWidget {
  const GotaControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surface,
      primary: AppColors.primary,
      error: AppColors.error,
    );
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colors,
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
        ),
        dividerColor: AppColors.divider,
      ),
      home: const MainShell(),
    );
  }
}
