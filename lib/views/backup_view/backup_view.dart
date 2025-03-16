import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rest_lite/restic/task_manager.dart';
import 'package:rest_lite/views/setting_view/setting_view.dart';
import 'package:rxdart/rxdart.dart';

import '../../pages/home_navigator.dart';
import '../../restic/json_type.dart';
import '../../restic/tasks.dart';
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
  @override
  void initState() {
    super.initState();
    _loadFiles();
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
    super.dispose();
  }

  final _nodesStreamController = StreamController<Set<Node>>();
  late final _nodesStream = _nodesStreamController.stream
      .throttleTime(
    const Duration(milliseconds: 500),
    trailing: true,
  )
      .asyncMap((data) async {
    return await Isolate.run(() => buildDirectoryTree(data));
  });
  final Set<Node> nodes = {};
  List<Snapshot>? snapshots;

  void _loadFiles() async {
    snapshots = await loadSnapshots(
      widget.loginContext.savePath,
      widget.loginContext.password,
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
      );
    }
  }

  final _backingUpStreamController = StreamController<BackupOutput>();
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
        "主动备份",
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
            content: const Text('备份完成'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: '好的',
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ));
          break;
        case Cancel<BackupOutput>():
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('备份取消'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            action: SnackBarAction(
              label: '好的',
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
            directoryViewer = const Center(
              child: Text("空"),
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
                            child: const Text("开始备份")),
                        if (_isBackingUp)
                          const SizedBox(
                            height: 8,
                          ),
                        if (_isBackingUp)
                          OutlinedButton(
                              onPressed: _cancel, child: const Text("取消备份")),
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
                                Text(
                                    "已花费时间：${snapshot.data?.secondsElapsed.toString()}秒"),
                                Text(
                                    "总文件数量：${snapshot.data?.totalFiles.toString()}"),
                                Text(
                                    "已完成备份文件数量：${snapshot.data?.filesDone.toString()}"),
                              ],
                            );
                          }),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Column(
                      children: [
                        Text("快照数量: ${snapshots?.length}"),
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
          title: const Text('尚未设置备份目标'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('请先于设置中添加备份目标'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('确认'),
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
