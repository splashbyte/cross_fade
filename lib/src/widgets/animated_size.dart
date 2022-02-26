import 'package:flutter/material.dart';

import 'empty_widget.dart';

/// More efficient handling of [Duration.zero] in contrast to [AnimatedSize].
class CustomAnimatedSize extends StatefulWidget {
  final Clip clipBehavior;
  final Duration duration;
  final Curve curve;
  final Widget child;
  final AlignmentGeometry alignment;

  const CustomAnimatedSize({
    Key? key,
    this.clipBehavior = Clip.hardEdge,
    required this.duration,
    this.curve = Curves.linear,
    required this.child,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  State<CustomAnimatedSize> createState() => _CustomAnimatedSizeState();
}

class _CustomAnimatedSizeState extends State<CustomAnimatedSize> {
  final GlobalKey _childKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget child = EmptyWidget(key: _childKey, child: widget.child);
    if (widget.duration <= Duration.zero) return child;
    return AnimatedSize(
      clipBehavior: widget.clipBehavior,
      duration: widget.duration,
      curve: widget.curve,
      alignment: widget.alignment,
      child: child,
    );
  }
}
