import 'package:flutter/foundation.dart';

import '../../data/database/database_helper.dart';
import '../../data/models/cliente.dart';
import '../../data/models/cuota.dart';
import '../../data/models/pago.dart';
import '../../data/models/prestamo.dart';
import '../services/calculadora_service.dart';
import '../services/mora_service.dart';

class GotaProvider extends ChangeNotifier {
  GotaProvider({
    DatabaseHelper? databaseHelper,
    this._calculadora = const CalculadoraService(),
    DateTime Function()? reloj,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       _reloj = reloj ?? DateTime.now;

  final DatabaseHelper _databaseHelper;
  final CalculadoraService _calculadora;
  final DateTime Function() _reloj;

  List<Cliente> _clientes = [];
  List<Prestamo> _prestamos = [];
  Map<int, List<Cuota>> _cuotasPorPrestamo = {};
  List<Pago> _pagosHoy = [];
  List<Pago> _pagos = [];
  Map<String, dynamic> _resumenDashboard = {};
  List<PrestamoEnMora> _moras = [];
  bool cargando = true;
  String? errorCarga;

  List<Cliente> get clientes =>
      List.unmodifiable(_clientes.where((cliente) => cliente.activo));

  List<Prestamo> get prestamos => List.unmodifiable(_prestamos);

  List<Prestamo> get prestamosActivos => List.unmodifiable(
    _prestamos.where(
      (prestamo) => prestamo.estado == 'ACTIVO' || prestamo.estado == 'MORA',
    ),
  );

  List<Pago> get pagos => List.unmodifiable(_pagos);
  List<Pago> get pagosHoy => List.unmodifiable(_pagosHoy);
  Map<String, dynamic> get resumenDashboard =>
      Map.unmodifiable(_resumenDashboard);
  List<PrestamoEnMora> get moras => List.unmodifiable(_moras);

  double get totalEnCalle => _valorDouble(_resumenDashboard['total_en_calle']);
  double get recaudadoHoy => _valorDouble(_resumenDashboard['recaudo_hoy']);
  double get gananciaHoy => _valorDouble(_resumenDashboard['ganancia_hoy']);
  int get clientesActivos => clientes.length;
  int get clientesEnMora =>
      _moras.map((mora) => mora.cliente.id).toSet().length;

  List<Cuota> get cuotasDeHoy {
    final hoy = _soloFecha(_reloj());
    return List.unmodifiable(
      _cuotasPorPrestamo.values
          .expand((cuotas) => cuotas)
          .where((cuota) {
            final estadoPrestamo = _prestamoPorId(cuota.prestamoId)?.estado;
            return cuota.estado != 'PAGADA' &&
                _mismaFecha(cuota.fechaVencimiento, hoy) &&
                (estadoPrestamo == 'ACTIVO' || estadoPrestamo == 'MORA');
          }),
    );
  }

  List<Cuota> get todasLasCuotas =>
      List.unmodifiable(_cuotasPorPrestamo.values.expand((cuotas) => cuotas));

  Future<void> cargarDatos() async {
    cargando = true;
    errorCarga = null;
    notifyListeners();

    try {
      final clientes = await _databaseHelper.obtenerTodosLosClientes();
      final prestamosActivos = await _databaseHelper.obtenerPrestamosActivos();
      final prestamosPorId = <int, Prestamo>{
        for (final prestamo in prestamosActivos)
          if (prestamo.id != null) prestamo.id!: prestamo,
      };

      for (final cliente in clientes) {
        if (cliente.id == null) continue;
        final prestamosCliente = await _databaseHelper
            .obtenerPrestamosPorCliente(cliente.id!);
        for (final prestamo in prestamosCliente) {
          if (prestamo.id != null) prestamosPorId[prestamo.id!] = prestamo;
        }
      }

      final prestamos = prestamosPorId.values.toList()
        ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
      final cuotasPorPrestamo = <int, List<Cuota>>{};
      final pagosPorId = <int, Pago>{};

      for (final prestamo in prestamos) {
        final id = prestamo.id;
        if (id == null) continue;
        cuotasPorPrestamo[id] = await _databaseHelper.obtenerCuotasPorPrestamo(
          id,
        );
        for (final pago in await _databaseHelper.obtenerPagosPorPrestamo(id)) {
          if (pago.id != null) pagosPorId[pago.id!] = pago;
        }
      }

      final pagosHoy = await _databaseHelper.obtenerPagosDelDia(_reloj());
      for (final pago in pagosHoy) {
        if (pago.id != null) pagosPorId[pago.id!] = pago;
      }

      final resumen = await _databaseHelper.obtenerResumenDashboard();
      final clientesPorId = {
        for (final cliente in clientes)
          if (cliente.id != null) cliente.id!: cliente,
      };
      final moras = _construirMoras(
        prestamos: prestamos,
        clientesPorId: clientesPorId,
        cuotasPorPrestamo: cuotasPorPrestamo,
      );

      _clientes = clientes;
      _prestamos = prestamos;
      _cuotasPorPrestamo = cuotasPorPrestamo;
      _pagosHoy = pagosHoy;
      _pagos = pagosPorId.values.toList()
        ..sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      _resumenDashboard = resumen;
      _moras = moras;
    } on Object catch (error, stackTrace) {
      errorCarga = error.toString();
      debugPrint('GotaControl: error cargando SQLite: $error\n$stackTrace');
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> agregarCliente({
    required String nombre,
    required String telefono,
    String? cedula,
  }) async {
    if (nombre.trim().isEmpty || telefono.trim().isEmpty) {
      throw ArgumentError('Nombre y teléfono son obligatorios.');
    }
    await _databaseHelper.insertarCliente(
      Cliente(
        nombre: nombre.trim(),
        telefono: telefono.trim(),
        cedula: cedula?.trim().isEmpty ?? true ? null : cedula!.trim(),
        fechaRegistro: _reloj(),
      ),
    );
    await cargarDatos();
  }

  Future<void> eliminarCliente(int id) async {
    await _databaseHelper.eliminarCliente(id);
    await cargarDatos();
  }

  Future<Prestamo> crearPrestamo({
    required int clienteId,
    required double capital,
    required double porcentajeInteres,
    required int numCuotas,
    required String frecuencia,
    List<int>? diasPersonalizados,
  }) async {
    final cliente = clientePorId(clienteId);
    if (cliente == null || !cliente.activo) {
      throw StateError('Selecciona un cliente activo.');
    }
    final calculo = _calculadora.calcularPrestamo(
      capital: capital,
      porcentajeInteres: porcentajeInteres,
      numCuotas: numCuotas,
    );
    final fechaInicio = _soloFecha(_reloj());
    final fechas = _calculadora.generarFechasPago(
      fechaInicio: fechaInicio,
      numCuotas: numCuotas,
      frecuencia: frecuencia,
      diasPersonalizados: diasPersonalizados,
    );
    final prestamo = Prestamo(
      clienteId: clienteId,
      montoCapital: capital,
      porcentajeInteres: porcentajeInteres,
      montoInteres: calculo.montoInteres,
      montoTotalPagar: calculo.montoTotalPagar,
      numCuotas: numCuotas,
      valorCuota: calculo.valorCuota,
      frecuencia: frecuencia,
      diasPersonalizados: diasPersonalizados?.join(','),
      fechaInicio: fechaInicio,
      fechaFinEstimada: fechas.last,
      estado: 'ACTIVO',
      saldoPendiente: calculo.montoTotalPagar,
      totalPagado: 0,
      createdAt: _reloj(),
    );
    final cuotas = [
      for (var indice = 0; indice < fechas.length; indice++)
        Cuota(
          prestamoId: 0,
          numeroCuota: indice + 1,
          fechaVencimiento: fechas[indice],
          montoCuota: calculo.valorCuota,
        ),
    ];

    final prestamoId = await _databaseHelper.crearPrestamoConCuotas(
      prestamo,
      cuotas,
    );
    await cargarDatos();
    return _prestamoPorId(prestamoId) ?? prestamo.copyWith(id: prestamoId);
  }

  Future<Pago> registrarPago({
    required int prestamoId,
    required int cuotaId,
    required double monto,
    required String metodoPago,
    required DateTime fecha,
    String? nota,
  }) async {
    final prestamo = _prestamoPorId(prestamoId);
    if (prestamo == null || prestamo.id == null) {
      throw StateError('No se encontró el préstamo.');
    }
    final cliente = clientePorId(prestamo.clienteId);
    if (cliente == null || cliente.id == null) {
      throw StateError('No se encontró el cliente del préstamo.');
    }
    final pago = Pago(
      cuotaId: cuotaId,
      prestamoId: prestamoId,
      clienteId: cliente.id!,
      monto: monto,
      fechaHora: fecha,
      metodoPago: metodoPago,
      nota: nota,
      registradoPor: 'App',
    );
    final pagoId = await _databaseHelper.registrarPago(pago);
    await cargarDatos();
    return pago.copyWith(id: pagoId);
  }

  Cliente? clientePorId(int id) {
    for (final cliente in _clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  Prestamo? prestamoPorId(int id) => _prestamoPorId(id);

  List<Prestamo> prestamosDeCliente(int clienteId) => List.unmodifiable(
    _prestamos.where((prestamo) => prestamo.clienteId == clienteId),
  );

  List<Cuota> cuotasDePrestamo(int prestamoId) =>
      List.unmodifiable(_cuotasPorPrestamo[prestamoId] ?? const <Cuota>[]);

  List<Pago> pagosDePrestamo(int prestamoId) =>
      List.unmodifiable(_pagos.where((pago) => pago.prestamoId == prestamoId));

  Prestamo? _prestamoPorId(int id) {
    for (final prestamo in _prestamos) {
      if (prestamo.id == id) return prestamo;
    }
    return null;
  }

  List<PrestamoEnMora> _construirMoras({
    required List<Prestamo> prestamos,
    required Map<int, Cliente> clientesPorId,
    required Map<int, List<Cuota>> cuotasPorPrestamo,
  }) {
    final hoy = _soloFecha(_reloj());
    final moras = <PrestamoEnMora>[];
    for (final prestamo in prestamos) {
      if (prestamo.id == null ||
          (prestamo.estado != 'ACTIVO' && prestamo.estado != 'MORA')) {
        continue;
      }
      final cliente = clientesPorId[prestamo.clienteId];
      if (cliente == null) continue;
      final cuotasAtrasadas =
          (cuotasPorPrestamo[prestamo.id] ?? const <Cuota>[])
              .where(
                (cuota) =>
                    cuota.estado != 'PAGADA' &&
                    _soloFecha(cuota.fechaVencimiento).isBefore(hoy),
              )
              .toList();
      if (cuotasAtrasadas.isEmpty) continue;
      final diasAtraso = cuotasAtrasadas
          .map(
            (cuota) =>
                hoy.difference(_soloFecha(cuota.fechaVencimiento)).inDays,
          )
          .reduce((a, b) => a > b ? a : b);
      moras.add(
        PrestamoEnMora(
          prestamo: prestamo,
          cliente: cliente,
          cuotasAtrasadas: cuotasAtrasadas,
          diasAtraso: diasAtraso,
        ),
      );
    }
    moras.sort((a, b) => b.diasAtraso.compareTo(a.diasAtraso));
    return moras;
  }

  static DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  static bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static double _valorDouble(Object? valor) => (valor as num?)?.toDouble() ?? 0;
}
