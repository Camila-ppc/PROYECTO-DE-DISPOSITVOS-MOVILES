import 'categorias.dart';

/// Posible coincidencia entre un objeto perdido y uno encontrado.
class Coincidencia {
  final String itemId; // el OTRO objeto
  final int puntaje; // 0 a 100
  final String motivo;

  const Coincidencia({
    required this.itemId,
    required this.puntaje,
    this.motivo = '',
  });

  Map<String, dynamic> toJson() =>
      {'itemId': itemId, 'puntaje': puntaje, 'motivo': motivo};

  factory Coincidencia.fromJson(Map<String, dynamic> j) => Coincidencia(
        itemId: j['itemId'].toString(),
        puntaje: (j['puntaje'] as num).toInt(),
        motivo: (j['motivo'] ?? '').toString(),
      );
}

class Item {
  final String id;
  final String titulo;
  final String descripcion;
  final String lugar;
  final bool encontrado; // true = lo encontraron, false = lo perdieron
  final String? fotoPath;
  final DateTime fecha;
  final String? pregunta; // verificación del dueño
  final String? respuesta;
  final String textoOcr; // texto leído en la foto con ML Kit
  final String categoria;
  bool reclamado;
  List<Coincidencia> coincidencias;

  Item({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.encontrado,
    this.fotoPath,
    this.pregunta,
    this.respuesta,
    this.textoOcr = '',
    this.categoria = 'Otros',
    this.reclamado = false,
    List<Coincidencia>? coincidencias,
    DateTime? fecha,
  })  : fecha = fecha ?? DateTime.now(),
        coincidencias = coincidencias ?? <Coincidencia>[];

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'lugar': lugar,
        'encontrado': encontrado,
        'fotoPath': fotoPath,
        'fecha': fecha.toIso8601String(),
        'pregunta': pregunta,
        'respuesta': respuesta,
        'textoOcr': textoOcr,
        'categoria': categoria,
        'reclamado': reclamado,
        'coincidencias': [for (final c in coincidencias) c.toJson()],
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'].toString(),
        titulo: (j['titulo'] ?? '').toString(),
        descripcion: (j['descripcion'] ?? '').toString(),
        lugar: (j['lugar'] ?? '').toString(),
        encontrado: j['encontrado'] == true,
        fotoPath: j['fotoPath'] as String?,
        fecha: DateTime.tryParse((j['fecha'] ?? '').toString()),
        pregunta: j['pregunta'] as String?,
        respuesta: j['respuesta'] as String?,
        textoOcr: (j['textoOcr'] ?? '').toString(),
        categoria: categoriaValida(j['categoria'] as String?),
        reclamado: j['reclamado'] == true,
        coincidencias: [
          for (final c in (j['coincidencias'] as List? ?? const []))
            Coincidencia.fromJson(c as Map<String, dynamic>),
        ],
      );
}
