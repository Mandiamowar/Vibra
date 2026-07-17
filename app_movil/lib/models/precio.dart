class Precio {
  final double precio;
  final double gini;
  final int transacciones24h;

  Precio({
    required this.precio,
    required this.gini,
    required this.transacciones24h,
  });

  factory Precio.fromJson(Map<String, dynamic> json) {
    return Precio(
      precio: (json['precio'] as num).toDouble(),
      gini: (json['gini'] as num).toDouble(),
      transacciones24h: json['transacciones_24h'] as int,
    );
  }
}