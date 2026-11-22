import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucb_perdidos/models/alerta.dart';
import 'package:ucb_perdidos/models/item.dart';
import 'package:ucb_perdidos/services/busqueda_service.dart';
import 'package:ucb_perdidos/services/ia_service.dart';
import 'package:ucb_perdidos/services/match_service.dart';
import 'package:ucb_perdidos/services/storage_service.dart';
import 'package:ucb_perdidos/services/texto_util.dart';
import 'package:ucb_perdidos/services/verificacion_service.dart';

Item _item(
  String id,
  String titulo, {
  bool encontrado = false,
  String desc = '',
  String cat = 'Otros',
  String lugar = '',
  bool reclamado = false,
}) =>
    Item(
      id: id,
      titulo: titulo,
      descripcion: desc,
      lugar: lugar,
      encontrado: encontrado,
      categoria: cat,
      reclamado: reclamado,
    );

/// Respuesta con el formato que devuelve Gemini.
String _gemini(Object datos) => jsonEncode({
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
  tearDown(() {
    IaService.claveParaPruebas = null;
    IaService.cliente = http.Client();
  });

  group('texto', () {
    test('normalizar quita tildes, signos y mayúsculas', () {
      expect(normalizar('Mochila ÁZUL, Ñandú!'), 'mochila azul nandu');
    });

    test('la búsqueda ignora tildes y filtra por categoría', () {
      final items = [
        _item('1', 'Cámara Canon', cat: 'Electrónicos'),
        _item('2', 'Camisa roja', cat: 'Ropa'),
      ];
      expect(BusquedaService.buscar(items, 'camara').map((i) => i.id), ['1']);
      expect(BusquedaService.buscar(items, '', categoria: 'Ropa').map((i) => i.id),
          ['2']);
      expect(BusquedaService.buscar(items, '').length, 2);
    });
  });

  group('modelo y guardado', () {
    test('Item se convierte a JSON y vuelve igual', () {
      final original = _item('7', 'Llaves', cat: 'Llaves', lugar: 'Biblioteca')
        ..reclamado = true
        ..coincidencias = [
          const Coincidencia(itemId: '8', puntaje: 77, motivo: 'Llavero rojo'),
        ];
      final copia = Item.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(copia.titulo, 'Llaves');
      expect(copia.categoria, 'Llaves');
      expect(copia.reclamado, isTrue);
      expect(copia.coincidencias.single.puntaje, 77);
      expect(copia.coincidencias.single.motivo, 'Llavero rojo');
    });

    test('las publicaciones y avisos sobreviven al reiniciar', () async {
      SharedPreferences.setMockInitialValues({});
      await StorageService.guardar(
        [_item('1', 'Mochila')],
        [Alerta(id: 'a', mensaje: 'Aviso', itemId: '1', puntaje: 80)],
      );
      final datos = await StorageService.cargar();
      expect(datos.items.single.titulo, 'Mochila');
      expect(datos.alertas.single.puntaje, 80);
    });

    test('sin datos guardados devuelve listas vacías', () async {
      SharedPreferences.setMockInitialValues({});
      final datos = await StorageService.cargar();
      expect(datos.items, isEmpty);
      expect(datos.alertas, isEmpty);
    });
  });

  group('coincidencias', () {
    final perdido = _item('1', 'Mochila azul',
        desc: 'Marca Totto con llavero', cat: 'Mochilas y bolsos');
    final parecido = _item('2', 'Mochila azul',
        encontrado: true, desc: 'Totto, cierre roto', cat: 'Mochilas y bolsos');
    final distinto =
        _item('3', 'Llaves de auto', encontrado: true, cat: 'Llaves');

    test('sin IA usa palabras en común y solo compara tipos contrarios', () async {
      IaService.claveParaPruebas = '';
      final otroPerdido = _item('4', 'Mochila azul', desc: 'Totto');
      final r = await MatchService.buscar(
          perdido, [perdido, parecido, distinto, otroPerdido]);
      expect(r.map((c) => c.itemId), ['2']);
      expect(r.first.puntaje, greaterThanOrEqualTo(MatchService.umbralLocal));
    });

    test('no propone objetos ya reclamados', () async {
      IaService.claveParaPruebas = '';
      final reclamado = _item('5', 'Mochila azul',
          encontrado: true, desc: 'Totto', cat: 'Mochilas y bolsos', reclamado: true);
      expect(await MatchService.buscar(perdido, [perdido, reclamado]), isEmpty);
    });

    test('con IA usa sus puntajes y descarta ids inventados y puntajes bajos',
        () async {
      IaService.claveParaPruebas = 'clave';
      IaService.cliente = MockClient((_) async => http.Response(
            _gemini({
              'coincidencias': [
                {'id': '2', 'puntaje': 90, 'motivo': 'Misma marca'},
                {'id': '3', 'puntaje': 20, 'motivo': 'Solo es un objeto'},
                {'id': '999', 'puntaje': 99, 'motivo': 'Inventado'},
              ],
            }),
            200,
          ));
      final r = await MatchService.buscar(perdido, [perdido, parecido, distinto]);
      expect(r.length, 1);
      expect(r.single.itemId, '2');
      expect(r.single.puntaje, 90);
      expect(r.single.motivo, 'Misma marca');
    });

    test('si la IA falla vuelve al cálculo local', () async {
      IaService.claveParaPruebas = 'clave';
      IaService.cliente = MockClient((_) async => http.Response('error', 500));
      final r = await MatchService.buscar(perdido, [perdido, parecido, distinto]);
      expect(r.map((c) => c.itemId), ['2']);
    });
  });

  group('verificación del dueño', () {
    test('acepta mayúsculas, tildes y espacios sin usar la IA', () async {
      IaService.claveParaPruebas = '';
      expect(
        await VerificacionService.respuestaCorrecta(
            pregunta: '¿Color?', esperada: 'Azúl oscuro', dada: ' azul OSCURO '),
        isTrue,
      );
    });

    test('sin IA rechaza respuestas distintas', () async {
      IaService.claveParaPruebas = '';
      expect(
        await VerificacionService.respuestaCorrecta(
            pregunta: '¿Color?', esperada: 'rojo', dada: 'azul'),
        isFalse,
      );
    });

    test('con IA acepta sinónimos y respeta cuando dice que no', () async {
      IaService.claveParaPruebas = 'clave';
      IaService.cliente = MockClient(
          (_) async => http.Response(_gemini({'coincide': true}), 200));
      expect(
        await VerificacionService.respuestaCorrecta(
            pregunta: '¿Color?', esperada: 'rojo', dada: 'colorado'),
        isTrue,
      );
      IaService.cliente = MockClient(
          (_) async => http.Response(_gemini({'coincide': false}), 200));
      expect(
        await VerificacionService.respuestaCorrecta(
            pregunta: '¿Color?', esperada: 'rojo', dada: 'verde'),
        isFalse,
      );
    });
  });
}
