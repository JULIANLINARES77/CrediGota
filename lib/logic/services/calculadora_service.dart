class ResultadoCalculoPrestamo {
  const ResultadoCalculoPrestamo({
    required this.montoInteres,
    required this.montoTotalPagar,
    required this.valorCuota,
    required this.gananciaDiariaPromedio,
  });

  final double montoInteres;
  final double montoTotalPagar;
  final double valorCuota;
  final double gananciaDiariaPromedio;
}

class CalculadoraService {
  const CalculadoraService();

  static const frecuenciaDiaria = 'DIARIA';
  static const frecuenciaSemanal = 'SEMANAL';
  static const frecuenciaQuincenal = 'QUINCENAL';
  static const frecuenciaLunesMiercolesViernes = 'LUN_MIE_VIE';
  static const frecuenciaPersonalizada = 'PERSONALIZADA';

  ResultadoCalculoPrestamo calcularPrestamo({
    required double capital,
    required double porcentajeInteres,
    required int numCuotas,
  }) {
    if (!capital.isFinite || capital <= 0) {
      throw ArgumentError.value(capital, 'capital', 'Debe ser mayor que cero.');
    }
    if (!porcentajeInteres.isFinite || porcentajeInteres < 0) {
      throw ArgumentError.value(
        porcentajeInteres,
        'porcentajeInteres',
        'Debe ser mayor o igual que cero.',
      );
    }
    if (numCuotas <= 0) {
      throw ArgumentError.value(
        numCuotas,
        'numCuotas',
        'Debe ser mayor que cero.',
      );
    }

    final montoInteres = _redondearDosDecimales(
      capital * (porcentajeInteres / 100),
    );
    final montoTotalPagar = _redondearDosDecimales(capital + montoInteres);
    final valorCuota = _redondearDosDecimales(montoTotalPagar / numCuotas);
    final gananciaDiariaPromedio = _redondearDosDecimales(
      montoInteres / numCuotas,
    );

    if (!montoInteres.isFinite || !montoTotalPagar.isFinite) {
      throw ArgumentError('El resultado del cálculo excede el rango válido.');
    }

    return ResultadoCalculoPrestamo(
      montoInteres: montoInteres,
      montoTotalPagar: montoTotalPagar,
      valorCuota: valorCuota,
      gananciaDiariaPromedio: gananciaDiariaPromedio,
    );
  }

  DateTime calcularFechaFin({
    required DateTime fechaInicio,
    required int numCuotas,
    required String frecuencia,
    List<int>? diasPersonalizados,
    bool saltarDomingos = false,
  }) => generarFechasPago(
    fechaInicio: fechaInicio,
    numCuotas: numCuotas,
    frecuencia: frecuencia,
    diasPersonalizados: diasPersonalizados,
    saltarDomingos: saltarDomingos,
  ).last;

  double calcularGananciaProporcional({
    required double montoPagado,
    required double totalPagar,
    required double interesTotal,
  }) => _calcularProporcional(
    montoPagado: montoPagado,
    totalPagar: totalPagar,
    baseTotal: interesTotal,
    nombreBase: 'interesTotal',
  );

  double calcularCapitalRecuperado({
    required double montoPagado,
    required double totalPagar,
    required double capital,
  }) => _calcularProporcional(
    montoPagado: montoPagado,
    totalPagar: totalPagar,
    baseTotal: capital,
    nombreBase: 'capital',
  );

