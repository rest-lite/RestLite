import 'dart:async';
import 'dart:isolate';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rest_lite/restic/task_manager.dart';
import 'package:rest_lite/views/setting_view/setting_view.dart';
import 'package:rxdart/rxdart.dart';

import '../../pages/view_navigator.dart';
import '../../restic/json_type.dart';
import '../../restic/tasks.dart';
import '../../services/periodic.dart';
import '../../services/restic.dart';
import '../../util/string.dart';
import 'directory_viewer.dart';
import 'util.dart';

final log = Logger('BackupView');

class BackupView extends StatefulWidget {
  const BackupView({
    required this.loginContext,
    required this.settingContext,
    required this.pageBuild,
    super.key,
  });

  final LoginContext loginContext;
  final SettingContext settingContext;
  final PageBuild pageBuild;
  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  final _nodesStreamController = StreamController<Set<Node>>();
  final _backingUpStreamController = StreamController<BackupOutput>();
  late final StreamSubscription _backupServiceSubscription;
  late final StreamSubscription _retentionCheckSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFiles();
      _backupServiceSubscription = BackupService.onCycleFinished.listen((_) {
        _loadFiles();
      });
      _retentionCheckSubscription =
          BackupRetentionCheckService.onCycleFinished.listen((_) {
        _loadFiles();
      });
    });
  }

  @override
  void didUpdateWidget(covariant BackupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loginContext != widget.loginContext) {
      _loadFiles();
    }
  }

  @override
  void dispose() {
    _nodesStreamController.close();
    _backingUpStreamController.close();
    _backupServiceSubscription.cancel();
    _retentionCheckSubscription.cancel();
    super.dispose();
  }

  final Set<Node> nodes = {};
  late final _nodesStream = _nodesStreamController.stream
      .throttleTime(
    const Duration(milliseconds: 500),
    trailing: true,
  )
      .asyncMap((data) async {
    return await Isolate.run(() => buildDirectoryTree(data));
  });
  List<Snapshot>? snapshots;

  void _loadFiles() async {
    snapshots = await loadSnapshots(
      widget.loginContext.savePath,
      widget.loginContext.password,
      context,
    );

    // 刷新snapshots信息
    setState(() {});

    nodes.clear();
    if (snapshots?.isEmpty ?? false) {
      _nodesStreamController.add(nodes);
    }

    for (var snapshot in snapshots!) {
      loadFiles(
        widget.loginContext.savePath,
        snapshot.id,
        widget.loginContext.password,
        widget.settingContext.backupPaths
            .map((v) => toLinuxStylePath(v))
            .toSet(),
        nodes,
        _nodesStreamController,
        context,
      );
    }
  }

  late final _backingUpStream = _backingUpStreamController.stream.throttleTime(
    const Duration(milliseconds: 500),
    trailing: true,
  );
  bool _isBackingUp = false;
  TaskControl<BackupOutput>? backupTask;
  Future<void> _backup() async {
    if (widget.settingContext.backupPaths.isEmpty) {
      _showMyDialog();
      return;
    }
    setState(() {
      _isBackingUp = true;
    });

    backupTask = resticService.addTask(BackupTask(
        context.tr("backup_view.backup_task_name"),
        widget.settingContext.backupPaths,
        widget.loginContext.savePath,
        widget.loginContext.password));

    await for (final data in backupTask!.stream) {
      switch (data) {
        case Msg<BackupOutput> value:
          _backingUpStreamController.add(value.data);
          break;
        case MakeWay<BackupOutput>():
          break;
        case Done<BackupOutput>():
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr("backup_view.backup_success")),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: context.tr("ok"),
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ));
          break;
        case Cancel<BackupOutput>():
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr("backup_view.backup_cancel")),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            action: SnackBarAction(
              label: context.tr("ok"),
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ));
          break;
      }
    }

    _loadFiles();
    setState(() {
      _isBackingUp = false;
    });
  }

  void _cancel() {
    backupTask?.cancel();
    setState(() {
      _isBackingUp = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _nodesStream,
      builder: (context, snapshot) {
        Widget directoryViewer = const Center(
          child: CircularProgressIndicator(),
        );
        if (snapshot.data != null) {
          if ((snapshot.data!.children?.isEmpty ?? true)) {
            directoryViewer = Center(
              child: Text(context.tr("backup_view.no_snapshots")),
            );
          } else {
            directoryViewer = DirectoryViewer(
              root: snapshot.data!,
              loadDirectory: (dir) async {
                for (var value in snapshots!) {
                  loadFiles(
                    widget.loginContext.savePath,
                    value.id,
                    widget.loginContext.password,
                    {dir},
                    nodes,
                    _nodesStreamController,
                    context,
                  );
                }
              },
              showDetail: (path) => widget.pageBuild.buildFileDetailPage(path),
            );
          }
        }
        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Column(
                      children: [
                        OutlinedButton(
                            onPressed: _isBackingUp ? null : _backup,
                            child:
                                Text(context.tr("backup_view.start_backup"))),
                        if (_isBackingUp)
                          const SizedBox(
                            height: 8,
                          ),
                        if (_isBackingUp)
                          OutlinedButton(
                              onPressed: _cancel,
                              child: Text(
                                  context.tr("backup_view.cancel_backup"))),
                      ],
                    ),
                    if (_isBackingUp)
                      const SizedBox(
                        width: 8,
                      ),
                    Offstage(
                      offstage: !_isBackingUp,
                      child: StreamBuilder(
                          stream: _backingUpStream,
                          builder: (context, snapshot) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.tr("backup_view.seconds_elapsed",
                                    namedArgs: {
                                      "second": snapshot.data?.secondsElapsed
                                              .toString() ??
                                          ""
                                    })),
                                Text(context
                                    .tr("backup_view.total_files", namedArgs: {
                                  "number":
                                      snapshot.data?.totalFiles.toString() ?? ""
                                })),
                                Text(context
                                    .tr("backup_view.files_done", namedArgs: {
                                  "number":
                                      snapshot.data?.filesDone.toString() ?? ""
                                })),
                              ],
                            );
                          }),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Column(
                      children: [
                        Text(context.tr("backup_view.snapshot_number",
                            namedArgs: {
                              "number": snapshots?.length.toString() ?? ""
                            })),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: directoryViewer)
          ],
        );
      },
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(context.tr("backup_view.backup_target_empty_dialog_title")),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(context.tr("backup_view.backup_target_empty_dialog_text")),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr("confirm")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
