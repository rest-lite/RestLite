import 'package:easy_localization/easy_localization.dart';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr("setting_view.system_setting"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: context.tr("setting_view.concurrency_limit"),
                hintText:
                    context.tr("setting_view.concurrency_limit_hint_text"),
                suffix:
                    Text(context.tr("setting_view.concurrency_limit_suffix")),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.schedule),
              ),
              validator: (v) => validateNonZeroInput(context, v),
              onChanged: (value) async {
                if (validateNonZeroInput(context, value) != null) {
                  return;
                }
                widget.onUpdate(int.parse(controller.text), autoStartup);
              },
            ),
            CheckboxListTile(
              title: Text(context.tr("setting_view.auto_startup")),
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
