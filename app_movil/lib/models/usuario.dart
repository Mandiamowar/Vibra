class Usuario {
  final int id;
  final String nombre;
  final double saldo;
  final double reputacion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.saldo,
    required this.reputacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      saldo: (json['saldo'] as num).toDouble(),
      reputacion: (json['reputacion'] as num).toDouble(),
    );
  }
}