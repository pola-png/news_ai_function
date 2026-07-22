import 'dart:io';

void logMessage(dynamic context, String message) {
  try {
    context.log(message);
  } catch (_) {
    stderr.writeln(message);
  }
}

String truncateString(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength);
}
