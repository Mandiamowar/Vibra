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

  // ---- AUTH ----
  Future<Map<String, dynamic>> registrarUsuario(String nombre) async {
    return await post('/usuarios/', {'nombre': nombre});
  }

  Future<Map<String, dynamic>> login(String nombre, String password) async {
    return await post('/usuarios/login', {'nombre': nombre, 'password': password});
  }

  // ---- USUARIOS ----
  Future<Map<String, dynamic>> obtenerUsuario(int id) async {
    return await get('/usuarios/$id');
  }

  Future<List<dynamic>> buscarUsuarios(String nombre) async {
    try {
      final response = await get('/usuarios/buscar/$nombre');
      if (response is List) {
        return response;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ---- TRANSACCIONES ----
  Future<Map<String, dynamic>> transferir(int emisorId, int receptorId, double monto) async {
    return await post('/transacciones/transferir', {
      'emisor_id': emisorId,
      'receptor_id': receptorId,
      'monto': monto,
    });
  }

  // ---- PRECIO ----
  Future<Map<String, dynamic>> obtenerPrecio() async {
    return await get('/precio/');
  }

  // ---- PAGOS con código ----
  Future<Map<String, dynamic>> generarPago({
  required int receptorId,
  required double monto,
}) async {
  return await post('/pagos/generar', {
    'receptor_id': receptorId,
    'monto': monto,
  });
}

  Future<Map<String, dynamic>> confirmarPago(String codigo, {required int emisorId}) async {
  return await post('/pagos/confirmar', {
    'codigo': codigo,
    'emisor_id': emisorId,
  });
}

  // ---- FACTURAS ----
  Future<Map<String, dynamic>> generarFactura({
    required int negocioId,
    required int clienteId,
    required double importe,
    required String concepto,
    String? emailDestino,
  }) async {
    return await post('/facturas/generar', {
      'negocio_id': negocioId,
      'cliente_id': clienteId,
      'importe': importe,
      'concepto': concepto,
      'email_destino': emailDestino,
    });
  }

  Future<List<dynamic>> misFacturas(int usuarioId) async {
    final response = await get('/facturas/mis-facturas/$usuarioId');
    if (response is List) {
      return response;
    } else {
      return [];
    }
  }

  Future<String> descargarFactura(int facturaId) async {
    return '$baseUrl/facturas/$facturaId/pdf';
  }

  // ---- NEGOCIOS (para facturación B2B) ----
  Future<Map<String, dynamic>> registrarNegocio({
    required int usuarioId,
    required String nombreComercial,
    required String nif,
    String? direccion,
    String? emailContacto,
    String? telefono,
    String serieFactura = 'A',
  }) async {
    return await post('/negocios/registrar', {
      'usuario_id': usuarioId,
      'nombre_comercial': nombreComercial,
      'nif': nif,
      'direccion': direccion,
      'email_contacto': emailContacto,
      'telefono': telefono,
      'serie_factura': serieFactura,
    });
  }

  Future<Map<String, dynamic>> obtenerNegocio(int usuarioId) async {
    return await get('/negocios/$usuarioId');
  }

  // ---- UTILITY ----
  Future<int?> obtenerIdUsuario() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      return int.tryParse(token);
    }
    return null;
  }
  Future<Map<String, dynamic>> actualizarUsuario(int id, Map<String, dynamic> data) async {
     return await put('/usuarios/$id', data);
  }
  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
     final url = Uri.parse('$baseUrl$endpoint');
     final response = await http.put(
      url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );
   return jsonDecode(response.body);
 }
   Future<Map<String, dynamic>> actualizarNegocio(int negocioId, Map<String, dynamic> data) async {
     return await put('/negocios/$negocioId', data);
 }
}