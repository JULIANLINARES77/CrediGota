import 'package:flutter/services.dart';

class MilesInputFormatter extends TextInputFormatter {
  const MilesInputFormatter({this.maxDigits = 12});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) return oldValue;
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final normalizedDigits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final formatted = _formatThousands(normalizedDigits);
    final oldOffset = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCursor = newValue.text
        .substring(0, oldOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    final cursorOffset = _offsetAfterDigits(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
      composing: TextRange.empty,
    );
  }

  static String _formatThousands(String digits) {
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        result.write('.');
      }
      result.write(digits[index]);
    }
    return result.toString();
  }

  static int _offsetAfterDigits(String text, int digitCount) {
    if (digitCount == 0) return 0;
    var foundDigits = 0;
    for (var index = 0; index < text.length; index++) {
      if (RegExp(r'\d').hasMatch(text[index])) foundDigits++;
      if (foundDigits == digitCount) return index + 1;
    }
    return text.length;
  }
}
