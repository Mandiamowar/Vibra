class Transaccion {
  final int id;
  final int emisorId;
  final int receptorId;
  final double monto;
  final String estado;

  Transaccion({
    required this.id,
    required this.emisorId,
    required this.receptorId,
    required this.monto,
    required this.estado,
  });

  factory Transaccion.fromJson(Map<String, dynamic> json) {
    return Transaccion(
      id: json['id'] as int,
      emisorId: json['emisor_id'] as int,
      receptorId: json['receptor_id'] as int,
      monto: (json['monto'] as num).toDouble(),
      estado: json['estado'] as String,
    );
  }
}