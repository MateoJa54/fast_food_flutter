import 'package:flutter/services.dart';

/// 1234567812345678 -> 1234 5678 1234 5678
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 16 ? digits.substring(0, 16) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      buffer.write(clipped[i]);
      final isEndOfGroup = (i + 1) % 4 == 0;
      if (isEndOfGroup && i + 1 != clipped.length) buffer.write(' ');
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// MM/YY con auto slash
class ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;

    String text;
    if (clipped.length <= 2) {
      text = clipped;
    } else {
      text = '${clipped.substring(0, 2)}/${clipped.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
