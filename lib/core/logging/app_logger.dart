import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static void debug(String message) {
    developer.log(message, name: 'ArtrosiCane');
  }
}
