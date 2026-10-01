import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_prestamos/logic/providers/gota_provider.dart';
import 'package:flutter_prestamos/main.dart';

void main() {
  testWidgets('muestra carga SQLite y navega por las secciones principales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GotaProvider()..cargando = false,
        child: const GotaControlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ganancia de hoy'), findsOneWidget);

    await tester.tap(find.text('Nuevo').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Primero agrega un cliente para continuar.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Clientes').last);
    await tester.pumpAndSettle();
    expect(find.text('Buscar por nombre, cédula o teléfono'), findsOneWidget);

    await tester.tap(find.text('Reportes').last);
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un reporte'), findsOneWidget);

    await tester.tap(find.text('Ajustes').last);
    await tester.pumpAndSettle();
    expect(find.text('Datos del negocio'), findsOneWidget);
  });
}
