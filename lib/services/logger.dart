import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

void init() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      debugPrint(
          '${record.loggerName} ${record.level.name}: ${record.time}: ${record.message}');
      if (record.level == Level.SEVERE) {
        debugPrintStack(stackTrace: record.stackTrace);
      }
    }
  });
}
