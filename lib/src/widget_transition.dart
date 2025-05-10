import 'package:flutter/material.dart';

import 'widgets/empty_widget.dart';

/// A widget to apply a crossfade animation
/// between different states and/or widgets.
class WidgetTransition<T> extends StatefulWidget {
  /// The current value.
  final T value;

  /// The builder which builds the different values during the animation.
  final Widget Function(BuildContext, T) builder;

  /// The duration of the fading.
  final Duration duration;

  /// The overriding of the equals function.
  /// [WidgetTransition] only animates between two different values
  /// if [equals] returns [false] for these two.
  final bool Function(T, T) equals;

  /// [WidgetTransition] only highlights the new value during the animation
  /// if [highlightTransition] returns [true].
  final bool Function(T, T) highlightTransition;

  /// The maximum scale during the highlight animation.
  final double highlightScale;

  /// The duration of the whole highlight animation. Defaults to [duration].
  final Duration? highlightDuration;

  /// Curve of the fading in animation.
  final Curve curve;

  /// Curve of the highlighting animation.
  final Curve highlightingCurve;

  /// Reverse curve of the highlighting animation.
  /// Defaults to [highlightingCurve.flipped].
  final Curve? highlightingReverseCurve;

  /// Transition of the animation. [previous] and [previousChild] are [null] if no transition is currently in progress.
  final Widget Function(
      BuildContext context,
      Widget? previousChild,
      Widget child,
      T? previous,
      T current,
      Animation<double> animation) transitionBuilder;

  // const constructor doesn't make sense here
  /// The default constructor of [WidgetTransition].
  ///
  /// If you want to disable the size animation for performance reasons,
  /// set [sizeDuration] to [Duration.zero].
  const WidgetTransition({
    Key? key,
    this.duration = const Duration(milliseconds: 750),
    required this.value,
    required this.builder,
    this.equals = _defaultEquals,
    this.highlightTransition = _defaultHighlightTransition,
    this.highlightScale = 1.2,
    this.highlightDuration,
    this.curve = Curves.easeIn,
    this.highlightingCurve = Curves.ease,
    this.highlightingReverseCurve,
    required this.transitionBuilder,
  }) : super(key: key);

  static bool _defaultEquals(dynamic t1, dynamic t2) => t1 == t2;

  static bool _defaultHighlightTransition(dynamic t1, dynamic t2) => false;

  @override
  _WidgetTransitionState<T> createState() => _WidgetTransitionState<T>();
}

class _WidgetTransitionState<T> extends State<WidgetTransition<T>>
    with TickerProviderStateMixin {
  late final List<T> _todo;
  late final AnimationController _transitionController;
  late final AnimationController _sizeController;
  late final CurvedAnimation _transitionAnimation;
  late final CurvedAnimation _highlightingAnimation;
  final UniqueKey _stateKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _todo = [widget.value];
    _transitionController =
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

    _transitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: widget.curve,
    );

    _highlightingAnimation = CurvedAnimation(
      parent: _sizeController,
      curve: widget.highlightingCurve,
      reverseCurve: widget.highlightingReverseCurve,
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WidgetTransition<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.equals(oldWidget.value, widget.value)) {
      if (_todo.length < 3) {
        _todo.add(widget.value);
      } else {
        _todo[_todo.length - 1] = widget.value;
      }
      if (!_transitionController.isAnimating) {
        _animateNext();
      }
    } else {
      _todo[_todo.length - 1] = widget.value;
    }
    if (oldWidget.duration != widget.duration) {
      _transitionController.duration = widget.duration;
    }
    if (oldWidget.highlightDuration != widget.highlightDuration) {
      _sizeController.duration =
          (widget.highlightDuration ?? widget.duration) * 0.5;
    }
    if (oldWidget.curve != widget.curve) {
      _transitionAnimation.curve = widget.curve;
    }
    if (oldWidget.highlightingCurve != widget.highlightingCurve) {
      _highlightingAnimation.curve = widget.highlightingCurve;
    }
    if (oldWidget.highlightingReverseCurve != widget.highlightingReverseCurve) {
      _highlightingAnimation.reverseCurve = widget.highlightingReverseCurve;
    }
  }

  void _animateNext() {
    if (_todo.length < 2) return;
    if (widget.highlightTransition.call(_todo[0], _todo[1])) {
      _sizeController.forward();
    }
    _transitionController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    bool twoActive = _todo.length > 1;
    final current = twoActive ? _todo[1] : _todo[0];
    final previous = twoActive ? _todo[0] : null;
    final child = AnimatedBuilder(
        animation: _highlightingAnimation,
        child: EmptyWidget(
            key: _getKey(current), child: widget.builder(context, current)),
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 +
                (widget.highlightScale - 1.0) * _highlightingAnimation.value,
            child: child,
          );
        });
    final previousChild = previous == null
        ? null
        : EmptyWidget(
            key: _getKey(previous), child: widget.builder(context, previous));
    return widget.transitionBuilder(
        context, previousChild, child, previous, current, _transitionAnimation);
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
