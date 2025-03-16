import 'package:rest_lite/restic/task_manager.dart';

class ResticService {
  static late TaskManager taskManager;

  static void init(int maxConcurrency) {
    taskManager = TaskManager(maxConcurrency);
  }
}
