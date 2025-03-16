import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rest_lite/restic/task_manager.dart';
import 'package:rxdart/rxdart.dart';

// 一个示例实现，假设输出为 String，错误为 String
sealed class ExampleEvent {}

final class OutEvent extends ExampleEvent {
  final String data;
  OutEvent(this.data);
}

final class ErrEvent extends ExampleEvent {
  final String error;
  ErrEvent(this.error);
}

class ExampleTask extends ResticTask<ExampleEvent> {
  // Future 类型是为了加快start中process的赋值速度
  Future<Process>? process;
  @override
  bool get concurrent => false;

  @override
  Stream<ExampleEvent> start() async* {
    process = Process.start('echo', ["Hello, World!"], runInShell: true);

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    final stdoutStream = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => OutEvent(line));

    final stderrStream = _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => ErrEvent(line));

    final mergedStream =
        MergeStream<ExampleEvent>([stdoutStream, stderrStream]);

    await for (var line in mergedStream) {
      yield line;
    }

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        yield OutEvent("done");
        break;
      case -1:
        yield OutEvent("kill");
        break;
      default:
        yield ErrEvent("exitCode: " + exitCode.toString());
    }
  }

  @override
  Future<void> kill() async {
    (await process)?.kill();
  }

  @override
  String get name => "";
}

class ExampleConcurrentTask extends ResticTask<ExampleEvent> {
  // Future 类型是为了加快start中process的赋值速度
  Future<Process>? process;
  @override
  bool get concurrent => true;

  @override
  Stream<ExampleEvent> start() async* {
    process = Process.start('echo', ["Hello, World!"], runInShell: true);

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    final stdoutStream = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => OutEvent(line));

    final stderrStream = _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) => ErrEvent(line));

    final mergedStream =
        MergeStream<ExampleEvent>([stdoutStream, stderrStream]);

    await for (var line in mergedStream) {
      yield line;
    }

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        yield OutEvent("done");
        break;
      case -1:
        yield OutEvent("kill");
        break;
      default:
        yield ErrEvent("exitCode: " + exitCode.toString());
    }
  }

  @override
  Future<void> kill() async {
    (await process)?.kill();
  }

  @override
  String get name => "";
}

