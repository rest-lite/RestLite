import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:rest_lite/pages/file_download.dart';

import '../views/backup_view/directory_viewer.dart';
import '../views/backup_view/util.dart';
import 'file_detail.dart';
import 'home.dart';

class ViewNavigator extends StatefulWidget {
  const ViewNavigator(
      {Key? key, required this.loginContext, required this.exit})
      : super(key: key);

  final LoginContext loginContext;

  final void Function() exit;
  @override
  State<ViewNavigator> createState() => _ViewNavigatorState();
}

final log = Logger('HomeView');

class _ViewNavigatorState extends State<ViewNavigator> implements PageBuild {
  final Queue<Page<dynamic>> pages = Queue();
  @override
  void initState() {
    super.initState();
    pages.add(MaterialPage(
        key: const ValueKey('home'),
        child: Home(
          key: const ValueKey('homePage'),
          loginContext: widget.loginContext,
          pageBuild: this,
          exit: widget.exit,
        )));
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: pages.toList(),
      onDidRemovePage: (page) {
        pages.remove(page);
      },
    );
  }

  @override
  void buildFileDetailPage(FileInfo filePath) {
    pages.add(MaterialPage(
        key: const ValueKey('fileDetail'),
        child: FileDetail(
          key: const ValueKey('fileDetailPage'),
          fileInfo: filePath,
          pageBuild: this,
          loginContext: widget.loginContext,
        )));
    setState(() {});
  }

  @override
  void buildFileDownloadPage(
      String fileName, filePath, snapshotID, downloadPath) {
    pages.add(MaterialPage(
        key: const ValueKey('fileDownload'),
        child: FileDownload(
          key: const ValueKey('fileDownloadPage'),
          fileName: fileName,
          filePath: filePath,
          loginContext: widget.loginContext,
          snapshotID: snapshotID,
          downloadPath: downloadPath,
        )));
    setState(() {});
  }
}

abstract class PageBuild {
  void buildFileDownloadPage(
      String fileName, filePath, snapshotID, downloadPath);
  void buildFileDetailPage(FileInfo filePath);
}
