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
  bool reclamado;

  Item({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.encontrado,
    this.fotoPath,
    this.pregunta,
    this.respuesta,
    this.reclamado = false,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}
