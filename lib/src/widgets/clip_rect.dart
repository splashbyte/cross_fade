import 'package:flutter/material.dart';

import 'empty_widget.dart';

/// Support [Clip.none] in contrast to [ClipRect].
class CustomClipRect extends StatefulWidget {
  final Widget child;
  final Clip clipBehavior;

  const CustomClipRect(
      {Key? key, required this.child, this.clipBehavior = Clip.hardEdge})
      : super(key: key);

  @override
  State<CustomClipRect> createState() => _CustomClipRectState();
}

class _CustomClipRectState extends State<CustomClipRect> {
  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget child = EmptyWidget(key: _childKey, child: widget.child);
    if (widget.clipBehavior == Clip.none) return child;
    return ClipRect(
      child: child,
      clipBehavior: widget.clipBehavior,
    );
  }
}
