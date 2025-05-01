import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
// ignore: unnecessary_import
import 'package:objectbox/objectbox.dart';

final store = DB._internal();

class DB {
  final log = Logger('Store Service');
  late final Store database;
  DB._internal();

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();

    database = await openStore(directory: p.join(docsDir.path, "RestLite"));
  }

  Future<Set<Node>?> getFileListCachedData(
    String snapshotID,
    String path,
  ) async {
    final snapshotBox = database.box<SnapshotStore>();
    final query = (snapshotBox.query(
            SnapshotStore_.snapshotID.equals(snapshotID) &
                SnapshotStore_.path.equals(path)))
        .build();
    final results = await query.findAsync();
    query.close();

    if (results.isEmpty) {
      return null;
    }
    return results.first.nodes.toSet();
  }

  Future<void> setFileListCachedData(
    String snapshotID,
    String path,
    Set<Node> data,
  ) async {
    final snapshotStore = SnapshotStore(snapshotID: snapshotID, path: path);
    snapshotStore.nodes.addAll(data);

    final snapshotBox = database.box<SnapshotStore>();
    await snapshotBox.putAsync(snapshotStore);
  }

  Future<void> deleteFileListCachedData(String snapshotID) async {
    final snapshotBox = database.box<SnapshotStore>();
    final query =
        snapshotBox.query(SnapshotStore_.snapshotID.equals(snapshotID)).build();
    await snapshotBox.removeManyAsync(query.findIds());
    query.close();
  }
}

// 更新使用: flutter pub run build_runner build
@Entity()
class Node {
  @Id()
  int id;
  final String name;
  final String type;
  final String path;
  final int? size;

  @Property(type: PropertyType.date)
  final DateTime snapshotsTime;
  @Property(type: PropertyType.date)
  final DateTime modificationTime;
  final String snapshotID;
  Node({
    this.id = 0,
    required this.size,
    required this.name,
    required this.type,
    required this.path,
    required this.snapshotID,
    required this.snapshotsTime,
    required this.modificationTime,
  });
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Node &&
        other.path == path &&
        other.modificationTime == modificationTime &&
        other.size == size;
  }

  @override
  int get hashCode => path.hashCode ^ modificationTime.hashCode ^ size.hashCode;
}

@Entity()
class SnapshotStore {
  @Id()
  int id;
  final nodes = ToMany<Node>();
  final String snapshotID;
  final String path;
  SnapshotStore({
    this.id = 0,
    required this.snapshotID,
    required this.path,
  });
}
