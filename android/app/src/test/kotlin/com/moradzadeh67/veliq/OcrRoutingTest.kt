package com.moradzadeh67.veliq

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class OcrRoutingTest {

    private fun text(length: Int) = "a".repeat(length)

    // --- T-168: a Tesseract result must cover enough text to compete ----------

    @Test
    fun `a short confident Tesseract fragment does not beat a long ML Kit reading`() {
        // Measured on-device: French printed, ML Kit 71 chars @0.608 lost to
        // Tesseract 3 chars @0.82 and the user saw "۲۱۹".
        val result = chooseOcrResult(
            mlKitText = text(71),
            mlKitConf = 0.608f,
            tessText = text(3),
            tessConf = 0.82f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.ML_KIT, result.engine)
        assertFalse(result.tessIsCandidate)
        assertEquals(text(71), result.text)
        assertEquals(0.608f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `a full Tesseract reading wins when its confidence is higher`() {
        val result = chooseOcrResult(
            mlKitText = text(75),
            mlKitConf = 0.469f,
            tessText = text(34),
            tessConf = 0.69f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.TESSERACT, result.engine)
        assertTrue(result.tessIsCandidate)
        assertEquals(text(34), result.text)
        assertEquals(0.69f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `Tesseract wins when ML Kit read nothing`() {
        val result = chooseOcrResult(
            mlKitText = "",
            mlKitConf = 0.0f,
            tessText = text(896),
            tessConf = 0.84f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.TESSERACT, result.engine)
        assertEquals(text(896), result.text)
        assertEquals(0.84f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `a low-confidence ML Kit reading with no Tesseract text is rejected`() {
        // Handwriting measured 0.336 / 0.357 / 0.411 on-device.
        val result = chooseOcrResult(
            mlKitText = text(39),
            mlKitConf = 0.357f,
            tessText = "",
            // meanConfidence() reports 95 even with no text at all.
            tessConf = 0.95f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.NONE, result.engine)
        assertEquals("", result.text)
        assertEquals(0.0f, result.chosenConfidence, 0.001f)
        assertFalse(result.tessIsCandidate)
    }

    @Test
    fun `trusted ML Kit is used without needing Tesseract`() {
        val result = chooseOcrResult(
            mlKitText = text(67),
            mlKitConf = 0.730f,
            tessText = "",
            tessConf = 0.0f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.ML_KIT, result.engine)
        assertEquals(text(67), result.text)
        assertEquals(0.730f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `explicit Latin language rejects a low-confidence ML Kit reading`() {
        val result = chooseOcrResult(
            mlKitText = text(28),
            mlKitConf = 0.336f,
            tessText = "unused",
            tessConf = 0.90f,
            sourceLanguage = "fr",
        )

        assertEquals(OcrEngine.NONE, result.engine)
        assertEquals("", result.text)
    }

    @Test
    fun `Tesseract below the minimum length never competes`() {
        val result = chooseOcrResult(
            mlKitText = text(60),
            mlKitConf = 0.50f,
            tessText = text(8),
            tessConf = 0.99f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.ML_KIT, result.engine)
        assertFalse(result.tessIsCandidate)
        assertEquals(text(60), result.text)
    }

    // --- retained routing coverage --------------------------------------------

    @Test
    fun `auto source trusts a high-confidence ML Kit reading`() {
        val result = chooseOcrResult(
            mlKitText = "Hello World",
            mlKitConf = 0.85f,
            tessText = "سلام دنیای من",
            tessConf = 0.60f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.ML_KIT, result.engine)
        assertEquals("Hello World", result.text)
        assertEquals(0.85f, result.chosenConfidence, 0.001f)
        assertEquals(0.85f, result.mlKitConfidence, 0.001f)
    }

    @Test
    fun `auto source falls back to Tesseract when ML Kit confidence is low`() {
        val result = chooseOcrResult(
            mlKitText = "abc junk",
            mlKitConf = 0.40f,
            tessText = "سلام دنیای من",
            tessConf = 0.80f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.TESSERACT, result.engine)
        assertEquals("سلام دنیای من", result.text)
        assertEquals(0.80f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `auto source returns empty text when both engines read nothing`() {
        val result = chooseOcrResult(
            mlKitText = "",
            mlKitConf = 0.0f,
            tessText = "",
            tessConf = 0.0f,
            sourceLanguage = "auto",
        )

        assertEquals(OcrEngine.NONE, result.engine)
        assertEquals("", result.text)
        assertEquals(0.00f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `explicit Tesseract language routes to Tesseract and enforces min accept`() {
        val accepted = chooseOcrResult(
            mlKitText = "",
            mlKitConf = 0.0f,
            tessText = "سلام",
            tessConf = 0.60f,
            sourceLanguage = "fa",
        )
        assertEquals(OcrEngine.TESSERACT, accepted.engine)
        assertEquals("سلام", accepted.text)

        val rejected = chooseOcrResult(
            mlKitText = "",
            mlKitConf = 0.0f,
            tessText = "junk",
            tessConf = 0.20f,
            sourceLanguage = "fa",
        )
        assertEquals(OcrEngine.NONE, rejected.engine)
        assertEquals("", rejected.text)
    }

    @Test
    fun `explicit Latin language routes to ML Kit and enforces min accept`() {
        val accepted = chooseOcrResult(
            mlKitText = "Bonjour",
            mlKitConf = 0.80f,
            tessText = "unused",
            tessConf = 0.90f,
            sourceLanguage = "fr",
        )
        assertEquals(OcrEngine.ML_KIT, accepted.engine)
        assertEquals("Bonjour", accepted.text)

        val rejected = chooseOcrResult(
            mlKitText = "junk",
            mlKitConf = 0.20f,
            tessText = "unused",
            tessConf = 0.90f,
            sourceLanguage = "fr",
        )
        assertEquals(OcrEngine.NONE, rejected.engine)
        assertEquals("", rejected.text)
    }
}
