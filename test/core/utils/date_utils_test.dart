import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/core/utils/date_utils.dart';

void main() {
  test('formatea fecha, fecha y hora y moneda', () {
    final fecha = DateTime(2024, 9, 26, 14, 30);

    expect(GotaDateUtils.formatearFecha(fecha), '26/09/2024');
    expect(GotaDateUtils.formatearFechaHora(fecha), '26/09/2024 14:30');
    expect(GotaDateUtils.formatearMoneda(1200000), '\$1,200,000');
  });

  test('nombre del día, fin de semana y diferencia ignoran horas', () {
    expect(GotaDateUtils.obtenerNombreDia(DateTime.monday), 'Lunes');
    expect(GotaDateUtils.esFinDeSemana(DateTime(2024, 9, 28)), isTrue);
    expect(GotaDateUtils.esFinDeSemana(DateTime(2024, 9, 27)), isFalse);
    expect(
      GotaDateUtils.diasEntreFechas(
        DateTime(2024, 9, 26, 23),
        DateTime(2024, 9, 27, 1),
      ),
      1,
    );
  });
}
