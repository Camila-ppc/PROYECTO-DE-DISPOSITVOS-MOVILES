package com.example.ucb_perdidos

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val mensajero = flutterEngine.dartExecutor.binaryMessenger
        // Cargamos la foto fuera del hilo que dibuja la pantalla.
        val canal = MethodChannel(
            mensajero, "ucb_perdidos/ocr", StandardMethodCodec.INSTANCE,
            mensajero.makeBackgroundTaskQueue()
        )
        canal.setMethodCallHandler { llamada, respuesta ->
            if (llamada.method == "reconocerTexto") {
                reconocerTexto(llamada.arguments as String, respuesta)
            } else {
                respuesta.notImplemented()
            }
        }
    }

    private fun reconocerTexto(ruta: String, respuesta: MethodChannel.Result) {
        try {
            val imagen = InputImage.fromFilePath(applicationContext, Uri.fromFile(File(ruta)))
            val lector = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            lector.process(imagen).addOnCompleteListener { tarea ->
                // El resultado conserva los saltos de línea del documento.
                lector.close()
                if (tarea.isSuccessful) {
                    respuesta.success(tarea.result.text)
                } else {
                    respuesta.error("ocr", "No se pudo reconocer el texto.", null)
                }
            }
        } catch (_: Exception) {
            respuesta.error("imagen", "No se pudo abrir la imagen.", null)
        }
    }
}
