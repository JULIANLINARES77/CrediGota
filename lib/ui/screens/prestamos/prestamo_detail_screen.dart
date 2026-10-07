import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/prestamo.dart';
import '../../../logic/providers/gota_provider.dart';
import '../../widgets/cuota_row.dart';
import '../../widgets/payment_bottom_sheet.dart';

class PrestamoDetailScreen extends StatelessWidget {
  const PrestamoDetailScreen({super.key, required this.prestamoId});

  final int prestamoId;

  @override
  Widget build(BuildContext context) {
    final demo = context.watch<GotaProvider>();
    if (demo.cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del préstamo')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (demo.errorCarga != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del préstamo')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No se pudo cargar el detalle del préstamo.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: demo.cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    final prestamo = demo.prestamoPorId(prestamoId);
    if (prestamo == null) {
      return _estadoNoEncontrado(context, 'No se encontró el préstamo.');
    }
    final cliente = demo.clientePorId(prestamo.clienteId);
    if (cliente == null || cliente.id == null) {
      return _estadoNoEncontrado(context, 'No se encontró el cliente.');
    }
    final prestamosCliente = demo.prestamosDeCliente(cliente.id!).toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
    final cuotas = demo.cuotasDePrestamo(prestamoId);
    final pagadas = cuotas.where((cuota) => cuota.estado == 'PAGADA').length;
    final progreso = cuotas.isEmpty ? 0.0 : pagadas / cuotas.length;
    final proxima = cuotas
        .where((cuota) => cuota.estado != 'PAGADA')
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del préstamo'),
        actions: [
          IconButton(
            tooltip: 'Historial de pagos',
            onPressed: () => _mostrarHistorial(context, demo, prestamo),
            icon: const Icon(Icons.history),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          cliente.telefono,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _EstadoPrestamo(estado: prestamo.estado),
                ],
              ),
              const SizedBox(height: 18),
              _ResumenPrestamo(prestamo: prestamo),
              const SizedBox(height: 22),
              Text(
                'Historial de préstamos',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...prestamosCliente.map(
                (item) => _HistorialPrestamoTile(
                  prestamo: item,
                  seleccionado: item.id == prestamo.id,
                  onTap: item.id == null || item.id == prestamo.id
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PrestamoDetailScreen(prestamoId: item.id!),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Progreso del préstamo',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$pagadas/${cuotas.length} cuotas · ${(progreso * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progreso,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.primary,
                      backgroundColor: AppColors.elevatedSurface,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _Saldo(
                            label: 'Saldo pendiente',
                            valor: prestamo.saldoPendiente,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _Saldo(
                            label: 'Total pagado',
                            valor: prestamo.totalPagado,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (prestamo.saldoPendiente <= 0) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _pazYSalvo(context, cliente.nombre),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Generar paz y salvo'),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Plan de pagos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (proxima != null)
                    Text(
                      'Siguiente: ${GotaDateUtils.formatearFecha(proxima.fechaVencimiento)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (cuotas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Este préstamo todavía no tiene cuotas registradas.',
                  ),
                )
              else ...[
                const _EncabezadoCuotas(),
                const SizedBox(height: 8),
                ...cuotas.map(
                  (cuota) => CuotaRow(
                    cuota: cuota,
                    diasAtraso: cuota.estado == 'PAGADA'
                        ? 0
                        : _diasAtraso(cuota.fechaVencimiento),
                    onPagar: () => PaymentBottomSheet.show(
                      context,
                      cliente: cliente,
                      prestamo: prestamo,
                      cuota: cuota,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _estadoNoEncontrado(BuildContext context, String mensaje) =>
      Scaffold(
        appBar: AppBar(title: const Text('Detalle del préstamo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(mensaje, textAlign: TextAlign.center),
          ),
        ),
      );

  static int _diasAtraso(DateTime fecha) {
    final hoy = DateTime.now();
    return DateTime(hoy.year, hoy.month, hoy.day)
        .difference(DateTime(fecha.year, fecha.month, fecha.day))
        .inDays
        .clamp(0, 100000);
  }

  static void _mostrarHistorial(
    BuildContext context,
    GotaProvider demo,
    Prestamo prestamo,
  ) {
    final prestamoId = prestamo.id;
    if (prestamoId == null) return;
    final pagos = demo.pagosDePrestamo(prestamoId);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Historial de pagos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (pagos.isEmpty) const Text('Aún no hay pagos registrados.'),
            for (final pago in pagos)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.primary,
                ),
                title: Text(GotaDateUtils.formatearMoneda(pago.monto)),
                subtitle: Text(
                  '${GotaDateUtils.formatearFechaHora(pago.fechaHora)} · ${pago.metodoPago ?? 'Sin método'}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  static void _pazYSalvo(BuildContext context, String nombre) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paz y salvo de $nombre listo para generar.')),
    );
  }
}

class _ResumenPrestamo extends StatelessWidget {
  const _ResumenPrestamo({required this.prestamo});
  final Prestamo prestamo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      children: [
        _Dato(label: 'Capital prestado', valor: prestamo.montoCapital),
        _Dato(
          label: 'Interés (${prestamo.porcentajeInteres.toStringAsFixed(0)}%)',
          valor: prestamo.montoInteres,
        ),
        const Divider(height: 18),
        _Dato(
          label: 'Total a pagar',
          valor: prestamo.montoTotalPagar,
          destacado: true,
        ),
        _Dato(label: 'Valor por cuota', valor: prestamo.valorCuota),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Frecuencia',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Text(
              prestamo.frecuencia.replaceAll('_', ' '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Inicio / final estimado',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Text(
              '${GotaDateUtils.formatearFecha(prestamo.fechaInicio)} · ${GotaDateUtils.formatearFecha(prestamo.fechaFinEstimada)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HistorialPrestamoTile extends StatelessWidget {
  const _HistorialPrestamoTile({
    required this.prestamo,
    required this.seleccionado,
    required this.onTap,
  });

  final Prestamo prestamo;
  final bool seleccionado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 7),
    color: seleccionado ? AppColors.elevatedSurface : AppColors.surface,
    child: ListTile(
      onTap: onTap,
      leading: Icon(
        seleccionado ? Icons.radio_button_checked : Icons.receipt_long_outlined,
        color: seleccionado ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        GotaDateUtils.formatearMoneda(prestamo.montoCapital),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${GotaDateUtils.formatearFecha(prestamo.fechaInicio)} · Saldo ${GotaDateUtils.formatearMoneda(prestamo.saldoPendiente)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _EstadoPrestamo(estado: prestamo.estado),
    ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.label,
    required this.valor,
    this.destacado = false,
  });
  final String label;
  final double valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: destacado
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          GotaDateUtils.formatearMoneda(valor),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: destacado ? AppColors.primary : null,
          ),
        ),
      ],
    ),
  );
}

class _Saldo extends StatelessWidget {
  const _Saldo({required this.label, required this.valor, required this.color});
  final String label;
  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 3),
      FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          GotaDateUtils.formatearMoneda(valor),
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _EstadoPrestamo extends StatelessWidget {
  const _EstadoPrestamo({required this.estado});
  final String estado;

  Color get _color => switch (estado) {
    'MORA' => AppColors.error,
    'PAGADO' => AppColors.primary,
    'CANCELADO' => AppColors.textSecondary,
    'ACTIVO' => AppColors.warning,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EncabezadoCuotas extends StatelessWidget {
  const _EncabezadoCuotas();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '#',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Vencimiento',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Valor',
            textAlign: TextAlign.end,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        SizedBox(width: 38),
      ],
    ),
  );
}