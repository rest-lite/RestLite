import 'dart:ffi' as ffi;

const int ctrlCEvent = 0;

typedef GenerateConsoleCtrlEventNative = ffi.Int32 Function(
    ffi.Uint32 dwCtrlEvent, ffi.Uint32 dwProcessGroupId);
typedef GenerateConsoleCtrlEventDart = int Function(
    int dwCtrlEvent, int dwProcessGroupId);

typedef AttachConsoleNative = ffi.Int32 Function(ffi.Uint32 dwProcessId);
typedef AttachConsoleDart = int Function(int dwProcessId);

typedef FreeConsoleNative = ffi.Int32 Function();
typedef FreeConsoleDart = int Function();

typedef SetConsoleCtrlHandlerNative = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> handler, ffi.Int32 add);
typedef SetConsoleCtrlHandlerDart = int Function(
    ffi.Pointer<ffi.Void> handler, int add);

/// 向指定 pid 的进程发送 CTRL_C_EVENT 信号
///
/// 仅限windows平台
///
/// dart中[Process.kill](https://api.flutter.dev/flutter/dart-io/Process/kill.html)不支持在windows平台发送SIGINT信号，使用此方法替代
void sendCtrlCEvent(int pid) {
  // 加载 kernel32.dll
  final kernel32 = ffi.DynamicLibrary.open('kernel32.dll');

  final freeConsole = kernel32
      .lookupFunction<FreeConsoleNative, FreeConsoleDart>('FreeConsole');
  final attachConsole = kernel32
      .lookupFunction<AttachConsoleNative, AttachConsoleDart>('AttachConsole');
  final generateConsoleCtrlEvent = kernel32.lookupFunction<
      GenerateConsoleCtrlEventNative,
      GenerateConsoleCtrlEventDart>('GenerateConsoleCtrlEvent');
  final setConsoleCtrlHandler = kernel32.lookupFunction<
      SetConsoleCtrlHandlerNative,
      SetConsoleCtrlHandlerDart>('SetConsoleCtrlHandler');

  // 1. 先脱离当前控制台（如果有的话）
  freeConsole();

  // 2. 附加到目标进程的控制台
  if (attachConsole(pid) == 0) {
    print('附加控制台失败，请检查 pid 是否正确以及目标进程是否有控制台。');
    return;
  }

  // 3. 设置一个空的控制台控制处理器，避免当前进程接收到 CTRL_C_EVENT 后退出
  // 传入 null 指针表示默认处理，第二个参数 1 表示添加处理器
  setConsoleCtrlHandler(ffi.Pointer.fromAddress(0), 1);

  // 4. 发送 CTRL_C_EVENT 信号，第二个参数传入 pid（要求目标进程独立在一个进程组中）
  if (generateConsoleCtrlEvent(ctrlCEvent, pid) == 0) {
    print('发送 CTRL_C_EVENT 失败。');
  }

  // 5. 移除空的信号处理器设置
  setConsoleCtrlHandler(ffi.Pointer.fromAddress(0), 0);

  // 6. 脱离当前控制台
  freeConsole();
}
