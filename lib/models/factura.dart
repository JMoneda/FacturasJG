class Factura {
  final int? id;
  final String tiquete;
  final String fecha;
  final String placa;
  final String nombreDestino;
  final double peso;
  final double precio;
  final double total;
  final String observaciones;
  final DateTime fechaCreacion;

  Factura({
    this.id,
    required this.tiquete,
    required this.fecha,
    required this.placa,
    required this.nombreDestino,
    required this.peso,
    required this.precio,
    required this.total,
    this.observaciones = '',
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tiquete': tiquete,
      'fecha': fecha,
      'placa': placa,
      'nombre_destino': nombreDestino,
      'peso': peso,
      'precio': precio,
      'total': total,
      'observaciones': observaciones,
      'fecha_creacion': fechaCreacion.millisecondsSinceEpoch,
    };
  }

  factory Factura.fromMap(Map<String, dynamic> map) {
    return Factura(
      id: map['id'],
      tiquete: map['tiquete'],
      fecha: map['fecha'],
      placa: map['placa'],
      nombreDestino: map['nombre_destino'],
      peso: map['peso'].toDouble(),
      precio: map['precio'].toDouble(),
      total: map['total'].toDouble(),
      observaciones: map['observaciones'] ?? '',
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion']),
    );
  }
}