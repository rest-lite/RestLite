import 'package:easy_localization/easy_localization.dart';
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
                Row(
                  children: [
                    Text(
                      context.tr("setting_view.auto_backup"),
                    ),
                    Tooltip(
                      message: context.tr("setting_view.auto_backup_tip"),
                      child: const Icon(
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
              decoration: InputDecoration(
                labelText: context.tr("setting_view.backup_interval"),
                hintText: context.tr("setting_view.backup_interval_hint_text"),
                suffix: Text(context.tr("setting_view.backup_interval_suffix")),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.schedule),
              ),
              validator: (v) => validateNonZeroInput(context, v),
              onChanged: (value) async {
                if (validateNonZeroInput(context, value) != null) {
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

String? validateNonZeroInput(BuildContext context, String? value) {
  final errTip = context.tr("setting_view.number_validation_hint");
  if (value == null || value.isEmpty) {
    return errTip;
  }
  final v = int.tryParse(value);
  if (v == null || v < 1) {
    return errTip;
  }
  return null;
}
