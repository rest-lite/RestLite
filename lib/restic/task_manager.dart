import 'dart:async';
import 'dart:collection';

abstract class ResticTask<T> {
  Stream<T> start();
  void kill();

  bool get concurrent;
  String get name;
}

class TaskControl<T> {
  void Function() immediately;
  void Function() cancel;
  final bool concurrent;
  final String name;
  Stream<TaskRunning<T>> stream;

  TaskControl(
      this.stream, this.immediately, this.cancel, this.concurrent, this.name);
}

/// 任务状态
sealed class TaskRunning<T> {}

/// 普通消息
final class Msg<T> extends TaskRunning<T> {
  final T data;
  Msg(this.data);
}

/// 任务停止做出避让
final class MakeWay<T> extends TaskRunning<T> {}

/// 任务取消
final class Cancel<T> extends TaskRunning<T> {}

/// 任务完成
final class Done<T> extends TaskRunning<T> {}

sealed class _WrapperControl {}

final class _Destroy extends _WrapperControl {}

final class _SkipDestroy extends _WrapperControl {}

class _TaskWrapper<T> {
  final ResticTask<T> task;
  final TaskManager _manager;
  late final TaskControl<T> control = TaskControl<T>(
    _msg.stream,
    () => _manager._runTaskImmediately(this),
    () => _manager._cancelTask(this),
    task.concurrent,
    task.name,
  );

  final StreamController<TaskRunning<T>> _msg = StreamController.broadcast();
  var abnormal = false;

  /// 控制
  final StreamController<_WrapperControl> _wrapperController =
      StreamController.broadcast();
  _TaskWrapper(this.task, this._manager);

  // 在_TaskWrapper内部封装start是为了保证event类型不被丢失
  Future<void> start() async {
    await for (var event in task.start()) {
      _msg.add(Msg(event));
    }
    _wrapperController.add(_Destroy());
  }

  void end() {
    if (!abnormal) {
      _msg.add(Done());
    }
    _msg.close();
    _wrapperController.close();
  }

  void makeWay() {
    _msg.add(MakeWay<T>());
  }

  void cancel() {
    _msg.add(Cancel<T>());
  }
}

class TaskManager {
  final Queue<_TaskWrapper> _taskQueue = Queue();
  final Set<_TaskWrapper> _runningTasks = {};
  final StreamController<void> taskUpdate = StreamController<void>.broadcast();
  int maxConcurrency;

  TaskManager(this.maxConcurrency) {
    _startLoop();
  }

  List<TaskControl<dynamic>> runningTasks() {
    return _runningTasks.map((v) => v.control).toList();
  }

  List<TaskControl<dynamic>> queuedTasks() {
    return _taskQueue.map((v) => v.control).toList();
  }

  // 持续运行的任务调度循环
  // 按照队列顺序执行任务
  // 下一个任务如果是并行任务则加入执行，否则等待执行完毕再加入执行
  void _startLoop() async {
    while (true) {
      if (
          // 空队列等待
          _taskQueue.isEmpty ||
              // 并行任务达到上限等待
              _runningTasks.length >= maxConcurrency ||
              // 并行与非并行任务排斥
              (_runningTasks.isNotEmpty &&
                  (!_taskQueue.first.task.concurrent ||
                      !_runningTasks.first.task.concurrent))) {
        await _waitForTask();
        continue;
      }

      var currentTask = _taskQueue.removeFirst();
      _runningTasks.add(currentTask);

      currentTask.start();
      (() async {
        var skipDestroy = false;
        await for (final value in currentTask._wrapperController.stream) {
          if (skipDestroy) {
            break;
          }
          switch (value) {
            case _SkipDestroy():
              skipDestroy = true;
            case _Destroy():
              currentTask.end();
              _runningTasks.remove(currentTask);
              _notifyTaskUpdate();
          }
        }
      })();
    }
  }

  // 等待新任务到来
  Future<void> _waitForTask() async {
    await taskUpdate.stream.first;
  }

  // 有新任务或队列空缺时通知等待中的循环
  void _notifyTaskUpdate() {
    taskUpdate.add(null);
  }

  // 添加任务到队列中，并返回对应的 TaskControl
  TaskControl<T> addTask<T>(ResticTask<T> task) {
    final wrapper = _TaskWrapper<T>(task, this);
    _taskQueue.add(wrapper);
    _notifyTaskUpdate();
    return wrapper.control;
  }

  // 立即执行指定任务
  void _runTaskImmediately<T>(_TaskWrapper<T> wrapper) {
    // 忽略执行中任务
    if (_runningTasks.contains(wrapper)) return;

    if (_runningTasks.isNotEmpty) {
      // 移除一个执行中任务
      var victim = _runningTasks.first;
      victim._wrapperController.add(_SkipDestroy());
      victim.task.kill();
      victim.makeWay();
      _runningTasks.remove(victim);
      _taskQueue.addFirst(victim);
    }

    // 将立即执行任务移动到队列最前端
    _taskQueue.remove(wrapper);
    _taskQueue.addFirst(wrapper);

    _notifyTaskUpdate();
  }

  // 取消指定任务：若任务正在运行则停止，否则直接从队列中移除
  void _cancelTask<T>(_TaskWrapper<T> wrapper) {
    wrapper.cancel();
    wrapper.abnormal = true;
    if (_runningTasks.contains(wrapper)) {
      wrapper.task.kill();
      _runningTasks.remove(wrapper);
      _notifyTaskUpdate();
    } else {
      _taskQueue.remove(wrapper);
      wrapper.end();
    }
  }
}
