import 'dart:async';
import 'dart:core';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rest_lite/restic/task_manager.dart';
import 'package:rxdart/rxdart.dart';

import '../restic/json_type.dart';
import '../restic/tasks.dart';
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
  static BackupService? _instance;
  final log = Logger('Periodic Service');
  final Periodic periodic;
  late BuildContext context;

  BackupService._internal(this.periodic);

  static final StreamController<void> _controller =
      StreamController.broadcast();
  static final onCycleFinished = _controller.stream;

  static void build(BuildContext context) {
    _instance ??= BackupService._internal(Periodic());
    _instance!.context = context;
  }

  // TODO: 尚未处理一次备份未完成时到达备份间隔立即开始第二次备份的问题
  static void update(
    Duration duration,
    String repositoryPath,
    List<String> backupPaths,
    String password,
  ) {
    final instance = _instance;
    if (instance == null) throw Error();

    instance.log.info("BackupService update");
    instance.periodic.update(duration, () async {
      instance.log.info("BackupService run");

      final backupTask = resticService.addTask(BackupTask(
          instance.context.tr("periodic_task.auto_backup"),
          backupPaths,
          repositoryPath,
          password));

      final outLogController = StreamController<BackupOutput>();

      backupTask.stream.listen((v) {
        switch (v) {
          case Msg<BackupOutput> v:
            outLogController.add(v.data);
          case MakeWay<BackupOutput>():
            instance.log.info("BackupService make way");
          case Done<BackupOutput>():
            instance.log.fine("BackupService done");
            _controller.add(null);
          case Cancel<BackupOutput>():
            instance.log.fine("BackupService cancel");
        }
      });

      outLogController.stream
          .throttleTime(
            const Duration(seconds: 5),
            trailing: true,
          )
          .listen((v) =>
              instance.log.fine("total:${v.totalBytes} done: ${v.bytesDone}"));

      await backupTask.stream.last;
      outLogController.close();
    });
  }

  static void stop() {
    final instance = _instance;
    if (instance == null) throw Error();

    instance.log.fine("BackupService stop");
    instance.periodic.stop();
  }
}

class BackupRetentionCheckService {
  static BackupRetentionCheckService? _instance;
  final log = Logger('DeleteService');
  final Periodic periodic;
  late BuildContext context;

  BackupRetentionCheckService._internal(this.periodic);

  static final StreamController<void> _controller =
      StreamController.broadcast();
  static final onCycleFinished = _controller.stream;

  static void build(BuildContext context) {
    _instance ??= BackupRetentionCheckService._internal(Periodic());
    _instance!.context = context;
  }

  static void update(
    Duration duration,
    int keepDay,
    String repositoryPath,
    String password,
  ) {
    final instance = _instance;
    if (instance == null) throw Error();

    instance.log.info("update");
    instance.periodic.update(duration, () async {
      instance.log.info("run");

      final backupTask = resticService.addTask(DeleteSnapshotsTask(
          instance.context.tr("periodic_task.retention_check"),
          keepDay,
          repositoryPath,
          password));

      List<Snapshot> removes = [];
      await for (final v in backupTask.stream) {
        switch (v) {
          case Msg<ForgetGroup> v:
            removes.addAll(v.data.remove ?? []);
          case MakeWay<ForgetGroup>():
          case Cancel<ForgetGroup>():
            instance.log.info("cancel");
          case Done<ForgetGroup>():
            instance.log.info("done");
            _controller.add(null);
        }
      }
      // 移除快照缓存
      if (removes.isNotEmpty) {
        for (final v in removes) {
          store.deleteFileListCachedData(v.id);
        }
      }
    });
  }

  static void stop() {
    final instance = _instance;
    if (instance == null) throw Error();

    instance.log.fine("stop");
    instance.periodic.stop();
  }
}
