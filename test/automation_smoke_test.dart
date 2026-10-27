import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inno_media/core/di/injection_container.dart' as di;
import 'package:inno_media/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Standard 1x1 transparent PNG to immediately satisfy Flutter image loaders in tests
final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUp(() async {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    await di.initDependencies();
  });

  tearDown(() async {
    await di.sl.reset();
  });

  group('Playwright-Style Deterministic Automation & Smoke Tests', () {
    testWidgets('1. Verifies login page renders deterministic automation keys and autofill works', (tester) async {
      await tester.pumpWidget(const InnoMediaApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Find by deterministic automation keys
      final mobileInput = find.byKey(const Key('input_mobile'));
      final passwordInput = find.byKey(const Key('input_password'));
      final loginButton = find.byKey(const Key('btn_login'));
      final autofillButton = find.byKey(const Key('btn_demo_autofill'));

      expect(mobileInput, findsOneWidget);
      expect(passwordInput, findsOneWidget);
      expect(loginButton, findsOneWidget);
      expect(autofillButton, findsOneWidget);

      // Trigger Autofill
      await tester.tap(autofillButton);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('2. Authenticates and verifies bottom navigation tabs', (tester) async {
      await tester.pumpWidget(const InnoMediaApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Autofill and Login
      await tester.tap(find.byKey(const Key('btn_demo_autofill')));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('btn_login')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify deterministic navigation tabs
      expect(find.byKey(const Key('tab_feed')), findsOneWidget);
      expect(find.byKey(const Key('tab_reels')), findsOneWidget);
      expect(find.byKey(const Key('tab_dynamic_form')), findsOneWidget);
      expect(find.byKey(const Key('tab_profile')), findsOneWidget);
    });

    testWidgets('3. Navigates to Dynamic Form, verifies field rendering and conditional disclosure', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const InnoMediaApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Login
      await tester.tap(find.byKey(const Key('btn_demo_autofill')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('btn_login')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // Tap Dynamic Form Tab
      await tester.tap(find.byKey(const Key('tab_dynamic_form')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify key dynamic form controls exist
      expect(find.byKey(const Key('btn_open_schema_editor')), findsOneWidget);
      expect(find.byKey(const Key('btn_submit_form')), findsOneWidget);

      // Verify field_is_married exists
      final marriedField = find.byKey(const Key('field_is_married'));
      expect(marriedField, findsOneWidget);

      // Before toggle: field_spouse_name should NOT be in the tree (visibleIf: is_married == true)
      expect(find.byKey(const Key('field_spouse_name')), findsNothing);

      // Toggle married switch to true
      await tester.tap(find.descendant(of: marriedField, matching: find.byType(Switch)));
      await tester.pump(const Duration(milliseconds: 400));

      // After toggle: field_spouse_name MUST appear dynamically!
      expect(find.byKey(const Key('field_spouse_name')), findsOneWidget);
    });
  });
}
