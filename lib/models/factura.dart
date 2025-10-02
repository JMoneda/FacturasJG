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
  final String semana; // NUEVO CAMPO

  Factura({
    this.id,
    required this.tiquete,
    required this.fecha,
    required this.placa,
    required this.nombreDestino,
    required this.peso,
    required this.precio,
    required this.total,
    required this.observaciones,
    required this.fechaCreacion,
    required this.semana, // NUEVO CAMPO
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
      'semana': semana, // NUEVO CAMPO
    };
  }

  factory Factura.fromMap(Map<String, dynamic> map) {
    return Factura(
      id: map['id'],
      tiquete: map['tiquete'],
      fecha: map['fecha'],
      placa: map['placa'],
      nombreDestino: map['nombre_destino'],
      peso: map['peso'],
      precio: map['precio'],
      total: map['total'],
      observaciones: map['observaciones'],
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(map['fecha_creacion']),
      semana: map['semana'] ?? _calcularSemanaAutomatica(map['fecha']), // NUEVO CAMPO con fallback
    );
  }

  // Función helper para calcular la semana automáticamente
  static String _calcularSemanaAutomatica(String fecha) {
    try {
      final partes = fecha.split('/');
      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final ano = int.parse(partes[2]);
      final fechaObj = DateTime(ano, mes, dia);
      
      final primerDiaDelAno = DateTime(ano, 1, 1);
      final diferencia = fechaObj.difference(primerDiaDelAno).inDays;
      final numeroSemana = (diferencia / 7).ceil() + 1;
      
      return 'Semana $numeroSemana - $ano';
    } catch (e) {
      return 'Sin semana';
    }
  }

  // Función estática para generar nombre de semana automático
  static String generarNombreSemana(DateTime fecha) {
    final primerDiaDelAno = DateTime(fecha.year, 1, 1);
    final diferencia = fecha.difference(primerDiaDelAno).inDays;
    final numeroSemana = (diferencia / 7).ceil() + 1;
    
    return 'Semana $numeroSemana - ${fecha.year}';
  }
}