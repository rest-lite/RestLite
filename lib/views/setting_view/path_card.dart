import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'delete_dialog.dart';

class PathCard extends StatelessWidget {
  PathCard(
      {super.key, required List<String> paths, required this.onDataChanged})
      : paths = List.from(paths);

  final List<String> paths;
  final ValueChanged<List<String>> onDataChanged;

  @override
  Widget build(BuildContext context) {
    Future<void> _pickPath() async {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        return;
      }

      final exists = paths.any((text) => text == selectedDirectory);
      if (exists) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('目录已存在: $selectedDirectory'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: '好的',
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        );
        return;
      }

      paths.add(selectedDirectory);
      onDataChanged(paths);

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已添加目录: $selectedDirectory'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: '好的',
            onPressed: () {},
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    }

    Future<void> _removeField(int index) async {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除目录: ${paths[index]}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: '好的',
            onPressed: () {},
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
      paths.removeAt(index);
      onDataChanged(paths);
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Row(
              children: [
                Text(
                  "备份目标",
                ),
                Tooltip(
                  message: '将会对以下目录进行备份',
                  child: Icon(
                    Icons.help_outline,
                    size: 20,
                  ),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paths.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(paths[index]
                      .split('\\')
                      .where((part) => part.isNotEmpty)
                      .last),
                  subtitle: Text(paths[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (BuildContext context) => DeleteDialog(
                              path: paths[index],
                              onConfirm: () => _removeField(index),
                            )),
                  ),
                );
              },
            ),
            OutlinedButton(
              onPressed: _pickPath,
              child: const Text('添加目录'),
            ),
          ],
        ),
      ),
    );
  }
}
