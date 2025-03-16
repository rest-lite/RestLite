import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../restic/json_type.dart';
import '../restic/task_manager.dart';
import '../restic/tasks.dart';
import '../services/restic.dart';
import '../util/string.dart';
import '../views/backup_view/util.dart';

class FileDownload extends StatefulWidget {
  const FileDownload({
    super.key,
    required this.loginContext,
    required this.fileName,
    required this.filePath,
    required this.snapshotID,
    required this.downloadPath,
  });

  final String fileName;
  final String filePath;
  final String snapshotID;
  final String downloadPath;
  final LoginContext loginContext;

  @override
  State<FileDownload> createState() => _FileDownloadState();
}

final log = Logger('FileDownload');

class _FileDownloadState extends State<FileDownload> {
  var downloading = false;
  RestoreOutput? data;
  TaskControl<RestoreOutput>? task;

  void download(String snapshotID, String filePath, String downloadPath) async {
    final _task = ResticService.taskManager.addTask(RestoreTask(
      "下载备份文件",
      widget.loginContext.savePath,
      widget.loginContext.password,
      snapshotID,
      filePath,
      downloadPath,
    ));
    task = _task;

    _task.immediately();
    final _nodesStreamController = StreamController<RestoreOutput>();
    late final _nodesStream = _nodesStreamController.stream.throttleTime(
      const Duration(milliseconds: 100),
      trailing: true,
    );
    _task.stream.listen((v) {
      switch (v) {
        case Msg<RestoreOutput> v:
          _nodesStreamController.add(v.data);
        case MakeWay<RestoreOutput>():
        case Cancel<RestoreOutput>():
        case Done<RestoreOutput>():
          downloading = false;
      }
    });
    _nodesStream.listen((v) {
      data = v;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    downloading = true;
    download(widget.snapshotID, widget.filePath, widget.downloadPath);
  }

  @override
  Widget build(BuildContext context) {
    var _data = data;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: _data == null
            ? const CircularProgressIndicator(strokeWidth: 6)
            : _downloadStatus(_data),
      ),
    );
  }

  Widget _downloadStatus(RestoreOutput data) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              downloading ? "正在下载" : "下载完成",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            // 自定义带背景的进度条
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (data.bytesRestored ?? 0) / (data.totalBytes ?? 1),
                    minHeight: 20,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.fileName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "已下载：${formatBytes(data.bytesRestored ?? 0)}(跳过${formatBytes(data.bytesSkipped ?? 0)})",
                    style: const TextStyle(fontSize: 16)),
                Text("总大小：${formatBytes(data.totalBytes ?? 0)}",
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Text("已花费时间：${data.secondsElapsed ?? 0}秒",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (downloading)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  task?.cancel();
                },
                icon: const Icon(Icons.cancel),
                label: const Text("取消下载"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.done),
                label: const Text("确认"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
