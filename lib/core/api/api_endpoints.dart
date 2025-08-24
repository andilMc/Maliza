import 'package:maliza/core/config/config_global.dart';

class ApiEndpoints {
  static const String baseUrl = 'http://${ConfigGlobal.serverIpAPI}/todo';

  // Auth Endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';

  // Todo Endpoints
  static const String todos = '$baseUrl/todos';
  static const String insertTodo = '$baseUrl/inserttodo';
  static const String updateTodo = '$baseUrl/updatetodo';
  static const String deleteTodo = '$baseUrl/deletetodo';
}
