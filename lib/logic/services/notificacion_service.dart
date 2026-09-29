import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificacionService {
  NotificacionService._();

  static final NotificacionService instance = NotificacionService._();
  static const _canalId = 'gota_control_recordatorios';
  static const _notificacionDiariaId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  Future<void> inicializarNotificaciones() async {
    if (_inicializado) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Bogota'));

    const ajustes = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    final resultado = await _plugin.initialize(settings: ajustes);
    _inicializado = resultado ?? false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _canalId,
          'Recordatorios de GotaControl',
          description: 'Vencimientos y resumen diario de cobros.',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
    }
    debugPrint('GotaControl: notificaciones inicializadas=$_inicializado');
  }

  Future<void> programarNotificacionDiaria({
    required TimeOfDay hora,
    required String mensaje,
  }) async {
    await _asegurarInicializacion();
    final ahora = tz.TZDateTime.now(tz.local);
    var siguiente = tz.TZDateTime(
      tz.local,
      ahora.year,
      ahora.month,
      ahora.day,
      hora.hour,
      hora.minute,
    );
    if (!siguiente.isAfter(ahora)) {
      siguiente = siguiente.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _notificacionDiariaId,
      title: 'Resumen diario',
      body: mensaje,
      scheduledDate: siguiente,
      notificationDetails: _detalles,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> programarAlertaVencimiento({
    required int cuotaId,
    required DateTime fechaVencimiento,
    required String nombreCliente,
    required double monto,
  }) async {
    await _asegurarInicializacion();
    final fecha = _fechaALasOcho(fechaVencimiento);
    if (!fecha.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _programarCuota(
      id: _idCuota(cuotaId, 0),
      fecha: fecha,
      titulo: 'Cuota por vencer',
      mensaje: '$nombreCliente debe pagar ${_formatearPesos(monto)} hoy.',
      payload: 'cuota:$cuotaId',
    );
  }

  Future<void> programarAlertaMora({
    required int cuotaId,
    required DateTime fechaVencimiento,
    required String nombreCliente,
  }) async {
    await _asegurarInicializacion();
    final fechaMora = _fechaALasOcho(
      fechaVencimiento.add(const Duration(days: 3)),
    );
    if (!fechaMora.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _programarCuota(
      id: _idCuota(cuotaId, 1),
      fecha: fechaMora,
      titulo: 'Cuota en mora',
      mensaje: '$nombreCliente tiene una cuota vencida hace 3 días.',
      payload: 'mora:$cuotaId',
    );
  }

  Future<void> cancelarNotificacion(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }

  Future<void> _asegurarInicializacion() async {
    if (!_inicializado) await inicializarNotificaciones();
  }

  Future<void> _programarCuota({
    required int id,
    required tz.TZDateTime fecha,
    required String titulo,
    required String mensaje,
    required String payload,
  }) => _plugin.zonedSchedule(
    id: id,
    title: titulo,
    body: mensaje,
    scheduledDate: fecha,
    notificationDetails: _detalles,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  NotificationDetails get _detalles => const NotificationDetails(
    android: AndroidNotificationDetails(
      _canalId,
      'Recordatorios de GotaControl',
      channelDescription: 'Vencimientos y resumen diario de cobros.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  tz.TZDateTime _fechaALasOcho(DateTime fecha) =>
      tz.TZDateTime(tz.local, fecha.year, fecha.month, fecha.day, 8);

  int _idCuota(int cuotaId, int tipo) => cuotaId * 2 + 10 + tipo;

  String _formatearPesos(double monto) => '\$${monto.toStringAsFixed(0)}';
}
