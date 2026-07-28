import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket.dart';

class TicketService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Subir un ticket (con foto)
  Future<Ticket> subirTicket({
    required int usuarioId,
    required DateTime fecha,
    required double importe,
    required String proveedor,
    String? categoria,
    XFile? imagen,
  }) async {
    String? fotoUrl;

    if (imagen != null) {
      final compressedFile = await _comprimirImagen(imagen);
      final fileBytes = await compressedFile.readAsBytes();
      final fileName = 'tickets/${usuarioId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('tickets').uploadBinary(
        fileName,
        fileBytes,
      );
      
      fotoUrl = _supabase.storage.from('tickets').getPublicUrl(fileName);
    }

    final ticket = Ticket(
      usuarioId: usuarioId,
      fecha: fecha,
      importe: importe,
      proveedor: proveedor,
      categoria: categoria,
      fotoUrl: fotoUrl,
      mes: fecha.month,
      year: fecha.year,
    );

    final response = await _supabase
        .from('tickets')
        .insert(ticket.toJson())
        .select()
        .single();

    return Ticket.fromJson(response);
  }

  // Obtener tickets de un usuario (con filtro opcional de mes/año)
  Future<List<Ticket>> obtenerTickets({
    required int usuarioId,
    int? mes,
    int? year,
  }) async {
    // 🔥 CONSTRUIR LA CONSULTA PASO A PASO
    var query = _supabase
        .from('tickets')
        .select()
        .eq('usuario_id', usuarioId);

    if (mes != null && year != null) {
      query = query.eq('mes', mes).eq('year', year);
    }

    // 🔥 APLICAR ORDEN AL FINAL (devuelve PostgrestTransformBuilder)
    final response = await query.order('fecha', ascending: false);

    return (response as List).map((e) => Ticket.fromJson(e)).toList();
  }

  // Eliminar un ticket
  Future<void> eliminarTicket(int ticketId) async {
    await _supabase.from('tickets').delete().eq('id', ticketId);
  }

  // COMPRIMIR IMAGEN
  Future<File> _comprimirImagen(XFile image) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Error al comprimir la imagen');
    }
    return File(result.path);
  }

  // OCR (placeholder)
  Future<Map<String, dynamic>> extraerDatosOCR(XFile image) async {
    return {};
  }
}