import 'package:flutter/material.dart';

import 'empty_widget.dart';

///Support Clip.none in contrast to ClipRect.
class CustomClipRect extends StatefulWidget {
  final Widget child;
  final Clip clipBehaviour;

  const CustomClipRect(
      {Key? key, required this.child, this.clipBehaviour = Clip.hardEdge})
      : super(key: key);

  @override
  State<CustomClipRect> createState() => _CustomClipRectState();
}

class _CustomClipRectState extends State<CustomClipRect> {
  final UniqueKey _childKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    Widget child = EmptyWidget(key: _childKey, child: widget.child);
    if (widget.clipBehaviour == Clip.none) return child;
    return ClipRect(
      child: child,
      clipBehavior: widget.clipBehaviour,
    );
  }
}
