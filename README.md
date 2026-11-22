# UCB Perdidos
App móvil (Flutter) para reportar y encontrar objetos perdidos en la universidad, con IA.

## Qué hace
- **Publicar** un objeto perdido o encontrado, con foto (cámara o galería) y lugar (se puede escanear el QR de un punto de entrega).
- **OCR local (ML Kit, Android):** al elegir la foto se lee el texto (marca, nombre en un carnet, serie). Funciona sin internet.
- **IA con Gemini (visión):** el botón "IA" manda la foto + el texto del OCR y rellena *qué es*, *descripción* y *categoría*.
- **Coincidencias con IA:** al publicar, Gemini compara el objeto con los del tipo contrario ("perdí" vs "encontré") y muestra un porcentaje y el motivo. Si no hay IA, usa un cálculo local por palabras.
- **Avisos dentro de la app** (campana) cuando hay una coincidencia fuerte (70% o más).
- **Reclamar un objeto** con una pregunta de verificación; la IA acepta respuestas equivalentes ("colorado" = "rojo").
- **Buscar y filtrar** por texto (incluye el texto leído por OCR) y por categoría.
- **Guardado en el teléfono:** las publicaciones y avisos no se pierden al cerrar la app.
- Modo claro/oscuro automático.

## Correr
1. `flutter pub get`
2. Crea una API key en https://aistudio.google.com/apikey
3. Corre pasando la clave (NO la pegues en el código ni la subas a GitHub):

```
flutter run --dart-define=GEMINI_API_KEY=tu-clave
```

Opcional: `--dart-define=GEMINI_MODEL=gemini-3.5-flash-lite` (es el modelo por defecto).

> Una clave dentro de un APK se puede extraer. Para la demo está bien; en producción
> las llamadas a Gemini deben pasar por un backend.

## Límites actuales
- Los datos viven en **cada teléfono** (no se comparten entre usuarios). Para eso hace falta un backend o Firebase.
- Los avisos son **dentro de la app**, no notificaciones push del sistema (también requieren backend).
- El OCR con ML Kit solo funciona en Android.

## Tests
`flutter test`

## Roadmap
- [x] Publicar objeto con foto
- [x] OCR local con ML Kit (Android) integrado al publicar
- [x] IA real (Gemini) para describir la foto y elegir categoría
- [x] Coincidencias perdido <-> encontrado con IA
- [x] Guardado local, avisos en la app, filtros por categoría
- [ ] Backend / base de datos compartida entre usuarios
- [ ] Notificaciones push
- [ ] Login con correo universitario
