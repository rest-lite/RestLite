import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

final String cliToolPath =
    path.join(Directory.current.path, 'bin', 'restic.exe');
const resticPassword = 'RESTIC_PASSWORD';

enum RepositoryStatus {
  ok,
  notExist,
  wrongPassword,
  invalidPath,
}

/// 检查储存库是否存在
Future<RepositoryStatus> checkRepositoryInitialized(
    String repositoryPath, String password) async {
  // 输入空字符串密码会导致restic一直等待输入密码，因此需要特殊处理
  if (password.isEmpty) {
    return RepositoryStatus.wrongPassword;
  }
  // 检查路径合法性
  final directory = Directory(repositoryPath);
  if (!await directory.exists()) {
    return RepositoryStatus.invalidPath;
  }
  // 检查储存库
  final process = await Process.start(
    cliToolPath,
    ['-r', repositoryPath, "cat", "config", "--json"],
    environment: {
      resticPassword: password,
    },
    mode: ProcessStartMode.normal,
  );

  // https://restic.readthedocs.io/en/latest/075_scripting.html#exit-codes
  final exitCode = await process.exitCode;
  switch (exitCode) {
    case 0:
      return RepositoryStatus.ok;
    case 10:
      return RepositoryStatus.notExist;
    case 12:
      return RepositoryStatus.wrongPassword;
    default:
      throw Exception(exitCode);
  }
}

/// 创建储存库
Future<
    (
      Stream<String> err,
      Stream<String> out,
      Process process,
    )> createRepo(String repositoryPath, String password) async {
  final process = await Process.start(
    cliToolPath,
    ["init", '--repo', repositoryPath, "--json"],
    environment: {
      resticPassword: password,
    },
    mode: ProcessStartMode.normal,
  );

  var stdout = process.stdout.transform(utf8.decoder).map((output) {
    return output;
  });

  var stderr = process.stderr.transform(utf8.decoder).map((error) {
    return error;
  });

  return (stderr, stdout, process);
}
