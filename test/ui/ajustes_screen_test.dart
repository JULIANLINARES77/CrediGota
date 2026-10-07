import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_prestamos/logic/providers/gota_provider.dart';
import 'package:flutter_prestamos/ui/screens/ajustes/ajustes_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('muestra validación si el nombre del negocio está vacío', (
    tester,
  ) async {
    final provider = GotaProvider()..cargando = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<GotaProvider>.value(
        value: provider,
        child: const MaterialApp(home: AjustesScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '   ');
    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isFalse);
    await tester.pump();

    expect(find.text('El nombre del negocio es obligatorio.'), findsOneWidget);
  });

  testWidgets('limita teléfono y dirección desde los campos', (tester) async {
    final provider = GotaProvider()..cargando = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<GotaProvider>.value(
        value: provider,
        child: const MaterialApp(home: AjustesScreen()),
      ),
    );

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(1), '1234567890123456');
    await tester.enterText(campos.at(2), 'D' * 260);

    expect(
      tester.widget<TextFormField>(campos.at(1)).controller!.text.length,
      15,
    );
    expect(
      tester.widget<TextFormField>(campos.at(2)).controller!.text.length,
      250,
    );
  });
}
