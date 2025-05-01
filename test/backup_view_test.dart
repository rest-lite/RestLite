import 'package:flutter_test/flutter_test.dart';
import 'package:rest_lite/services/store.dart';
import 'package:rest_lite/views/backup_view/util.dart';

void main() {
  group('buildDirectoryTree', () {
    test('空输入返回仅有根节点的树', () {
      final tree = buildDirectoryTree({});
      expect(tree.path, '/');
      // 根节点 children 为空或为 null 均可视为正确
      expect(tree.children == null || tree.children!.isEmpty, isTrue);
    });

    test('单个节点测试', () {
      final dt = DateTime(2020, 1, 1);
      final node = Node(
        name: 'fileA',
        type: 'file',
        path: '/C/Users/userA/Desktop/fileA',
        size: 100,
        snapshotID: 's1',
        snapshotsTime: dt,
        modificationTime: dt,
      );
      final tree = buildDirectoryTree({node});

      // 根据算法，父节点为 "/C/Users/userA/Desktop"，名称为 "C/Users/userA/Desktop"
      expect(tree.children, isNotNull);
      expect(tree.children!.length, 1);

      final parentDir = tree.children!.first;
      expect(parentDir.path, '/C/Users/userA/Desktop');
      expect(parentDir.name, 'C/Users/userA/Desktop');

      // 父节点下应包含 fileA 节点
      expect(parentDir.children, isNotNull);
      expect(parentDir.children!.length, 1);
      final fileNode = parentDir.children!.first;
      expect(fileNode.path, '/C/Users/userA/Desktop/fileA');
      expect(fileNode.name, 'fileA');
      expect(fileNode.isDirectory, isFalse);
      expect(fileNode.snapshots.length, 1);
    });

    test('多个节点构建目录树', () {
      final dt = DateTime(2020, 1, 1);

      Node createNode(String type, String name, String path) {
        return Node(
          name: name,
          type: type,
          path: path,
          size: 100,
          snapshotID: 's1',
          snapshotsTime: dt,
          modificationTime: dt,
        );
      }

      final nodes = {
        createNode('file', 'fileA', '/C/Users/userA/Desktop/fileA'),
        createNode('file', 'fileB', '/C/Users/userA/Desktop/fileB'),
        createNode('file', 'fileA', '/C/Users/userB/Desktop/fileA'),
        createNode('file', 'fileA', '/C/Users/userB/Desktop/dirA/fileA'),
        createNode('dir', 'User', '/C/Users'),
        createNode('dir', 'userC', '/C/Users/userC'),
        createNode('file', 'fileA', '/C/Users/userC/fileA'),
        createNode('file', 'fileA', '/C/Users/userD/fileA'),
      };

      final tree = buildDirectoryTree(nodes);
      final want = DirectoryNode(
          name: "/",
          path: "/",
          isDirectory: true,
          snapshots: {},
          children: [
            DirectoryNode(
                name: "C/Users/userC",
                path: "/C/Users/userC",
                isDirectory: true,
                snapshots: {
                  SnapshotInfo("s1", null, dt, dt)
                },
                children: [
                  DirectoryNode(
                      name: "fileA",
                      path: "/C/Users/userC/fileA",
                      isDirectory: false,
                      snapshots: {SnapshotInfo("s1", 100, dt, dt)},
                      children: null),
                ]),
            DirectoryNode(
                name: "C/Users/userD",
                path: "/C/Users/userD",
                isDirectory: true,
                snapshots: {
                  SnapshotInfo("s1", null, dt, dt)
                },
                children: [
                  DirectoryNode(
                      name: "fileA",
                      path: "/C/Users/userD/fileA",
                      isDirectory: false,
                      snapshots: {SnapshotInfo("s1", 100, dt, dt)},
                      children: null),
                ]),
            DirectoryNode(
                name: "C/Users/userA/Desktop",
                path: "/C/Users/userA/Desktop",
                isDirectory: true,
                snapshots: {
                  SnapshotInfo("s1", null, dt, dt)
                },
                children: [
                  DirectoryNode(
                      name: "fileA",
                      path: "/C/Users/userA/Desktop/fileA",
                      isDirectory: false,
                      snapshots: {SnapshotInfo("s1", 100, dt, dt)},
                      children: null),
                  DirectoryNode(
                      name: "fileB",
                      path: "/C/Users/userA/Desktop/fileB",
                      isDirectory: false,
                      snapshots: {SnapshotInfo("s1", 100, dt, dt)},
                      children: null)
                ]),
            DirectoryNode(
                name: "C/Users/userB/Desktop",
                path: "/C/Users/userB/Desktop",
                isDirectory: true,
                snapshots: {
                  SnapshotInfo("s1", null, dt, dt)
                },
                children: [
                  DirectoryNode(
                      name: "fileA",
                      path: "/C/Users/userB/Desktop/fileA",
                      isDirectory: false,
                      snapshots: {SnapshotInfo("s1", 100, dt, dt)},
                      children: null),
                  DirectoryNode(
                      name: "dirA",
                      path: "/C/Users/userB/Desktop/dirA",
                      isDirectory: true,
                      snapshots: {
                        SnapshotInfo("s1", null, dt, dt)
                      },
                      children: [
                        DirectoryNode(
                            name: "fileA",
                            path: "/C/Users/userB/Desktop/dirA/fileA",
                            isDirectory: false,
                            snapshots: {SnapshotInfo("s1", 100, dt, dt)},
                            children: null)
                      ])
                ]),
          ]);
      void compareTrees(
          DirectoryNode actual, DirectoryNode expected, String path) {
        expect(actual.name, expected.name, reason: "路径 $path 的名称不匹配");
        expect(actual.path, expected.path, reason: "路径 $path 的路径值不匹配");
        expect(actual.isDirectory, expected.isDirectory,
            reason: "路径 $path 是否为目录的状态不匹配");
        // expect(actual.snapshots, expected.snapshots,
        //     reason: "路径 $path 的快照数据不匹配");

        if ((actual.children == null) != (expected.children == null)) {
          fail("路径 $path：一个有子节点，一个没有");
        }

        if (actual.children != null && expected.children != null) {
          expect(actual.children!.length, expected.children!.length,
              reason: "路径 $path 的子节点数量不匹配");

          for (int i = 0; i < actual.children!.length; i++) {
            compareTrees(actual.children![i], expected.children![i],
                actual.children![i].path);
          }
        }
      }

      compareTrees(tree, want, "/");
    });

    test('重复节点应合并快照信息', () {
      final dt = DateTime(2020, 1, 1);
      final node1 = Node(
        name: 'fileA',
        type: 'file',
        path: '/C/Users/userA/Desktop/fileA',
        size: 100,
        snapshotID: 's1',
        snapshotsTime: dt,
        modificationTime: dt,
      );
      final node2 = Node(
        name: 'fileA',
        type: 'file',
        path: '/C/Users/userA/Desktop/fileA',
        size: 150,
        snapshotID: 's2',
        snapshotsTime: dt,
        modificationTime: dt,
      );

      final tree = buildDirectoryTree({node1, node2});
      // 先获取父目录节点 "/C/Users/userA/Desktop"
      final parentDir = tree.children!.firstWhere(
          (n) => n.path == '/C/Users/userA/Desktop',
          orElse: () => throw '缺少目录 /C/Users/userA/Desktop');
      // 在该目录下找到 fileA 节点
      final fileNode = parentDir.children!.firstWhere(
          (n) => n.path == '/C/Users/userA/Desktop/fileA',
          orElse: () => throw '缺少文件 /C/Users/userA/Desktop/fileA');
      // 快照版本数量应为 2
      expect(fileNode.snapshots.length, 2);
    });
  });
}
