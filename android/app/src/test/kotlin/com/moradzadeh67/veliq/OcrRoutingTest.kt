package com.moradzadeh67.veliq

import org.junit.Assert.assertEquals
import org.junit.Test

class OcrRoutingTest {

    @Test
    fun `auto source trusts ML Kit when confidence is above trust threshold`() {
        val result = chooseOcrResult(
            mlKitText = "Hello World",
            mlKitConf = 0.85f,
            tessText = "سلام",
            tessConf = 0.60f,
            sourceLanguage = "auto",
        )

        assertEquals("Hello World", result.text)
        assertEquals(0.85f, result.chosenConfidence, 0.001f)
        assertEquals(0.85f, result.mlKitConfidence, 0.001f)
    }

    @Test
    fun `auto source falls back to Tesseract when ML Kit confidence is low`() {
        val result = chooseOcrResult(
            mlKitText = "abc junk",
            mlKitConf = 0.40f,
            tessText = "سلام دنیا",
            tessConf = 0.80f,
            sourceLanguage = "auto",
        )

        assertEquals("سلام دنیا", result.text)
        assertEquals(0.80f, result.chosenConfidence, 0.001f)
        assertEquals(0.40f, result.mlKitConfidence, 0.001f)
        assertEquals(0.80f, result.tessConfidence, 0.001f)
    }

    @Test
    fun `auto source returns empty text when both confidences are below min accept`() {
        val result = chooseOcrResult(
            mlKitText = "junk1",
            mlKitConf = 0.20f,
            tessText = "junk2",
            tessConf = 0.25f,
            sourceLanguage = "auto",
        )

        assertEquals("", result.text)
        assertEquals(0.00f, result.chosenConfidence, 0.001f)
    }

    @Test
    fun `explicit Tesseract language routes to Tesseract and enforces min accept`() {
        val accepted = chooseOcrResult(
            mlKitText = "unused",
            mlKitConf = 0.90f,
            tessText = "سلام",
            tessConf = 0.60f,
            sourceLanguage = "fa",
        )
        assertEquals("سلام", accepted.text)

        val rejected = chooseOcrResult(
            mlKitText = "unused",
            mlKitConf = 0.90f,
            tessText = "junk",
            tessConf = 0.20f,
            sourceLanguage = "fa",
        )
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
        assertEquals("Bonjour", accepted.text)

        val rejected = chooseOcrResult(
            mlKitText = "junk",
            mlKitConf = 0.20f,
            tessText = "unused",
            tessConf = 0.90f,
            sourceLanguage = "fr",
        )
        assertEquals("", rejected.text)
    }
}
