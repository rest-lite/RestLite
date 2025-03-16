import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rest_lite/restic/task_manager.dart';
import 'package:rxdart/rxdart.dart';

import '../objectbox.g.dart';
import '../restic/json_type.dart';
import '../restic/tasks.dart';
import '../views/backup_view/util.dart';
import 'restic.dart';
import 'store.dart';

class Periodic {
  Completer<bool>? _completer;
  Function? _func;
  bool _running = false;

  Future<void> update(Duration duration, Function? func) async {
    _completer?.complete(false);
    _completer = null;
    _func = func;
    _running = true;

    while (_running) {
      _completer = Completer();
      Future<bool> future = _completer!.future;
      final timer = Timer((duration), () {
        _completer?.complete(true);
        _completer = null;
      });

      if (!await future) {
        timer.cancel();
        return;
      }
      _func?.call();
    }
  }

  void stop() {
    _running = false;
    _completer?.complete(false);
    _completer = null;
    _func = null;
  }
}

class BackupService {
  static late BackupService instance;
  final log = Logger('Periodic Service');

  final Periodic _periodic;
  BackupService._internal(this._periodic);

  static void init() {
    instance = BackupService._internal(Periodic());
  }

  // TODO: 尚未处理一次备份未完成时到达备份间隔立即开始第二次备份的问题
  void update(
    Duration duration,
    String repositoryPath,
    List<String> backupPaths,
    String password,
  ) {
    log.info("BackupService update");
    _periodic.update(duration, () async {
      log.info("BackupService run");

      final backupTask = ResticService.taskManager
          .addTask(BackupTask("自动备份", backupPaths, repositoryPath, password));

      final outLogController = StreamController<BackupOutput>();

      backupTask.stream.listen((v) {
        switch (v) {
          case Msg<BackupOutput> v:
            outLogController.add(v.data);
            break;
          case MakeWay<BackupOutput>():
            log.info("BackupService make way");
            break;
          case Done<BackupOutput>():
            log.fine("BackupService done");
            break;
          case Cancel<BackupOutput>():
            log.fine("BackupService cancel");
        }
      });

      outLogController.stream
          .throttleTime(
            const Duration(seconds: 5),
            trailing: true,
          )
          .listen(
              (v) => log.fine("total:${v.totalBytes} done: ${v.bytesDone}"));

      await backupTask.stream.last;
      outLogController.close();
    });
  }

  void stop() {
    log.fine("BackupService stop");
    _periodic.stop();
  }
}

class BackupRetentionCheckService {
  static late BackupRetentionCheckService instance;
  final log = Logger('DeleteService');

  final Periodic _periodic;
  BackupRetentionCheckService._internal(this._periodic);

  static void init() {
    instance = BackupRetentionCheckService._internal(Periodic());
  }

  void update(
    Duration duration,
    int keepDay,
    String repositoryPath,
    String password,
  ) {
    log.info("update");
    _periodic.update(duration, () async {
      log.info("run");

      final backupTask = ResticService.taskManager.addTask(
          DeleteSnapshotsTask("尝试删除过期备份", keepDay, repositoryPath, password));

      List<Snapshot> removes = [];
      await for (final v in backupTask.stream) {
        switch (v) {
          case Msg<ForgetGroup> v:
            removes.addAll(v.data.remove ?? []);
          case MakeWay<ForgetGroup>():
          case Cancel<ForgetGroup>():
            log.info("cancel");
          case Done<ForgetGroup>():
            log.info("done");
        }
      }
      // 移除快照缓存
      if (removes.isNotEmpty) {
        log.info("remove len:", removes.length.toString());
        final box = ObjectBox.store.box<SnapshotStore>();
        for (final v in removes) {
          final query =
              box.query(SnapshotStore_.snapshotID.equals(v.id)).build();
          box.removeMany(query.findIds());
          query.close();
          log.info("remove cache: ${v.id}");
        }
      }
    });
  }

  void stop() {
    log.fine("stop");
    _periodic.stop();
  }
}
