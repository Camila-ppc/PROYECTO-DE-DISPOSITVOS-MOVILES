import 'dart:io';

/// MAÑANA: aquí reemplazamos el simulado por la llamada real a Gemini.
class IaService {
  static Future<Map<String, String>> describirFoto(File foto) async {
    await Future.delayed(const Duration(seconds: 1)); // simula espera de la IA
    return {
      'titulo': 'Objeto detectado (demo)',
      'descripcion': 'Descripción generada por IA: color, marca y detalles del objeto.',
    };
  }
}
