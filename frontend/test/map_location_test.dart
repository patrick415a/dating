import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dating_web/screens/map_search_screen.dart';
import 'package:dating_web/theme/app_theme.dart';

class FakeLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  Future<Position> Function() locate = () async => position(37.4, 127.1);
  LocationSettings? requestedSettings;
  int requests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    requests++;
    requestedSettings = locationSettings;
    return locate();
  }
}

class FakeWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => FakeWebView(params);
}

class FakeWebView extends PlatformInAppWebViewWidget {
  FakeWebView(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnsupportedError('No browser controller is needed by these tests.');

  @override
  void dispose() {}
}

Position position(double latitude, double longitude, {double accuracy = 20}) =>
    Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

String mapHtml(WidgetTester tester) => tester
    .widget<InAppWebView>(find.byType(InAppWebView))
    .platform.params.initialData!.data;

void main() {
  late FakeLocation location;
  late GeolocatorPlatform originalLocation;
  final webViewPlatform = FakeWebViewPlatform();

  setUp(() {
    originalLocation = GeolocatorPlatform.instance;
    location = FakeLocation();
    GeolocatorPlatform.instance = location;
    InAppWebViewPlatform.instance = webViewPlatform;
  });

  tearDown(() => GeolocatorPlatform.instance = originalLocation);

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const MapSearchScreen(),
    ));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    // Allow the existing toast's delayed dismissal to finish before teardown.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('Device coordinates reach Kakao in latitude-longitude order and retry updates the map', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    expect(mapHtml(tester), contains('LatLng(37.4, 127.1)'));
    expect(find.text('내 위치 확인완료'), findsOneWidget);
    expect(location.requestedSettings!.accuracy, LocationAccuracy.high);
    expect(location.requestedSettings!.timeLimit, const Duration(seconds: 15));
    final buttonLabel = tester.widget<Text>(find.text('주변 인연 찾기'));
    expect(buttonLabel.style!.color, AppColors.onPrimary);
    final locationLabel = tester.widget<Text>(find.text('내 위치 확인완료'));
    expect(locationLabel.style!.fontSize, 14);

    location.locate = () async => position(35.9, 126.7);
    await tester.tap(find.byTooltip('내 위치 다시 확인'));
    await tester.pumpAndSettle();
    expect(location.requests, 2);
    expect(mapHtml(tester), contains('LatLng(35.9, 126.7)'));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Coarse device coordinates are labelled approximate', (tester) async {
    location.locate = () async => position(35.9, 126.7, accuracy: 4000);
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('대략적인 위치'), findsOneWidget);
    expect(find.text('내 위치 확인완료'), findsNothing);
    expect(mapHtml(tester), contains('LatLng(35.9, 126.7)'));
    expect(find.byTooltip(RegExp(r'예상 오차 약 4\.0km')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Denied permission clearly labels Seoul as a default location', (tester) async {
    location.permission = LocationPermission.deniedForever;
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('기본 위치 · 서울'), findsOneWidget);
    expect(find.text('내 위치 확인완료'), findsNothing);
    expect(location.requests, 0);
    expect(mapHtml(tester), contains('LatLng(37.5666, 126.9784)'));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('A location timeout leaves a usable retry and truthful default label', (tester) async {
    location.locate = () async => throw TimeoutException('Location timed out');
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('기본 위치 · 서울'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    location.locate = () async => position(37.4, 127.1);
    await tester.tap(find.byTooltip('내 위치 다시 확인'));
    await tester.pumpAndSettle();
    expect(find.text('내 위치 확인완료'), findsOneWidget);
    expect(mapHtml(tester), contains('LatLng(37.4, 127.1)'));
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('Leaving during a location request does not update a disposed screen', (tester) async {
    final pending = Completer<Position>();
    location.locate = () => pending.future;
    await open(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(position(37.4, 127.1));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}
