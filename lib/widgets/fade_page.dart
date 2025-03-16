import 'package:flutter/material.dart';

// TODO: createRoute仅在创建页面时调用，如果仅切换页面位置不销毁页面，不会触发动画
// TODO: FadePage会阻止子组件的didUpdateWidget
class FadePage<T> extends Page<T> {
  final Widget child;

  const FadePage({
    super.key,
    required this.child,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
