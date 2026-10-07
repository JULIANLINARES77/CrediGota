import 'dart:convert';
import 'dart:typed_data';

import '../providers/gota_provider.dart';

class DatabaseExportService {
  DatabaseExportService._();

  static Map<String, Uint8List> exportarCsv(GotaProvider provider) => {
    'clientes.csv': _csv([
      ['id', 'nombre', 'cedula', 'telefono', 'direccion', 'notas', 'fecha_registro', 'activo'],
      for (final cliente in provider.clientesRegistrados)
        [
          '${cliente.id ?? ''}',
          cliente.nombre,
          cliente.cedula ?? '',
          cliente.telefono,
          cliente.direccion ?? '',
          cliente.notas ?? '',
          cliente.fechaRegistro.toIso8601String(),
          cliente.activo ? 'Sí' : 'No',
        ],
    ]),
    'prestamos.csv': _csv([
      ['id', 'cliente_id', 'capital', 'porcentaje_interes', 'interes', 'total', 'cuotas', 'frecuencia', 'fecha_inicio', 'fecha_fin_estimada', 'estado', 'saldo_pendiente', 'total_pagado'],
      for (final prestamo in provider.prestamos)
        [
          '${prestamo.id ?? ''}',
          '${prestamo.clienteId}',
          _numero(prestamo.montoCapital),
          _numero(prestamo.porcentajeInteres),
          _numero(prestamo.montoInteres),
          _numero(prestamo.montoTotalPagar),
          '${prestamo.numCuotas}',
          prestamo.frecuencia,
          prestamo.fechaInicio.toIso8601String(),
          prestamo.fechaFinEstimada.toIso8601String(),
          prestamo.estado,
          _numero(prestamo.saldoPendiente),
          _numero(prestamo.totalPagado),
        ],
    ]),
    'cuotas.csv': _csv([
      ['id', 'prestamo_id', 'numero', 'fecha_vencimiento', 'monto', 'monto_pagado', 'fecha_pago', 'estado', 'dias_atraso', 'es_penalizacion'],
      for (final cuota in provider.todasLasCuotas)
        [
          '${cuota.id ?? ''}',
          '${cuota.prestamoId}',
          '${cuota.numeroCuota}',
          cuota.fechaVencimiento.toIso8601String(),
          _numero(cuota.montoCuota),
          _numero(cuota.montoPagado),
          cuota.fechaPago?.toIso8601String() ?? '',
          cuota.estado,
          '${cuota.diasAtraso}',
          cuota.esPenalizacion ? 'Sí' : 'No',
        ],
    ]),
    'pagos.csv': _csv([
      ['id', 'cliente_id', 'prestamo_id', 'cuota_id', 'monto', 'fecha_hora', 'metodo_pago', 'nota', 'registrado_por'],
      for (final pago in provider.pagos)
        [
          '${pago.id ?? ''}',
          '${pago.clienteId}',
          '${pago.prestamoId}',
          '${pago.cuotaId}',
          _numero(pago.monto),
          pago.fechaHora.toIso8601String(),
          pago.metodoPago ?? '',
          pago.nota ?? '',
          pago.registradoPor ?? '',
        ],
    ]),
  };

  static Uint8List _csv(List<List<String>> rows) {
    final text = rows
        .map(
          (row) => row.map(_escapeCell).join(','),
        )
        .join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$text\r\n'));
  }

  static String _escapeCell(String value) {
    final safeValue = RegExp(r'^\s*[=+\-@]').hasMatch(value)
        ? "'$value"
        : value;
    return '"${safeValue.replaceAll('"', '""')}"';
  }

  static String _numero(num value) => value.toString();
}
