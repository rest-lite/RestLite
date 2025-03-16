import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemCard extends StatefulWidget {
  const SystemCard({
    required this.concurrencyLimit,
    required this.autoStartup,
    required this.onUpdate,
    super.key,
  });
  final int concurrencyLimit;
  final bool autoStartup;
  final void Function(int concurrencyLimit, bool autoStartup) onUpdate;

  @override
  State<SystemCard> createState() => _SystemCardState();
}

class _SystemCardState extends State<SystemCard> {
  final controller = TextEditingController();
  late bool autoStartup;
  @override
  void initState() {
    super.initState();
    controller.text = widget.concurrencyLimit.toString();
    autoStartup = widget.autoStartup;
  }

  @override
  void didUpdateWidget(covariant SystemCard oldWidget) {
    if (controller.text != widget.concurrencyLimit.toString() ||
        autoStartup != widget.autoStartup) {
      setState(() {
        controller.text = widget.concurrencyLimit.toString();
        autoStartup = widget.autoStartup;
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "系统设置",
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: '并发限制',
                hintText: '允许并发执行的任务数量限制',
                suffix: Text('个'),
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.schedule),
              ),
              validator: validateNonZeroInput,
              onChanged: (value) async {
                if (validateNonZeroInput(value) != null) {
                  return;
                }
                widget.onUpdate(int.parse(controller.text), autoStartup);
              },
            ),
            CheckboxListTile(
              title: const Text("开机启动"),
              onChanged: (value) async {
                autoStartup = value ?? false;
                setState(() {});
                widget.onUpdate(int.parse(controller.text), autoStartup);
              },
              value: autoStartup,
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
