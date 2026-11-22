/// Aviso dentro de la app: "encontramos una posible coincidencia".
class Alerta {
  final String id;
  final String mensaje;
  final String itemId; // objeto que se abre al tocar el aviso
  final int puntaje;
  final DateTime fecha;
  bool leida;

  Alerta({
    required this.id,
    required this.mensaje,
    required this.itemId,
    required this.puntaje,
    DateTime? fecha,
    this.leida = false,
  }) : fecha = fecha ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'mensaje': mensaje,
        'itemId': itemId,
        'puntaje': puntaje,
        'fecha': fecha.toIso8601String(),
        'leida': leida,
      };

  factory Alerta.fromJson(Map<String, dynamic> j) => Alerta(
        id: j['id'].toString(),
        mensaje: (j['mensaje'] ?? '').toString(),
        itemId: j['itemId'].toString(),
        puntaje: (j['puntaje'] as num).toInt(),
        fecha: DateTime.tryParse((j['fecha'] ?? '').toString()),
        leida: j['leida'] == true,
      );
}
