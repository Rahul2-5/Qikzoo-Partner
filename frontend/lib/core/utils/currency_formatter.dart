class CurrencyFormatter {
  CurrencyFormatter._();

  static String rupees(num amount) => '₹${_group(amount.toStringAsFixed(0))}';

  static String rupeesPrecise(num amount) {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    return '₹${_group(parts[0])}.${parts[1]}';
  }

  static String _group(String integerDigits) {
    final negative = integerDigits.startsWith('-');
    final digits = negative ? integerDigits.substring(1) : integerDigits;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}$buffer';
  }
}
