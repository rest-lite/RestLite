import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:logging/logging.dart';
import 'package:rest_lite/services/periodic.dart';
import 'package:rest_lite/views/backup_view/backup_view.dart';
import 'package:rest_lite/views/queue_view.dart';
import 'package:rest_lite/views/setting_view/setting_view.dart';

import '../services/restic.dart';
import '../views/backup_view/util.dart';
import 'home_navigator.dart';

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.loginContext,
    required this.exit,
    required this.pageBuild,
  });
  final LoginContext loginContext;

  final void Function() exit;
  final PageBuild pageBuild;

  @override
  State<Home> createState() => _HomeState();
}

final log = Logger('Home');

class _HomeState extends State<Home> {
  var _selectedIndex = 0;
  SettingContext? settingContext;
  @override
  void didUpdateWidget(covariant Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loginContext != widget.loginContext) {
      log.fine("Home didUpdateWidget updateService");
      updateService();
    }
  }

  @override
  void dispose() {
    BackupService.stop();
    BackupRetentionCheckService.stop();
    super.dispose();
  }

  Future<void> updateService() async {
    var _settingContext = settingContext;

    if (_settingContext == null) return;

    final autoStartup = await launchAtStartup.isEnabled();
    log.fine("autoStartup: " + autoStartup.toString());
    if (_settingContext.autoStartup != autoStartup) {
      if (_settingContext.autoStartup) {
        await launchAtStartup.enable();
        log.fine("enable autoStartup");
      } else {
        await launchAtStartup.disable();
        log.fine("disable autoStartup");
      }
    }

    resticService.maxConcurrency = _settingContext.concurrencyLimit;

    if (!_settingContext.useBackupInterval) {
      log.fine("SettingView didUpdateWidget, useBackupInterval is false");
      BackupService.stop();
    } else {
      BackupService.update(
        Duration(minutes: _settingContext.backupInterval),
        widget.loginContext.savePath,
        _settingContext.backupPaths,
        widget.loginContext.password,
      );
    }
    if (!_settingContext.useBackupRetentionPeriod) {
      log.fine(
          "SettingView didUpdateWidget, useBackupRetentionPeriod is false");
      BackupRetentionCheckService.stop();
    } else {
      BackupRetentionCheckService.update(
        Duration(minutes: _settingContext.checkInterval),
        _settingContext.backupRetentionPeriod,
        widget.loginContext.savePath,
        widget.loginContext.password,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _settingContext = settingContext;
    final views = [
      if (_settingContext != null)
        BackupView(
          key: const ValueKey("backupView"),
          loginContext: widget.loginContext,
          settingContext: _settingContext,
          pageBuild: widget.pageBuild,
        )
      else
        Container(),
      const QueueView(
        key: ValueKey("queueView"),
      ),
      SettingView(
        key: const ValueKey("settingView"),
        onUpdate: (value) {
          log.fine(
              "SettingView onUpdate, settingContext is updated; ${value.toString()}");
          setState(() {
            settingContext = value;
          });
          updateService();
        },
      ),
    ];
    final home = Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.insert_drive_file),
                  label: Text('备份'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.view_list),
                  label: Text('任务'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings),
                  label: Text('设置'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: widget.exit,
                      child: const Text("退出"),
                    ),
                  ),
                ),
              ),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  _selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
              child: IndexedStack(
            index: _selectedIndex,
            children: views,
          )),
        ],
      ),
    );
    return home;
  }
}
