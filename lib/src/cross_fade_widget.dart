import 'package:flutter/material.dart';

import 'widgets/animated_size.dart';
import 'widgets/clip_rect.dart';
import 'widgets/empty_widget.dart';

/// A widget to apply a crossfade animation
/// between different states and/or widgets.
class CrossFade<T> extends StatefulWidget {
  /// The current value.
  final T value;

  /// The builder which builds the different values during the animation.
  final Widget Function(BuildContext, T) builder;

  /// The duration of the fading.
  final Duration duration;

  /// The overriding of the equals function.
  /// [CrossFade] only animates between two different values
  /// if [equals] returns [false] for these two.
  final bool Function(T, T) equals;

  /// [CrossFade] only highlights the new value during the animation
  /// if [highlightTransition] returns [true].
  final bool Function(T, T) highlightTransition;

  /// The maximum scale during the highlight animation.
  final double highlightScale;

  /// The duration of the whole highlight animation. Defaults to [duration].
  final Duration? highlightDuration;

  /// The alignment for the children of the underlying stack.
  final AlignmentGeometry stackAlignment;

  /// The clip behaviour for clipping while the size animation.
  /// For more customization like BorderRadius or similar please use
  /// widgets like [ClipRRect] or [Container] and their [clipBehavior].
  final Clip clipBehavior;

  /// Curve of the fading in animation.
  final Curve curve;

  /// Curve of the fading out animation. Defaults to [curve.flipped].
  final Curve? disappearingCurve;

  /// Curve of the highlighting animation.
  final Curve highlightingCurve;

  /// Reverse curve of the highlighting animation.
  /// Defaults to [highlightingCurve.flipped].
  final Curve? highlightingReverseCurve;

  /// Curve of the size animation.
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  final Curve sizeCurve;

  /// Duration of the size animation. Defaults to [duration].
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  final Duration? sizeDuration;

  // const constructor doesn't make sense here
  /// The default constructor of [CrossFade].
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  const CrossFade({
    Key? key,
    this.duration = const Duration(milliseconds: 750),
    required this.value,
    required this.builder,
    this.equals = _defaultEquals,
    this.highlightTransition = _defaultHighlightTransition,
    this.stackAlignment = AlignmentDirectional.center,
    this.highlightScale = 1.2,
    this.highlightDuration,
    this.clipBehavior = Clip.none,
    this.curve = Curves.easeIn,
    this.disappearingCurve,
    this.highlightingCurve = Curves.ease,
    this.highlightingReverseCurve,
    this.sizeCurve = Curves.linear,
    this.sizeDuration,
  }) : super(key: key);

  static bool _defaultEquals(dynamic t1, dynamic t2) => t1 == t2;

  static bool _defaultHighlightTransition(dynamic t1, dynamic t2) => false;

  @override
  _CrossFadeState<T> createState() => _CrossFadeState<T>();
}

class _CrossFadeState<T> extends State<CrossFade<T>>
    with TickerProviderStateMixin {
  late final List<T> _todo;
  late final AnimationController _opacityController;
  late final AnimationController _sizeController;
  late final CurvedAnimation _opacityAnimation;
  late final CurvedAnimation _sizeAnimation;
  final UniqueKey _stateKey = UniqueKey();
  final UniqueKey _animatedSizeKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _todo = [widget.value];
    _opacityController =
    AnimationController(vsync: this, duration: widget.duration, value: 1.0)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_todo.length <= 1) return;
          _todo.removeAt(0);
          // rebuild necessary for setting GlobalKeys simultaneously
          setState(() {});
          if (_todo.length > 1) {
            _animateNext();
          }
        }
      });

    _sizeController = AnimationController(
        vsync: this,
        duration: (widget.highlightDuration ?? widget.duration) * 0.5)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _sizeController.reverse();
        }
      });

    _opacityAnimation = CurvedAnimation(
      parent: _opacityController,
      curve: widget.curve,
      reverseCurve: widget.disappearingCurve,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _sizeController,
      curve: widget.highlightingCurve,
      reverseCurve: widget.highlightingReverseCurve,
    );
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CrossFade<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.equals(oldWidget.value, widget.value)) {
      if (_todo.length < 3) {
        _todo.add(widget.value);
      } else {
        _todo[_todo.length - 1] = widget.value;
      }
      if (!_opacityController.isAnimating) {
        _animateNext();
      }
    }
    if (oldWidget.duration != widget.duration) {
      _opacityController.duration = widget.duration;
    }
    if (oldWidget.highlightDuration != widget.highlightDuration) {
      _sizeController.duration =
          (widget.highlightDuration ?? widget.duration) * 0.5;
    }
    if (oldWidget.curve != widget.curve) {
      _opacityAnimation.curve = widget.curve;
    }
    if (oldWidget.disappearingCurve != widget.disappearingCurve) {
      _opacityAnimation.reverseCurve = widget.disappearingCurve;
    }
    if (oldWidget.highlightingCurve != widget.highlightingCurve) {
      _sizeAnimation.curve = widget.highlightingCurve;
    }
    if (oldWidget.highlightingReverseCurve != widget.highlightingReverseCurve) {
      _sizeAnimation.reverseCurve = widget.highlightingReverseCurve;
    }
  }

  void _animateNext() {
    if (_todo.length < 2) return;
    if (widget.highlightTransition.call(_todo[0], _todo[1])) {
      _sizeController.forward();
    }
    _opacityController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    bool twoActive = _todo.length > 1;
    T current = twoActive ? _todo[1] : _todo[0];
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.passthrough,
        alignment: widget.stackAlignment,
        children: [
          if (twoActive)
            Positioned.fill(
              child: CustomClipRect(
                clipBehavior: widget.clipBehavior,
                child: OverflowBox(
                  alignment: widget.stackAlignment,
                  minWidth: constraints.minWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: constraints.minHeight,
                  maxHeight: constraints.maxHeight,
                  child: ConstrainedBox(
                    constraints: constraints,
                    child: AnimatedBuilder(
                      animation: _opacityAnimation,
                      builder: (context, child) => Opacity(
                        opacity: 1 - _opacityAnimation.value,
                        child: child,
                      ),
                      child: EmptyWidget(
                          key: _getKey(_todo[0]),
                          child: widget.builder(context, _todo[0])),
                    ),
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            key: _animatedSizeKey,
            animation: _sizeAnimation,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (widget.highlightScale - 1.0) * _sizeAnimation.value,
              child: child,
            ),
            child: CustomAnimatedSize(
              clipBehavior: widget.clipBehavior,
              duration: widget.sizeDuration ?? widget.duration,
              curve: widget.sizeCurve,
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) => Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
                child: EmptyWidget(
                    key: _getKey(current),
                    child: widget.builder(context, current)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _LocalKey<T> _getKey(T value) => _LocalKey(_stateKey, value, _equals);

  bool _equals(T t1, T t2) => widget.equals(t1, t2);
}

class _LocalKey<T> extends GlobalKey {
  final Key stateKey;
  final T value;
  final bool Function(T t1, T t2) equals;

  const _LocalKey(this.stateKey, this.value, this.equals) : super.constructor();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LocalKey<T> &&
          runtimeType == other.runtimeType &&
          stateKey == other.stateKey &&
          equals(value, other.value);

  // Because of the customizable equals method, the hashcode of value cannot
  // be used here without the risk of a falsely unequal hashcode.
  @override
  int get hashCode => stateKey.hashCode;
}
