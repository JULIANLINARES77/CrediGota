import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/data/models/cuota.dart';
import 'package:flutter_prestamos/logic/services/mora_service.dart';

void main() {
  final mora = MoraService(reloj: () => DateTime(2026, 10, 10, 15));
  final cuotaBase = Cuota(
    prestamoId: 1,
    numeroCuota: 1,
    fechaVencimiento: DateTime(2026, 10, 7),
    montoCuota: 50000,
  );

  test('calcula días completos de atraso sin fracción horaria', () {
    expect(mora.calcularDiasAtraso(cuotaBase.fechaVencimiento), 3);
    expect(mora.calcularDiasAtraso(DateTime(2026, 10, 11)), 0);
  });

  test('aplica porcentaje de mora al completar los días de gracia', () {
    expect(
      mora.calcularPenalizacionMora(
        cuota: cuotaBase,
        porcentajeMora: 10,
        diasGracia: 3,
      ),
      5000,
    );
    expect(
      mora.calcularPenalizacionMora(
        cuota: cuotaBase.copyWith(fechaVencimiento: DateTime(2026, 10, 8)),
        porcentajeMora: 10,
        diasGracia: 3,
      ),
      0,
    );
  });

  test('determina el estado pendiente, atrasado, parcial o pagado', () {
    expect(mora.verificarEstadoCuota(cuotaBase), 'ATRASADA');
    expect(
      mora.verificarEstadoCuota(
        cuotaBase.copyWith(fechaVencimiento: DateTime(2026, 10, 10)),
      ),
      'PENDIENTE',
    );
    expect(
      mora.verificarEstadoCuota(cuotaBase.copyWith(montoPagado: 10000)),
      'PARCIAL',
    );
    expect(
      mora.verificarEstadoCuota(cuotaBase.copyWith(montoPagado: 50000)),
      'PAGADA',
    );
  });
}
