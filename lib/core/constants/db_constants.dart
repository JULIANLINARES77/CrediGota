class DbConstants {
  DbConstants._();

  static const databaseName = 'gota_control.db';
  static const databaseVersion = 4;

  static const tableClientes = 'clientes';
  static const tablePrestamos = 'prestamos';
  static const tableCuotas = 'cuotas';
  static const tablePagos = 'pagos';
  static const tableConfiguracion = 'configuracion';

  static const columnId = 'id';

  static const clienteNombre = 'nombre';
  static const clienteCedula = 'cedula';
  static const clienteTelefono = 'telefono';
  static const clienteDireccion = 'direccion';
  static const clienteFotoPath = 'foto_path';
  static const clienteNotas = 'notas';
  static const clienteFechaRegistro = 'fecha_registro';
  static const clienteActivo = 'activo';

  static const prestamoClienteId = 'cliente_id';
  static const prestamoMontoCapital = 'monto_capital';
  static const prestamoPorcentajeInteres = 'porcentaje_interes';
  static const prestamoMontoInteres = 'monto_interes';
  static const prestamoMontoTotalPagar = 'monto_total_pagar';
  static const prestamoNumCuotas = 'num_cuotas';
  static const prestamoValorCuota = 'valor_cuota';
  static const prestamoFrecuencia = 'frecuencia';
  static const prestamoDiasPersonalizados = 'dias_personalizados';
  static const prestamoFechaInicio = 'fecha_inicio';
  static const prestamoFechaFinEstimada = 'fecha_fin_estimada';
  static const prestamoEstado = 'estado';
  static const prestamoSaldoPendiente = 'saldo_pendiente';
  static const prestamoTotalPagado = 'total_pagado';
  static const prestamoCreatedAt = 'created_at';

  static const cuotaPrestamoId = 'prestamo_id';
  static const cuotaNumero = 'numero_cuota';
  static const cuotaFechaVencimiento = 'fecha_vencimiento';
  static const cuotaMonto = 'monto_cuota';
  static const cuotaMontoPagado = 'monto_pagado';
  static const cuotaFechaPago = 'fecha_pago';
  static const cuotaEstado = 'estado';
  static const cuotaDiasAtraso = 'dias_atraso';
  static const cuotaEsPenalizacion = 'es_penalizacion';

  static const pagoCuotaId = 'cuota_id';
  static const pagoPrestamoId = 'prestamo_id';
  static const pagoClienteId = 'cliente_id';
  static const pagoMonto = 'monto';
  static const pagoFechaHora = 'fecha_hora';
  static const pagoMetodoPago = 'metodo_pago';
  static const pagoNota = 'nota';
  static const pagoRegistradoPor = 'registrado_por';

  static const configuracionNombreNegocio = 'nombre_negocio';
  static const configuracionTelefonoNegocio = 'telefono_negocio';
  static const configuracionMetaDiaria = 'meta_diaria';
  static const configuracionPorcentajeMora = 'porcentaje_mora';
  static const configuracionDiasGraciaMora = 'dias_gracia_mora';
  static const configuracionPinSeguridad = 'pin_seguridad';
  static const configuracionPinHash = 'pin_hash';
  static const configuracionPinIntentosFallidos = 'pin_intentos_fallidos';
  static const configuracionPinBloqueadoHasta = 'pin_bloqueado_hasta';
  static const configuracionMoneda = 'moneda';
  static const configuracionDireccionNegocio = 'direccion_negocio';
  static const configuracionAlertasMora = 'alertas_mora';
  static const configuracionRecordatorioDiario = 'recordatorio_diario';
  static const configuracionHoraRecordatorio = 'hora_recordatorio';
  static const configuracionFrecuenciaRespaldo = 'frecuencia_respaldo';
  static const configuracionUltimoRespaldo = 'ultimo_respaldo';

  static const indexPrestamosCliente = 'idx_prestamos_cliente';
  static const indexCuotasPrestamoFecha = 'idx_cuotas_prestamo_fecha';
  static const indexCuotasFechaEstado = 'idx_cuotas_fecha_estado';
  static const indexPagosFecha = 'idx_pagos_fecha';
  static const indexPagosPrestamo = 'idx_pagos_prestamo';
}
