import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'alert_cubit.dart';

const kAlertHeight = 80.0;

class AlertWidget extends StatelessWidget {
  const AlertWidget({
    Key? key,
    required this.alertEntity,
  }) : super(key: key);

  final AlertEntity alertEntity;

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;
    return Material(
      child: Ink(
        color: alertEntity.backgroundColor,
        height: kAlertHeight + statusbarHeight,
        child: Column(
          children: [
            SizedBox(height: statusbarHeight),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 28.0),
                  IconTheme(
                    data: const IconThemeData(
                      color: Colors.white,
                      size: 36,
                    ),
                    child: Icon(alertEntity.leading),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Text(alertEntity.child),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28.0),
          ],
        ),
      ),
    );
  }
}

class AlertMessenger extends StatefulWidget {
  const AlertMessenger({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AlertMessenger> createState() => AlertMessengerState();

  static AlertMessengerState of(BuildContext context) {
    try {
      final scope = _AlertMessengerScope.of(context);
      return scope.state;
    } catch (error) {
      throw FlutterError.fromParts(
        [
          ErrorSummary('No AlertMessenger was found in the Element tree'),
          ErrorDescription('AlertMessenger required.'),
          ...context.describeMissingAncestor(
              expectedAncestorType: AlertMessenger),
        ],
      );
    }
  }
}

class AlertMessengerState extends State<AlertMessenger>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> animation;

  AlertEntity? alertEntity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final alertHeight = MediaQuery.of(context).padding.top + kAlertHeight;
    animation = Tween<double>(begin: -alertHeight, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _showAlert(AlertEntity value) async {
    alertEntity = value;
    await controller.forward();
  }

  Future<void> _hideAlert() async {
    await controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final statusbarHeight = MediaQuery.of(context).padding.top;

    return BlocListener<AlertCubit, AlertEntity?>(
      listener: (context, state) async {
        if (state != null) {
          await _hideAlert();

          _showAlert(state);
        } else {
          _hideAlert();
        }
      },
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final position = animation.value + kAlertHeight;
          return Stack(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            children: [
              Positioned.fill(
                top: position <= statusbarHeight
                    ? 0
                    : position - statusbarHeight,
                child: _AlertMessengerScope(
                  state: this,
                  child: widget.child,
                ),
              ),
              Positioned(
                top: animation.value,
                left: 0,
                right: 0,
                child: alertEntity != null
                    ? AlertWidget(alertEntity: alertEntity!)
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlertMessengerScope extends InheritedWidget {
  const _AlertMessengerScope({
    required this.state,
    required super.child,
  });

  final AlertMessengerState state;

  @override
  bool updateShouldNotify(_AlertMessengerScope oldWidget) =>
      state != oldWidget.state;

  static _AlertMessengerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AlertMessengerScope>();
  }

  static _AlertMessengerScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No _AlertMessengerScope found in context');
    return scope!;
  }
}
