import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/cliente.dart';
import '../../../logic/providers/demo_provider.dart';
import 'pdf_generator.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String _tipo = 'diario';
  DateTime _fecha = DateTime.now();
  int? _clienteId;
  bool _vistaPrevia = false;

  static const _reportes = {
    'diario': ('Reporte diario', Icons.today_outlined),
    'semanal': ('Reporte semanal', Icons.view_week_outlined),
    'mensual': ('Reporte mensual', Icons.bar_chart_outlined),
    'mora': ('Reporte de mora', Icons.warning_amber_outlined),
    'cliente': ('Estado de cuenta', Icons.person_search_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final demo = context.watch<DemoProvider>();
    final cliente = _clienteId == null ? null : demo.clientePorId(_clienteId!);
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                'Selecciona un reporte',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
                children: [
                  for (final entrada in _reportes.entries)
                    _ReporteChoice(
                      titulo: entrada.value.$1,
                      icono: entrada.value.$2,
                      seleccionado: _tipo == entrada.key,
                      onTap: () => setState(() {
                        _tipo = entrada.key;
                        _vistaPrevia = false;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_tipo == 'cliente')
                DropdownButtonFormField<int>(
                  initialValue: _clienteId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: demo.clientes
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) => setState(() {
                    _clienteId = valor;
                    _vistaPrevia = false;
                  }),
                )
              else
                OutlinedButton.icon(
                  onPressed: _seleccionarFecha,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _tipo == 'mensual'
                        ? DateFormatUtils.mes(_fecha)
                        : GotaDateUtils.formatearFecha(_fecha),
                  ),
                ),
              const SizedBox(height: 14),
              _ResumenPreview(
                demo: demo,
                tipo: _tipo,
                cliente: cliente,
                fecha: _fecha,
              ),
              const SizedBox(height: 16),
              if (_vistaPrevia) ...[
                SizedBox(
                  height: 620,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: PdfPreview(
                      build: (_) => _generarBytes(demo, cliente),
                      pdfFileName: 'GotaControl-$_tipo.pdf',
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      allowPrinting: false,
                      allowSharing: false,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async => PdfGenerator.imprimir(
                          await _generarBytes(demo, cliente),
                        ),
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Imprimir / guardar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async => PdfGenerator.compartir(
                          await _generarBytes(demo, cliente),
                          nombre: 'GotaControl-$_tipo.pdf',
                        ),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Compartir'),
                      ),
                    ),
                  ],
                ),
              ] else
                FilledButton.icon(
                  onPressed: _tipo == 'cliente' && cliente == null
                      ? null
                      : () => setState(() => _vistaPrevia = true),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Vista previa PDF'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) {
      setState(() {
        _fecha = fecha;
        _vistaPrevia = false;
      });
    }
  }

  Future<Uint8List> _generarBytes(DemoProvider demo, Cliente? cliente) =>
      switch (_tipo) {
        'diario' => PdfGenerator.reporteDiario(demo, _fecha),
        'semanal' => PdfGenerator.reporteSemanal(demo, _fecha),
        'mensual' => PdfGenerator.reporteMensual(demo, _fecha),
        'mora' => PdfGenerator.reporteMora(demo, _fecha),
        'cliente' when cliente != null => PdfGenerator.estadoCuenta(
          demo,
          cliente,
        ),
        _ => Future.error(
          StateError('Selecciona un cliente para generar el estado de cuenta.'),
        ),
      };
}

class _ReporteChoice extends StatelessWidget {
  const _ReporteChoice({
    required this.titulo,
    required this.icono,
    required this.seleccionado,
    required this.onTap,
  });
  final String titulo;
  final IconData icono;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: seleccionado
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: seleccionado ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icono,
            color: seleccionado ? AppColors.primary : AppColors.textSecondary,
          ),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _ResumenPreview extends StatelessWidget {
  const _ResumenPreview({
    required this.demo,
    required this.tipo,
    required this.cliente,
    required this.fecha,
  });
  final DemoProvider demo;
  final String tipo;
  final Cliente? cliente;
  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    final filas = switch (tipo) {
      'diario' => [
        ('Recaudo', GotaDateUtils.formatearMoneda(demo.recaudadoHoy)),
        ('Ganancia', GotaDateUtils.formatearMoneda(demo.gananciaHoy)),
        ('Pagos', '${demo.pagos.length}'),
      ],
      'semanal' => [
        ('Semana de', GotaDateUtils.formatearFecha(fecha)),
        ('Recaudo', GotaDateUtils.formatearMoneda(demo.recaudadoHoy)),
        ('Pagos', '${demo.pagos.length}'),
      ],
      'mensual' => [
        ('Mes', DateFormatUtils.mes(fecha)),
        ('Operaciones registradas', '${demo.pagos.length}'),
        ('Interés estimado', GotaDateUtils.formatearMoneda(demo.gananciaHoy)),
      ],
      'mora' => [
        ('Préstamos atrasados', '${demo.moras.length}'),
        (
          'Saldo en mora',
          GotaDateUtils.formatearMoneda(
            demo.moras.fold(
              0.0,
              (total, mora) => total + mora.prestamo.saldoPendiente,
            ),
          ),
        ),
      ],
      _ => [
        ('Cliente', cliente?.nombre ?? 'Selecciona un cliente'),
        (
          'Préstamos',
          '${cliente == null ? 0 : demo.prestamosDeCliente(cliente!.id!).length}',
        ),
        (
          'Saldo',
          GotaDateUtils.formatearMoneda(
            cliente == null
                ? 0
                : demo
                      .prestamosDeCliente(cliente!.id!)
                      .fold(
                        0.0,
                        (total, prestamo) => total + prestamo.saldoPendiente,
                      ),
          ),
        ),
      ],
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del reporte',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final fila in filas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fila.$1,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    fila.$2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DateFormatUtils {
  DateFormatUtils._();
  static String mes(DateTime fecha) {
    const nombres = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${nombres[fecha.month - 1]} ${fecha.year}';
  }
}
