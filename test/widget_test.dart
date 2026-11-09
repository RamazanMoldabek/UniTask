import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unitask/main.dart';
import 'package:unitask/screens/tasks_screen.dart';
import 'package:unitask/screens/task_detail_screen.dart';
import 'package:unitask/models/task.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  void close({bool force = false}) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> head(String host, int port, String path) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}

  @override
  set keyLog(Function(String line)? callback) {}
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool bufferOutput = true;

  @override
  int contentLength = 0;

  @override
  Encoding encoding = utf8;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  String method = 'GET';

  @override
  Uri uri = Uri.parse('https://example.com');

  @override
  bool persistentConnection = false;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future flush() async {}

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  void clear() => _headers.clear();

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) => _headers[name]?.remove(value.toString());

  @override
  void removeAll(String name) => _headers.remove(name);

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  String? value(String name) => _headers[name]?.first;

  @override
  bool chunkedTransferEncoding = false;

  @override
  int contentLength = 0;

  @override
  ContentType? contentType;

  @override
  DateTime? date;

  @override
  DateTime? expires;

  @override
  String? host;

  @override
  DateTime? ifModifiedSince;

  @override
  bool persistentConnection = false;

  @override
  int? port;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final String _body = jsonEncode([
    {
      'id': '1',
      'title': 'Зертханалық жұмыс №4',
      'subject': 'Деректер қоры',
      'deadline': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'priority': 'Орташа',
      'isCompleted': false,
    }
  ]);

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => utf8.encode(_body).length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) =>
      throw UnimplementedError();

  @override
  List<RedirectInfo> get redirects => [];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(utf8.encode(_body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  X509Certificate? get certificate => null;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('UniTask app smoke test and 5-tab navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const UniTaskApp());
    // Splash screen runs for 1800ms
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify HomeScreen content
    expect(find.text('Сәлем, Рамазан!'), findsOneWidget);
    expect(find.text('Осы аптадағы жетістік'), findsOneWidget);
    expect(find.text('Барлығы'), findsOneWidget);
    expect(find.text('Шұғыл'), findsOneWidget);

    // Switch to Tasks tab
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TasksScreen), findsOneWidget);

    // Switch to Calendar tab (Kept in bottom navbar as user requested!)
    await tester.tap(find.text('Күнтізбе'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Бүгін'), findsOneWidget);

    // Switch to Search tab
    await tester.tap(find.text('Іздеу'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Соңғы іздеулер'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Профиль'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Рамазан Т.'), findsOneWidget);
    expect(find.text('Қараңғы режим'), findsOneWidget);

    // Toggle dark mode switch
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 500));

    // Switch back to Home tab
    await tester.tap(find.text('Басты'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Сәлем, Рамазан!'), findsOneWidget);
  });

  testWidgets('TaskDetailScreen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final sampleTask = Task.sampleTasks.first;
    await tester.pumpWidget(
      MaterialApp(
        home: TaskDetailScreen(
          task: sampleTask,
          onUpdate: (_) {},
          onDelete: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тапсырма'), findsOneWidget);
    expect(find.text(sampleTask.title), findsOneWidget);
    expect(find.text('Тапсыру мерзімі'), findsOneWidget);
    expect(find.text('Өңдеу'), findsOneWidget);
    expect(find.text('Жою'), findsOneWidget);
  });
}
