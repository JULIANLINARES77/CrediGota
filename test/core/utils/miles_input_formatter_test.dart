import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_prestamos/core/utils/miles_input_formatter.dart';

void main() {
  const formatter = MilesInputFormatter(maxDigits: 12);

  test('agrupa miles con punto y deja el cursor después del último dígito', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1000000',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );

    expect(result.text, '1.000.000');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('rechaza más dígitos que el máximo configurado', () {
    final oldValue = const TextEditingValue(text: '100.000.000.000');
    final result = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(text: '1000000000000'),
    );

    expect(result, oldValue);
  });

  test('admite campo vacío y quita ceros iniciales', () {
    expect(
      formatter
          .formatEditUpdate(
            const TextEditingValue(text: '0'),
            TextEditingValue.empty,
          )
          .text,
      isEmpty,
    );
    expect(
      formatter
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '00010000'),
          )
          .text,
      '10.000',
    );
  });
}
