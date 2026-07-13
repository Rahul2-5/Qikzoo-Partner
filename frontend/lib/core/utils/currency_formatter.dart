class CurrencyFormatter {
  CurrencyFormatter._();

  static String rupees(num amount) => '₹${amount.toStringAsFixed(0)}';

  static String rupeesPrecise(num amount) => '₹${amount.toStringAsFixed(2)}';
}
