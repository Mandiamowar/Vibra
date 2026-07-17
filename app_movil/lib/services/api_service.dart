import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://vibra-pay-backend.onrender.com';
  final _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  Future<dynamic> get(String endpoint) async {
  final url = Uri.parse('$baseUrl$endpoint');
  final response = await http.get(url);
  return jsonDecode(response.body);
}

  Future<Map<String, dynamic>> registrarUsuario(String nombre, String password) async {
  return await post('/usuarios/', {'nombre': nombre, 'password': password});
}

  Future<Map<String, dynamic>> transferir(int emisorId, int receptorId, double monto) async {
    return await post('/transacciones/transferir', {
      'emisor_id': emisorId,
      'receptor_id': receptorId,
      'monto': monto,
    });
  }
  Future<Map<String, dynamic>> obtenerUsuario(int id) async {
  return await get('/usuarios/$id');
}

  Future<Map<String, dynamic>> obtenerPrecio() async {
    return await get('/precio/');
  }

  Future<int?> obtenerIdUsuario() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      return int.tryParse(token);
    }
    return null;
  }
  Future<List<dynamic>> misFacturas(int usuarioId) async {
  final response = await get('/facturas/mis-facturas/$usuarioId');
  if (response is List) {
    return response;
  } else {
    throw Exception('La respuesta no es una lista');
  }
}

Future<String> descargarFactura(int facturaId) async {
  return '$baseUrl/facturas/$facturaId/pdf';
}
Future<Map<String, dynamic>> generarPago({
  required int emisorId,
  required int receptorId,
  required double monto,
}) async {
  return await post('/pagos/generar', {
    'emisor_id': emisorId,
    'receptor_id': receptorId,
    'monto': monto,
  });
}

Future<Map<String, dynamic>> confirmarPago(String codigo) async {
  return await post('/pagos/confirmar', {'codigo': codigo});
}

Future<Map<String, dynamic>> login(String nombre, String password) async {
  return await post('/usuarios/login', {'nombre': nombre, 'password': password});
}

}