import 'package:flutter/foundation.dart';

import '../../data/models/cliente.dart';
import '../../data/models/cuota.dart';
import '../../data/models/pago.dart';
import '../../data/models/prestamo.dart';
import '../services/calculadora_service.dart';

class DemoProvider extends ChangeNotifier {
  DemoProvider({DateTime? fechaDemo})
    : _hoy = _soloFecha(fechaDemo ?? DateTime.now()) {
    _cargarDatosDemo();
  }

  final DateTime _hoy;
  final CalculadoraService _calculadora = const CalculadoraService();
  final List<Cliente> _clientes = [];
  final List<Prestamo> _prestamos = [];
  final Map<int, List<Cuota>> _cuotasPorPrestamo = {};
  final List<Pago> _pagos = [];
  int _siguienteClienteId = 4;
  int _siguientePrestamoId = 4;
  int _siguienteCuotaId = 40;
  int _siguientePagoId = 10;

  DateTime get hoy => _hoy;
  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Prestamo> get prestamos => List.unmodifiable(_prestamos);
  List<Pago> get pagos => List.unmodifiable(_pagos);

  List<Prestamo> get prestamosActivos => _prestamos
      .where(
        (prestamo) => prestamo.estado == 'ACTIVO' || prestamo.estado == 'MORA',
      )
      .toList(growable: false);

  double get totalEnCalle => prestamosActivos.fold(
    0,
    (total, prestamo) => total + prestamo.saldoPendiente,
  );

  double get recaudadoHoy => _pagos
      .where((pago) => _mismaFecha(pago.fechaHora, _hoy))
      .fold(0, (total, pago) => total + pago.monto);

  double get gananciaHoy => _pagos
      .where((pago) => _mismaFecha(pago.fechaHora, _hoy))
      .fold(0.0, (total, pago) {
        final prestamo = _prestamoPorId(pago.prestamoId);
        final cuota = _cuotaPorId(pago.prestamoId, pago.cuotaId);
        if (prestamo == null || (cuota?.esPenalizacion ?? false)) return total;
        return total +
            _calculadora.calcularGananciaProporcional(
              montoPagado: pago.monto,
              totalPagar: prestamo.montoTotalPagar,
              interesTotal: prestamo.montoInteres,
            );
      });

  int get clientesActivos =>
      _clientes.where((cliente) => cliente.activo).length;
  int get clientesEnMora => _prestamos
      .where((prestamo) => prestamo.estado == 'MORA')
      .map((prestamo) => prestamo.clienteId)
      .toSet()
      .length;

  List<Cuota> get cuotasDeHoy => _cuotasPorPrestamo.values
      .expand((cuotas) => cuotas)
      .where(
        (cuota) =>
            _mismaFecha(cuota.fechaVencimiento, _hoy) &&
            cuota.estado != 'PAGADA',
      )
      .toList(growable: false);

  List<Cuota> get todasLasCuotas => _cuotasPorPrestamo.values
      .expand((cuotas) => cuotas)
      .toList(growable: false);

  List<PrestamoEnMoraDemo> get moras {
    final resultado = <PrestamoEnMoraDemo>[];
    for (final prestamo in prestamosActivos) {
      final cliente = clientePorId(prestamo.clienteId);
      if (cliente == null) continue;
      final cuotas = cuotasDePrestamo(prestamo.id!)
          .where(
            (cuota) =>
                cuota.estado != 'PAGADA' &&
                _soloFecha(cuota.fechaVencimiento).isBefore(_hoy),
          )
          .toList();
      if (cuotas.isEmpty) continue;
      final dias = cuotas
          .map(
            (cuota) =>
                _hoy.difference(_soloFecha(cuota.fechaVencimiento)).inDays,
          )
          .reduce((a, b) => a > b ? a : b);
      resultado.add(
        PrestamoEnMoraDemo(
          prestamo: prestamo,
          cliente: cliente,
          cuotas: cuotas,
          diasAtraso: dias,
        ),
      );
    }
    resultado.sort((a, b) => b.diasAtraso.compareTo(a.diasAtraso));
    return resultado;
  }

