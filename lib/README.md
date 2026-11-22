# UCB Perdidos
App móvil (Flutter) para reportar y encontrar objetos perdidos en la universidad, con IA.

## Cómo funciona la IA
- **OCR local (ML Kit, Android):** al elegir la foto se lee el texto (marca, nombre en un carnet, serie). Funciona sin internet.
- **IA con OpenAI (visión):** el botón "IA" manda la foto + el texto del OCR y rellena *qué es* y *descripción*.

## Correr
1. `flutter pub get`
2. Crea una API key en https://platform.openai.com/api-keys
3. Corre pasando la clave (NO la pegues en el código ni la subas a GitHub):

```
flutter run --dart-define=OPENAI_API_KEY=sk-tu-clave
```

Opcional: `--dart-define=OPENAI_MODEL=gpt-4o-mini` (es el modelo por defecto).

> Una clave dentro de un APK se puede extraer. Para la demo está bien; en producción
> las llamadas a OpenAI deben pasar por un backend.

## Tests
`flutter test`

## Roadmap
- [x] Publicar objeto con foto
- [x] OCR local con ML Kit (Android) integrado al publicar
- [x] IA real (OpenAI) para describir la foto
- [ ] Matching perdido <-> encontrado con IA
- [ ] Backend + base de datos (hoy todo vive en memoria)
- [ ] Notificaciones push
