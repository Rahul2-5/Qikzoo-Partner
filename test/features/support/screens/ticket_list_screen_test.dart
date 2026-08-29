import 'dart:async';
import 'dart:typed_data';

import 'package:delivery_partner_app/core/api/api_client.dart';
import 'package:delivery_partner_app/features/support/screens/ticket_list_screen.dart';
import 'package:delivery_partner_app/providers/core/api_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(String body, int statusCode) =>
    ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        'content-type': ['application/json'],
      },
    );

Widget buildApp(ApiClient apiClient) => ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(apiClient)],
      child: const GetMaterialApp(home: TicketListScreen()),
    );

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets(
      'a real (empty) backend response shows the honest empty state, not fabricated tickets',
      (tester) async {
    final apiClient = ApiClient(
      Dio()..httpClientAdapter = FakeHttpClientAdapter(
        (_) async => jsonResponse('{"data":[]}', 200),
      ),
    );

    await tester.pumpWidget(buildApp(apiClient));
    await tester.pumpAndSettle();

    // Regression guard: this screen used to seed 3 fabricated tickets
    // (TCK-1002/TCK-0985/TCK-0961) with invented outlet names and dates —
    // client-side data with no backend behind it at all. It now genuinely
    // fetches from SupportRepository, so an empty backend response must
    // show the screen's own honest empty state, never invented history.
    expect(find.text('No tickets found'), findsOneWidget);
    expect(find.textContaining('TCK-'), findsNothing);
    expect(find.text('Noodle House, Mumbai'), findsNothing);
  });

  testWidgets(
      'a failed backend request shows an honest error, never fabricated tickets',
      (tester) async {
    final apiClient = ApiClient(
      Dio()..httpClientAdapter = FakeHttpClientAdapter(
        (_) async => jsonResponse('{"message":"Internal error"}', 500),
      ),
    );

    await tester.pumpWidget(buildApp(apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load support tickets.'), findsOneWidget);
    expect(find.textContaining('TCK-'), findsNothing);
    expect(find.text('Noodle House, Mumbai'), findsNothing);
  });
}
