import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'util.dart';

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
  @override
  String toString() {
    return 'SnapshotInfo { '
        'id: $id, '
        'size: ${size ?? "null"}, '
        'time: ${time.toIso8601String()}, '
        'fileModificationTime: ${fileModificationTime.toIso8601String()} '
        '}';
  }
}

class FileInfo {
  final String name;
  final String path;
  final bool isDirectory;
  final Set<SnapshotInfo> snapshots;

  FileInfo(this.name, this.path, this.isDirectory, this.snapshots);
}

enum SampleItem { itemOne, itemTwo, itemThree }

class DirectoryViewer extends StatelessWidget {
  final DirectoryNode root;

  const DirectoryViewer({
    Key? key,
    required this.root,
    required this.loadDirectory,
    required this.showDetail,
  }) : super(key: key);

  final Function(String) loadDirectory;
  final void Function(FileInfo) showDetail;
  void show(DirectoryNode node) {
    final info = FileInfo(
      node.name,
      node.path,
      node.isDirectory,
      node.snapshots,
    );
    showDetail(info);
  }

  Widget _buildDirectoryItem(
      DirectoryNode node, int depth, BuildContext context) {
    final double indent = depth * 8.0; // 根据深度设置缩进
    if (node.isDirectory) {
      final initiallyExpanded = depth < 2;
      if (initiallyExpanded && node.children == null) {}

      node.children?.sort((a, b) => a.name.compareTo(b.name));

      return Padding(
        key: Key(node.path),
        padding: EdgeInsets.only(left: indent),
        child: ExpansionTile(
          key: PageStorageKey(node.path),
          leading: const Icon(Icons.folder),
          initiallyExpanded: initiallyExpanded,
          trailing: IconButton(
            onPressed: () => show(node),
            icon: const Icon(Icons.more_vert),
          ),
          title: Text(node.name),
          children: node.children
                  ?.map(
                      (child) => _buildDirectoryItem(child, depth + 1, context))
                  .toList() ??
              [
                Container(
                  padding: const EdgeInsets.all(5),
                  child: const CircularProgressIndicator(),
                )
              ],
          onExpansionChanged: (expanding) {
            if (node.children == null && expanding) loadDirectory(node.path);
          },
        ),
      );
    } else {
      return Padding(
        key: Key(node.path),
        padding: EdgeInsets.only(left: indent),
        child: ListTile(
          leading: const Icon(Icons.insert_drive_file),
          trailing: IconButton(
            onPressed: () => show(node),
            icon: const Icon(Icons.more_vert),
          ),
          title: Text(node.name),
          subtitle: Text(context.tr("backup_view.file_version_number",
              namedArgs: {"number": node.snapshots.length.toString()})),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [_buildDirectoryItem(root, 0, context)],
    );
  }
}
