import '../models/item.dart';

class BusquedaService {
  static List<Item> buscar(List<Item> items, String texto) {
    final consulta = texto.trim().toLowerCase();

    if (consulta.isEmpty) return List<Item>.of(items);

    return items.where((item) {
      return item.titulo.toLowerCase().contains(consulta) ||
          item.descripcion.toLowerCase().contains(consulta) ||
          item.lugar.toLowerCase().contains(consulta);
    }).toList();
  }
}
