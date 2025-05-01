import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:rest_lite/restic/task_manager.dart';

import '../../restic/json_type.dart';
import '../../restic/tasks.dart';
import '../../services/restic.dart';
import '../../services/store.dart';

class SnapshotInfo {
  String id;
  int? size;
  DateTime time;
  DateTime fileModificationTime;
  SnapshotInfo(
    this.id,
    this.size,
    this.time,
    this.fileModificationTime,
  );
}

class FileInfo {
  final String name;
  final String path;
  final bool isDirectory;
  final Set<SnapshotInfo> snapshots;

  FileInfo(this.name, this.path, this.isDirectory, this.snapshots);
}

class LoginContext {
  String savePath;
  String password;

  LoginContext({required this.savePath, required this.password});
}

class DirectoryNode {
  final String name;
  final String path;
  final bool isDirectory;
  Set<SnapshotInfo> snapshots;
  List<DirectoryNode>? children;

  DirectoryNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.snapshots,
    this.children,
  });
}

/// 构建目录树
//
// 路径格式示例:
// "/C/Users/userA/Desktop/fileA"
// "/C/Users/userA/Desktop/fileB"
// "/C/Users/userB/Desktop/fileA"
// "/C/Users/userB/Desktop/dirA/FileA"
// "/D/File/fileA"
//
// 实现逻辑：
// 1. 按照路径级数排序
// 2. 从最低路径开始，尝试建立父路径节点及目标节点
//  2.1. 如果父路径节点已存在，跳过
//       如果父路径节点不存在，从最高路径开始，检查父路径是否包含已存在节点
//   2.1.1. 如果包含已存在节点，建立父路径节点并加入已存在节点
//          如果不包含已存在节点，建立父路径并加入根节点
//  2.2. 如果目标节点不存在，建立目标节点
//       如果目标节点已存在，向节点中添加快照信息
DirectoryNode buildDirectoryTree(Set<Node> originNodes) {
  final root = DirectoryNode(
      isDirectory: true, name: '/', path: '/', snapshots: <SnapshotInfo>{});
  Map<String, DirectoryNode> pathToNode = {r"/": root};
  DirectoryNode tree = root;

  removeFitDir(originNodes);

  var _originNodes = originNodes.toList();
  // 1.
  _originNodes.sort(
      (a, b) => a.path.split('/').length.compareTo(b.path.split('/').length));

  // 2.
  for (var originNode in _originNodes) {
    final parts =
        originNode.path.split('/').where((part) => part.isNotEmpty).toList();

    final parentIndex = parts.length - 1;
    final parentPath = parentIndex < 0
        ? root.path
        : root.path + parts.sublist(0, parentIndex).join("/");

    // 2.1.
    if (pathToNode[parentPath] == null) {
      for (var i = parts.length - 2; i >= 0; i--) {
        final lastPath = root.path + parts.sublist(0, i).join("/");

        // 2.1.1
        if (pathToNode[lastPath] != null) {
          final node = DirectoryNode(
            name: parts.sublist(i, parentIndex).join("/"),
            path: parentPath,
            isDirectory: true,
            snapshots: <SnapshotInfo>{
              SnapshotInfo(
                originNode.snapshotID,
                null,
                originNode.snapshotsTime,
                originNode.modificationTime,
              )
            },
          );

          pathToNode[parentPath] = node;
          pathToNode[lastPath]!.children ??= [];
          pathToNode[lastPath]!.children!.add(node);
          break;
        }
      }
    }

    // 2.2.
    if (pathToNode[originNode.path] == null) {
      final node = DirectoryNode(
        name: originNode.name,
        path: originNode.path,
        isDirectory: originNode.type == "dir",
        snapshots: <SnapshotInfo>{
          SnapshotInfo(
            originNode.snapshotID,
            originNode.size,
            originNode.snapshotsTime,
            originNode.modificationTime,
          )
        },
      );
      pathToNode[originNode.path] = node;
      pathToNode[parentPath]!.children ??= [];
      pathToNode[parentPath]!.children!.add(node);
    } else {
      pathToNode[originNode.path]!.snapshots.add(SnapshotInfo(
            originNode.snapshotID,
            originNode.size,
            originNode.snapshotsTime,
            originNode.modificationTime,
          ));
    }
  }
  inspect(tree);

  return tree;
}

Future<List<Snapshot>> snapshotList(
  String repositoryPath,
  String password,
  BuildContext context,
) async {
  final task = resticService.addTask(LoadSnapshotsTask(
      context.tr("backup_view.load_snapshots_list_task_name"),
      repositoryPath,
      password));

  await for (final out in task.stream) {
    if (out is Msg<List<Snapshot>>) return out.data;
  }
  return [];
}

Stream<Node> fileList(
  String repositoryPath,
  String snapshotID,
  String password,
  Set<String> paths,
  BuildContext context,
) async* {
  final loadFileTask = resticService.addTask(LoadFileTask(
    context.tr("backup_view.load_snapshots_file_task_name"),
    paths,
    repositoryPath,
    password,
    snapshotID,
  ));

  DateTime? snapshotTime;
  await for (final data in loadFileTask.stream) {
    switch (data) {
      case Msg<LsOutput> value:
        if (value.data.messageType == "node") {
          final node = Node(
            name: value.data.name!,
            size: value.data.size,
            type: value.data.type!,
            path: value.data.path!,
            snapshotID: snapshotID,
            snapshotsTime: snapshotTime!,
            modificationTime: DateTime.parse(value.data.mtime!),
          );
          yield node;
        } else if (value.data.messageType == "snapshot") {
          snapshotTime = DateTime.parse(value.data.time!);
        }
      case MakeWay<LsOutput>():
        snapshotTime = null;
      case Done<LsOutput>():
        return;
      case Cancel<LsOutput>():
        return;
    }
  }
}

void removeFitDir(Set<Node> nodes) {
  Map<String, Node> uniquePathNodes = {};
  for (var node in nodes) {
    uniquePathNodes[node.path] = node;
  }

  for (final node in uniquePathNodes.values.where((n) => n.type == "file")) {
    if (node.type == "file") {
      final parts =
          node.path.split('/').where((part) => part.isNotEmpty).toList();

      for (var i = 0; i < parts.length; i++) {
        final partPath = "/" + parts.sublist(0, i).join("/");
        nodes
            .removeWhere((node) => node.type == "dir" && node.path == partPath);
      }
    }
  }
}
