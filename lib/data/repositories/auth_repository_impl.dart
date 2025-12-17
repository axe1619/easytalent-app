import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../domain/models/login_response.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<LoginResponse> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.loginUrl),
            body: {
              'username': username,
              'password': password,
            },
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return LoginResponse.fromJson(responseBody);
      } else if (response.statusCode == 401) {
        throw Exception('Usuario o contraseña incorrectos');
      } else if (response.statusCode == 400) {
        throw Exception('Datos de inicio de sesión inválidos');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio no encontrado');
      } else {
        throw Exception('Error al iniciar sesión. Código: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Tiempo de conexión agotado. Verifica tu conexión a internet');
    } on FormatException {
      throw Exception('Error en la respuesta del servidor');
    } catch (e) {
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('Error de conexión. Verifica tu conexión a internet');
      } else if (e.toString().contains('Exception: ')) {
        // Si ya es una excepción con mensaje en español, relanzarla
        rethrow;
      } else {
        throw Exception('Error al conectar con el servidor: ${e.toString()}');
      }
    }
  }
}
