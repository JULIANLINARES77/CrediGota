import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqlite_ffi;

import 'package:flutter_prestamos/core/constants/app_colors.dart';
import 'package:flutter_prestamos/data/database/database_helper.dart';
import 'package:flutter_prestamos/logic/providers/gota_provider.dart';
import 'package:flutter_prestamos/logic/services/calculadora_service.dart';
import 'package:flutter_prestamos/logic/services/local_backup_service.dart';
import 'package:flutter_prestamos/ui/screens/ajustes/ajustes_screen.dart';
import 'package:flutter_prestamos/ui/screens/clientes/clientes_screen.dart';
import 'package:flutter_prestamos/ui/screens/dashboard/dashboard_screen.dart';
import 'package:flutter_prestamos/ui/screens/prestamos/nuevo_prestamo_screen.dart';
import 'package:flutter_prestamos/ui/screens/prestamos/prestamo_detail_screen.dart';
import 'package:flutter_prestamos/ui/screens/prestamos/prestamos_cliente_screen.dart';
import 'package:flutter_prestamos/ui/screens/reportes/reportes_screen.dart';
import 'package:flutter_prestamos/ui/widgets/payment_bottom_sheet.dart';

class _CapturePathProvider extends PathProviderPlatform {
  _CapturePathProvider(this.supportPath);

  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const backupChannel = MethodChannel('gotacontrol/local_backup');
  final captureRoot = GlobalKey();
  late Directory supportDirectory;
  late Directory captureDirectory;
  late GotaProvider provider;
  late int clientId;
  late int firstLoanId;

  setUpAll(() {
    sqlite_ffi.sqfliteFfiInit();
    databaseFactory = sqlite_ffi.databaseFactoryFfi;
  });

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'gotacontrol_manual_',
    );
    captureDirectory = Directory('manual de usuario/capturas');
    await captureDirectory.create(recursive: true);
    PathProviderPlatform.instance = _CapturePathProvider(
      supportDirectory.path,
    );
    provider = GotaProvider();
    await provider.cargarDatos();
    await provider.agregarCliente(
      nombre: 'María Fernanda López',
      telefono: '3001234567',
      cedula: '1032456789',
    );
    await provider.agregarCliente(
      nombre: 'Carlos Méndez',
      telefono: '3107654321',
    );
    clientId = provider.clientes.first.id!;
    final loan = await provider.crearPrestamo(
      clienteId: clientId,
      capital: 800000,
      porcentajeInteres: 20,
      numCuotas: 12,
      frecuencia: CalculadoraService.frecuenciaSemanal,
    );
    firstLoanId = loan.id!;
    await provider.crearPrestamo(
      clienteId: clientId,
      capital: 400000,
      porcentajeInteres: 15,
      numCuotas: 8,
      frecuencia: CalculadoraService.frecuenciaQuincenal,
    );
    final firstInstallment = provider.cuotasDePrestamo(firstLoanId).first;
    await provider.registrarPago(
      prestamoId: firstLoanId,
      cuotaId: firstInstallment.id!,
      monto: firstInstallment.montoCuota,
      metodoPago: 'EFECTIVO',
      fecha: DateTime.now(),
      nota: 'Pago de demostración',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backupChannel, (call) async {
          switch (call.method) {
            case 'getBackupStatus':
              return {
                'folderUri': 'content://demo/GotaControl',
                'folderName': 'GotaControl',
                'automaticDestination': false,
                'frequency': 'weekly',
                'lastSuccess': DateTime.now().millisecondsSinceEpoch,
                'lastFile': 'GotaControl_auto_demostracion.db',
                'lastError': null,
              };
            case 'configureSchedule':
              return {'scheduled': true};
            default:
              return null;
          }
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(backupChannel, null);
    await DatabaseHelper.instance.close();
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  testWidgets('captures illustrative user manual screens', (tester) async {
    tester.view.physicalSize = const Size(432, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> showScreen(Widget screen) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureRoot,
          child: ChangeNotifierProvider<GotaProvider>.value(
            value: provider,
            child: MaterialApp(
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Brightness.dark,
                  surface: AppColors.surface,
                  primary: AppColors.primary,
                  error: AppColors.error,
                ),
                scaffoldBackgroundColor: AppColors.background,
                cardColor: AppColors.surface,
              ),
              home: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> capture(String fileName) async {
      final boundary = captureRoot.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${captureDirectory.path}/$fileName.png').writeAsBytes(
        bytes!.buffer.asUint8List(),
      );
      image.dispose();
    }

    await showScreen(
      DashboardScreen(
        onNuevoPrestamo: () {},
        onClientes: () {},
        onMora: () {},
        onPrestamos: () {},
      ),
    );
    await capture('01-inicio');

    await showScreen(const ClientesScreen());
    await capture('02-clientes');

    await showScreen(PrestamosClienteScreen(clienteId: clientId));
    await capture('03-prestamos-cliente');

    await showScreen(const NuevoPrestamoScreen());
    await capture('04-nuevo-prestamo');

    await showScreen(PrestamoDetailScreen(prestamoId: firstLoanId));
    await capture('05-detalle-prestamo');

    await showScreen(const ReportesScreen());
    await capture('06-reportes');

    await showScreen(const AjustesScreen());
    await capture('07-ajustes');
  });
}
