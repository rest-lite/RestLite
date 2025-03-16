import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BackupCard extends StatefulWidget {
  const BackupCard({
    required this.enabled,
    required this.backupInterval,
    required this.onUpdate,
    super.key,
  });
  final bool enabled;
  final int backupInterval;
  final void Function(bool enable, int text) onUpdate;

  @override
  State<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends State<BackupCard> {
  late bool _enable;
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    _enable = widget.enabled;
    controller.text = widget.backupInterval.toString();
  }

  @override
  void didUpdateWidget(covariant BackupCard oldWidget) {
    if (oldWidget.enabled != _enable ||
        controller.text != widget.backupInterval.toString()) {
      setState(() {
        _enable = widget.enabled;
        controller.text = widget.backupInterval.toString();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      "自动备份",
                    ),
                    Tooltip(
                      message: '以应用运行时间为准，定期执行备份',
                      child: Icon(
                        Icons.help_outline,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Switch(
                  onChanged: (value) async {
                    setState(() {
                      _enable = value;
                    });
                    widget.onUpdate(_enable, int.parse(controller.text));
                  },
                  value: _enable,
                ),
              ],
            ),
            TextFormField(
              controller: controller,
              enabled: _enable,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: '备份间隔时间',
                hintText: '每次自动备份的间隔时间',
                suffix: Text('分钟'),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.schedule),
              ),
              validator: validateNonZeroInput,
              onChanged: (value) async {
                if (validateNonZeroInput(value) != null) {
                  return;
                }
                widget.onUpdate(_enable, int.parse(controller.text));
              },
            ),
          ],
        ),
      ),
    );
  }
}

String? validateNonZeroInput(String? value) {
  const errTip = '请输入不为零的数';
  if (value == null || value.isEmpty) {
    return errTip;
  }
  final v = int.tryParse(value);
  if (v == null || v < 1) {
    return errTip;
  }
  return null;
}
