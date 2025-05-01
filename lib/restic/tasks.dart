import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';

import 'json_type.dart';
import 'core.dart';
import 'kill.dart';
import 'task_manager.dart';

const ignoreKillMassage = [
  "signal interrupt received, cleaning up",
  "unable to save snapshot: context canceled",
  "context canceled"
];

class BackupTask extends ResticTask<BackupOutput> {
  Future<Process>? process;
  String repositoryPath;
  List<String> backupPaths;
  String password;
  final String _name;
  BackupTask(
    this._name,
    this.backupPaths,
    this.repositoryPath,
    this.password,
  );

  @override
  String get name => _name;

  @override
  bool get concurrent => false;

  @override
  String? get description =>
      "restic -r $repositoryPath backup ${backupPaths.join(" ")}";

  @override
  Stream<BackupOutput> start() async* {
    process = Process.start(
      cliToolPath,
      ['-r', repositoryPath, "backup", ...backupPaths, "--json"],
      environment: {
        resticPassword: password,
      },
    );

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    var stdoutStream =
        _process.stdout.transform(utf8.decoder).map((multiLineJson) {
      List<String> lines = multiLineJson.trim().split('\n');
      return BackupOutput.fromJson(jsonDecode(lines.last));
    });

    var stderrStream = _process.stderr
        .transform(utf8.decoder)
        .where((multiLineJson) =>
            !ignoreKillMassage.any((v) => multiLineJson.contains(v)))
        .map((multiLineJson) {
      List<String> lines = multiLineJson.trim().split('\n');

      return BackupOutput.fromJson(jsonDecode(lines.last));
    });

    final mergedStream =
        MergeStream<BackupOutput>([stdoutStream, stderrStream]);

    await for (var line in mergedStream) {
      yield line;
    }

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        break;
      case 1: // SIGINT
        break;
      case 130:
        break;
      default:
        throw Exception(exitCode);
    }
  }

  @override
  Future<void> kill() async {
    final _process = (await process);
    if (_process == null) throw Error();
    int pid = _process.pid;

    sendCtrlCEvent(pid);
  }
}

class LoadFileTask extends ResticTask<LsOutput> {
  Future<Process>? process;
  String repositoryPath;
  String snapshotID;
  String password;
  Set<String> paths;
  final String _name;
  LoadFileTask(
    this._name,
    this.paths,
    this.repositoryPath,
    this.password,
    this.snapshotID,
  );

  @override
  bool get concurrent => true;
  @override
  String get name => _name;
  @override
  String? get description =>
      "restic -r $repositoryPath ls $snapshotID --long --no-lock ${paths.join(" ")}";

  @override
  Stream<LsOutput> start() async* {
    process = Process.start(
      cliToolPath,
      [
        '-r',
        repositoryPath,
        "ls",
        snapshotID,
        "--long",
        "--no-lock",
        "--json",
        ...paths
      ],
      environment: {
        resticPassword: password,
      },
      mode: ProcessStartMode.normal,
    );

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    var stdoutStream = _process.stdout
        .transform(utf8.decoder)
        .transform(createJsonTransformer<LsOutput>(LsOutput.fromJson));

    _process.stderr
        .transform(utf8.decoder)
        .where((multiLineJson) =>
            !ignoreKillMassage.any((v) => multiLineJson.contains(v)))
        .forEach((multiLineJson) {
      print(multiLineJson);
    });

    final mergedStream = MergeStream<LsOutput>([stdoutStream]);

    await for (var line in mergedStream) {
      yield line;
    }

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        break;
      case 1:
        break;
      case 130:
        break;
      default:
        throw Exception(exitCode);
    }
  }

  @override
  Future<void> kill() async {
    final _process = (await process);
    if (_process == null) throw Error();
    int pid = _process.pid;

    sendCtrlCEvent(pid);
  }
}

class LoadSnapshotsTask extends ResticTask<List<Snapshot>> {
  Future<Process>? process;
  String repositoryPath;
  String password;
  final String _name;
  LoadSnapshotsTask(this._name, this.repositoryPath, this.password);

  @override
  bool get concurrent => true;
  @override
  String get name => _name;
  @override
  String? get description => "restic -r $repositoryPath snapshots";

  @override
  Stream<List<Snapshot>> start() async* {
    process = Process.start(
      cliToolPath,
      ['-r', repositoryPath, "snapshots", "--json"],
      environment: {
        resticPassword: password,
      },
    );

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    List<dynamic> jsonArray =
        jsonDecode(await _process.stdout.transform(utf8.decoder).join(""));

    yield jsonArray.map((json) => Snapshot.fromJson(json)).toList();

    _process.stderr
        .transform(utf8.decoder)
        .where((multiLineJson) =>
            !ignoreKillMassage.any((v) => multiLineJson.contains(v)))
        .forEach((multiLineJson) {
      print(multiLineJson);
    });

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        break;
      case 1:
        break;
      case 130:
        break;
      default:
        throw Exception(exitCode);
    }
  }

  @override
  Future<void> kill() async {
    final _process = (await process);
    if (_process == null) throw Error();
    int pid = _process.pid;

    sendCtrlCEvent(pid);
  }
}

