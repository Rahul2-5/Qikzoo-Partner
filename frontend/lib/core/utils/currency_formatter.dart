class CurrencyFormatter {
  CurrencyFormatter._();

  static String rupees(num amount) => '₹${amount.toStringAsFixed(0)}';
}
