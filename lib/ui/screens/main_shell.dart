import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../screens/ajustes/ajustes_screen.dart';
import '../screens/clientes/clientes_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/prestamos/nuevo_prestamo_screen.dart';
import '../screens/reportes/reportes_screen.dart';
import '../widgets/database_status_overlay.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _indice = 0;
  int _clientesRevision = 0;
  String _filtroInicialClientes = 'Todos';

  void _abrirClientes(String filtro) {
    setState(() {
      _indice = 1;
      _filtroInicialClientes = filtro;
      _clientesRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paginas = [
      DashboardScreen(
        onNuevoPrestamo: () => setState(() => _indice = 2),
        onClientes: () => _abrirClientes('Todos'),
        onMora: () => _abrirClientes('En mora'),
        onPrestamos: () => _abrirClientes('Con préstamos'),
      ),
      ClientesScreen(
        key: ValueKey(_clientesRevision),
        filtroInicial: _filtroInicialClientes,
      ),
      const NuevoPrestamoScreen(),
      const ReportesScreen(),
      const AjustesScreen(),
    ];
    return Scaffold(
      body: DatabaseStatusOverlay(
        child: IndexedStack(index: _indice, children: paginas),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() {
          _indice = indice;
          if (indice == 1) {
            _filtroInicialClientes = 'Todos';
            _clientesRevision++;
          }
        }),
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
