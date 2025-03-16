import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../util/string.dart';
import '../views/backup_view/directory_viewer.dart';
import '../views/backup_view/util.dart';
import 'home_navigator.dart';

class FileDetail extends StatefulWidget {
  const FileDetail({
    super.key,
    this.loginContext,
    required this.pageBuild,
    required this.fileInfo,
  });

  final FileInfo fileInfo;
  final LoginContext? loginContext;
  final PageBuild pageBuild;

  @override
  State<FileDetail> createState() => _FileDetailState();
}

final log = Logger('FileDetail');

class _FileDetailState extends State<FileDetail> {
  Future<void> download(String snapshotID, String fileName, filePath) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return;
    }
    widget.pageBuild.buildFileDownloadPage(
        fileName, filePath, snapshotID, selectedDirectory);
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = widget.fileInfo.snapshots.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileInfo.name,
          textWidthBasis: TextWidthBasis.parent,
          overflow: TextOverflow.fade,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: ListView.builder(
                    itemCount: snapshots.length,
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title:
                              Text('上一次修改日期: ${snapshot.fileModificationTime}'),
                          subtitle: Text(
                              "大小: ${snapshot.size == null ? '未知' : formatBytes(snapshot.size!)}"),
                          trailing: ElevatedButton(
                            onPressed: () => download(snapshot.id,
                                widget.fileInfo.name, widget.fileInfo.path),
                            child: const Text('下载'),
                          ),
                        ),
                      );
                    })),
          ],
        ),
      ),
    );
  }
}
