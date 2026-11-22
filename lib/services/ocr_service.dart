import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:flutter/services.dart';

/// Lee el texto de una foto con ML Kit (corre en el teléfono, sin internet).
/// El código nativo está en MainActivity.kt, canal "ucb_perdidos/ocr".
class OcrService {
  static const MethodChannel _canal = MethodChannel('ucb_perdidos/ocr');

  /// ML Kit solo está conectado en Android.
  static bool get disponible =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Devuelve el texto de la foto, o '' si no hay texto o falla la lectura.
  static Future<String> leer(String ruta) async {
    if (!disponible) return '';
    try {
      final texto = await _canal.invokeMethod<String>('reconocerTexto', ruta);
      return texto?.trim() ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }
}