class DeleteSnapshotsTask extends ResticTask<ForgetGroup> {
  Future<Process>? process;
  String repositoryPath;
  String password;
  int keepDay;
  final String _name;
  DeleteSnapshotsTask(
      this._name, this.keepDay, this.repositoryPath, this.password);

  @override
  bool get concurrent => false;
  @override
  String get name => _name;
  @override
  String? get description =>
      "restic -r $repositoryPath forget --keep-within ${keepDay.toString()}d";

  @override
  Stream<ForgetGroup> start() async* {
    // restic -r <REPO> forget  forget --keep-within <day>d --json
    process = Process.start(
      cliToolPath,
      [
        '-r',
        repositoryPath,
        "forget",
        "--keep-within",
        "${keepDay.toString()}d",
        "--json"
      ],
      environment: {
        resticPassword: password,
      },
    );

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    var stdoutStream = _process.stdout
        .transform(utf8.decoder)
        .transform(createJsonTransformer<ForgetGroup>(ForgetGroup.fromJson));

    _process.stderr
        .transform(utf8.decoder)
        .where((multiLineJson) =>
            !ignoreKillMassage.any((v) => multiLineJson.contains(v)))
        .forEach((multiLineJson) {
      print(multiLineJson);
    });

    final mergedStream = MergeStream<ForgetGroup>([stdoutStream]);

    await for (var line in mergedStream) {
      yield line;
    }

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        break;
      case 1:
        break;
      case 130:
        break;
      default:
        throw Exception(exitCode);
    }

    // restic -r <REPO> prune
    await Process.run(cliToolPath, [
      '-r',
      repositoryPath,
      "prune",
    ], environment: {
      resticPassword: password,
    });
  }

  @override
  Future<void> kill() async {
    final _process = (await process);
    if (_process == null) throw Error();
    int pid = _process.pid;

    sendCtrlCEvent(pid);
  }
}

class RestoreTask extends ResticTask<RestoreOutput> {
  Future<Process>? process;
  final String repositoryPath;
  final String password;
  final String savePath;
  final String restoreTargetPath;
  final String snapshot;
  final String _name;
  RestoreTask(this._name, this.repositoryPath, this.password, this.snapshot,
      this.restoreTargetPath, this.savePath);

  @override
  bool get concurrent => true;
  @override
  String get name => _name;
  @override
  String? get description =>
      "restic -r $repositoryPath restore $snapshot:${path.dirname(restoreTargetPath)} --target $savePath --include ${path.basename(restoreTargetPath)}";

  // restic -r <repo> restore <snapshot>:<prefix_path> --target <save_path> --include <restore_target> --json
  @override
  Stream<RestoreOutput> start() async* {
    path.dirname(restoreTargetPath);
    process = Process.start(
      cliToolPath,
      [
        '-r',
        repositoryPath,
        "restore",
        "$snapshot:${path.dirname(restoreTargetPath)}",
        "--target",
        savePath,
        "--include",
        path.basename(restoreTargetPath),
        "--json"
      ],
      environment: {
        resticPassword: password,
      },
    );

    var _process = await process;
    if (_process == null) {
      throw Exception();
    }

    var stdoutStream = _process.stdout.transform(utf8.decoder).transform(
        createJsonTransformer<RestoreOutput>(RestoreOutput.fromJson));

    _process.stderr
        .transform(utf8.decoder)
        .where((multiLineJson) =>
            !ignoreKillMassage.any((v) => multiLineJson.contains(v)))
        .forEach((multiLineJson) {
      print(multiLineJson);
    });

    final mergedStream = MergeStream<RestoreOutput>([stdoutStream]);

    await for (var line in mergedStream) {
      yield line;
    }

    int exitCode = await _process.exitCode;
    switch (exitCode) {
      case 0:
        break;
      case 1:
        break;
      case 130:
        break;
      default:
        throw Exception(exitCode);
    }
  }

  @override
  Future<void> kill() async {
    final _process = (await process);
    if (_process == null) throw Error();
    int pid = _process.pid;

    sendCtrlCEvent(pid);
  }
}

StreamTransformer<String, T> createJsonTransformer<T>(
  T Function(Map<String, dynamic>) fromJson,
) {
  String buffer = '';

  // 适应的数据格式为: "{v:1}\n{v:2}\n{v:"
  // 返回 "{v:"
  String? tryParseBuffer(EventSink<T> sink, String buffer) {
    List<String> parts = buffer.split('\n');
    for (final part in parts) {
      try {
        final decoded = jsonDecode(part);
        if (decoded is Map<String, dynamic>) {
          sink.add(fromJson(decoded));
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              sink.add(fromJson(item));
            }
          }
        }
      } catch (_) {
        return parts.last;
      }
    }
    return null;
  }

  return StreamTransformer<String, T>.fromHandlers(
    handleData: (chunk, sink) {
      buffer += chunk;
      buffer = tryParseBuffer(sink, buffer) ?? '';
    },
    handleDone: (sink) {
      // 流结束时如果缓存中还有数据，再次尝试解析
      if (buffer.isNotEmpty && tryParseBuffer(sink, buffer) != null) {
        print("结束时剩余数据解析失败：$buffer");
      }
      sink.close();
    },
  );
}
