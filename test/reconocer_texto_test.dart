import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ucb_perdidos/main.dart';
import 'package:ucb_perdidos/screens/reconocer_texto_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const selector = MethodChannel('plugins.flutter.io/image_picker');
  const ocr = MethodChannel('ucb_perdidos/ocr');
  const foto = 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png';
  final botonReconocer = find.byWidgetPredicate(
    (widget) => widget is FilledButton,
  );

  Future<void> abrirGaleria(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReconocerTextoScreen()));
    await tester.tap(find.text('Seleccionar de la galería'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    // Simulamos el selector y ML Kit para probar la pantalla sin un teléfono.
    mensajero.setMockMethodCallHandler(selector, (_) async => foto);
  });

  tearDown(() {
    mensajero.setMockMethodCallHandler(selector, null);
    mensajero.setMockMethodCallHandler(ocr, null);
    mensajero.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('abre el OCR desde inicio y avisa si se deniega la cámara',
      (tester) async {
    mensajero.setMockMethodCallHandler(selector, (llamada) async {
      expect(llamada.arguments['source'], ImageSource.camera.index);
      throw PlatformException(code: 'camera_access_denied');
    });
    await tester.pumpWidget(const PerdidosApp());
    await tester.tap(find.byTooltip('Reconocer texto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar fotografía'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Permite el acceso a la cámara'), findsOneWidget);
    expect(tester.widget<FilledButton>(botonReconocer).onPressed, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('muestra la foto, espera al OCR y copia el texto', (
    tester,
  ) async {
    final lectura = Completer<String>();
    mensajero.setMockMethodCallHandler(ocr, (llamada) async {
      expect(llamada.method, 'reconocerTexto');
      expect(llamada.arguments, foto);
      return lectura.future;
    });
    String? textoCopiado;
    mensajero.setMockMethodCallHandler(SystemChannels.platform, (
      llamada,
    ) async {
      if (llamada.method == 'Clipboard.setData') {
        textoCopiado = llamada.arguments['text'];
      }
      return null;
    });

    await abrirGaleria(tester);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(botonReconocer);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    lectura.complete('Biblioteca UCB\nLa Paz');
    await tester.pumpAndSettle();
    expect(find.text('Biblioteca UCB\nLa Paz'), findsOneWidget);
    await tester.ensureVisible(find.text('Copiar texto'));
    await tester.tap(find.text('Copiar texto'));
    await tester.pump();
    expect(textoCopiado, 'Biblioteca UCB\nLa Paz');
  });

  testWidgets('avisa si la foto está vacía y permite reintentar si falla', (
    tester,
  ) async {
    await abrirGaleria(tester);
    mensajero.setMockMethodCallHandler(ocr, (_) async => '  ');
    await tester.tap(botonReconocer);
    await tester.pumpAndSettle();
    expect(find.textContaining('No se detectó texto'), findsOneWidget);
    expect(find.text('Copiar texto'), findsNothing);

    mensajero.setMockMethodCallHandler(
      ocr,
      (_) => throw PlatformException(code: 'imagen'),
    );
    await tester.tap(botonReconocer);
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo leer la imagen'), findsOneWidget);
    expect(tester.widget<FilledButton>(botonReconocer).onPressed, isNotNull);
  });

  testWidgets('cancelar la selección deja el reconocimiento desactivado', (
    tester,
  ) async {
    mensajero.setMockMethodCallHandler(selector, (_) async => null);
    await abrirGaleria(tester);
    expect(tester.widget<FilledButton>(botonReconocer).onPressed, isNull);
    expect(find.text('Copiar texto'), findsNothing);
  });
}
