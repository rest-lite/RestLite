import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final String path;
  final Function onConfirm;
  const DeleteDialog({required this.path, required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr("setting_view.delete_target_path_dialog_title")),
      content: Text(context.tr(
        "setting_view.delete_target_path_dialog_content",
        namedArgs: {"path": path},
      )),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(context.tr("cancel")),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text(context.tr("confirm")),
        ),
      ],
    );
  }
}
