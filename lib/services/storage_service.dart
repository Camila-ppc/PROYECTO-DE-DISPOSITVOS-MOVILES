import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alerta.dart';
import '../models/item.dart';

class DatosGuardados {
  final List<Item> items;
  final List<Alerta> alertas;
  const DatosGuardados(this.items, this.alertas);
}

/// Guarda las publicaciones en el teléfono para que no se pierdan al cerrar
/// la app. (Para compartirlas entre usuarios hace falta un backend.)
class StorageService {
  static const String _clave = 'ucb_perdidos_datos_v1';

  static Future<DatosGuardados> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clave);
      if (texto == null) return const DatosGuardados([], []);
      final json = jsonDecode(texto) as Map<String, dynamic>;
      return DatosGuardados(
        [
          for (final i in (json['items'] as List? ?? const []))
            Item.fromJson(i as Map<String, dynamic>),
        ],
        [
          for (final a in (json['alertas'] as List? ?? const []))
            Alerta.fromJson(a as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      return const DatosGuardados([], []);
    }
  }

  static Future<void> guardar(List<Item> items, List<Alerta> alertas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final datos = {
        'items': [
          for (final i in items)
            // En web las fotos son enlaces temporales que no sobreviven.
            {...i.toJson(), if (kIsWeb) 'fotoPath': null},
        ],
        'alertas': [for (final a in alertas) a.toJson()],
      };
      await prefs.setString(_clave, jsonEncode(datos));
    } catch (_) {
      // Si no se puede guardar, la app sigue funcionando en memoria.
    }
  }

  /// Copia la foto a la carpeta de la app para que siga existiendo después.
  static Future<String?> guardarFoto(XFile? foto) async {
    if (foto == null) return null;
    if (kIsWeb) return foto.path;
    try {
      final base = await getApplicationDocumentsDirectory();
      final carpeta = Directory('${base.path}/fotos');
      await carpeta.create(recursive: true);
      final destino =
          '${carpeta.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(foto.path).copy(destino);
      return destino;
    } catch (_) {
      return foto.path;
    }
  }
}
