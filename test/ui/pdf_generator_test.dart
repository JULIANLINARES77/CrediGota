import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/logic/providers/gota_provider.dart';
import 'package:flutter_prestamos/ui/screens/reportes/pdf_generator.dart';

void main() {
  test(
    'genera bytes PDF para los reportes diario, semanal, mora y mensual',
    () async {
      final demo = GotaProvider();
      final fecha = DateTime(2026, 9, 28);
      final documentos = [
        await PdfGenerator.reporteDiario(demo, fecha),
        await PdfGenerator.reporteSemanal(demo, fecha),
        await PdfGenerator.reporteMora(demo, fecha),
        await PdfGenerator.reporteMensual(demo, fecha),
      ];

      for (final documento in documentos) {
        expect(String.fromCharCodes(documento.take(5)), '%PDF-');
      }
    },
  );
}
