class Cliente {
  final int id;
  final String nombre;
  final String? nif;
  final String? email;
  final String? direccion;
  final String? razonSocial;
  final String? telefono;

  Cliente({
    required this.id,
    required this.nombre,
    this.nif,
    this.email,
    this.direccion,
    this.razonSocial,
    this.telefono,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre'],
      nif: json['nif'],
      email: json['email'],
      direccion: json['direccion'],
      razonSocial: json['razon_social'],
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'nif': nif,
    'email': email,
    'direccion': direccion,
    'razon_social': razonSocial,
    'telefono': telefono,
  };
}