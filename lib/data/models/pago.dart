import '../../core/constants/db_constants.dart';

class Pago {
  const Pago({
    this.id,
    required this.cuotaId,
    required this.prestamoId,
    required this.clienteId,
    required this.monto,
    required this.fechaHora,
    this.metodoPago,
    this.nota,
    this.registradoPor,
  });

  final int? id;
  final int cuotaId;
  final int prestamoId;
  final int clienteId;
  final double monto;
  final DateTime fechaHora;
  final String? metodoPago;
  final String? nota;
  final String? registradoPor;

  Map<String, Object?> toMap() => {
    DbConstants.columnId: id,
    DbConstants.pagoCuotaId: cuotaId,
    DbConstants.pagoPrestamoId: prestamoId,
    DbConstants.pagoClienteId: clienteId,
    DbConstants.pagoMonto: monto,
    DbConstants.pagoFechaHora: fechaHora.toIso8601String(),
    DbConstants.pagoMetodoPago: metodoPago,
    DbConstants.pagoNota: nota,
    DbConstants.pagoRegistradoPor: registradoPor,
  };

  factory Pago.fromMap(Map<String, Object?> map) => Pago(
    id: (map[DbConstants.columnId] as num?)?.toInt(),
    cuotaId: (map[DbConstants.pagoCuotaId] as num).toInt(),
    prestamoId: (map[DbConstants.pagoPrestamoId] as num).toInt(),
    clienteId: (map[DbConstants.pagoClienteId] as num).toInt(),
    monto: (map[DbConstants.pagoMonto] as num).toDouble(),
    fechaHora: DateTime.parse(map[DbConstants.pagoFechaHora] as String),
    metodoPago: map[DbConstants.pagoMetodoPago] as String?,
    nota: map[DbConstants.pagoNota] as String?,
    registradoPor: map[DbConstants.pagoRegistradoPor] as String?,
  );

  Pago copyWith({
    int? id,
    int? cuotaId,
    int? prestamoId,
    int? clienteId,
    double? monto,
    DateTime? fechaHora,
    String? metodoPago,
    String? nota,
    String? registradoPor,
  }) => Pago(
    id: id ?? this.id,
    cuotaId: cuotaId ?? this.cuotaId,
    prestamoId: prestamoId ?? this.prestamoId,
    clienteId: clienteId ?? this.clienteId,
    monto: monto ?? this.monto,
    fechaHora: fechaHora ?? this.fechaHora,
    metodoPago: metodoPago ?? this.metodoPago,
    nota: nota ?? this.nota,
    registradoPor: registradoPor ?? this.registradoPor,
  );
}
