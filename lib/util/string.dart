String toLinuxStylePath(String path) {
  // 替换反斜杠为正斜杠
  String linuxPath = path.replaceAll(r'\', '/');

  // 如果路径以类似 "C:/" 的形式开头，将其替换为 "/C/"
  if (RegExp(r'^[a-zA-Z]:').hasMatch(linuxPath)) {
    linuxPath = '/${linuxPath[0]}${linuxPath.substring(2)}';
  }

  return linuxPath;
}

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes < 0) return "0 B";

  const suffixes = ["B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB"];
  int i = 0;
  double size = bytes.toDouble();

  // 计算合适的单位
  while (size >= 1024 && i < suffixes.length - 1) {
    size /= 1024;
    i++;
  }

  // 格式化结果，保留指定的小数位数
  return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
}
