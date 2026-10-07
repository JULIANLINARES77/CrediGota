import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../logic/providers/gota_provider.dart';

class DatabaseStatusOverlay extends StatelessWidget {
  const DatabaseStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GotaProvider>();
    if (!provider.cargando && provider.errorCarga == null) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(ignoring: true, child: child),
        ColoredBox(
          color: AppColors.background.withValues(alpha: 0.96),
          child: SafeArea(
            child: Center(
              child: provider.cargando
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text('Cargando información local...'),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storage_outlined,
                            size: 44,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No se pudo cargar la base de datos local.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.errorCarga!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: provider.cargarDatos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}