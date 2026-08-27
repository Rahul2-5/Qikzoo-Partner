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
    if (digits.length <= 3) return (negative ? '-' : '') + digits;

    final lastThree = digits.substring(digits.length - 3);
    final leading = digits.substring(0, digits.length - 3);
    final buffer = StringBuffer();
    final firstGroupLength = leading.length.isEven ? 2 : 1;
    buffer.write(leading.substring(0, firstGroupLength));
    for (var index = firstGroupLength; index < leading.length; index += 2) {
      buffer.write(',');
      buffer.write(leading.substring(index, index + 2));
    }
    buffer.write(',');
    buffer.write(lastThree);
    return (negative ? '-' : '') + buffer.toString();
  }
}
