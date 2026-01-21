final class IdrFormatter {
  static const currencySymbol = 'Rp';

  static String format(int amount) {
    final isNegative = amount < 0;
    final value = amount.abs();
    final digits = value.toString();

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      final shouldAddSeperator = reverseIndex > 1 && reverseIndex % 3 == 1;
      if (shouldAddSeperator) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    final prefix = isNegative ? '-' : '';
    return '$prefix$currencySymbol $formatted';
  }
}