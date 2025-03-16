import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_card.dart';
import 'path_card.dart';
import 'retention_card.dart';
import 'system_card.dart';

class SettingsKeys {
  static const backupPaths = "backupPaths";
  static const useBackupInterval = "useBackupIntervalKey";
  static const backupInterval = "backupIntervalKey";
  static const useBackupRetentionPeriod = "useBackupRetentionPeriodKey";
  static const backupRetentionPeriod = "backupRetentionPeriodKey";
  static const checkInterval = "checkInterval";
  static const concurrencyLimit = "concurrencyLimit";
  static const autoStartup = "autoStartup ";
}

class SettingContext {
  List<String> backupPaths;
  bool useBackupInterval;
  int backupInterval;
  bool useBackupRetentionPeriod;
  int backupRetentionPeriod;
  int checkInterval;
  int concurrencyLimit;
  bool autoStartup;

  SettingContext({
    this.backupPaths = const [],
    this.useBackupInterval = false,
    this.backupInterval = 30,
    this.useBackupRetentionPeriod = false,
    this.backupRetentionPeriod = 30,
    this.checkInterval = 5,
    this.concurrencyLimit = 5,
    this.autoStartup = true,
  });

  void loadPrefer(SharedPreferences prefer) {
    final List<String> paths =
        prefer.getStringList(SettingsKeys.backupPaths) ?? [];

    backupPaths = paths;
    useBackupInterval =
        prefer.getBool(SettingsKeys.useBackupInterval) ?? useBackupInterval;
    backupInterval =
        prefer.getInt(SettingsKeys.backupInterval) ?? backupInterval;
    useBackupRetentionPeriod =
        prefer.getBool(SettingsKeys.useBackupRetentionPeriod) ??
            useBackupRetentionPeriod;
    backupRetentionPeriod = prefer.getInt(SettingsKeys.backupRetentionPeriod) ??
        backupRetentionPeriod;
    checkInterval = prefer.getInt(SettingsKeys.checkInterval) ?? checkInterval;
    concurrencyLimit =
        prefer.getInt(SettingsKeys.concurrencyLimit) ?? concurrencyLimit;
    autoStartup = prefer.getBool(SettingsKeys.autoStartup) ?? autoStartup;
  }

  Future<void> savePrefer(SharedPreferences prefer) async {
    await Future.wait([
      prefer.setStringList(SettingsKeys.backupPaths, backupPaths),
      prefer.setBool(SettingsKeys.useBackupInterval, useBackupInterval),
      prefer.setInt(SettingsKeys.backupInterval, backupInterval),
      prefer.setBool(
          SettingsKeys.useBackupRetentionPeriod, useBackupRetentionPeriod),
      prefer.setInt(SettingsKeys.backupRetentionPeriod, backupRetentionPeriod),
      prefer.setInt(SettingsKeys.checkInterval, checkInterval),
      prefer.setInt(SettingsKeys.concurrencyLimit, concurrencyLimit),
      prefer.setBool(SettingsKeys.autoStartup, autoStartup),
    ]);
  }
}

class SettingView extends StatefulWidget {
  const SettingView({
    required this.onUpdate,
    Key? key,
  }) : super(key: key);

  final void Function(SettingContext settingContext) onUpdate;

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  late final SharedPreferences _prefer;
  final log = Logger('Home');
  final SettingContext _context = SettingContext();

  Future<void> _updateSettings() async {
    try {
      await _context.savePrefer(_prefer);
      widget.onUpdate(_context);
    } catch (e) {
      log.shout('更新配置时出错: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _init() async {
    _prefer = await SharedPreferences.getInstance();
    _context.loadPrefer(_prefer);
    widget.onUpdate(_context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          PathCard(
            paths: _context.backupPaths,
            onDataChanged: (List<String> value) {
              _context.backupPaths = value;
              _updateSettings();
              setState(() {});
            },
          ),
          BackupCard(
            enabled: _context.useBackupInterval,
            backupInterval: _context.backupInterval,
            onUpdate: (bool enable, int text) {
              _context.backupInterval = text;
              _context.useBackupInterval = enable;
              _updateSettings();
            },
          ),
          RetentionCard(
            enabled: _context.useBackupRetentionPeriod,
            retentionPeriod: _context.backupRetentionPeriod,
            checkInterval: _context.checkInterval,
            onUpdate: (bool enable, int retentionPeriod, int checkInterval) {
              _context.useBackupRetentionPeriod = enable;
              _context.backupRetentionPeriod = retentionPeriod;
              _context.checkInterval = checkInterval;
              _updateSettings();
            },
          ),
          SystemCard(
            concurrencyLimit: _context.concurrencyLimit,
            autoStartup: _context.autoStartup,
            onUpdate: (int concurrencyLimit, bool autoStartup) {
              _context.concurrencyLimit = concurrencyLimit;
              _context.autoStartup = autoStartup;
              _updateSettings();
            },
          ),
        ],
      ),
    );
  }
}
