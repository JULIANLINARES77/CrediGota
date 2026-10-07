import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqlite_ffi;

import 'package:flutter_prestamos/data/database/database_helper.dart';
import 'package:flutter_prestamos/logic/providers/gota_provider.dart';
import 'package:flutter_prestamos/logic/services/calculadora_service.dart';
import 'package:flutter_prestamos/logic/services/pin_hash_service.dart';
import 'package:flutter_prestamos/ui/widgets/pin_security_gate.dart';
import 'package:flutter_prestamos/ui/screens/prestamos/prestamo_detail_screen.dart';
import 'package:flutter_prestamos/ui/screens/prestamos/prestamos_cliente_screen.dart';

class _TestPathProvider extends PathProviderPlatform {
  _TestPathProvider(this.supportPath);

  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

class _PinGateProvider extends GotaProvider {
  @override
  bool get pinActivo => true;

  @override
  Future<PinValidationResult> validarPin(String pin) async =>
      pin == '123456' ? PinValidationResult.valid : PinValidationResult.invalid;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory supportDirectory;
  late GotaProvider provider;

  setUpAll(() {
    sqlite_ffi.sqfliteFfiInit();
    databaseFactory = sqlite_ffi.databaseFactoryFfi;
  });

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'gotacontrol_loans_ui_',
    );
    PathProviderPlatform.instance = _TestPathProvider(supportDirectory.path);
    provider = GotaProvider(reloj: () => DateTime(2026, 9, 30, 12));
    await provider.cargarDatos();
    await provider.agregarCliente(
      nombre: 'Cliente con préstamos',
      telefono: '3001234567',
    );
    await provider.agregarCliente(nombre: 'Sin deuda', telefono: '3007654321');
    final clienteId = provider.clientes
        .firstWhere((cliente) => cliente.nombre == 'Cliente con préstamos')
        .id!;
    await provider.crearPrestamo(
      clienteId: clienteId,
      capital: 100000,
      porcentajeInteres: 20,
      numCuotas: 4,
      frecuencia: CalculadoraService.frecuenciaSemanal,
    );
    await provider.crearPrestamo(
      clienteId: clienteId,
      capital: 200000,
      porcentajeInteres: 10,
      numCuotas: 2,
      frecuencia: CalculadoraService.frecuenciaQuincenal,
    );
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  testWidgets('lista préstamos independientes y abre el detalle seleccionado', (
    tester,
  ) async {
    final clienteId = provider.clientes
        .firstWhere((cliente) => cliente.nombre == 'Cliente con préstamos')
        .id!;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: PrestamosClienteScreen(clienteId: clienteId)),
      ),
    );

    expect(find.text('Saldo total pendiente'), findsOneWidget);
    expect(find.textContaining('Préstamo #'), findsNWidgets(2));

    await tester.tap(find.textContaining('Préstamo #').first);
    await tester.pumpAndSettle();

    expect(find.byType(PrestamoDetailScreen), findsOneWidget);
    expect(find.text('Historial de préstamos'), findsOneWidget);
  });

  testWidgets('muestra estado vacío para cliente sin préstamos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: PrestamosClienteScreen(
            clienteId: provider.clientes
                .firstWhere((cliente) => cliente.nombre == 'Sin deuda')
                .id!,
          ),
        ),
      ),
    );

    expect(
      find.text('Este cliente todavía no tiene préstamos.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra error de PIN y desbloquea al validar', (tester) async {
    final pinProvider = _PinGateProvider()..cargando = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<GotaProvider>.value(
        value: pinProvider,
        child: const MaterialApp(
          home: PinSecurityGate(child: Text('Datos privados')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Desbloquear GotaControl'), findsOneWidget);
    expect(find.text('Datos privados'), findsNothing);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Desbloquear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PIN incorrecto.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Desbloquear'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Datos privados'), findsOneWidget);
  });
}
