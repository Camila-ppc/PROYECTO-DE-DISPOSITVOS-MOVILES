import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ucb_perdidos/services/ia_service.dart';

String _respuestaGemini(Map<String, String> datos) => jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': jsonEncode(datos)},
            ],
          },
        },
      ],
    });

void main() {
  final foto = XFile.fromData(
    Uint8List.fromList([1, 2, 3]),
    mimeType: 'image/png',
    name: 'foto.png',
  );

  tearDown(() {
    IaService.claveParaPruebas = null;
    IaService.cliente = http.Client();
  });

  test('envía foto y texto OCR a Gemini y devuelve título y descripción',
      () async {
    IaService.claveParaPruebas = 'sk-prueba';
    late http.Request enviada;
    IaService.cliente = MockClient((req) async {
      enviada = req;
      return http.Response(
        _respuestaGemini(
            {'titulo': 'Mochila azul', 'descripcion': 'Marca Totto, con llavero.'}),
        200,
      );
    });

    final r = await IaService.describirFoto(foto, textoOcr: 'TOTTO');

    expect(r['titulo'], 'Mochila azul');
    expect(r['descripcion'], 'Marca Totto, con llavero.');
    expect(enviada.headers['x-goog-api-key'], 'sk-prueba');
    expect(enviada.url.path, contains(':generateContent'));
    expect(enviada.body, contains('"mimeType":"image/png"'));
    expect(enviada.body, contains(base64Encode([1, 2, 3])));
    expect(enviada.body, contains('TOTTO'));
  });

  test('sin API key avisa cómo configurarla', () async {
    IaService.claveParaPruebas = '';
    expect(
      () => IaService.describirFoto(foto),
      throwsA(isA<IaException>()
          .having((e) => e.mensaje, 'mensaje', contains('GEMINI_API_KEY'))),
    );
  });

  test('traduce errores de Gemini a mensajes claros', () {
    expect(() => IaService.interpretar(403, ''),
        throwsA(isA<IaException>()));
    expect(
        () => IaService.interpretar(
            400, '{"error":{"message":"API key not valid"}}'),
        throwsA(isA<IaException>()
            .having((e) => e.mensaje, 'mensaje', contains('API key not valid'))));
    expect(() => IaService.interpretar(429, ''),
        throwsA(isA<IaException>()));
    expect(() => IaService.interpretar(500, ''),
        throwsA(isA<IaException>()));
    expect(() => IaService.interpretar(200, '{"candidates": []}'),
        throwsA(isA<IaException>()));
  });
}
