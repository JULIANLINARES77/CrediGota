import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/cuota.dart';
import '../../../data/models/prestamo.dart';
import '../../../logic/providers/gota_provider.dart';
import '../../widgets/cliente_card.dart';
import '../../widgets/gotacontrol_logo.dart';
import '../../widgets/payment_bottom_sheet.dart';
import '../../widgets/resumen_card.dart';
import '../prestamos/prestamo_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNuevoPrestamo,
    required this.onClientes,
    required this.onMora,
    required this.onPrestamos,
  });

  final VoidCallback onNuevoPrestamo;
  final VoidCallback onClientes;
  final VoidCallback onMora;
  final VoidCallback onPrestamos;

  @override
  Widget build(BuildContext context) {
    final demo = context.watch<GotaProvider>();
    if (demo.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ancho = MediaQuery.sizeOf(context).width;
    final dosColumnas = ancho > 650;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const GotaControlLogo(size: 40),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.appName,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  GotaDateUtils.formatearFecha(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => _mostrarNotificaciones(context, demo.moras.length),
            icon: Badge(
              isLabelVisible: demo.moras.isNotEmpty,
              label: Text('${demo.moras.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard-new-loan',
        onPressed: onNuevoPrestamo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo préstamo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              if (demo.avisoRespaldoInicio case final String aviso)
                Card(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    title: const Text('Revisa el respaldo'),
                    subtitle: Text(aviso),
                  ),
                ),
              ResumenCard(
                titulo: AppStrings.profitToday,
                valor: GotaDateUtils.formatearMoneda(demo.gananciaHoy),
                icono: Icons.trending_up,
                color: AppColors.primary,
                destacado: true,
                subtitulo: 'Interés proporcional recibido',
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: dosColumnas ? 2 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: dosColumnas ? 2.4 : 1.15,
                children: [
                  ResumenCard(
                    titulo: AppStrings.totalOnStreet,
                    valor: GotaDateUtils.formatearMoneda(demo.totalEnCalle),
                    icono: Icons.account_balance_wallet_outlined,
                    color: AppColors.orange,
                  ),
                  ResumenCard(
                    titulo: AppStrings.collectedToday,
                    valor: GotaDateUtils.formatearMoneda(demo.recaudadoHoy),
                    icono: Icons.payments_outlined,
                    color: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Estadisticas(
                clientes: demo.clientesActivos,
                enMora: demo.clientesEnMora,
                prestamos: demo.prestamosActivos.length,
                onClientes: onClientes,
                onMora: onMora,
                onPrestamos: onPrestamos,
              ),
              const SizedBox(height: 26),
              _TituloSeccion(
                titulo: AppStrings.todayDue,
                contador: demo.cuotasDeHoy.length,
                trailing: IconButton(
                  tooltip: 'Ver lista de clientes',
                  onPressed: onPrestamos,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
              const SizedBox(height: 8),
              if (demo.cuotasDeHoy.isEmpty)
                const _EstadoVacio(
                  mensaje: 'No hay cuotas pendientes para hoy.',
                )
              else
                ...demo.cuotasDeHoy.map((cuota) => _CobroDeHoy(cuota: cuota)),
              const SizedBox(height: 22),
              _TituloSeccion(
                titulo: AppStrings.overdueClients,
                contador: demo.moras.length,
                trailing: IconButton(
                  tooltip: 'Ver clientes en mora',
                  onPressed: onMora,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
              const SizedBox(height: 8),
              if (demo.moras.isEmpty)
                const _EstadoVacio(mensaje: 'No hay préstamos atrasados.')
              else
                ...demo.moras.map(
                  (mora) => ClienteCard(
                    cliente: mora.cliente,
                    saldoPendiente: mora.prestamo.saldoPendiente,
                    estado: 'MORA',
                    diasAtraso: mora.diasAtraso,
                    onTap: () => _abrirDetalle(context, mora.prestamo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void _abrirDetalle(BuildContext context, Prestamo prestamo) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PrestamoDetailScreen(prestamoId: prestamo.id!),
      ),
    );
  }

  static void _mostrarNotificaciones(BuildContext context, int cantidad) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alertas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              cantidad == 0
                  ? 'No tienes alertas pendientes.'
                  : 'Hay $cantidad préstamos con cuotas atrasadas.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CobroDeHoy extends StatelessWidget {
  const _CobroDeHoy({required this.cuota});

  final Cuota cuota;

  @override
  Widget build(BuildContext context) {
    final demo = context.read<GotaProvider>();
    final prestamo = demo.prestamoPorId(cuota.prestamoId);
    final cliente = prestamo == null
        ? null
        : demo.clientePorId(prestamo.clienteId);
    if (prestamo == null || cliente == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surface,
      child: ListTile(
        onTap: () => DashboardScreen._abrirDetalle(context, prestamo),
        leading: CircleAvatar(
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          child: const Icon(Icons.person_outline, color: AppColors.warning),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cliente.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              GotaDateUtils.formatearMoneda(
                cuota.montoCuota - cuota.montoPagado,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        subtitle: Text('Cuota ${cuota.numeroCuota} · ${cliente.telefono}'),
        trailing: IconButton(
          tooltip: 'Cobrar',
          onPressed: () => PaymentBottomSheet.show(
            context,
            cliente: cliente,
            prestamo: prestamo,
            cuota: cuota,
          ),
          icon: const Icon(Icons.payments_outlined, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Estadisticas extends StatelessWidget {
  const _Estadisticas({
    required this.clientes,
    required this.enMora,
    required this.prestamos,
    required this.onClientes,
    required this.onMora,
    required this.onPrestamos,
  });

  final int clientes;
  final int enMora;
  final int prestamos;
  final VoidCallback onClientes;
  final VoidCallback onMora;
  final VoidCallback onPrestamos;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _DatoCompacto(
        label: 'Clientes',
        valor: '$clientes',
        icono: Icons.people_outline,
        onTap: onClientes,
      ),
      const SizedBox(width: 8),
      _DatoCompacto(
        label: 'En mora',
        valor: '$enMora',
        icono: Icons.warning_amber,
        color: enMora > 0 ? AppColors.error : AppColors.primary,
        onTap: onMora,
      ),
      const SizedBox(width: 8),
      _DatoCompacto(
        label: 'Préstamos',
        valor: '$prestamos',
        icono: Icons.receipt_long_outlined,
        onTap: onPrestamos,
      ),
    ],
  );
}

class _DatoCompacto extends StatelessWidget {
  const _DatoCompacto({
    required this.label,
    required this.valor,
    required this.icono,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final String label;
  final String valor;
  final IconData icono;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 19),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.titulo, this.contador, this.trailing});

  final String titulo;
  final int? contador;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      if (contador case final contador?)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.elevatedSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$contador',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ?trailing,
    ],
  );
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      mensaje,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}
