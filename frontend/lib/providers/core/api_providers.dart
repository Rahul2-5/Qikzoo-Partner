import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_service.dart';
import '../../core/storage/secure_storage.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => SecureTokenStorage(),
);

final dioServiceProvider = Provider<DioService>(
  (ref) => DioService(ref.watch(secureTokenStorageProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => ref.watch(dioServiceProvider).dio,
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
