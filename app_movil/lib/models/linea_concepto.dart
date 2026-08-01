class LineaConcepto {
  final int cantidad;
  final String descripcion;
  final double precioUnitario;
  double get subtotal => cantidad * precioUnitario;

  LineaConcepto({
    required this.cantidad,
    required this.descripcion,
    required this.precioUnitario,
  });

  Map<String, dynamic> toJson() => {
    'cantidad': cantidad,
    'descripcion': descripcion,
    'precio_unitario': precioUnitario,
  };

  factory LineaConcepto.fromJson(Map<String, dynamic> json) => LineaConcepto(
    cantidad: json['cantidad'],
    descripcion: json['descripcion'],
    precioUnitario: json['precio_unitario'],
  );
}