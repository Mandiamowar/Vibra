class Factura {
  final int id;
  final String numeroFactura;
  final String fecha;
  final double importe;
  final String concepto;
  final String clienteNombre;
  final bool enviado;

  Factura({
    required this.id,
    required this.numeroFactura,
    required this.fecha,
    required this.importe,
    required this.concepto,
    required this.clienteNombre,
    required this.enviado,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['id'] ?? 0,
      numeroFactura: json['numero_factura'] ?? '',
      fecha: json['fecha'] ?? '',
      importe: (json['importe'] ?? 0.0).toDouble(),
      concepto: json['concepto'] ?? '',
      clienteNombre: json['cliente_nombre'] ?? '',
      enviado: json['enviado'] == true || json['enviado'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero_factura': numeroFactura,
    'fecha': fecha,
    'importe': importe,
    'concepto': concepto,
    'cliente_nombre': clienteNombre,
    'enviado': enviado,
  };
}