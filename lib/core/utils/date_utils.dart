import 'package:intl/intl.dart';

class GotaDateUtils {
  GotaDateUtils._();

  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _currencyFormat = NumberFormat('#,##0.##', 'en_US');

  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static String formatearFecha(DateTime fecha) => _dateFormat.format(fecha);

  static String formatearFechaHora(DateTime fecha) =>
      _dateTimeFormat.format(fecha);

  static String formatearMoneda(double valor) =>
      '\$${_currencyFormat.format(valor)}';

  static String obtenerNombreDia(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'Debe estar entre 1 y 7.');
    }
    return _weekdays[weekday - 1];
  }

  static bool esFinDeSemana(DateTime fecha) =>
      fecha.weekday == DateTime.saturday || fecha.weekday == DateTime.sunday;

  static int diasEntreFechas(DateTime inicio, DateTime fin) {
    final inicioDia = DateTime(inicio.year, inicio.month, inicio.day);
    final finDia = DateTime(fin.year, fin.month, fin.day);
    return finDia.difference(inicioDia).inDays;
  }
}
