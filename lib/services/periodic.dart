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
  static late BackupService _instance;
  final log = Logger('Periodic Service');

  final Periodic _periodic;
  BackupService._internal(this._periodic);

  static final StreamController<void> _controller =
      StreamController.broadcast();
  static final onCycleFinished = _controller.stream;

  static void init() {
    _instance = BackupService._internal(Periodic());
  }

  // TODO: 尚未处理一次备份未完成时到达备份间隔立即开始第二次备份的问题
  static void update(
    Duration duration,
    String repositoryPath,
    List<String> backupPaths,
    String password,
  ) {
    _instance.log.info("BackupService update");
    _instance._periodic.update(duration, () async {
      _instance.log.info("BackupService run");

      final backupTask = resticService
          .addTask(BackupTask("自动备份", backupPaths, repositoryPath, password));

      final outLogController = StreamController<BackupOutput>();

      backupTask.stream.listen((v) {
        switch (v) {
          case Msg<BackupOutput> v:
            outLogController.add(v.data);
          case MakeWay<BackupOutput>():
            _instance.log.info("BackupService make way");
          case Done<BackupOutput>():
            _instance.log.fine("BackupService done");
            _controller.add(null);
          case Cancel<BackupOutput>():
            _instance.log.fine("BackupService cancel");
        }
      });

      outLogController.stream
          .throttleTime(
            const Duration(seconds: 5),
            trailing: true,
          )
          .listen((v) =>
              _instance.log.fine("total:${v.totalBytes} done: ${v.bytesDone}"));

      await backupTask.stream.last;
      outLogController.close();
    });
  }

  static void stop() {
    _instance.log.fine("BackupService stop");
    _instance._periodic.stop();
  }
}

class BackupRetentionCheckService {
  static late BackupRetentionCheckService _instance;
  final log = Logger('DeleteService');

  final Periodic _periodic;
  BackupRetentionCheckService._internal(this._periodic);

  static final StreamController<void> _controller =
      StreamController.broadcast();
  static final onCycleFinished = _controller.stream;

  static void init() {
    _instance = BackupRetentionCheckService._internal(Periodic());
  }

  static void update(
    Duration duration,
    int keepDay,
    String repositoryPath,
    String password,
  ) {
    _instance.log.info("update");
    _instance._periodic.update(duration, () async {
      _instance.log.info("run");

      final backupTask = resticService.addTask(
          DeleteSnapshotsTask("尝试删除过期备份", keepDay, repositoryPath, password));

      List<Snapshot> removes = [];
      await for (final v in backupTask.stream) {
        switch (v) {
          case Msg<ForgetGroup> v:
            removes.addAll(v.data.remove ?? []);
          case MakeWay<ForgetGroup>():
          case Cancel<ForgetGroup>():
            _instance.log.info("cancel");
          case Done<ForgetGroup>():
            _instance.log.info("done");
            _controller.add(null);
        }
      }
      // 移除快照缓存
      if (removes.isNotEmpty) {
        _instance.log.info("remove len:", removes.length.toString());
        final box = store.box<SnapshotStore>();
        for (final v in removes) {
          final query =
              box.query(SnapshotStore_.snapshotID.equals(v.id)).build();
          box.removeMany(query.findIds());
          query.close();
          _instance.log.info("remove cache: ${v.id}");
        }
      }
    });
  }

  static void stop() {
    _instance.log.fine("stop");
    _instance._periodic.stop();
  }
}
