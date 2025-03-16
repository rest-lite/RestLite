import 'package:rest_lite/restic/task_manager.dart';

late final TaskManager resticService;

void init(int maxConcurrency) {
  resticService = TaskManager(maxConcurrency);
}