  List<DateTime> generarFechasPago({
    required DateTime fechaInicio,
    required int numCuotas,
    required String frecuencia,
    List<int>? diasPersonalizados,
    bool saltarDomingos = false,
  }) {
    if (numCuotas <= 0) {
      throw ArgumentError.value(
        numCuotas,
        'numCuotas',
        'Debe ser mayor que cero.',
      );
    }

    final frecuenciaNormalizada = frecuencia.trim().toUpperCase();
    final diasPermitidos = switch (frecuenciaNormalizada) {
      frecuenciaLunesMiercolesViernes => const [
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ],
      frecuenciaPersonalizada => _validarDiasPersonalizados(diasPersonalizados),
      _ => null,
    };

    if (frecuenciaNormalizada != frecuenciaDiaria &&
        frecuenciaNormalizada != frecuenciaSemanal &&
        frecuenciaNormalizada != frecuenciaQuincenal &&
        diasPermitidos == null) {
      throw ArgumentError.value(
        frecuencia,
        'frecuencia',
        'Frecuencia no válida.',
      );
    }

    final fechas = <DateTime>[];
    var fechaActual = fechaInicio;

    switch (frecuenciaNormalizada) {
      case frecuenciaDiaria:
        while (fechas.length < numCuotas) {
          fechaActual = _sumarDiasCalendario(fechaActual, 1);
          if (saltarDomingos && fechaActual.weekday == DateTime.sunday) {
            continue;
          }
          fechas.add(fechaActual);
        }
      case frecuenciaSemanal:
        for (var i = 0; i < numCuotas; i++) {
          fechaActual = _sumarDiasCalendario(fechaActual, 7);
          fechas.add(fechaActual);
        }
      case frecuenciaQuincenal:
        for (var i = 0; i < numCuotas; i++) {
          fechaActual = _sumarDiasCalendario(fechaActual, 15);
          fechas.add(fechaActual);
        }
      case frecuenciaLunesMiercolesViernes:
      case frecuenciaPersonalizada:
        for (var i = 0; i < numCuotas; i++) {
          fechaActual = _siguienteDiaHabil(fechaActual, diasPermitidos!);
          fechas.add(fechaActual);
        }
    }

    return fechas;
  }

  List<int> _validarDiasPersonalizados(List<int>? dias) {
    if (dias == null || dias.isEmpty) {
      throw ArgumentError.value(
        dias,
        'diasPersonalizados',
        'Debe incluir al menos un día de la semana.',
      );
    }
    if (dias.any((dia) => dia < DateTime.monday || dia > DateTime.sunday)) {
      throw ArgumentError.value(
        dias,
        'diasPersonalizados',
        'Los días deben estar entre 1 (lunes) y 7 (domingo).',
      );
    }
    return dias.toSet().toList()..sort();
  }

  DateTime _siguienteDiaHabil(DateTime fecha, List<int> diasPermitidos) {
    var siguiente = _sumarDiasCalendario(fecha, 1);
    while (!diasPermitidos.contains(siguiente.weekday)) {
      siguiente = _sumarDiasCalendario(siguiente, 1);
    }
    return siguiente;
  }

  DateTime _sumarDiasCalendario(DateTime fecha, int dias) {
    if (fecha.isUtc) {
      return DateTime.utc(
        fecha.year,
        fecha.month,
        fecha.day + dias,
        fecha.hour,
        fecha.minute,
        fecha.second,
        fecha.millisecond,
        fecha.microsecond,
      );
    }
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day + dias,
      fecha.hour,
      fecha.minute,
      fecha.second,
      fecha.millisecond,
      fecha.microsecond,
    );
  }

  double _redondearDosDecimales(double valor) =>
      (valor * 100).roundToDouble() / 100;

  double _calcularProporcional({
    required double montoPagado,
    required double totalPagar,
    required double baseTotal,
    required String nombreBase,
  }) {
    if (!montoPagado.isFinite || montoPagado < 0) {
      throw ArgumentError.value(
        montoPagado,
        'montoPagado',
        'Debe ser un valor finito no negativo.',
      );
    }
    if (!totalPagar.isFinite || totalPagar <= 0) {
      throw ArgumentError.value(
        totalPagar,
        'totalPagar',
        'Debe ser mayor que cero.',
      );
    }
    if (!baseTotal.isFinite || baseTotal < 0) {
      throw ArgumentError.value(
        baseTotal,
        nombreBase,
        'Debe ser un valor finito no negativo.',
      );
    }
    return _redondearDosDecimales(montoPagado / totalPagar * baseTotal);
  }
}
