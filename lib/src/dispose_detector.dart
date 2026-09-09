

import 'package:flutter/material.dart';

/// 创建人：  NX
/// 创建时间: 2023/6/15 13:44
/// 注释： 状态探测控件
class StateDetector<T extends Widget, S> extends StatefulWidget {
  final Function onInitState;
  final Function onDispose;
  final Function(StateDetector<T, S> oldWidget) onDidUpdateWidget;
  final T child;
  final S? tag; //自定义数据,用于dispose回调,比如指向父控件
  const StateDetector({super.key, 
    required this.child,
    required this.onInitState,
    required this.onDispose,
    required this.onDidUpdateWidget,
    this.tag,
  });
  @override
  _DisposeDetector<T, S> createState() => _DisposeDetector<T, S>();
}

class _DisposeDetector<T extends Widget, S> extends State<StateDetector<T, S>>
    with TickerProviderStateMixin {

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.onInitState();
  }

  @override
  void dispose() {
    super.dispose();
    widget.onDispose();
  }

  @override
  void didUpdateWidget(covariant StateDetector<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.onDidUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
