import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/prestamo.dart';
import '../../../logic/providers/gota_provider.dart';
import '../../../logic/services/calculadora_service.dart';
import '../../widgets/resumen_card.dart';
import 'prestamo_detail_screen.dart';

class NuevoPrestamoScreen extends StatefulWidget {
  const NuevoPrestamoScreen({super.key});

  @override
  State<NuevoPrestamoScreen> createState() => _NuevoPrestamoScreenState();
}

class _NuevoPrestamoScreenState extends State<NuevoPrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capital = TextEditingController();
  final _interes = TextEditingController(text: '20');
  final _cuotas = TextEditingController(text: '24');
  final _calculadora = const CalculadoraService();
  int? _clienteId;
  String _frecuencia = CalculadoraService.frecuenciaLunesMiercolesViernes;
  final Set<int> _dias = {DateTime.monday, DateTime.wednesday, DateTime.friday};

  static const _opcionesFrecuencia = {
    CalculadoraService.frecuenciaDiaria: 'Diaria',
    CalculadoraService.frecuenciaSemanal: 'Semanal',
    CalculadoraService.frecuenciaQuincenal: 'Quincenal',
    CalculadoraService.frecuenciaLunesMiercolesViernes:
        'Lunes, miércoles y viernes',
    CalculadoraService.frecuenciaPersonalizada: 'Días personalizados',
  };

  @override
  void initState() {
    super.initState();
    _capital.addListener(_actualizar);
    _interes.addListener(_actualizar);
    _cuotas.addListener(_actualizar);
  }

  @override
  void dispose() {
    _capital.dispose();
    _interes.dispose();
    _cuotas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = context.watch<GotaProvider>();
    _clienteId ??= demo.clientes.isEmpty ? null : demo.clientes.first.id;
    final calculo = _calculoPreview();
    final fechas = _fechasPreview();
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo préstamo')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                const _Paso(titulo: '1. Selecciona el cliente'),
                const SizedBox(height: 10),
                if (demo.clientes.isEmpty)
                  const Text(
                    'Primero agrega un cliente para continuar.',
                    style: TextStyle(color: AppColors.warning),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _clienteId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                          ),
                          items: demo.clientes
                              .map(
                                (cliente) => DropdownMenuItem(
                                  value: cliente.id,
                                  child: Text(
                                    cliente.nombre,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (valor) =>
                              setState(() => _clienteId = valor),
                          validator: (valor) =>
                              valor == null ? 'Selecciona un cliente' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Crear cliente',
                        onPressed: _crearClienteRapido,
                        icon: const Icon(Icons.person_add_alt_1),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                const _Paso(titulo: '2. Datos del préstamo'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _capital,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Capital prestado',
                    prefixText: '\$ ',
                    hintText: '1.000.000',
                  ),
                  validator: (valor) => (_parsear(valor) ?? 0) <= 0
                      ? 'Ingresa un capital mayor que cero'
                      : null,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final campoInteres = TextFormField(
                      controller: _interes,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Interés (%)',
                        suffixText: '%',
                      ),
                      validator: (valor) => (_parsear(valor) ?? -1) < 0
                          ? 'Revisa el interés'
                          : null,
                    );
                    final campoCuotas = TextFormField(
                      controller: _cuotas,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Número de cuotas',
                      ),
                      validator: (valor) =>
                          (int.tryParse(valor ?? '') ?? 0) <= 0
                          ? 'Debe ser mayor que cero'
                          : null,
                    );
                    return constraints.maxWidth < 430
                        ? Column(
                            children: [
                              campoInteres,
                              const SizedBox(height: 12),
                              campoCuotas,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: campoInteres),
                              const SizedBox(width: 10),
                              Expanded(child: campoCuotas),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _frecuencia,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Frecuencia de pago',
                  ),
                  items: _opcionesFrecuencia.entries
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.key,
                          child: Text(
                            item.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) =>
                      setState(() => _frecuencia = valor ?? _frecuencia),
                ),
                if (_frecuencia ==
                    CalculadoraService.frecuenciaPersonalizada) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Días de pago',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    children: [
                      for (var dia = 1; dia <= 7; dia++)
                        FilterChip(
                          label: Text(
                            GotaDateUtils.obtenerNombreDia(dia).substring(0, 3),
                          ),
                          selected: _dias.contains(dia),
                          onSelected: (seleccionado) => setState(() {
                            if (seleccionado) {
                              _dias.add(dia);
                            } else {
                              _dias.remove(dia);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const _Paso(titulo: '3. Resumen'),
                const SizedBox(height: 10),
                if (calculo != null && fechas != null)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ResumenCard(
                              titulo: 'Total a pagar',
                              valor: GotaDateUtils.formatearMoneda(
                                calculo.montoTotalPagar,
                              ),
                              icono: Icons.account_balance_outlined,
                              color: AppColors.blue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ResumenCard(
                              titulo: 'Valor de cuota',
                              valor: GotaDateUtils.formatearMoneda(
                                calculo.valorCuota,
                              ),
                              icono: Icons.event_repeat,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Final estimado · ${GotaDateUtils.formatearFecha(fechas.last)}',
                              ),
                            ),
                            Text(
                              'Ganancia ${GotaDateUtils.formatearMoneda(calculo.montoInteres)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Completa capital, interés y cuotas para ver el cálculo.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: demo.clientes.isEmpty
                      ? null
                      : () => _crearPrestamo(demo),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Crear préstamo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _parsear(String? valor) =>
      double.tryParse((valor ?? '').trim().replaceAll(',', '.'));

  ResultadoCalculoPrestamo? _calculoPreview() {
    final capital = _parsear(_capital.text);
    final interes = _parsear(_interes.text);
    final cantidad = int.tryParse(_cuotas.text);
    if (capital == null ||
        interes == null ||
        cantidad == null ||
        capital <= 0 ||
        interes < 0 ||
        cantidad <= 0) {
      return null;
    }
    try {
      return _calculadora.calcularPrestamo(
        capital: capital,
        porcentajeInteres: interes,
        numCuotas: cantidad,
      );
    } on ArgumentError {
      return null;
    }
  }

  List<DateTime>? _fechasPreview() {
    final cantidad = int.tryParse(_cuotas.text);
    if (cantidad == null ||
        cantidad <= 0 ||
        (_frecuencia == CalculadoraService.frecuenciaPersonalizada &&
            _dias.isEmpty)) {
      return null;
    }
    try {
      return _calculadora.generarFechasPago(
        fechaInicio: DateTime.now(),
        numCuotas: cantidad,
        frecuencia: _frecuencia,
        diasPersonalizados:
            _frecuencia == CalculadoraService.frecuenciaPersonalizada
            ? _dias.toList()
            : null,
      );
    } on ArgumentError {
      return null;
    }
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _crearPrestamo(GotaProvider demo) async {
    if (!_formKey.currentState!.validate()) return;
    if (_frecuencia == CalculadoraService.frecuenciaPersonalizada &&
        _dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día de pago.')),
      );
      return;
    }
    final Prestamo prestamo;
    try {
      prestamo = await demo.crearPrestamo(
        clienteId: _clienteId!,
        capital: _parsear(_capital.text)!,
        porcentajeInteres: _parsear(_interes.text)!,
        numCuotas: int.parse(_cuotas.text),
        frecuencia: _frecuencia,
        diasPersonalizados:
            _frecuencia == CalculadoraService.frecuenciaPersonalizada
            ? _dias.toList()
            : null,
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Préstamo creado.')));
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PrestamoDetailScreen(prestamoId: prestamo.id!),
      ),
    );
  }

  Future<void> _crearClienteRapido() async {
    final nombre = TextEditingController();
    final telefono = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (!mounted) {
      nombre.dispose();
      telefono.dispose();
      return;
    }
    if (confirmado == true &&
        nombre.text.trim().isNotEmpty &&
        telefono.text.trim().isNotEmpty) {
      final demo = context.read<GotaProvider>();
      await demo.agregarCliente(nombre: nombre.text, telefono: telefono.text);
      setState(() => _clienteId = demo.clientes.last.id);
    }
    nombre.dispose();
    telefono.dispose();
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.titulo});
  final String titulo;
  @override
  Widget build(BuildContext context) => Text(
    titulo,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );
}
