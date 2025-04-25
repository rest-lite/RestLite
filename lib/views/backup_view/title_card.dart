import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../restic/json_type.dart';

class TitleCard extends StatelessWidget {
  const TitleCard({
    super.key,
    required this.isBackingUp,
    required this.backingUpStream,
    required this.snapshotNumber,
    required this.backup,
    required this.cancel,
  });
  final bool isBackingUp;
  final Stream<BackupOutput> backingUpStream;
  final int snapshotNumber;
  final VoidCallback backup;
  final VoidCallback cancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Column(
              children: [
                OutlinedButton(
                    onPressed: isBackingUp ? null : backup,
                    child: Text(context.tr("backup_view.start_backup"))),
                if (isBackingUp)
                  const SizedBox(
                    height: 8,
                  ),
                if (isBackingUp)
                  OutlinedButton(
                      onPressed: cancel,
                      child: Text(context.tr("backup_view.cancel_backup"))),
              ],
            ),
            if (isBackingUp)
              const SizedBox(
                width: 8,
              ),
            Offstage(
              offstage: !isBackingUp,
              child: StreamBuilder(
                  stream: backingUpStream,
                  builder: (context, snapshot) {
                    var _data = snapshot.data;
                    if (_data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr("backup_view.seconds_elapsed",
                            namedArgs: {
                              "second": _data.secondsElapsed.toString()
                            })),
                        Text(context.tr("backup_view.total_files", namedArgs: {
                          "number": _data.totalFiles.toString()
                        })),
                        Text(context.tr("backup_view.files_done",
                            namedArgs: {"number": _data.filesDone.toString()})),
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
                    namedArgs: {"number": snapshotNumber.toString()})),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
