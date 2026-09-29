import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/cliente.dart';
import '../../data/models/cuota.dart';
import '../../data/models/prestamo.dart';
import '../../logic/providers/demo_provider.dart';

class PaymentBottomSheet extends StatefulWidget {
  const PaymentBottomSheet({
    super.key,
    required this.cliente,
    required this.prestamo,
    required this.cuota,
  });

  final Cliente cliente;
  final Prestamo prestamo;
  final Cuota cuota;

  static Future<void> show(
    BuildContext context, {
    required Cliente cliente,
    required Prestamo prestamo,
    required Cuota cuota,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        PaymentBottomSheet(cliente: cliente, prestamo: prestamo, cuota: cuota),
  );

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  late final TextEditingController _montoController;
  final _notaController = TextEditingController();
  DateTime _fecha = DateTime.now();
  String _metodo = 'EFECTIVO';
  String? _error;

  @override
  void initState() {
    super.initState();
    final saldo = widget.cuota.montoCuota - widget.cuota.montoPagado;
    _montoController = TextEditingController(text: saldo.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _montoController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Registrar pago',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.cliente.nombre,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto recibido',
                prefixText: '\$ ',
                helperText:
                    'Saldo de esta cuota: ${GotaDateUtils.formatearMoneda(widget.cuota.montoCuota - widget.cuota.montoPagado)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(GotaDateUtils.formatearFecha(_fecha)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _metodo,
              decoration: const InputDecoration(labelText: 'Método de pago'),
              items: const [
                DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
                DropdownMenuItem(value: 'NEQUI', child: Text('Nequi')),
                DropdownMenuItem(value: 'DAVIPLATA', child: Text('Daviplata')),
                DropdownMenuItem(
                  value: 'TRANSFERENCIA',
                  child: Text('Transferencia'),
                ),
              ],
              onChanged: (value) => setState(() => _metodo = value ?? _metodo),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notaController,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _confirmar,
              icon: const Icon(Icons.check),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Text('Confirmar pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _elegirFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (seleccion != null) setState(() => _fecha = seleccion);
  }

  void _confirmar() {
    final monto = double.tryParse(_montoController.text.replaceAll(',', '.'));
    try {
      context.read<DemoProvider>().registrarPago(
        prestamoId: widget.prestamo.id!,
        cuotaId: widget.cuota.id!,
        monto: monto ?? 0,
        metodoPago: _metodo,
        fecha: _fecha,
        nota: _notaController.text.trim().isEmpty
            ? null
            : _notaController.text.trim(),
      );
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Pago registrado correctamente')),
      );
    } on Object catch (error) {
      setState(
        () => _error = error.toString().replaceFirst('ArgumentError: ', ''),
      );
    }
  }
}
