/// An exception whose [message] is safe to show to the user.
///
/// Translation backends raise this instead of letting raw failures escape:
/// a `PlatformException` carries a native stack trace, and an HTTP error can
/// carry request details. Neither belongs in the UI, and neither should ever
/// expose the API key or the translated text.
class TranslationException implements Exception {
  /// A short, human-readable explanation suitable for display.
  final String message;

  /// The underlying failure, kept for debugging only — never displayed.
  final Object? cause;

  const TranslationException(this.message, {this.cause});

  @override
  String toString() =>
      'TranslationException: $message${cause == null ? '' : ' (cause: $cause)'}';
}
