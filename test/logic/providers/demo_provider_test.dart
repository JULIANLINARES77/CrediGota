import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/logic/providers/demo_provider.dart';

void main() {
  late DemoProvider demo;
  final hoy = DateTime(2026, 9, 28);

  setUp(() => demo = DemoProvider(fechaDemo: hoy));

  test('carga datos demo y calcula los indicadores del dashboard', () {
    expect(demo.clientesActivos, 3);
    expect(demo.prestamosActivos.length, 3);
    expect(demo.totalEnCalle, 2120000);
    expect(demo.recaudadoHoy, 100000);
    expect(demo.cuotasDeHoy, isNotEmpty);
    expect(demo.moras, hasLength(1));
  });

  test('un pago actualiza cuota, saldo y estado en memoria', () {
    final prestamo = demo.prestamoPorId(1)!;
    final cuota = demo
        .cuotasDePrestamo(1)
        .firstWhere((item) => item.estado != 'PAGADA');

    demo.registrarPago(
      prestamoId: prestamo.id!,
      cuotaId: cuota.id!,
      monto: cuota.montoCuota,
      metodoPago: 'NEQUI',
      fecha: hoy,
    );

    expect(demo.prestamoPorId(1)!.saldoPendiente, 900000);
    expect(demo.prestamoPorId(1)!.totalPagado, 300000);
    expect(
      demo.cuotasDePrestamo(1).firstWhere((item) => item.id == cuota.id).estado,
      'PAGADA',
    );
    expect(demo.pagosDePrestamo(1), hasLength(3));
  });
}
