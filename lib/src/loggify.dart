import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Opinionated, only one logger per app.
class Loggify {
  static Loggify? _instance;
  final Logger _log;
  final StringBuffer _dumpBuffer;

  const Loggify._({required StringBuffer dumpBuffer, required Logger logger})
    : _dumpBuffer = dumpBuffer,
      _log = logger;

  factory Loggify.init({required String loggerName}) {
    if (_instance == null) {
      hierarchicalLoggingEnabled = true;
      final dumpBuffer = StringBuffer();
      final logger = Logger(loggerName);
      _instance = Loggify._(dumpBuffer: dumpBuffer, logger: logger);
      logger.onRecord.listen((record) {
        final outputString = StringBuffer();
        switch (record.level) {
          case Level.SHOUT:
            outputString.write("\x1B[41m"); // Red background
          case Level.SEVERE:
            outputString.write("\x1B[31m"); // Red foreground
          case Level.WARNING:
            outputString.write("\x1B[33m"); // Yellow foreground
          case Level.INFO:
            outputString.write("\x1B[35m"); // Magenta background
          case Level.CONFIG:
            outputString.write("\x1B[36m"); // Cyan foreground
          case Level.FINE:
            outputString.write("\x1B[1;92m"); // Green bold intense foreground
          case Level.FINER:
          case Level.FINEST:
            outputString.write("\x1B[0;32m"); // Green foreground
        }
        outputString.write(
          '${record.level.name}: ${record.time}: ${record.message}',
        );
        final errorObj = record.error;
        if (errorObj != null) {
          outputString.write("\n$errorObj");
        }
        if (record.stackTrace != null) {
          outputString.write("\nStacktrace: ${record.stackTrace}");
        }
        outputString.write("\x1B[0m");
        dumpBuffer.write(outputString.toString());
        if (kDebugMode) {
          debugPrint(outputString.toString());
        }
      });
    }
    return _instance!;
  }
  static void dispose() async {
    _instance?._log.clearListeners();
    _instance = null;
  }

  static String? get getLogDump => _instance?._dumpBuffer.toString();

  static Logger? get getLogger => _instance?._log;
}
