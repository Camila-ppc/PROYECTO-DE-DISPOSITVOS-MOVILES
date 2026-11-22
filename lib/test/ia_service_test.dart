import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ucb_perdidos/services/ia_service.dart';

String _respuestaOpenAi(Map<String, String> datos) => jsonEncode({
      'choices': [
        {
          'message': {'content': jsonEncode(datos)},
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

  test('envía foto y texto OCR a OpenAI y devuelve título y descripción',
      () async {
    IaService.claveParaPruebas = 'sk-prueba';
    late http.Request enviada;
    IaService.cliente = MockClient((req) async {
      enviada = req;
      return http.Response(
        _respuestaOpenAi(
            {'titulo': 'Mochila azul', 'descripcion': 'Marca Totto, con llavero.'}),
        200,
      );
    });

    final r = await IaService.describirFoto(foto, textoOcr: 'TOTTO');

    expect(r['titulo'], 'Mochila azul');
    expect(r['descripcion'], 'Marca Totto, con llavero.');
    expect(enviada.headers['Authorization'], 'Bearer sk-prueba');
    final cuerpo = jsonDecode(enviada.body) as Map<String, dynamic>;
    expect(cuerpo['model'], isNotEmpty);
    expect(enviada.body, contains('data:image/png;base64,'));
    expect(enviada.body, contains('TOTTO'));
  });

  test('sin API key avisa cómo configurarla', () async {
    IaService.claveParaPruebas = '';
    expect(
      () => IaService.describirFoto(foto),
      throwsA(isA<IaException>()
          .having((e) => e.mensaje, 'mensaje', contains('OPENAI_API_KEY'))),
    );
  });

  test('traduce errores de OpenAI a mensajes claros', () {
    expect(() => IaService.interpretar(401, ''),
        throwsA(isA<IaException>()));
    expect(() => IaService.interpretar(429, ''),
        throwsA(isA<IaException>()));
    expect(() => IaService.interpretar(500, ''),
        throwsA(isA<IaException>()));
    expect(() => IaService.interpretar(200, '{"choices": []}'),
        throwsA(isA<IaException>()));
  });
}
