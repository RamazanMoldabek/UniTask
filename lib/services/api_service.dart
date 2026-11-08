import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../utils/app_logger.dart';

class ApiService {
  static const String baseUrl =
      'https://6aeac9de3d3dd3d37be73500.mockapi.io/tasks';
  static const Duration timeoutDuration = Duration(seconds: 10);

  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;
  ApiService._internal();

  /// GET-запрос списка задач
  Future<List<Task>> fetchTasks() async {
    AppLogger.network('GET', baseUrl);
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      AppLogger.network('GET', baseUrl, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => Task.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Сервер қатесі: ${response.statusCode} (${response.reasonPhrase ?? ''})');
      }
    } on SocketException catch (e) {
      AppLogger.error('Network disconnect on fetchTasks', error: e);
      throw Exception('Сервермен байланыс жоқ. Интернет желісін тексеріңіз.');
    } on TimeoutException catch (e) {
      AppLogger.error('Timeout on fetchTasks', error: e);
      throw Exception('Серверден жауап күту уақыты аяқталды (10 секунд).');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error on fetchTasks',
          error: e, stackTrace: stackTrace);
      if (e is Exception) rethrow;
      throw Exception('Тапсырмаларды жүктеу кезінде қате орын алды: $e');
    }
  }

  /// POST-запрос с отправкой тела jsonEncode(task.toJson()) и заголовком 'Content-Type': 'application/json'
  Future<Task> createTask(Task task) async {
    final body = jsonEncode(task.toJson());
    AppLogger.network('POST', baseUrl, body: body);
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      AppLogger.network('POST', baseUrl, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Task.fromJson(data);
      } else {
        throw Exception(
            'Тапсырма жасау қатесі: ${response.statusCode} (${response.reasonPhrase ?? ''})');
      }
    } on SocketException catch (e) {
      AppLogger.error('Network disconnect on createTask', error: e);
      throw Exception('Сервермен байланыс жоқ. Интернет желісін тексеріңіз.');
    } on TimeoutException catch (e) {
      AppLogger.error('Timeout on createTask', error: e);
      throw Exception('Серверден жауап күту уақыты аяқталды (10 секунд).');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error on createTask',
          error: e, stackTrace: stackTrace);
      if (e is Exception) rethrow;
      throw Exception('Тапсырма жасау кезінде қате орын алды: $e');
    }
  }

  /// PUT-запрос на '$baseUrl/${task.id}' для обновления статуса или данных задачи
  Future<Task> updateTask(Task task) async {
    if (task.id.isEmpty) {
      throw Exception('Тапсырманың идентификаторы (id) табылмады');
    }
    final url = '$baseUrl/${task.id}';
    final body = jsonEncode(task.toJson());
    AppLogger.network('PUT', url, body: body);

    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      AppLogger.network('PUT', url, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Task.fromJson(data);
      } else {
        throw Exception(
            'Тапсырманы жаңарту қатесі: ${response.statusCode} (${response.reasonPhrase ?? ''})');
      }
    } on SocketException catch (e) {
      AppLogger.error('Network disconnect on updateTask', error: e);
      throw Exception('Сервермен байланыс жоқ. Интернет желісін тексеріңіз.');
    } on TimeoutException catch (e) {
      AppLogger.error('Timeout on updateTask', error: e);
      throw Exception('Серверден жауап күту уақыты аяқталды (10 секунд).');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error on updateTask',
          error: e, stackTrace: stackTrace);
      if (e is Exception) rethrow;
      throw Exception('Тапсырманы жаңарту кезінде қате орын алды: $e');
    }
  }

  /// DELETE-запрос на '$baseUrl/$id'
  Future<bool> deleteTask(String id) async {
    if (id.isEmpty) {
      throw Exception('Жойылатын тапсырманың идентификаторы (id) көрсетілмеген');
    }
    final url = '$baseUrl/$id';
    AppLogger.network('DELETE', url);

    try {
      final response = await http
          .delete(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      AppLogger.network('DELETE', url, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
            'Тапсырманы жою қатесі: ${response.statusCode} (${response.reasonPhrase ?? ''})');
      }
    } on SocketException catch (e) {
      AppLogger.error('Network disconnect on deleteTask', error: e);
      throw Exception('Сервермен байланыс жоқ. Интернет желісін тексеріңіз.');
    } on TimeoutException catch (e) {
      AppLogger.error('Timeout on deleteTask', error: e);
      throw Exception('Серверден жауап күту уақыты аяқталды (10 секунд).');
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error on deleteTask',
          error: e, stackTrace: stackTrace);
      if (e is Exception) rethrow;
      throw Exception('Тапсырманы жою кезінде қате орын алды: $e');
    }
  }
}