void main() {
  group('TaskManager Tests', () {
    test('T1: 运行单个任务', () async {
      var manager = TaskManager(2);
      var controller = manager.addTask(ExampleConcurrentTask());
      var results = <String>[];

      controller.stream.listen((event) {
        switch (event) {
          case Msg<ExampleEvent> v:
            switch (v.data) {
              case OutEvent v:
                results.add(v.data);
                break;
              case ErrEvent():
                break;
            }
            break;
          case MakeWay<ExampleEvent>():
            break;
          case Done<ExampleEvent>():
            results.add("success");
            break;
          case Cancel<ExampleEvent>():
            break;
        }
      });

      await controller.stream.last;
      expect(results, ['"Hello, World!"', "done", "success"]);
    });

    test('T2.1: 顺序执行多个任务，区分并发与非并发任务', () async {
      var manager = TaskManager(2);
      var results = <String>[];

      var controllerA = manager.addTask(ExampleTask());
      var controllerB = manager.addTask(ExampleConcurrentTask());

      controllerA.stream.listen((event) {
        if (event is Msg<ExampleEvent> && event.data is OutEvent) {
          results.add("A ${(event.data as OutEvent).data}");
        }
      });

      controllerB.stream.listen((event) {
        if (event is Msg<ExampleEvent> && event.data is OutEvent) {
          results.add("B ${(event.data as OutEvent).data}");
        }
      });

      await controllerB.stream.last;
      expect(results,
          ['A "Hello, World!"', 'A done', 'B "Hello, World!"', 'B done']);
    });
    test('T2.2: 顺序执行多个任务，区分并发与非并发任务', () async {
      var manager = TaskManager(2);
      var results = <String>[];

      var controllerA = manager.addTask(ExampleConcurrentTask());
      var controllerB = manager.addTask(ExampleTask());

      controllerA.stream.listen((event) {
        if (event is Msg<ExampleEvent> && event.data is OutEvent) {
          results.add("A ${(event.data as OutEvent).data}");
        }
      });

      controllerB.stream.listen((event) {
        if (event is Msg<ExampleEvent> && event.data is OutEvent) {
          results.add("B ${(event.data as OutEvent).data}");
        }
      });

      await controllerB.stream.last;
      expect(results,
          ['A "Hello, World!"', 'A done', 'B "Hello, World!"', 'B done']);
    });

    test('T3: 并发任务数受 maxConcurrency 限制', () async {
      var manager = TaskManager(1); // 设定最大同时运行任务数=1

      var controllerA = manager.addTask(ExampleConcurrentTask());
      var controllerB = manager.addTask(ExampleConcurrentTask());

      var aIsRunning = false;
      controllerA.stream.listen(
        (event) {
          aIsRunning = true;
        },
        onDone: () {
          aIsRunning = false;
        },
      );
      controllerB.stream.listen((event) {
        if (aIsRunning) {
          throw Exception("任务A与B同时运行");
        }
      });

      await controllerB.stream.last;
    });

    test('T4: 立即执行任务会抢占当前任务', () async {
      var manager = TaskManager(2);
      var controllerA = manager.addTask(ExampleTask());
      var controllerB = manager.addTask(ExampleTask());

      var results = <String>[];

      controllerA.stream.listen((event) {
        switch (event) {
          case Msg<ExampleEvent> value:
            results.add("A ${(value.data as OutEvent).data}");
          case MakeWay<ExampleEvent>():
            results.add("A make way");
          case Cancel<ExampleEvent>():
            results.add("A cancel");
          case Done<ExampleEvent>():
            results.add("A success");
        }
      });
      controllerB.stream.listen((event) {
        switch (event) {
          case Msg<ExampleEvent> value:
            results.add("B ${(value.data as OutEvent).data}");
          case MakeWay<ExampleEvent>():
            results.add("B make way");
          case Cancel<ExampleEvent>():
            results.add("B cancel");
          case Done<ExampleEvent>():
            results.add("B success");
        }
      });
      await Future.delayed(const Duration(milliseconds: 1));
      controllerB.immediately(); // 立即执行 B

      await controllerA.stream.last;
      expect(results, [
        'A make way',
        'A kill',
        'B "Hello, World!"',
        'B done',
        'B success',
        'A "Hello, World!"',
        'A done',
        'A success'
      ]); // A 被抢占
    });

    test('T5: 任务可以在运行前被取消', () async {
      var manager = TaskManager(2);
      var controller = manager.addTask(ExampleTask());

      controller.cancel();
      expect(true, manager.queuedTasks().isEmpty);
      expect(true, manager.runningTasks().isEmpty);
    });

    test('T6: 任务可以在运行时被取消', () async {
      var manager = TaskManager(2);
      var controller = manager.addTask(ExampleTask());
      var results = <String>[];

      controller.stream.listen((event) {
        switch (event) {
          case Msg<ExampleEvent> value:
            results.add((value.data as OutEvent).data);
          case MakeWay<ExampleEvent>():
            results.add("make way");
          case Cancel<ExampleEvent>():
            results.add("cancel");
          case Done<ExampleEvent>():
            results.add("success");
        }
      });
      await Future.delayed(const Duration(milliseconds: 1));
      controller.cancel();

      await controller.stream.last;
      expect(results, ['cancel', 'kill']);
    });
    test('T7: 并发任务可以并行执行', () async {
      var manager = TaskManager(2);

      var controllerA = manager.addTask(ExampleConcurrentTask());
      var controllerB = manager.addTask(ExampleConcurrentTask());

      bool concurrent = false;
      await Future.delayed(const Duration(milliseconds: 1));
      if (manager.runningTasks().length == 2) {
        concurrent = true;
      }

      await controllerA.stream.last;
      await controllerB.stream.last;

      expect(concurrent, true);
    });
  });
}
