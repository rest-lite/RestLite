import 'dart:async';
import 'dart:developer';

import 'package:rest_lite/restic/task_manager.dart';

import '../../objectbox.g.dart';
import '../../restic/json_type.dart';
import '../../restic/tasks.dart';
import '../../services/restic.dart';
import '../../services/store.dart';
import 'directory_viewer.dart';
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';

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

  @override
  String toString() {
    return _toStringWithIndent();
  }

  String _toStringWithIndent([String indent = '']) {
    final buffer = StringBuffer()
      ..writeln('$indent DirectoryNode(')
      ..writeln('$indent  name: "$name",')
      ..writeln('$indent  path: "$path",')
      ..writeln('$indent  isDirectory: $isDirectory,')
      ..writeln('$indent  snapshots: $snapshots,');

    if (children != null) {
      buffer.writeln('$indent  children: [');
      for (var child in children!) {
        buffer.write(child._toStringWithIndent('$indent    '));
      }
      buffer.writeln('$indent  ]');
    } else {
      buffer.writeln('$indent  children: null');
    }

    buffer.writeln('$indent),');
    return buffer.toString();
  }
}

// 更新使用: flutter pub run build_runner build
@Entity()
class Node {
  @Id()
  int id;
  final String name;
  final String type;
  final String path;
  final int? size;

  @Property(type: PropertyType.date)
  final DateTime snapshotsTime;
  @Property(type: PropertyType.date)
  final DateTime modificationTime;
  final String snapshotID;
  Node({
    this.id = 0,
    required this.size,
    required this.name,
    required this.type,
    required this.path,
    required this.snapshotID,
    required this.snapshotsTime,
    required this.modificationTime,
  });
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Node &&
        other.path == path &&
        other.modificationTime == modificationTime &&
        other.size == size;
  }

  @override
  int get hashCode => path.hashCode ^ modificationTime.hashCode ^ size.hashCode;
}

@Entity()
class SnapshotStore {
  @Id()
  int id;
  final nodes = ToMany<Node>();
  final String snapshotID;
  final String path;
  SnapshotStore({
    this.id = 0,
    required this.snapshotID,
    required this.path,
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

Future<List<Snapshot>> loadSnapshots(
  String repositoryPath,
  String password,
) async {
  final task = ResticService.taskManager
      .addTask(LoadSnapshotsTask("加载快照", repositoryPath, password));

  await for (final out in task.stream) {
    if (out is Msg<List<Snapshot>>) return out.data;
  }
  return [];
}

Future<void> loadFiles(
  String repositoryPath,
  String snapshotID,
  String password,
  Set<String> paths,
  Set<Node> nodes,
  StreamController<Set<Node>> outStreamController,
) async {
  final snapshotBox = ObjectBox.store.box<SnapshotStore>();
  for (var path in paths) {
    final query = (snapshotBox.query(
            SnapshotStore_.snapshotID.equals(snapshotID) &
                SnapshotStore_.path.equals(path)))
        .build();
    final results = query.find();
    query.close();
    if (results.isNotEmpty) {
      for (var v in results.first.nodes) {
        nodes.add(v);
      }
      outStreamController.add(nodes);
      continue;
    }

    final snapshotStore = SnapshotStore(snapshotID: snapshotID, path: path);
    final loadFileTask = ResticService.taskManager.addTask(LoadFileTask(
        "加载快照文件" + snapshotID, {path}, repositoryPath, password, snapshotID));

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
            nodes.add(node);
            snapshotStore.nodes.add(node);
          } else if (value.data.messageType == "snapshot") {
            snapshotTime = DateTime.parse(value.data.time!);
          }
        case MakeWay<LsOutput>():
          nodes.clear();
          snapshotStore.nodes.clear();
          snapshotTime = null;
        case Done<LsOutput>():
          snapshotBox.put(snapshotStore);
        case Cancel<LsOutput>():
      }
      outStreamController.add(nodes);
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
