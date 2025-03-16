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
                const Row(
                  children: [
                    Text(
                      "自动删除备份快照",
                    ),
                    Tooltip(
                      message: '以应用运行时间为准，定期检查快照是否过期并删除过期快照',
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
              decoration: const InputDecoration(
                labelText: '快照保留时间',
                hintText: '每个快照的保留时间，过期后会被删除',
                suffix: Text('天'),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.schedule),
              ),
              validator: validateNonZeroInput,
              onChanged: (value) async {
                if (validateNonZeroInput(value) != null) {
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
              decoration: const InputDecoration(
                labelText: '检查周期',
                hintText: '检查并删除过期快照的周期',
                suffix: Text('分钟'),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.schedule),
              ),
              validator: validateNonZeroInput,
              onChanged: (value) async {
                if (validateNonZeroInput(value) != null) {
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
