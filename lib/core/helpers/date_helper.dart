class DateHelper {
  DateHelper._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String formatShort(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
