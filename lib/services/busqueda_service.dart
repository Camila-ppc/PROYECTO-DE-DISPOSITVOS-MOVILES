import '../models/item.dart';
import 'texto_util.dart';

class BusquedaService {
  static List<Item> buscar(List<Item> items, String texto, {String? categoria}) {
    final consulta = normalizar(texto);

    return items.where((item) {
      if (categoria != null && item.categoria != categoria) return false;
      if (consulta.isEmpty) return true;
      final contenido = normalizar(
        '${item.titulo} ${item.descripcion} ${item.lugar} '
        '${item.textoOcr} ${item.categoria}',
      );
      return contenido.contains(consulta);
    }).toList();
  }
}
