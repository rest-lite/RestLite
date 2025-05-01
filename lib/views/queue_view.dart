import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../restic/task_manager.dart';
import '../services/restic.dart';

class QueueView extends StatefulWidget {
  const QueueView({Key? key}) : super(key: key);

  @override
  _QueueViewState createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  StreamSubscription<void>? listen;

  @override
  void initState() {
    super.initState();
    listen = resticService.taskUpdate.stream
        .throttleTime(
      const Duration(milliseconds: 500),
      trailing: true,
    )
        .listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    listen?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<TaskControl<dynamic>> runningTasks = resticService.runningTasks();
    List<TaskControl<dynamic>> queuedTasks = resticService.queuedTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("queue_view.view_title")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            _buildTaskSection(context.tr("queue_view.running_tasks_title"),
                runningTasks, Icons.play_arrow, Colors.green, true),
            _buildTaskSection(context.tr("queue_view.queued_tasks_title"),
                queuedTasks, Icons.queue, Colors.orange, false),
          ],
        ),
      ),
    );
  }

  /// 构建任务列表块
  Widget _buildTaskSection(String title, List<TaskControl<dynamic>> tasks,
      IconData icon, Color iconColor, bool running) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(context.tr("queue_view.empty_queue")),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              var taskControl = entry.value;
              bool isConcurrent = taskControl.concurrent;
              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(taskControl.name),
                subtitle: Text(taskControl.description ?? ""),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isConcurrent
                        ? Tooltip(
                            message:
                                context.tr("queue_view.task_is_concurrent"),
                            child: const Icon(
                              Icons.splitscreen,
                              color: Colors.green,
                            ),
                          )
                        : Tooltip(
                            message:
                                context.tr("queue_view.task_is_not_concurrent"),
                            child: const Icon(
                              Icons.splitscreen,
                              color: Colors.orange,
                            ),
                          ),
                    running
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            tooltip: context.tr("queue_view.cancel_tip"),
                            onPressed: () {
                              taskControl.cancel();
                              setState(() {});
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.play_circle_fill,
                                color: Colors.blue),
                            tooltip: context.tr("queue_view.immediately_tip"),
                            onPressed: () {
                              taskControl.immediately();
                              setState(() {});
                            },
                          ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
