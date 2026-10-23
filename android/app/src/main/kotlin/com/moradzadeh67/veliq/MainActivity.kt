package com.moradzadeh67.veliq

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume

class MainActivity : FlutterActivity() {
    private var galleryChoice: CompletableDeferred<Uri?>? = null
    private var cameraChoice: Continuation<Uri?>? = null
    private var cameraPermission: Continuation<Boolean>? = null
    private var cameraFileUri: Uri? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Only the two APIs the Android flow uses are registered (D-016).
        ImageSourceApi.setUp(messenger, AndroidImageSourceApi())
        OcrApi.setUp(messenger, AndroidOcrApi(applicationContext))
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            val granted =
                grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            cameraPermission?.resume(granted)
            cameraPermission = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            REQUEST_PICK_IMAGE -> {
                val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
                galleryChoice?.complete(uri)
                galleryChoice = null
            }
            REQUEST_TAKE_PHOTO -> {
                val uri = if (resultCode == Activity.RESULT_OK) cameraFileUri else null
                cameraChoice?.resume(uri)
                cameraChoice = null
                cameraFileUri = null
            }
            else -> super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private inner class AndroidImageSourceApi : ImageSourceApi {
        /// Android Photo Picker: no storage permission is requested, and the
        /// picker only shows the images the user chooses to grant access to.
        /// Cancelling resolves to null, which the Dart side treats as "no image".
        override suspend fun pickImageFromGallery(): ByteArray? {
            val choice = CompletableDeferred<Uri?>()
            galleryChoice = choice
            startActivityForResult(newGalleryIntent(), REQUEST_PICK_IMAGE)
            val uri = choice.await() ?: return null
            return withContext(Dispatchers.IO) { uriToJpeg(uri) }
        }

        /// Full-quality capture through a temporary FileProvider-backed file.
        /// The CAMERA permission is requested the first time only; denying it
        /// (or cancelling the camera app) resolves to null -> Flutter Idle.
        override suspend fun takePhotoWithCamera(): ByteArray? {
            if (!ensureCameraPermission()) return null

            val file = File(cacheDir, "photos/veliq_capture_${System.currentTimeMillis()}.jpg")
            file.parentFile?.mkdirs()
            val uri = FileProvider.getUriForFile(this@MainActivity, "$packageName.fileprovider", file)
            cameraFileUri = uri
            val result = suspendCancellableCoroutine<Uri?> { continuation ->
                cameraChoice = continuation
                val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                    putExtra(MediaStore.EXTRA_OUTPUT, uri)
                    addFlags(
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                }
                startActivityForResult(intent, REQUEST_TAKE_PHOTO)
            }
            val bytes = result?.let { withContext(Dispatchers.IO) { uriToJpeg(it) } }
            // The temp file is ours; drop it whether the shot succeeded or not.
            withContext(Dispatchers.IO) { file.delete() }
            return bytes
        }
    }

