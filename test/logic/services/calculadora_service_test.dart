import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/logic/services/calculadora_service.dart';

void main() {
  const calculadora = CalculadoraService();

  group('calcularPrestamo', () {
    test('calcula interés simple y redondea cada resultado a centavos', () {
      final resultado = calculadora.calcularPrestamo(
        capital: 1000000,
        porcentajeInteres: 20,
        numCuotas: 24,
      );

      expect(resultado.montoInteres, 200000);
      expect(resultado.montoTotalPagar, 1200000);
      expect(resultado.valorCuota, 50000);
      expect(resultado.gananciaDiariaPromedio, 8333.33);
    });

    test('rechaza valores fuera de rango', () {
      expect(
        () => calculadora.calcularPrestamo(
          capital: 0,
          porcentajeInteres: 20,
          numCuotas: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculadora.calcularPrestamo(
          capital: 9999,
          porcentajeInteres: 20,
          numCuotas: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculadora.calcularPrestamo(
          capital: 100000001,
          porcentajeInteres: 20,
          numCuotas: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculadora.calcularPrestamo(
          capital: 10000,
          porcentajeInteres: -1,
          numCuotas: 4,
        ),
        throwsArgumentError,
      );
      expect(
        calculadora
            .calcularPrestamo(
              capital: 10000,
              porcentajeInteres: 0,
              numCuotas: 1,
            )
            .valorCuota,
        10000,
      );
      expect(
        calculadora
            .calcularPrestamo(
              capital: 100000000,
              porcentajeInteres: 100,
              numCuotas: 365,
            )
            .montoTotalPagar,
        200000000,
      );
      expect(
        () => calculadora.calcularPrestamo(
          capital: 10000,
          porcentajeInteres: 101,
          numCuotas: 4,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculadora.calcularPrestamo(
          capital: 10000,
          porcentajeInteres: 20,
          numCuotas: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculadora.calcularPrestamo(
          capital: 10000,
          porcentajeInteres: 20,
          numCuotas: 366,
        ),
        throwsArgumentError,
      );
    });

    test('prorratea interés y capital sobre un pago parcial', () {
      expect(
        calculadora.calcularGananciaProporcional(
          montoPagado: 50000,
          totalPagar: 1200000,
          interesTotal: 200000,
        ),
        8333.33,
      );
      expect(
        calculadora.calcularCapitalRecuperado(
          montoPagado: 50000,
          totalPagar: 1200000,
          capital: 1000000,
        ),
        41666.67,
      );
    });
  });

  group('generarFechasPago', () {
    final lunes = DateTime(2026, 9, 28);

    test('genera fechas lunes, miércoles y viernes', () {
      final fechas = calculadora.generarFechasPago(
        fechaInicio: lunes,
        numCuotas: 4,
        frecuencia: CalculadoraService.frecuenciaLunesMiercolesViernes,
      );

      expect(fechas, [
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 5),
        DateTime(2026, 10, 7),
      ]);
    });

    test('respeta días personalizados y elimina duplicados', () {
      final fechas = calculadora.generarFechasPago(
        fechaInicio: lunes,
        numCuotas: 3,
        frecuencia: CalculadoraService.frecuenciaPersonalizada,
        diasPersonalizados: [2, 5, 2],
      );

      expect(fechas, [
        DateTime(2026, 9, 29),
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 6),
      ]);
    });

    test('diaria puede omitir domingos cuando se configura', () {
      final fechas = calculadora.generarFechasPago(
        fechaInicio: DateTime(2026, 10, 3),
        numCuotas: 2,
        frecuencia: CalculadoraService.frecuenciaDiaria,
        saltarDomingos: true,
      );

      expect(fechas, [DateTime(2026, 10, 5), DateTime(2026, 10, 6)]);
    });

    test('semanal conserva weekday y quincenal suma quince días', () {
      final semanales = calculadora.generarFechasPago(
        fechaInicio: lunes,
        numCuotas: 2,
        frecuencia: CalculadoraService.frecuenciaSemanal,
      );
      final quincenales = calculadora.generarFechasPago(
        fechaInicio: lunes,
        numCuotas: 2,
        frecuencia: CalculadoraService.frecuenciaQuincenal,
      );

      expect(semanales, [DateTime(2026, 10, 5), DateTime(2026, 10, 12)]);
      expect(quincenales, [DateTime(2026, 10, 13), DateTime(2026, 10, 28)]);
    });

    test('calcula la fecha de finalización de la última cuota', () {
      expect(
        calculadora.calcularFechaFin(
          fechaInicio: lunes,
          numCuotas: 4,
          frecuencia: CalculadoraService.frecuenciaLunesMiercolesViernes,
        ),
        DateTime(2026, 10, 7),
      );
    });

    test('valida el número de cuotas y los días personalizados', () {
      expect(
        () => calculadora.generarFechasPago(
          fechaInicio: lunes,
          numCuotas: 0,
          frecuencia: CalculadoraService.frecuenciaDiaria,
        ),
        throwsArgumentError,
      );
      expect(
        () => calculadora.generarFechasPago(
          fechaInicio: lunes,
          numCuotas: 2,
          frecuencia: CalculadoraService.frecuenciaPersonalizada,
          diasPersonalizados: [8],
        ),
        throwsArgumentError,
      );
    });
  });
}
