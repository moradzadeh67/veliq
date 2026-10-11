/// A single recorded translation, persisted in the local history.
class TranslationEntry {
  final String id;
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime createdAt;

  const TranslationEntry({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TranslationEntry.fromJson(Map<String, dynamic> json) {
    return TranslationEntry(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TranslationEntry &&
        other.id == id &&
        other.originalText == originalText &&
        other.translatedText == translatedText &&
        other.sourceLanguage == sourceLanguage &&
        other.targetLanguage == targetLanguage &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalText,
    translatedText,
    sourceLanguage,
    targetLanguage,
    createdAt,
  );

  @override
  String toString() =>
      'TranslationEntry(id: $id, originalText: $originalText, '
      'translatedText: $translatedText, sourceLanguage: $sourceLanguage, '
      'targetLanguage: $targetLanguage, createdAt: $createdAt)';
}
