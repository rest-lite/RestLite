import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RetentionCard extends StatefulWidget {
  const RetentionCard({
    required this.enabled,
    required this.retentionPeriod,
    required this.checkInterval,
    required this.onUpdate,
    super.key,
  });
  final bool enabled;
  final int retentionPeriod;
  final int checkInterval;
  final void Function(bool enable, int retentionPeriod, int checkInterval)
      onUpdate;

  @override
  State<RetentionCard> createState() => _RetentionCardState();
}

class _RetentionCardState extends State<RetentionCard> {
  late bool _enable;
  final retentionPeriodController = TextEditingController();
  final checkIntervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _enable = widget.enabled;
    retentionPeriodController.text = widget.retentionPeriod.toString();
    checkIntervalController.text = widget.checkInterval.toString();
  }

  @override
  void didUpdateWidget(covariant RetentionCard oldWidget) {
    if (oldWidget.enabled != _enable ||
        widget.retentionPeriod.toString() != retentionPeriodController.text) {
      setState(() {
        _enable = widget.enabled;
        retentionPeriodController.text = widget.retentionPeriod.toString();
        checkIntervalController.text = widget.checkInterval.toString();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    retentionPeriodController.dispose();
    checkIntervalController.dispose();
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
                      context.tr("setting_view.auto_delete"),
                    ),
                    Tooltip(
                      message: context.tr("setting_view.auto_delete_tip"),
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
                    widget.onUpdate(
                        _enable,
                        int.parse(retentionPeriodController.text),
                        int.parse(checkIntervalController.text));
                  },
                  value: _enable,
                ),
              ],
            ),
            TextFormField(
              controller: retentionPeriodController,
              enabled: _enable,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: context.tr("setting_view.retention_time"),
                hintText: context.tr("setting_view.retention_time_tip"),
                suffix: Text(context.tr("setting_view.retention_time_suffix")),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.schedule),
              ),
              validator: (v) => validateNonZeroInput(context, v),
              onChanged: (value) async {
                if (validateNonZeroInput(context, value) != null) {
                  return;
                }
                widget.onUpdate(
                    _enable,
                    int.parse(retentionPeriodController.text),
                    int.parse(checkIntervalController.text));
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: checkIntervalController,
              enabled: _enable,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText:
                    context.tr("setting_view.auto_delete_check_interval"),
                hintText: context
                    .tr("setting_view.auto_delete_check_interval_hint_text"),
                suffix: Text(context
                    .tr("setting_view.auto_delete_check_interval_suffix")),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.schedule),
              ),
              validator: (v) => validateNonZeroInput(context, v),
              onChanged: (value) async {
                if (validateNonZeroInput(context, value) != null) {
                  return;
                }
                widget.onUpdate(
                    _enable,
                    int.parse(retentionPeriodController.text),
                    int.parse(checkIntervalController.text));
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
