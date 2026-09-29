import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../screens/ajustes/ajustes_screen.dart';
import '../screens/clientes/clientes_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/prestamos/nuevo_prestamo_screen.dart';
import '../screens/reportes/reportes_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final paginas = [
      DashboardScreen(onNuevoPrestamo: () => setState(() => _indice = 2)),
      const ClientesScreen(),
      const NuevoPrestamoScreen(),
      const ReportesScreen(),
      const AjustesScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() => _indice = indice),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.dashboard,
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: AppStrings.clients,
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 29),
            selectedIcon: Icon(Icons.add_circle, size: 29),
            label: 'Nuevo',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: AppStrings.reports,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}
