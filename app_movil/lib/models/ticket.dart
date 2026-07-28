class Ticket {
  final int? id;
  final int usuarioId;
  final DateTime fecha;
  final double importe;
  final String proveedor;
  final String? categoria;
  final String? fotoUrl;
  final Map<String, dynamic>? ocrData;
  final int mes;
  final int year;  // Cambiado a year

  Ticket({
    this.id,
    required this.usuarioId,
    required this.fecha,
    required this.importe,
    required this.proveedor,
    this.categoria,
    this.fotoUrl,
    this.ocrData,
    required this.mes,
    required this.year,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      usuarioId: json['usuario_id'],
      fecha: DateTime.parse(json['fecha']),
      importe: (json['importe'] as num).toDouble(),
      proveedor: json['proveedor'],
      categoria: json['categoria'],
      fotoUrl: json['foto_url'],
      ocrData: json['ocr_data'],
      mes: json['mes'],
      year: json['year'],  // Cambiado
    );
  }

  Map<String, dynamic> toJson() => {
    'usuario_id': usuarioId,
    'fecha': fecha.toIso8601String().split('T')[0],
    'importe': importe,
    'proveedor': proveedor,
    'categoria': categoria,
    'foto_url': fotoUrl,
    'ocr_data': ocrData,
    'mes': mes,
    'year': year,  // Cambiado
  };
}