import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../restic/core.dart'; // 用于路径选择

const _passwordKey = "password";
const _savePathKey = "savePath";
const _keepPasswordKey = "_keepPassword";

class Login extends StatefulWidget {
  const Login({required this.login, super.key});
  final void Function(String savePath, String password) login;

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _directorySelectorKey = GlobalKey<FormFieldState>();
  late final SharedPreferences _prefer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _savePathController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _prefer = await SharedPreferences.getInstance();
    setState(() {
      _passwordController.text = _prefer.getString(_passwordKey) ?? "";
      _keepPassword = _prefer.getBool(_keepPasswordKey) ?? true;
      _savePathController.text = _prefer.getString(_savePathKey) ?? "";
    });
    if (_keepPassword) _submitForm();
  }

  // 表单字段
  final _passwordController = TextEditingController();
  bool _keepPassword = false;
  final _savePathController = TextEditingController();

  // 表单交互控制
  bool _enabled = true;

  // 路径选择器
  Future<void> _pickPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _savePathController.text = selectedDirectory;
      });
      await _prefer.setString(_savePathKey, _savePathController.text);
    }
    _directorySelectorKey.currentState!.validate();
  }

  // 提交表单
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _enabled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr("login.check_repository")),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        action: SnackBarAction(
          label: context.tr("cancel"),
          onPressed: () {},
          textColor: Theme.of(context).colorScheme.onSecondary,
        ),
      ));

      final loginStatus = await checkRepositoryInitialized(
          _savePathController.text, _passwordController.text);

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      switch (loginStatus) {
        case RepositoryStatus.notExist:
          final (err, out, process) = await createRepo(
              _savePathController.text, _passwordController.text);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr("login.create_repository")),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            action: SnackBarAction(
              label: context.tr("cancel"),
              onPressed: () {
                process.kill();
              },
              textColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ));
          final exitCode = await process.exitCode;
          switch (exitCode) {
            // 创建储存库完成
            case 0:
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.tr("success")),
                backgroundColor: Theme.of(context).colorScheme.primary,
                action: SnackBarAction(
                  label: context.tr("ok"),
                  onPressed: () {},
                  textColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ));
              widget.login(_savePathController.text, _passwordController.text);
              loginOk();
            //储存库创建被取消
            case -1:
          }
          break;
        case RepositoryStatus.ok:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr("success")),
            backgroundColor: Theme.of(context).colorScheme.primary,
            action: SnackBarAction(
              label: context.tr("ok"),
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ));
          widget.login(_savePathController.text, _passwordController.text);
          loginOk();
        case RepositoryStatus.wrongPassword:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr("login.password_wrong")),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: context.tr("ok"),
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ));
        case RepositoryStatus.invalidPath:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr("login.repository_path_not_exist")),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: context.tr("ok"),
              onPressed: () {},
              textColor: Theme.of(context).colorScheme.onError,
            ),
          ));
        default:
          throw Exception("状态未处理: " + loginStatus.toString());
      }
      setState(() {
        _enabled = true;
      });
    }
  }

  void loginOk() async {
    if (!_keepPassword) {
      setState(() {
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // 使用 Center 使表单居中
        child: SingleChildScrollView(
          // 使用滚动视图确保窗口较小时仍能滚动
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              // 限制表单的最大宽度
              constraints: const BoxConstraints(maxWidth: 300),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch, // 让表单的控件宽度充满
                  children: <Widget>[
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          key: _directorySelectorKey,
                          enabled: _enabled,
                          controller: _savePathController,
                          decoration: InputDecoration(
                            labelText:
                                context.tr("login.repository_path_label_text"),
                            hintText:
                                context.tr("login.repository_path_hint_text"),
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.folder_open),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context
                                  .tr("login.repository_validator_tip");
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _enabled ? _pickPath : null,
                        child: Text(
                            context.tr("login.repository_path_select_button")),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // 密码输入框
                    TextFormField(
                      enabled: _enabled,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: context.tr("login.password_label_text"),
                        border: const OutlineInputBorder(),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      obscureText: true,
                      validator: (value) => _validatePassword(context, value),
                      onChanged: (value) async {
                        if (_validatePassword(context, value) != null) return;

                        if (_keepPassword) {
                          await _prefer.setString(
                              _passwordKey, _passwordController.text);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 开关
                    SwitchListTile(
                      title: Row(
                        children: [
                          Text(
                            context.tr("login.keep_password"),
                          ),
                          Tooltip(
                            message: context.tr("login.keep_password_tip"),
                            child: const Icon(
                              Icons.help_outline,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      value: _keepPassword,
                      onChanged: _enabled
                          ? (value) async {
                              setState(() {
                                _keepPassword = value;
                              });
                              if (_keepPassword) {
                                await _prefer.setString(
                                    _passwordKey, _passwordController.text);
                              } else {
                                await _prefer.remove(_passwordKey);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // 提交按钮
                    ElevatedButton(
                      onPressed: _enabled ? _submitForm : null,
                      child: Text(context.tr("confirm")),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _validatePassword(BuildContext context, String? value) {
  if (value == null || value.isEmpty) {
    return context.tr("login.password_validation_hint");
  }
  return null;
}
