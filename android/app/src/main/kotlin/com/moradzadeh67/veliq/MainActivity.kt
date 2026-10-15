package com.moradzadeh67.veliq

import android.Manifest
import android.app.Activity
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
        OcrApi.setUp(messenger, MlKitOcrApi())
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

/// On-device Latin OCR (T-136). The image stays in memory: JPEG bytes ->
/// [Bitmap] -> [InputImage]; nothing is written to disk, logs or the network.
/// The bundled ML Kit model recognizes Latin-script text (the default source
/// language is English); other scripts are a future model addition.
private class MlKitOcrApi : OcrApi {
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    override suspend fun recognizeText(imageBytes: ByteArray): String? =
        withContext(Dispatchers.IO) {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                ?: throw IllegalArgumentException(
                    "Could not read the image (invalid or corrupt image data).",
                )
            val result = try {
                Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap, 0)))
            } catch (e: Exception) {
                // Surface a readable message through Pigeon instead of a raw
                // ML Kit stack trace; the Dart side shows it as the failure state.
                throw IllegalStateException("On-device text recognition failed: ${e.message}", e)
            }
            result.text.ifEmpty { null }
        }
}