  Cliente? clientePorId(int id) {
    for (final cliente in _clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  Prestamo? prestamoPorId(int id) => _prestamoPorId(id);

  List<Prestamo> prestamosDeCliente(int clienteId) => _prestamos
      .where((prestamo) => prestamo.clienteId == clienteId)
      .toList(growable: false);

  List<Cuota> cuotasDePrestamo(int prestamoId) =>
      List.unmodifiable(_cuotasPorPrestamo[prestamoId] ?? const []);

  List<Pago> pagosDePrestamo(int prestamoId) => _pagos
      .where((pago) => pago.prestamoId == prestamoId)
      .toList(growable: false);

  void agregarCliente({
    required String nombre,
    required String telefono,
    String? cedula,
  }) {
    _clientes.add(
      Cliente(
        id: _siguienteClienteId++,
        nombre: nombre.trim(),
        telefono: telefono.trim(),
        cedula: cedula?.trim(),
        fechaRegistro: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void desactivarCliente(int clienteId) {
    final indice = _clientes.indexWhere((cliente) => cliente.id == clienteId);
    if (indice < 0) return;
    _clientes[indice] = _clientes[indice].copyWith(activo: false);
    notifyListeners();
  }

  Prestamo crearPrestamo({
    required int clienteId,
    required double capital,
    required double porcentajeInteres,
    required int numCuotas,
    required String frecuencia,
    List<int>? diasPersonalizados,
  }) {
    final calculo = _calculadora.calcularPrestamo(
      capital: capital,
      porcentajeInteres: porcentajeInteres,
      numCuotas: numCuotas,
    );
    final fechas = _calculadora.generarFechasPago(
      fechaInicio: _hoy,
      numCuotas: numCuotas,
      frecuencia: frecuencia,
      diasPersonalizados: diasPersonalizados,
    );
    final id = _siguientePrestamoId++;
    final prestamo = Prestamo(
      id: id,
      clienteId: clienteId,
      montoCapital: capital,
      porcentajeInteres: porcentajeInteres,
      montoInteres: calculo.montoInteres,
      montoTotalPagar: calculo.montoTotalPagar,
      numCuotas: numCuotas,
      valorCuota: calculo.valorCuota,
      frecuencia: frecuencia,
      diasPersonalizados: diasPersonalizados?.join(','),
      fechaInicio: _hoy,
      fechaFinEstimada: fechas.last,
      saldoPendiente: calculo.montoTotalPagar,
      createdAt: DateTime.now(),
    );
    _prestamos.add(prestamo);
    _cuotasPorPrestamo[id] = [
      for (var indice = 0; indice < fechas.length; indice++)
        Cuota(
          id: _siguienteCuotaId++,
          prestamoId: id,
          numeroCuota: indice + 1,
          fechaVencimiento: fechas[indice],
          montoCuota: calculo.valorCuota,
        ),
    ];
    notifyListeners();
    return prestamo;
  }

  Pago registrarPago({
    required int prestamoId,
    required int cuotaId,
    required double monto,
    required String metodoPago,
    required DateTime fecha,
    String? nota,
  }) {
    if (!monto.isFinite || monto <= 0) {
      throw ArgumentError.value(monto, 'monto', 'Debe ser mayor que cero.');
    }
    final prestamo = _prestamoPorId(prestamoId);
    final cuota = _cuotaPorId(prestamoId, cuotaId);
    if (prestamo == null || cuota == null) {
      throw StateError('No se encontró el préstamo o la cuota.');
    }
    final saldoCuota = cuota.montoCuota - cuota.montoPagado;
    if (monto > saldoCuota + 0.000001 ||
        monto > prestamo.saldoPendiente + 0.000001) {
      throw ArgumentError('El pago supera el saldo pendiente.');
    }

    final pago = Pago(
      id: _siguientePagoId++,
      cuotaId: cuotaId,
      prestamoId: prestamoId,
      clienteId: prestamo.clienteId,
      monto: monto,
      fechaHora: fecha,
      metodoPago: metodoPago,
      nota: nota,
      registradoPor: 'Demo',
    );
    _pagos.add(pago);
    final nuevoMontoPagado = cuota.montoPagado + monto;
    final cuotaPagada = nuevoMontoPagado >= cuota.montoCuota - 0.000001;
    final cuotas = _cuotasPorPrestamo[prestamoId]!;
    final indice = cuotas.indexWhere((item) => item.id == cuotaId);
    cuotas[indice] = cuota.copyWith(
      montoPagado: cuotaPagada ? cuota.montoCuota : nuevoMontoPagado,
      estado: cuotaPagada ? 'PAGADA' : 'PARCIAL',
      fechaPago: cuotaPagada ? fecha : null,
    );
    final saldo = (prestamo.saldoPendiente - monto).clamp(0.0, double.infinity);
    final saldoRedondeado = double.parse(saldo.toStringAsFixed(2));
    final hayAtraso = cuotas.any(
      (item) =>
          item.estado != 'PAGADA' &&
          _soloFecha(item.fechaVencimiento).isBefore(_soloFecha(fecha)),
    );
    final nuevoEstado = saldoRedondeado <= 0
        ? 'PAGADO'
        : hayAtraso
        ? 'MORA'
        : 'ACTIVO';
    final prestamoIndice = _prestamos.indexWhere(
      (item) => item.id == prestamoId,
    );
    _prestamos[prestamoIndice] = prestamo.copyWith(
      saldoPendiente: saldoRedondeado,
      totalPagado: prestamo.totalPagado + monto,
      estado: nuevoEstado,
    );
    notifyListeners();
    return pago;
  }

  void _cargarDatosDemo() {
    _clientes.addAll([
      Cliente(
        id: 1,
        nombre: 'María Fernanda Rojas',
        telefono: '300 456 7890',
        cedula: '52123456',
        fechaRegistro: _hoy.subtract(const Duration(days: 90)),
      ),
      Cliente(
        id: 2,
        nombre: 'Carlos Andrés Mejía',
        telefono: '310 555 0182',
        cedula: '80123456',
        fechaRegistro: _hoy.subtract(const Duration(days: 60)),
      ),
      Cliente(
        id: 3,
        nombre: 'Diana Marcela Torres',
        telefono: '315 987 1234',
        cedula: '43123456',
        fechaRegistro: _hoy.subtract(const Duration(days: 30)),
      ),
    ]);
    final definiciones = [
      (1, 1, 1000000.0, 20.0, 24, 'LUN_MIE_VIE', 950000.0, 250000.0, 'ACTIVO'),
      (2, 2, 600000.0, 15.0, 18, 'DIARIA', 690000.0, 0.0, 'MORA'),
      (3, 3, 400000.0, 20.0, 12, 'SEMANAL', 480000.0, 0.0, 'ACTIVO'),
    ];
    var cuotaId = 1;
    for (final definicion in definiciones) {
      final (
        id,
        clienteId,
        capital,
        interes,
        cantidad,
        frecuencia,
        saldo,
        pagado,
        estado,
      ) = definicion;
      final calculo = _calculadora.calcularPrestamo(
        capital: capital,
        porcentajeInteres: interes,
        numCuotas: cantidad,
      );
      final inicio = _hoy.subtract(const Duration(days: 6));
      final fechas = _calculadora.generarFechasPago(
        fechaInicio: inicio,
        numCuotas: cantidad,
        frecuencia: frecuencia,
      );
      final cuotas = <Cuota>[];
      for (var indice = 0; indice < cantidad; indice++) {
        final vencimiento = id == 1 && indice == 5
            ? _hoy
            : id == 2 && indice == 2
            ? _hoy.subtract(const Duration(days: 5))
            : fechas[indice];
        final estaPagada = id == 1 && indice < 5;
        cuotas.add(
          Cuota(
            id: cuotaId++,
            prestamoId: id,
            numeroCuota: indice + 1,
            fechaVencimiento: vencimiento,
            montoCuota: calculo.valorCuota,
            montoPagado: estaPagada ? calculo.valorCuota : 0,
            fechaPago: estaPagada ? vencimiento : null,
            estado: estaPagada ? 'PAGADA' : 'PENDIENTE',
          ),
        );
      }
      _prestamos.add(
        Prestamo(
          id: id,
          clienteId: clienteId,
          montoCapital: capital,
          porcentajeInteres: interes,
          montoInteres: calculo.montoInteres,
          montoTotalPagar: calculo.montoTotalPagar,
          numCuotas: cantidad,
          valorCuota: calculo.valorCuota,
          frecuencia: frecuencia,
          fechaInicio: inicio,
          fechaFinEstimada: fechas.last,
          estado: estado,
          saldoPendiente: saldo,
          totalPagado: pagado,
          createdAt: inicio,
        ),
      );
      _cuotasPorPrestamo[id] = cuotas;
    }
    _siguienteCuotaId = cuotaId;
    _pagos.addAll([
      Pago(
        id: 1,
        cuotaId: 1,
        prestamoId: 1,
        clienteId: 1,
        monto: 50000,
        fechaHora: _hoy.add(const Duration(hours: 9, minutes: 15)),
        metodoPago: 'NEQUI',
        registradoPor: 'Demo',
      ),
      Pago(
        id: 2,
        cuotaId: 2,
        prestamoId: 1,
        clienteId: 1,
        monto: 50000,
        fechaHora: _hoy.add(const Duration(hours: 11, minutes: 5)),
        metodoPago: 'EFECTIVO',
        registradoPor: 'Demo',
      ),
    ]);
  }

  Prestamo? _prestamoPorId(int id) {
    for (final prestamo in _prestamos) {
      if (prestamo.id == id) return prestamo;
    }
    return null;
  }

  Cuota? _cuotaPorId(int prestamoId, int cuotaId) {
    for (final cuota in _cuotasPorPrestamo[prestamoId] ?? const <Cuota>[]) {
      if (cuota.id == cuotaId) return cuota;
    }
    return null;
  }

  static DateTime _soloFecha(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);
  static bool _mismaFecha(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class PrestamoEnMoraDemo {
  const PrestamoEnMoraDemo({
    required this.prestamo,
    required this.cliente,
    required this.cuotas,
    required this.diasAtraso,
  });

  final Prestamo prestamo;
  final Cliente cliente;
  final List<Cuota> cuotas;
  final int diasAtraso;
}
