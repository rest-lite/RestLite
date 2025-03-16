import 'dart:async';
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
        title: const Text("任务队列"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            _buildTaskSection(
                "正在运行任务", runningTasks, Icons.play_arrow, Colors.green),
            _buildTaskSection("等待任务", queuedTasks, Icons.queue, Colors.orange),
          ],
        ),
      ),
    );
  }

  /// 构建任务列表块
  Widget _buildTaskSection(String title, List<TaskControl<dynamic>> tasks,
      IconData icon, Color iconColor) {
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("暂无任务"),
            )
          else
            ...tasks.asMap().entries.map((entry) {
              var taskControl = entry.value;
              bool isConcurrent = taskControl.concurrent;
              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(taskControl.name),
                subtitle: Text("支持并行: ${isConcurrent ? '是' : '否'}"),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.blue),
                      tooltip: "立即执行",
                      onPressed: () {
                        taskControl.immediately();
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: "取消任务",
                      onPressed: () {
                        taskControl.cancel();
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
