import 'package:json_annotation/json_annotation.dart';

part 'json_type.g.dart';

// 使用json_serializable生成json序列化反序列化代码，
// 代码生成命令: flutter pub run build_runner build
// 来源: https://restic.readthedocs.io/en/latest/075_scripting.html#json-output
@JsonSerializable(fieldRename: FieldRename.snake)
class BackupOutput {
  // common
  final String messageType; // "status", "verbose_status", "error", "summary"

  // status
  final int? secondsElapsed;
  final int? secondsRemaining;
  final int? percentDone;
  final int? totalFiles;
  final int? filesDone;
  final int? totalBytes;
  final int? bytesDone;
  final int? errorCount;
  final List<String>? currentFiles;

  // verbose status
  // action
  // item
  // duration
  // dataSize
  // metadataSize
  // totalFiles

  // Error
  final BackupError? error;
  final String? during;
  final String? item;

  // summary
  final int? filesNew;
  final int? filesChanged;
  final int? filesUnmodified;
  final int? dirsNew;
  final int? dirsChanged;
  final int? dirsUnmodified;
  final int? dataBlobs;
  final int? treeBlobs;
  final int? dataAdded;
  final int? totalFilesProcessed;
  final int? totalBytesProcessed;
  final int? totalDuration;
  final String? snapshotId;

  BackupOutput({
    required this.messageType,
    this.error,
    this.secondsElapsed,
    this.secondsRemaining,
    this.errorCount,
    this.during,
    this.item,
    this.filesNew,
    this.filesChanged,
    this.filesUnmodified,
    this.dirsNew,
    this.dirsChanged,
    this.dirsUnmodified,
    this.dataBlobs,
    this.treeBlobs,
    this.dataAdded,
    this.totalFilesProcessed,
    this.totalBytesProcessed,
    this.totalDuration,
    this.snapshotId,
    this.percentDone,
    this.totalFiles,
    this.filesDone,
    this.totalBytes,
    this.bytesDone,
    this.currentFiles,
  });

  factory BackupOutput.fromJson(Map<String, dynamic> json) =>
      _$BackupOutputFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class BackupError {
  String message;
  BackupError({required this.message});

  factory BackupError.fromJson(Map<String, dynamic> json) =>
      _$BackupErrorFromJson(json);
}

// https://restic.readthedocs.io/en/latest/075_scripting.html#ls
@JsonSerializable(fieldRename: FieldRename.snake)
class LsOutput {
  // common
  final String messageType; // "snapshot", "node"

  // snapshot
  final String? time;
  final String? parent;
  final String? tree;
  final List<String>? paths;
  final String? hostname;
  final String? username;
  final String? programVersion;
  final String? id;
  final String? shortId;

  // node
  final String? name;
  final String? type;
  final String? path;
  final int? size;
  final int? uid;
  final int? gid;
  final int? mode;
  final String? permissions;
  final String? mtime;
  final String? atime;
  final String? ctime;

  LsOutput({
    required this.messageType,
    this.time,
    this.parent,
    this.tree,
    this.paths,
    this.hostname,
    this.username,
    this.programVersion,
    this.id,
    this.shortId,
    this.name,
    this.type,
    this.path,
    this.size,
    this.uid,
    this.gid,
    this.mode,
    this.permissions,
    this.mtime,
    this.atime,
    this.ctime,
  });
  factory LsOutput.fromJson(Map<String, dynamic> json) =>
      _$LsOutputFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SnapshotSummary {
  final String backupStart;
  final String backupEnd;
  final int filesNew;
  final int filesChanged;
  final int filesUnmodified;
  final int dirsNew;
  final int dirsChanged;
  final int dirsUnmodified;
  final int dataBlobs;
  final int treeBlobs;
  final int dataAdded;
  final int dataAddedPacked;
  final int totalFilesProcessed;
  final int totalBytesProcessed;

  SnapshotSummary({
    required this.backupStart,
    required this.backupEnd,
    required this.filesNew,
    required this.filesChanged,
    required this.filesUnmodified,
    required this.dirsNew,
    required this.dirsChanged,
    required this.dirsUnmodified,
    required this.dataBlobs,
    required this.treeBlobs,
    required this.dataAdded,
    required this.dataAddedPacked,
    required this.totalFilesProcessed,
    required this.totalBytesProcessed,
  });
  factory SnapshotSummary.fromJson(Map<String, dynamic> json) =>
      _$SnapshotSummaryFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Snapshot {
  final String time;
  final String? parent;
  final String tree;
  final List<String> paths;
  final String hostname;
  final String username;
  final String? uid;
  final String? gid;
  final List<String>? excludes;
  final List<String>? tags;
  final String programVersion;
  final SnapshotSummary? summary;
  final String id;
  final String shortId;

  Snapshot({
    this.parent,
    this.uid,
    this.gid,
    this.excludes,
    this.tags,
    this.summary,
    required this.time,
    required this.tree,
    required this.paths,
    required this.hostname,
    required this.username,
    required this.programVersion,
    required this.id,
    required this.shortId,
  });
  factory Snapshot.fromJson(Map<String, dynamic> json) =>
      _$SnapshotFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ForgetGroup {
  final List<String>? tags;
  final String host;
  final List<String> paths;
  final List<Snapshot>? keep;
  final List<Snapshot>? remove;
  final List<KeepReason> reasons;

  ForgetGroup({
    this.tags,
    required this.host,
    required this.paths,
    this.keep,
    this.remove,
    required this.reasons,
  });
  factory ForgetGroup.fromJson(Map<String, dynamic> json) =>
      _$ForgetGroupFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class KeepReason {
  final Snapshot snapshot;
  final List<String> matches;
  KeepReason({
    required this.snapshot,
    required this.matches,
  });
  factory KeepReason.fromJson(Map<String, dynamic> json) =>
      _$KeepReasonFromJson(json);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RestoreOutput {
  // common
  final String messageType;

  // Status
  final int? secondsElapsed;
  final int? percentDone;
  final int? totalFiles;
  final int? filesRestored;
  final int? filesSkipped;
  final int? totalBytes;
  final int? bytesRestored;
  final int? bytesSkipped;

  // Error
  final String? errorMessage;
  final String? during;
  // final String? item;

  // Verbose Status
  final String? action;
  final int? size;
  final String? item;
  RestoreOutput(
    this.messageType,
    this.secondsElapsed,
    this.percentDone,
    this.totalFiles,
    this.filesRestored,
    this.filesSkipped,
    this.totalBytes,
    this.bytesRestored,
    this.bytesSkipped,
    this.errorMessage,
    this.during,
    this.item,
    this.action,
    this.size,
  );
  factory RestoreOutput.fromJson(Map<String, dynamic> json) =>
      _$RestoreOutputFromJson(json);
}
