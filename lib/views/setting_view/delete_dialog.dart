import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final String path;
  final Function onConfirm;
  const DeleteDialog({required this.path, required this.onConfirm, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('删除备份目标'),
      content: Text("确认删除目录$path?"),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
