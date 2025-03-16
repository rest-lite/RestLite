// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackupOutput _$BackupOutputFromJson(Map<String, dynamic> json) => BackupOutput(
      messageType: json['message_type'] as String,
      error: json['error'] == null
          ? null
          : BackupError.fromJson(json['error'] as Map<String, dynamic>),
      secondsElapsed: (json['seconds_elapsed'] as num?)?.toInt(),
      secondsRemaining: (json['seconds_remaining'] as num?)?.toInt(),
      errorCount: (json['error_count'] as num?)?.toInt(),
      during: json['during'] as String?,
      item: json['item'] as String?,
      filesNew: (json['files_new'] as num?)?.toInt(),
      filesChanged: (json['files_changed'] as num?)?.toInt(),
      filesUnmodified: (json['files_unmodified'] as num?)?.toInt(),
      dirsNew: (json['dirs_new'] as num?)?.toInt(),
      dirsChanged: (json['dirs_changed'] as num?)?.toInt(),
      dirsUnmodified: (json['dirs_unmodified'] as num?)?.toInt(),
      dataBlobs: (json['data_blobs'] as num?)?.toInt(),
      treeBlobs: (json['tree_blobs'] as num?)?.toInt(),
      dataAdded: (json['data_added'] as num?)?.toInt(),
      totalFilesProcessed: (json['total_files_processed'] as num?)?.toInt(),
      totalBytesProcessed: (json['total_bytes_processed'] as num?)?.toInt(),
      totalDuration: (json['total_duration'] as num?)?.toInt(),
      snapshotId: json['snapshot_id'] as String?,
      percentDone: (json['percent_done'] as num?)?.toInt(),
      totalFiles: (json['total_files'] as num?)?.toInt(),
      filesDone: (json['files_done'] as num?)?.toInt(),
      totalBytes: (json['total_bytes'] as num?)?.toInt(),
      bytesDone: (json['bytes_done'] as num?)?.toInt(),
      currentFiles: (json['current_files'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BackupOutputToJson(BackupOutput instance) =>
    <String, dynamic>{
      'message_type': instance.messageType,
      'seconds_elapsed': instance.secondsElapsed,
      'seconds_remaining': instance.secondsRemaining,
      'percent_done': instance.percentDone,
      'total_files': instance.totalFiles,
      'files_done': instance.filesDone,
      'total_bytes': instance.totalBytes,
      'bytes_done': instance.bytesDone,
      'error_count': instance.errorCount,
      'current_files': instance.currentFiles,
      'error': instance.error,
      'during': instance.during,
      'item': instance.item,
      'files_new': instance.filesNew,
      'files_changed': instance.filesChanged,
      'files_unmodified': instance.filesUnmodified,
      'dirs_new': instance.dirsNew,
      'dirs_changed': instance.dirsChanged,
      'dirs_unmodified': instance.dirsUnmodified,
      'data_blobs': instance.dataBlobs,
      'tree_blobs': instance.treeBlobs,
      'data_added': instance.dataAdded,
      'total_files_processed': instance.totalFilesProcessed,
      'total_bytes_processed': instance.totalBytesProcessed,
      'total_duration': instance.totalDuration,
      'snapshot_id': instance.snapshotId,
    };

BackupError _$BackupErrorFromJson(Map<String, dynamic> json) => BackupError(
      message: json['message'] as String,
    );

Map<String, dynamic> _$BackupErrorToJson(BackupError instance) =>
    <String, dynamic>{
      'message': instance.message,
    };

LsOutput _$LsOutputFromJson(Map<String, dynamic> json) => LsOutput(
      messageType: json['message_type'] as String,
      time: json['time'] as String?,
      parent: json['parent'] as String?,
      tree: json['tree'] as String?,
      paths:
          (json['paths'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hostname: json['hostname'] as String?,
      username: json['username'] as String?,
      programVersion: json['program_version'] as String?,
      id: json['id'] as String?,
      shortId: json['short_id'] as String?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      path: json['path'] as String?,
      size: (json['size'] as num?)?.toInt(),
      uid: (json['uid'] as num?)?.toInt(),
      gid: (json['gid'] as num?)?.toInt(),
      mode: (json['mode'] as num?)?.toInt(),
      permissions: json['permissions'] as String?,
      mtime: json['mtime'] as String?,
      atime: json['atime'] as String?,
      ctime: json['ctime'] as String?,
    );

Map<String, dynamic> _$LsOutputToJson(LsOutput instance) => <String, dynamic>{
      'message_type': instance.messageType,
      'time': instance.time,
      'parent': instance.parent,
      'tree': instance.tree,
      'paths': instance.paths,
      'hostname': instance.hostname,
      'username': instance.username,
      'program_version': instance.programVersion,
      'id': instance.id,
      'short_id': instance.shortId,
      'name': instance.name,
      'type': instance.type,
      'path': instance.path,
      'size': instance.size,
      'uid': instance.uid,
      'gid': instance.gid,
      'mode': instance.mode,
      'permissions': instance.permissions,
      'mtime': instance.mtime,
      'atime': instance.atime,
      'ctime': instance.ctime,
    };

SnapshotSummary _$SnapshotSummaryFromJson(Map<String, dynamic> json) =>
    SnapshotSummary(
      backupStart: json['backup_start'] as String,
      backupEnd: json['backup_end'] as String,
      filesNew: (json['files_new'] as num).toInt(),
      filesChanged: (json['files_changed'] as num).toInt(),
      filesUnmodified: (json['files_unmodified'] as num).toInt(),
      dirsNew: (json['dirs_new'] as num).toInt(),
      dirsChanged: (json['dirs_changed'] as num).toInt(),
      dirsUnmodified: (json['dirs_unmodified'] as num).toInt(),
      dataBlobs: (json['data_blobs'] as num).toInt(),
      treeBlobs: (json['tree_blobs'] as num).toInt(),
      dataAdded: (json['data_added'] as num).toInt(),
      dataAddedPacked: (json['data_added_packed'] as num).toInt(),
      totalFilesProcessed: (json['total_files_processed'] as num).toInt(),
      totalBytesProcessed: (json['total_bytes_processed'] as num).toInt(),
    );

Map<String, dynamic> _$SnapshotSummaryToJson(SnapshotSummary instance) =>
    <String, dynamic>{
      'backup_start': instance.backupStart,
      'backup_end': instance.backupEnd,
      'files_new': instance.filesNew,
      'files_changed': instance.filesChanged,
      'files_unmodified': instance.filesUnmodified,
      'dirs_new': instance.dirsNew,
      'dirs_changed': instance.dirsChanged,
      'dirs_unmodified': instance.dirsUnmodified,
      'data_blobs': instance.dataBlobs,
      'tree_blobs': instance.treeBlobs,
      'data_added': instance.dataAdded,
      'data_added_packed': instance.dataAddedPacked,
      'total_files_processed': instance.totalFilesProcessed,
      'total_bytes_processed': instance.totalBytesProcessed,
    };

Snapshot _$SnapshotFromJson(Map<String, dynamic> json) => Snapshot(
      parent: json['parent'] as String?,
      uid: json['uid'] as String?,
      gid: json['gid'] as String?,
      excludes: (json['excludes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      summary: json['summary'] == null
          ? null
          : SnapshotSummary.fromJson(json['summary'] as Map<String, dynamic>),
      time: json['time'] as String,
      tree: json['tree'] as String,
      paths: (json['paths'] as List<dynamic>).map((e) => e as String).toList(),
      hostname: json['hostname'] as String,
      username: json['username'] as String,
      programVersion: json['program_version'] as String,
      id: json['id'] as String,
      shortId: json['short_id'] as String,
    );

Map<String, dynamic> _$SnapshotToJson(Snapshot instance) => <String, dynamic>{
      'time': instance.time,
      'parent': instance.parent,
      'tree': instance.tree,
      'paths': instance.paths,
      'hostname': instance.hostname,
      'username': instance.username,
      'uid': instance.uid,
      'gid': instance.gid,
      'excludes': instance.excludes,
      'tags': instance.tags,
      'program_version': instance.programVersion,
      'summary': instance.summary,
      'id': instance.id,
      'short_id': instance.shortId,
    };

ForgetGroup _$ForgetGroupFromJson(Map<String, dynamic> json) => ForgetGroup(
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      host: json['host'] as String,
      paths: (json['paths'] as List<dynamic>).map((e) => e as String).toList(),
      keep: (json['keep'] as List<dynamic>?)
          ?.map((e) => Snapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      remove: (json['remove'] as List<dynamic>?)
          ?.map((e) => Snapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      reasons: (json['reasons'] as List<dynamic>)
          .map((e) => KeepReason.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForgetGroupToJson(ForgetGroup instance) =>
    <String, dynamic>{
      'tags': instance.tags,
      'host': instance.host,
      'paths': instance.paths,
      'keep': instance.keep,
      'remove': instance.remove,
      'reasons': instance.reasons,
    };

KeepReason _$KeepReasonFromJson(Map<String, dynamic> json) => KeepReason(
      snapshot: Snapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
      matches:
          (json['matches'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$KeepReasonToJson(KeepReason instance) =>
    <String, dynamic>{
      'snapshot': instance.snapshot,
      'matches': instance.matches,
    };

RestoreOutput _$RestoreOutputFromJson(Map<String, dynamic> json) =>
    RestoreOutput(
      json['message_type'] as String,
      (json['seconds_elapsed'] as num?)?.toInt(),
      (json['percent_done'] as num?)?.toInt(),
      (json['total_files'] as num?)?.toInt(),
      (json['files_restored'] as num?)?.toInt(),
      (json['files_skipped'] as num?)?.toInt(),
      (json['total_bytes'] as num?)?.toInt(),
      (json['bytes_restored'] as num?)?.toInt(),
      (json['bytes_skipped'] as num?)?.toInt(),
      json['error_message'] as String?,
      json['during'] as String?,
      json['item'] as String?,
      json['action'] as String?,
      (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RestoreOutputToJson(RestoreOutput instance) =>
    <String, dynamic>{
      'message_type': instance.messageType,
      'seconds_elapsed': instance.secondsElapsed,
      'percent_done': instance.percentDone,
      'total_files': instance.totalFiles,
      'files_restored': instance.filesRestored,
      'files_skipped': instance.filesSkipped,
      'total_bytes': instance.totalBytes,
      'bytes_restored': instance.bytesRestored,
      'bytes_skipped': instance.bytesSkipped,
      'error_message': instance.errorMessage,
      'during': instance.during,
      'action': instance.action,
      'size': instance.size,
      'item': instance.item,
    };
