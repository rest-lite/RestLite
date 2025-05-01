import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/view_navigator.dart';
import 'pages/login.dart';
import 'services/periodic.dart';
import 'services/restic.dart' as restic_service;
import 'services/restic.dart';
import 'services/logger.dart' as log;
import 'services/store.dart';
import 'views/backup_view/util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(600, 400),
    center: true,
    // backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 将关闭按钮事件改为最小化
  await windowManager.setPreventClose(true);
  windowManager.addListener(CustomWindowListener());

  // 开机启动
  launchAtStartup.setup(
    appName: "RestLite",
    appPath: Platform.resolvedExecutable,
  );

  log.init();
  await store.init();
  restic_service.init(5);

  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('zh')],
    path: 'assets/translations',
    fallbackLocale: const Locale('zh'),
    child: const App(),
  ));
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest Lite',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        // https://github.com/flutter/flutter/issues/103811#issuecomment-1849033360
        fontFamily: Platform.isWindows ? "Microsoft YaHei" : null,
      ),
      home: const PageNavigator(),
    );
  }
}

class CustomWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    // 隐藏窗口而不是关闭
    await windowManager.hide();
  }
}

class PageNavigator extends StatefulWidget {
  const PageNavigator({super.key});

  @override
  State<PageNavigator> createState() => _PageNavigatorState();
}

class _PageNavigatorState extends State<PageNavigator> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    _initTray();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    bool visible = await windowManager.isVisible();
    if (visible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
  }

  @override
  void onTrayIconMouseUp() {}

  @override
  void onTrayIconRightMouseDown() {
    // bringAppToFront 可以起到更新菜单隐藏状态的效果
    // https://github.com/leanflutter/tray_manager/issues/63#issuecomment-2700179592
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayIconRightMouseUp() {}

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {}

  Future<void> _initTray() async {
    // 注意：Windows 平台需要使用 .ico 格式，其他平台可用 .png
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/tray_icon.ico' : 'assets/tray_icon.png',
    );
    trayManager.setToolTip(context.tr('tray.tooltip'));

    // 定义一个只有“退出”菜单项的简单菜单
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show',
          label: context.tr('tray.menu_show'),
          onClick: (item) {
            windowManager.show();
          },
        ),
        MenuItem(
          key: 'show',
          label: context.tr('tray.menu_hide'),
          onClick: (item) {
            windowManager.hide();
          },
        ),
        MenuItem(
            key: 'exit',
            label: context.tr('tray.menu_exit'),
            onClick: (item) async {
              await windowManager.setPreventClose(false);
              windowManager.close();
            }),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  LoginContext? loginContext;
  void _login(String savePath, String password) {
    setState(() {
      loginContext = LoginContext(savePath: savePath, password: password);
    });
  }

  void _exit() {
    // 退出时取消所有restic任务
    resticService.runningTasks().forEach(
      (element) {
        element.cancel();
      },
    );
    resticService.queuedTasks().forEach(
      (element) {
        element.cancel();
      },
    );
    setState(() {
      loginContext = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    BackupService.build(context);
    BackupRetentionCheckService.build(context);

    final login = MaterialPage(
        key: const ValueKey('login'),
        child: Login(
          login: _login,
        ));

    final _loginContext = loginContext;

    final pages = [
      login,
      if (_loginContext != null)
        MaterialPage(
            key: const ValueKey('home'),
            child: ViewNavigator(
              key: const ValueKey('homeNavigator'),
              loginContext: _loginContext,
              exit: _exit,
            )),
    ];

    return Navigator(
      pages: pages,
      onDidRemovePage: (page) {},
    );
  }
}
