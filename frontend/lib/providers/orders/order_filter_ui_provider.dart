import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderFilterType { all, ongoing, completed }

final orderFilterUiProvider = StateProvider<OrderFilterType>((ref) => OrderFilterType.all);