    private suspend fun ensureCameraPermission(): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return true
        }
        return suspendCancellableCoroutine { continuation ->
            cameraPermission = continuation
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                REQUEST_CAMERA_PERMISSION,
            )
        }
    }

    private fun newGalleryIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Intent(MediaStore.ACTION_PICK_IMAGES)
        } else {
            // The Photo Picker intent only exists on API 33+; ACTION_GET_CONTENT
            // with image/* is the recommended pre-33 equivalent and still shows
            // the system photo picker on modern devices.
            Intent(Intent.ACTION_GET_CONTENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/*"
            }
        }

    private fun uriToJpeg(uri: Uri): ByteArray? = try {
        contentResolver.openInputStream(uri)?.use { input ->
            val bitmap = BitmapFactory.decodeStream(input) ?: return null
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 92, out)
            out.toByteArray()
        }
    } catch (e: SecurityException) {
        // The chosen image can become unreadable if the grant is revoked while
        // the picker is open; treat it as a cancelled pick.
        null
    } catch (e: Exception) {
        null
    }

    companion object {
        private const val REQUEST_PICK_IMAGE = 0x5651
        private const val REQUEST_TAKE_PHOTO = 0x5652
        private const val REQUEST_CAMERA_PERMISSION = 0x5653
    }
}

/// On-device OCR for Android (T-136, T-163).
///
/// Two engines, because no single one covers the languages Veliq offers:
///  * **ML Kit** ships a bundled Latin model (`en, de, fr, es, it, pt, nl, tr`)
///    and needs no download — it stays the default.
///  * **Tesseract** reads what ML Kit has no model for: Persian/Arabic
///    (`fas`, `ara`) and Cyrillic (`rus`). Its traineddata files are bundled as
///    assets and copied to app storage on first use, so it runs offline too.
///
/// The image stays in memory: JPEG bytes -> [Bitmap] -> engine; nothing is
/// written to disk, logged or sent anywhere.
private class AndroidOcrApi(private val context: Context) : OcrApi {
    private val latinRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    private var tesseract: TessBaseAPI? = null
    private var tesseractLanguage: String? = null

    override suspend fun recognizeText(imageBytes: ByteArray, languageHint: String?): String? =
        withContext(Dispatchers.IO) {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: throw IllegalArgumentException(
                    "Could not read the image (invalid or corrupt image data).",
                )

            val hint = languageHint?.lowercase()
            val tesseractForHint = hint?.let { TESSERACT_LANGUAGES[it] }
            if (tesseractForHint != null) {
                return@withContext tesseract(bitmap, tesseractForHint)
            }

            val latin = latin(bitmap)
            if (latin != null) return@withContext latin

            // Auto-detect on a photo ML Kit could not read at all: try the
            // non-Latin scripts we bundle. Slower, so only as a fallback.
            tesseract(bitmap, FALLBACK_LANGUAGE)
        }

    private suspend fun latin(bitmap: Bitmap): String? {
        val result = try {
            Tasks.await(latinRecognizer.process(InputImage.fromBitmap(bitmap, 0)))
        } catch (e: Exception) {
            // Surface a readable message through Pigeon instead of a raw ML Kit
            // stack trace; the Dart side shows it as the failure state.
            throw IllegalStateException(
                "On-device text recognition failed: ${e.message}",
                e,
            )
        }
        return result.text.ifEmpty { null }
    }

    @Synchronized
    private fun tesseract(bitmap: Bitmap, language: String): String? {
        val engine = try {
            tesseractFor(language)
        } catch (e: Exception) {
            throw IllegalStateException(
                "On-device text recognition failed: ${e.message}",
                e,
            )
        }

        return try {
            engine.setImage(bitmap)
            engine.getUTF8Text()?.trim()?.ifEmpty { null }
        } finally {
            engine.clear()
        }
    }

    /// One engine per language string; re-initialising for every photo would
    /// re-read the traineddata each time.
    private fun tesseractFor(language: String): TessBaseAPI {
        tesseract?.let { existing ->
            if (tesseractLanguage == language) return existing
            existing.recycle()
        }

        copyTrainedData(language)
        val engine = TessBaseAPI()
        val dataPath = tesseractRoot().absolutePath
        if (!engine.init(dataPath, language)) {
            engine.recycle()
            throw IllegalStateException("Could not load the $language OCR data.")
        }
        engine.pageSegMode = TessBaseAPI.PageSegMode.PSM_AUTO
        tesseract = engine
        tesseractLanguage = language
        return engine
    }

    private fun tesseractRoot() = File(context.filesDir, "tesseract")

    /// Tesseract reads `tessdata/*.traineddata` from real files, not assets.
    private fun copyTrainedData(language: String) {
        val dir = File(tesseractRoot(), "tessdata")
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("Could not create the OCR data folder.")
        }
        for (code in language.split("+")) {
            val target = File(dir, "$code.traineddata")
            if (target.length() > 0) continue
            context.assets.open("tessdata/$code.traineddata").use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            }
        }
    }

    /// Languages Veliq can read on Android (D-018). ML Kit Latin plus the
    /// Tesseract scripts that are bundled; CJK is not bundled yet, so those
    /// stay disabled in Settings.
    override suspend fun supportedLanguages(): List<String> =
        listOf("en", "de", "fr", "es", "it", "pt", "nl", "tr", "fa", "ar", "ru")

    private companion object {
        /// Source language -> Tesseract language code.
        val TESSERACT_LANGUAGES = mapOf(
            "fa" to "fas",
            "ar" to "ara",
            "ru" to "rus",
        )

        /// Tried when the source is `auto` and ML Kit read nothing at all.
        const val FALLBACK_LANGUAGE = "rus+fas+ara"
    }
}
