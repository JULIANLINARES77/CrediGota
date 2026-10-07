import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/prestamo.dart';
import '../../../logic/providers/gota_provider.dart';
import 'prestamo_detail_screen.dart';

class PrestamosClienteScreen extends StatelessWidget {
  const PrestamosClienteScreen({super.key, required this.clienteId});

  final int clienteId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GotaProvider>();
    if (provider.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cliente = provider.clientePorId(clienteId);
    if (cliente == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Préstamos del cliente')),
        body: const Center(child: Text('No se encontró el cliente.')),
      );
    }
    final prestamos = provider.prestamosDeCliente(clienteId).toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    final totalPendiente = prestamos
        .where((prestamo) => prestamo.estado == 'ACTIVO' || prestamo.estado == 'MORA')
        .fold(0.0, (total, prestamo) => total + prestamo.saldoPendiente);

    return Scaffold(
      appBar: AppBar(title: Text('Préstamos · ${cliente.nombre}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Saldo total pendiente'),
              subtitle: Text(
                GotaDateUtils.formatearMoneda(totalPendiente),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Text('${prestamos.length}'),
            ),
          ),
          const SizedBox(height: 12),
          if (prestamos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text('Este cliente todavía no tiene préstamos.'),
              ),
            )
          else
            for (final prestamo in prestamos)
              _PrestamoTile(
                prestamo: prestamo,
                onTap: prestamo.id == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PrestamoDetailScreen(prestamoId: prestamo.id!),
                        ),
                      ),
              ),
        ],
      ),
    );
  }
}

class _PrestamoTile extends StatelessWidget {
  const _PrestamoTile({required this.prestamo, required this.onTap});

  final Prestamo prestamo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      title: Text(
        'Préstamo #${prestamo.id ?? '—'} · ${GotaDateUtils.formatearMoneda(prestamo.montoCapital)}',
      ),
      subtitle: Text(
        '${GotaDateUtils.formatearFecha(prestamo.fechaInicio)} · '
        '${GotaDateUtils.formatearMoneda(prestamo.saldoPendiente)} pendiente',
      ),
      trailing: Chip(label: Text(prestamo.estado)),
    ),
  );
}
