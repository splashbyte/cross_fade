import 'package:flutter/material.dart';

import 'custom_clip_rect.dart';
import 'empty_widget.dart';

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

  /// The duration of the highlight animation.
  final Duration highlightDuration;

  /// The alignment for the children of the underlying stack.
  final AlignmentGeometry stackAlignment;

  /// The clip behaviour for clipping while the size animation.
  /// For more customization like BorderRadius or similar please use
  /// widgets like [ClipRRect] or [Container] and their [clipBehaviour].
  final Clip clipBehaviour;

  /// The default constructor of [CrossFade].
  const CrossFade({
    Key? key,
    this.duration = const Duration(milliseconds: 750),
    required this.value,
    required this.builder,
    this.equals = _defaultEquals,
    this.highlightTransition = _defaultHighlightTransition,
    this.stackAlignment = AlignmentDirectional.center,
    this.highlightScale = 1.2,
    this.highlightDuration = const Duration(milliseconds: 750),
    this.clipBehaviour = Clip.none,
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
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _sizeAnimation;
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

    _sizeController =
        AnimationController(vsync: this, duration: widget.highlightDuration);

    _opacityAnimation = CurvedAnimation(
      parent: _opacityController,
      curve: Curves.easeIn,
    );

    _sizeAnimation = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(0.0),
          weight: 25.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.ease)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.ease.flipped)),
          weight: 50.0,
        ),
      ],
    ).animate(_sizeController);
  }

  @override
  void dispose() {
    _opacityController.dispose();
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
      _sizeController.duration = widget.highlightDuration;
    }
  }

  void _animateNext() {
    if (_todo.length < 2) return;
    if (widget.highlightTransition.call(_todo[0], _todo[1])) {
      _sizeController.forward(from: 0.0);
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
                clipBehaviour: widget.clipBehaviour,
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
            child: AnimatedSize(
              clipBehavior: widget.clipBehaviour,
              duration: widget.duration,
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
